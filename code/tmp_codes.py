

gcloud composer environments run gh-composer-env --location europe-west1 \
dags trigger -- --dag-id GH_Archive_data_ingestion \
    --from-date 2015-01-01 \
    --to-date 2015-01-06 \
    --reprocess-behavior completed \
    --max-active-runs 2 \
    --run-backwards \
    --dry-run


gcloud composer environments run gh-composer-env     --location europe-west1 dags trigger -- GH_Archive_data_ingestion     --exec-date 2015-01-01


gcloud storage cp pyspark_job.py gs://gh-data-lake-bucket-crucial-quarter-470111-v9/code/

gcloud storage cp ./data_ingestion.py gs://gh-composer-bucket-crucial-quarter-470111-v9/dags




gcloud dataproc jobs submit pyspark \
    gs://gh-persistent-data-crucial-quarter-470111-v9/code/pyspark_job.py \
    --cluster=gh-dataproc-cluster \
    --region=europe-west1 \
    -- \
    --year=2015 \
    --month=01 \
    --day=02


# submit job run to composer for a whole day range
for date in $(seq -w 5 31); do
  exec_date="2015-01-${date}"
  echo "Triggering DAG for ${exec_date}..."
  gcloud composer environments run gh-composer-env \
    --location europe-west1 \
    dags trigger \
    -- GH_Archive_data_ingestion \
    --exec-date ${exec_date}
done



# Connecting to DBT Cloud
# https://airflow.apache.org/docs/apache-airflow-providers-dbt-cloud/stable/connections.html#default-connection-id
# https://airflow.apache.org/docs/apache-airflow-providers-dbt-cloud/stable/operators.html
# https://airflow.apache.org/docs/apache-airflow-providers-dbt-cloud/stable/index.html#installation

export AIRFLOW_CONN_DBT_CLOUD_DEFAULT='dbt-cloud://account_id:api_token@my-access-url'
