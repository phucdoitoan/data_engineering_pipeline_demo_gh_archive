# ref: phuc
# https://cloud.google.com/composer/docs/composer-3/terraform-create-environments
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/composer_environment



resource "google_project_service" "composer_api" {
  provider = google-beta
  service = "composer.googleapis.com"
  // Disabling Cloud Composer API might irreversibly break all other
  // environments in your project.
  disable_on_destroy = false
  // this flag is introduced in 5.39.0 version of Terraform. If set to true it will
  //prevent you from disabling composer_api through Terraform if any environment was
  //there in the last 30 days
  check_if_service_has_usage_on_destroy = true
}

resource "google_storage_bucket" "gh-composer-bucket" {
  name     = "${var.gh_composer_bucket}-${var.project_id}"
  location = var.location
  force_destroy = var.force_destroy_gsc_bucket
}

resource "google_composer_environment" "gh-composer-env" {
  name   = "gh-composer-env"
  region = var.region

  storage_config {
      bucket = google_storage_bucket.gh-composer-bucket.name
  }

  config {

    software_config {
        image_version = "composer-3-airflow-2.10.5-build.15" #"composer-3-airflow-2"
      
        # airflow auto run at creation or not
        airflow_config_overrides = {
            core-dags_are_paused_at_creation = "True"
        }

        # install package in the airflow composer env
        pypi_packages = {
            #scipy = "==1.1.0"
            #apache-airflow-providers-dbt-cloud = ""
        }
        
        # set up env vars for airflow/composer env
        env_variables = {
            AIRFLOW_CONN_DBT_CLOUD_DEFAULT = "dbt-cloud://${var.dbt_account_id}:${var.dbt_token}@${var.dbt_access_url}"

            GCP_PROJECT_ID = var.project_id
            GCS_DATALAKE_BUCKET = "${var.gh_gcs_datalake_bucket}-${var.project_id}"

            DATAPROC_CLUSTER_NAME = var.gh_dataproc_cluster

            COMPOSER_BUCKET = google_storage_bucket.gh-composer-bucket.name

            REGION = var.region

            DBT_JOB_ID = dbtcloud_job.gcp_composer_job.job_id

        }
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      triggerer {
        cpu        = 0.5
        memory_gb  = 1
        count      = 1
      }
      dag_processor {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 1 #0.5 #1
        memory_gb  = 4 #2 #4
        storage_gb = 1
      }
      # phuc: increaase worker configure for more parallel and faster processing
      worker {
        cpu = 1 #0.5
        memory_gb  = 4 #2
        storage_gb = 1
        min_count  = 1
        max_count  = 4 #3
      }

    }
    
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.gh-composer-env-sa.name
    }
  }

  depends_on = [google_project_service.composer_api, google_project_iam_member.gh-composer-env-worker]
}

resource "google_service_account" "gh-composer-env-sa" {
  account_id   = "gh-composer-env-sa"
  display_name = "Service Account for GH Composer Environment"
}

resource "google_project_iam_member" "gh-composer-env-worker" {
  for_each = toset([
    "roles/composer.worker",         # Composer worker
    "roles/dataproc.editor",         # To submit job to dataproc
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gh-composer-env-sa.email}"
}