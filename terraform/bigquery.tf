resource "google_bigquery_dataset" "gh-bigquery-dataset" {
  dataset_id                  = var.bq_dataset_id
  description                 = "Bigquery dataset to store Github Archive data"
  location                    = var.location
  delete_contents_on_destroy  = var.force_destroy_bq_dataset
}
