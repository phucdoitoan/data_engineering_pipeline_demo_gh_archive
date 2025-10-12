resource "google_storage_bucket" "gh-gcs-datalake-bucket" {
  name     = "${var.gh_gcs_datalake_bucket}-${var.project_id}"
  location = var.location
  force_destroy = var.force_destroy_gsc_bucket
}