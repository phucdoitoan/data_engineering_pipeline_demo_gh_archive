variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "location" {
  default = "europe-west1"
}
variable "zone" {
  default = "europe-west1-b"
}
variable "region" {
  default = "europe-west1"
}


# Forcefully destroy gcs bucket and bigquery dataset
variable "force_destroy_gsc_bucket" {
  description = "On `terrafrom desstroy`, whether or not forcefully destroy gsc buckets with existing data"
  default = false
}

variable "force_destroy_bq_dataset" {
  description = "On `terrafrom desstroy`, whether or not forcefully destroy bq dataset with existing data"
  default = false
}


# DBT
variable "dbt_account_id" {}
variable "dbt_token" {}

variable "dbt_access_url" {
  description = "Dbt Cloud account Tenant domain, e.g. ab123.us1.dbt.com, ref: https://airflow.apache.org/docs/apache-airflow-providers-dbt-cloud/stable/connections.html#default-connection-id"
}

variable "dbt_host_url" {
  description = "Your dbt cloud access url + /api, e.g. https://ab123.us1.dbt.com/api"
}

# DBT connection to Bigquery: all this infos can be inferred from the key json file for authentication to your GCP project
variable "dbt_bigquery_private_key_id" {
  description = "SENSITIVE"
}

variable "dbt_bigquery_private_key" {
  description = "SENSITIVE"
}

variable "dbt_bigquery_client_email" {
  default="terraform@crucial-quarter-470111-v9.iam.gserviceaccount.com"
}

variable "dbt_bigquery_client_id" {
  default="107318012607790567176"
}

variable "dbt_bigquery_auth_uri" {
  default="https://accounts.google.com/o/oauth2/auth"
}

variable "dbt_bigquery_token_uri" {
  default = "https://oauth2.googleapis.com/token"
}

variable "dbt_bigquery_auth_provider_x509_cert_url" {
  default = "https://www.googleapis.com/oauth2/v1/certs"
}

variable "dbt_bigquery_client_x509_cert_url"{
  default = "https://www.googleapis.com/robot/v1/metadata/x509/terraform%40crucial-quarter-470111-v9.iam.gserviceaccount.com"
}

# Bigquery dataaset
variable "bq_dataset_id" {
  default = "gh_bq_dataset"
}

# GCS persistent data bucket
variable "gh_gcs_datalake_bucket" {
  default = "gh-data-lake-bucket"
}

# Composesr
variable "gh_composer_bucket" {
  default = "gh-composer-bucket"

}

# Dataproc variables
variable "gh_dataproc_staging_bucket" {
  default = "gh-dataproc-staging-bucket"
}

variable "gh_dataproc_temp_bucket" {
  default = "gh-dataproc-temp-bucket"
}

variable "gh_dataproc_cluster" {
  default = "gh-dataproc-cluster"
}


variable "dataproc_master_machine_type" {
  type        = string
  description = "dataproc master node machine tyoe"
  default     = "e2-standard-2"
}

variable "dataproc_worker_machine_type" {
  type        = string
  description = "dataproc worker nodes machine type"
  default     = "e2-standard-2"
}

variable "dataproc_workers_count" {
  type        = number
  description = "count of worker nodes in cluster"
  default     = 2
}
variable "dataproc_master_bootdisk" {
  type        = number
  description = "primary disk attached to master node, specified in GB"
  default     = 50
}

variable "dataproc_worker_bootdisk" {
  type        = number
  description = "primary disk attached to master node, specified in GB"
  default     = 50
}

variable "worker_local_ssd" {
  type        = number
  description = "primary disk attached to master node, specified in GB"
  default     = 0
}

# phuc: use more preemtible workers for short/stateless job
variable "preemptible_worker" {
  type        = number
  description = "number of preemptible nodes to create"
  default     = 4  #1
}