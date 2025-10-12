# reference: 
# https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest/docs#token-1
# https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest/docs/guides/1_getting_started

// create a project
resource "dbtcloud_project" "my_project" {
  name = "DBT Project for GH Archive"
}


// create a global connection
resource "dbtcloud_global_connection" "my_connection" {
  name = "DBT BigQuery connection"
  bigquery = {
    gcp_project_id              = var.project_id
    #timeout_seconds             = 1000
    private_key_id              = var.dbt_bigquery_private_key_id
    private_key                 = var.dbt_bigquery_private_key
    client_email                = var.dbt_bigquery_client_email
    client_id                   = var.dbt_bigquery_client_id
    auth_uri                    = var.dbt_bigquery_auth_uri
    token_uri                   = var.dbt_bigquery_token_uri
    auth_provider_x509_cert_url = var.dbt_bigquery_auth_provider_x509_cert_url
    client_x509_cert_url        = var.dbt_bigquery_client_x509_cert_url
  }
}


// link a repository to the dbt Cloud project
### repo cloned via the deploy token strategy
resource "dbtcloud_repository" "deploy_github_repo" {
  project_id         = dbtcloud_project.my_project.id
  remote_url         = "git@github.com:phucdoitoan/GH_Archive_data_pipeline.git"
  git_clone_strategy = "deploy_key"
}

resource "dbtcloud_project_repository" "my_project_repository" {
  project_id    = dbtcloud_project.my_project.id
  repository_id = dbtcloud_repository.deploy_github_repo.repository_id
}


// create 2 environments, one for Dev and one for Prod
// here both are linked to the same Data Warehouse connection
// for Prod, we need to create a credential as well
resource "dbtcloud_environment" "my_dev" {
  dbt_version     = "latest"
  name            = "Dev"
  project_id      = dbtcloud_project.my_project.id
  type            = "development"
  connection_id   = dbtcloud_global_connection.my_connection.id
}

resource "dbtcloud_environment" "my_prod" {
  dbt_version     = "latest"
  name            = "Prod"
  project_id      = dbtcloud_project.my_project.id
  type            = "deployment"
  deployment_type = "production"
  credential_id   = dbtcloud_bigquery_credential.my_credential.credential_id
  connection_id   = dbtcloud_global_connection.my_connection.id
}

resource "dbtcloud_bigquery_credential" "my_credential" {
  project_id  = dbtcloud_project.my_project.id
  dataset     = var.bq_dataset_id
  num_threads = 4
}


# job whose run is triggered by GCP Composer/Airflow
resource "dbtcloud_job" "gcp_composer_job" {
  environment_id = dbtcloud_environment.my_prod.environment_id
  execute_steps = [
    "dbt build"
  ]
  generate_docs        = false
  is_active            = true
  name                 = "Job Triggered from GCP Composer"
  num_threads          = 4
  project_id           = dbtcloud_project.my_project.id
  run_generate_sources = true
  target_name          = "default"
  triggers = {
    "github_webhook" : false
    "git_provider_webhook" : false
    "schedule" : false
    "on_merge" : false
  }
}