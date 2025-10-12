import datetime

from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator

from airflow.providers.google.cloud.operators.gcs import GCSCreateBucketOperator, GCSDeleteObjectsOperator
from airflow.providers.google.cloud.transfers.local_to_gcs import LocalFilesystemToGCSOperator

from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator

from airflow.providers.dbt.cloud.sensors.dbt import DbtCloudJobRunSensor
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator


# download files
import os


# need to export these vars in airflow containers, in order to import values from .envrc file
# GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "crucial-quarter-470111-v9")
# GCP_GCS_BUCKET = os.environ.get("GCP_GCS_BUCKET", f"gh-data-lake-bucket-{GCP_PROJECT_ID}")

# phuc: All the env vars are inferred from Composer/Airflow environments, which are set in composer.tf
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "")
GCP_GCS_BUCKET = os.environ.get("GCS_DATALAKE_BUCKET", "")

# DATAPROC_CLUSTER_NAME = os.environ.get("DATAPROC_CLUSTER_NAME", f"gh-dataproc-cluster")
DATAPROC_CLUSTER_NAME = os.environ.get("DATAPROC_CLUSTER_NAME", "")

# composer bucket
COMPOSER_BUCKET = os.environ.get("COMPOSER_BUCKET", "")

GCS_JOB_FILE = f"gs://{GCP_GCS_BUCKET}/code/pyspark_job.py"

# REGION = "europe-west1"
REGION = os.environ.get("REGION")

DBT_JOB_ID = os.environ.get("DBT_JOB_ID")


print(f"GCP_PROJECT_ID: {GCP_PROJECT_ID}")
print(f"GCP_GCS_BUCKET: {GCP_GCS_BUCKET}")
print(f"DATAPROC_CLUSTER_NAME: {DATAPROC_CLUSTER_NAME}")


START_HOUR = 0
END_HOUR = 23


def configure_download_url(start_hour=0, end_hour=23, **context):
    year = context['ds_nodash'][:4]
    month = context['ds_nodash'][4:6]
    day = context['ds_nodash'][6:8]

    #save_path = f"/opt/airflow/data/{year}-{month}-{day}"
    save_path = f"/home/airflow/gcs/data/{year}-{month}-{day}"
    if not os.path.exists(save_path):
        os.makedirs(save_path)

    assert end_hour >= start_hour
    download_url = f"https://data.gharchive.org/{year}-{month}-{day}-{{{start_hour}..{end_hour}}}.json.gz"

    print(f"Download URL: {download_url}")
    print(f"Save Path: {save_path}")
    print(f"Year: {year}, Month: {month}, Day: {day}")

    return {'download_url': download_url, 
            'save_path': save_path,
            'year': year,
            'month': month,
            'day': day,
            }


def define_pyspark_job(day, month, year):

    PYSPARK_JOB = {
        "reference": {"project_id": GCP_PROJECT_ID},
        "placement": {"cluster_name": DATAPROC_CLUSTER_NAME},
        "pyspark_job": {
            "main_python_file_uri": GCS_JOB_FILE,
            "args": [
                f"--year={year}",
                f"--month={month}",
                f"--day={day}"
            ]
        }
    }

    return PYSPARK_JOB

with DAG(
    dag_id="GH_Archive_data_ingestion",
    start_date=datetime.datetime(2015, 1, 1),
    #schedule="@daily",
    schedule="59 23 * * *",  # schedule at the end of each day, i.e. 23:59:00 UTC time
    catchup=False,
    max_active_runs=1
) as dag:
    
    configure_download_url_task = PythonOperator(
        task_id="configure_download_url",
        python_callable=configure_download_url,
        op_kwargs={
            'start_hour': START_HOUR,
            'end_hour': END_HOUR,
        },
        do_xcom_push=True,
    )


    download_task = BashOperator(
        task_id="download_GH_Archive_data",
        bash_command= 'wget {{ ti.xcom_pull(task_ids="configure_download_url")["download_url"] }} -P {{ ti.xcom_pull(task_ids="configure_download_url")["save_path"] }}'
    )

    # better to be created with terraform
    # create_bucket_task = GCSCreateBucketOperator(
    #     project_id=GCP_PROJECT_ID,
    #     task_id="create_gcs_bucket",
    #     bucket_name=GCP_GCS_BUCKET,
    #     location="EU",
    #     storage_class="STANDARD",
    # )

    upload_to_gcs_task = LocalFilesystemToGCSOperator(
        task_id="upload_to_gcs",
        #src="{{ ti.xcom_pull(task_ids='configure_download_url')['save_path'] }}/2025-10-02-0.json.gz",
        src= list(map(lambda x: f"{{{{ ti.xcom_pull(task_ids='configure_download_url')['save_path'] }}}}/{{{{ ti.xcom_pull(task_ids='configure_download_url')['year'] }}}}-{{{{ ti.xcom_pull(task_ids='configure_download_url')['month'] }}}}-{{{{ ti.xcom_pull(task_ids='configure_download_url')['day'] }}}}-{x}.json.gz", range(START_HOUR, END_HOUR+1))),
        dst="data/{{ ti.xcom_pull(task_ids='configure_download_url')['year'] }}-{{ ti.xcom_pull(task_ids='configure_download_url')['month'] }}-{{ ti.xcom_pull(task_ids='configure_download_url')['day'] }}/",
        bucket=GCP_GCS_BUCKET,
        chunk_size=5 * 1024 * 1024,
    )

    configure_download_url_task >> download_task
    download_task >> upload_to_gcs_task

    # to clean up temporary bucket that composer/airflow store download data, after uploading to a persistent "datalake" GCS bucket
    clean_up_temp_bucket_task = GCSDeleteObjectsOperator(
        task_id = "clean_up_temp_bucket_task",
        bucket_name = COMPOSER_BUCKET,
        prefix = "data/{{ ti.xcom_pull(task_ids='configure_download_url')['year'] }}-{{ ti.xcom_pull(task_ids='configure_download_url')['month'] }}-{{ ti.xcom_pull(task_ids='configure_download_url')['day'] }}/"
    )

    upload_to_gcs_task >> clean_up_temp_bucket_task

    # create_bucket_task >> upload_to_gcs_task

    submit_dataproc_job_task = DataprocSubmitJobOperator(
        task_id="dataproc_pyspark_task",
        job=define_pyspark_job(
            year="{{ ti.xcom_pull(task_ids='configure_download_url')['year'] }}",
            month="{{ ti.xcom_pull(task_ids='configure_download_url')['month'] }}",
            day="{{ ti.xcom_pull(task_ids='configure_download_url')['day'] }}"
        ),
        region=REGION,
        project_id=GCP_PROJECT_ID
    )

    upload_to_gcs_task >> submit_dataproc_job_task


    # trigger job run in dbt cloud
    dbt_job_run_trigger = DbtCloudRunJobOperator(
        task_id="dbt_job_run_trigger",
        job_id=DBT_JOB_ID,
        #check_interval=10,
        #timeout=300,
        wait_for_termination=False
    )

    dbt_job_run_sensor  = DbtCloudJobRunSensor(
        task_id="dbt_job_run_sensor",
        run_id=dbt_job_run_trigger.output,
        timeout=300,
        deferrable=True
    )

    submit_dataproc_job_task >> dbt_job_run_trigger >> dbt_job_run_sensor


    
