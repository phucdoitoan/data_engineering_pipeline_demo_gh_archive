resource "google_service_account" "gh-dataproc-sa" {
  account_id   = "gh-dataproc-sa"
  display_name = "Service Account for GH Dataproc Cluster"
}

resource "google_project_iam_member" "gh-dataproc-sa_roles" {
  for_each = toset([
    "roles/dataproc.worker",         # Required for Dataproc operations
    "roles/storage.objectAdmin",     # Read/write to GCS
    "roles/bigquery.dataEditor",     # Create and update tables
    "roles/bigquery.jobUser"         # Run BigQuery load/query jobs
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gh-dataproc-sa.email}"
}

# phuc: not really good as duplicate iam role access to storage.objectAdmin
# phuc: added this iam role to avoid error in case the bucket already existed and gh-dataproc-sa_roles not yet propagated
resource "google_storage_bucket_iam_member" "gh-dataproc-staging_access" {
  bucket = google_storage_bucket.gh-dataproc_staging-bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gh-dataproc-sa.email}"
}
# phuc: added this iam role to avoid error in case the bucket already existed and gh-dataproc-sa_roles not yet propagated
resource "google_storage_bucket_iam_member" "gh-dataproc-temp_access" {
  bucket = google_storage_bucket.gh-dataproc_temp-bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gh-dataproc-sa.email}"
}

resource "google_storage_bucket" "gh-dataproc_staging-bucket" {
  name     = "${var.gh_dataproc_staging_bucket}-${var.project_id}"
  location = var.location
  force_destroy = var.force_destroy_gsc_bucket
}

resource "google_storage_bucket" "gh-dataproc_temp-bucket" {
  name     = "${var.gh_dataproc_temp_bucket}-${var.project_id}" 
  location = var.location
  force_destroy = var.force_destroy_gsc_bucket
}


resource "google_dataproc_cluster" "gh-dataproc-cluster" {
  name     = var.gh_dataproc_cluster
  region   = var.location
  graceful_decommission_timeout = "120s"

  cluster_config {
    staging_bucket = google_storage_bucket.gh-dataproc_staging-bucket.name
    temp_bucket = google_storage_bucket.gh-dataproc_temp-bucket.name

    cluster_tier = "CLUSTER_TIER_STANDARD"

    # Override or set some custom properties
    software_config {
      image_version = "2.2-debian12"
      optional_components = ["JUPYTER", "DOCKER"]

      # phucdoitoan: use this to set env vars for dataproc as well
      # ref: 
      # https://stackoverflow.com/questions/61207679/setting-environment-variables-on-dataproc-cluster-nodes
      # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_cluster#nested_software_config
      override_properties = {
        "spark-env:GCP_PROJECT_ID" = var.project_id
        "spark-env:GCS_DATALAKE_BUCKET" = "${var.gh_gcs_datalake_bucket}-${var.project_id}"
        "spark-env:DATAPROC_TEMP_BUCKET" = "${var.gh_dataproc_temp_bucket}-${var.project_id}"
        "spark-env:BQ_DATASET" = var.bq_dataset_id
      }
    }

    master_config {
      num_instances = 1
      machine_type  = var.dataproc_master_machine_type
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = var.dataproc_master_bootdisk
      }
    }

    worker_config {
      num_instances    = var.dataproc_workers_count
      machine_type     = var.dataproc_worker_machine_type
      disk_config {
        boot_disk_type = "pd-standard"
        boot_disk_size_gb = var.dataproc_worker_bootdisk
        num_local_ssds    = var.worker_local_ssd
      }
    }

    preemptible_worker_config {
      num_instances = var.preemptible_worker
    }

    gce_cluster_config {
      # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
      zone = var.zone
      service_account = google_service_account.gh-dataproc-sa.email
      service_account_scopes = [
        "cloud-platform"
        #"https://www.googleapis.com/auth/cloud-platform"
      ]
    }

    # You can define multiple initialization_action blocks
    # Use this to install additional software, do some configuration on all nodes
    # initialization_action {
    #   script      = "gs://dataproc-initialization-actions/stackdriver/stackdriver.sh"
    #   timeout_sec = 500
    # }
  }
  
  depends_on = [google_project_iam_member.gh-dataproc-sa_roles, 
                google_storage_bucket_iam_member.gh-dataproc-staging_access, 
                google_storage_bucket_iam_member.gh-dataproc-temp_access]
}