# Upload necessary code/data files, e.g. pyspark job for dataproc or dags file for composer, to the proper target resources

# references: 
# https://stackoverflow.com/questions/58951704/terraform-upload-folder-to-google-storage
# https://developer.hashicorp.com/terraform/language/provisioners
# https://stackoverflow.com/questions/67217231/gsutil-not-found-with-terraform-and-cloudbuild


resource "google_storage_bucket_object" "dag_file" {
  name   = "dags/data_ingestion.py"
  bucket = google_storage_bucket.gh-composer-bucket.name
  source = "../code/airflow/data_ingestion.py"
}

resource "google_storage_bucket_object" "pyspark_job_file" {
  name   = "code/pyspark_job.py"
  bucket = google_storage_bucket.gh-gcs-datalake-bucket.name
  source = "../code/dataproc/pyspark_job.py"
}

# to upload a whole folder, use terraform provisioner such as 
# resource "null_resource" "upload_dags" {
#   provisioner "local-exec" {
#     command = "gsutil -m cp -r ./dags gs://${google_storage_bucket.composer_dag_bucket.name}/dags/"
#   }
# }