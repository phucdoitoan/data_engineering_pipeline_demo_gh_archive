from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql import types

import os


# phuc: All the env vars are inferred from Dataproc cluster environments, which are set in dataproc.tf
bq_dataset_id = os.environ.get("BQ_DATASET")
project_id = os.environ.get("GCP_PROJECT_ID")
download_data_bucket = os.environ.get("GCS_DATALAKE_BUCKET")
bucket = os.environ.get("DATAPROC_TEMP_BUCKET")


def pyspark_job(day, month, year):
    """
    day: string - dd
    month: string - mm
    year: string - yyyy
    """

    # bq_dataset_id = "gh_bq_dataset"
    # project_id = "crucial-quarter-470111-v9"
    # download_data_bucket = f"gh-data-lake-bucket-{project_id}"
    # bucket = f"gh-dataproc-temp-bucket-{project_id}"

    spark = SparkSession.builder \
        .appName("Github Archive") \
        .getOrCreate()

    #bucket = os.environ("TF_VAR_gh_dataproc_temp_bucket")
    spark.conf.set('temporaryGcsBucket', bucket)


    schema = types.StructType([
        types.StructField('id', types.StringType(), nullable=True),
        types.StructField('type', types.StringType(), nullable=True),

        types.StructField('actor', types.StructType([
            types.StructField('id', types.IntegerType(), nullable=True),
            types.StructField('login', types.StringType(), nullable=True),
            types.StructField('display_login', types.StringType(), nullable=True),
            types.StructField('gravatar_id', types.StringType(), nullable=True),
            types.StructField('url', types.StringType(), nullable=True),
            types.StructField('avatar_url', types.StringType(), nullable=True)
        ]), nullable=True),

        types.StructField('repo', types.StructType([
            types.StructField('id', types.IntegerType(), nullable=True),
            types.StructField('name', types.StringType(), nullable=True),
            types.StructField('url', types.StringType(), nullable=True)
        ]), nullable=True),

        types.StructField('payload', types.MapType(
            types.StringType(), types.StringType()
        ), nullable=True),

        types.StructField('public', types.BooleanType(), nullable=True),
        types.StructField('created_at', types.TimestampType(), nullable=True),

        types.StructField('org', types.StructType([
            types.StructField('id', types.IntegerType(), nullable=True),
            types.StructField('login', types.StringType(), nullable=True),
            types.StructField('gravatar_id', types.StringType(), nullable=True),
            types.StructField('url', types.StringType(), nullable=True),
            types.StructField('avatar_url', types.StringType(), nullable=True)
        ]), nullable=True)
    ])


    input_path = f"gs://{download_data_bucket}/data/{year}-{month}-{day}/"

    df = spark.read.schema(schema).json(input_path)

    def get_day(timestamp):
        return timestamp.strftime('%Y-%m-%d')

    def get_weekday(timestamp):
        return timestamp.strftime('%A')

    weekday = F.udf(get_weekday)
    day = F.udf(get_day)

    
    df_merge = df \
        .withColumn("user_name", F.col("actor.login")) \
        .withColumn("repo_id", F.col("repo.id")) \
        .withColumn("repo_name", F.split(F.col("repo.name"), "/")[1]) \
        .withColumn("org_exists", F.col("org").isNotNull()) \
        .withColumn(
            "count_commits",
            F.when(F.col("payload.size") >= 1, F.col("payload.size")).otherwise(0)
        )
    
    df_merge = df_merge \
        .drop(F.col("actor")) \
        .drop(F.col("repo")) \
        .drop(F.col("payload")) \
        .drop(F.col("org"))
    
    df_merge = df_merge.repartition("created_at")

    table_name = "github_activity"
    save_table = f"{project_id}.{bq_dataset_id}.{table_name}"
    

    print(f"WRITING: Now writing to {save_table}")

    df_merge.write.format('bigquery') \
        .mode('append') \
        .option("partitionBy", "created_at") \
        .option("partitionField", "created_at") \
        .option('table', save_table) \
        .save(save_table)

    print(f"FINISHING writing to {save_table}")

    

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--year', required=True, help="string yyyy")
parser.add_argument('--month', required=True, help="string mm")
parser.add_argument('--day', required=True, help="string dd")


args = parser.parse_args()

year = args.year
month = args.month
day = args.day

pyspark_job(day=day, month=month, year=year)