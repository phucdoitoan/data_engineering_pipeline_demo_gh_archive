# Data Engineering Pipeline Demo with Github Archive Data

## Pipeline Components

Components: <br>
* Data sources: Github Archive Data: https://www.gharchive.org/
* Data Lake: use a Google Cloud Storage (GCS) bucket as a data lake to store all the data pulled from the data source
* Data Warehouse: use BigQuery as our data warehouse to store structured data (tables) that is pulled from the data lake
* Batch Processing: use Dataproc (Pyspark) to process data (clean / load) from the data lake to data warehouse in batches
* Data Transformation Engine: DBT Cloud
* Data Visualization / Analytics: Looker Studio


## 1. Set-up

### 1.1 Environment
Use conda <brb>
gcloud for authentication <br>
direnv for manage credentials infos as env variables <br>
terraform for managing all cloud insfrastructure (GCP and DBT) <br>

#### 1.1.1 Manage sensitive credentials infos as environment variables with Direnv
Direnv is very convenient for manage credentials as env vars. <br>
Install Direnv <br>
Installation: https://direnv.net/docs/installation.html <br>
Set-up: https://direnv.net/docs/hook.html <br>
Put env vars in .envrc (or .env) file in the working directory. <br>
Whenever we enter a dir with .envrc file, direnv will ask to load the env vars with `direnv allow`. When exiting the dir, direnv will release/remove the env vars.   <br> 

#### 1.1.2 Setting up Google Cloud Platform (GCP)
When creating an account on GCP, there is a free 300$ trial. <br>

* We create a GCP project for the data pipeline manually. <br>
Instruction for project creation. <br>

* Then we need to create __a IAM service account__ that will be used by terraform for creating all the necessary computing resources. <br>

* Create __json key for authentication__ with the service account <br>
Save it as `~/.google/keys/terraform_gcp.json` (this will be used later)

#### 1.1.3 Setting up DBT Cloud 
Dbt is a tool for transforming data within a data warehouse. Basically, it allows us to conveniently and neatly define/save/test a bunch of sql codes to transform data (tables).

We need to create a dbt cloud account: https://www.getdbt.com/signup . <br>
Use the 14-day free starter since we need to use its APIs for dbt project/job setup with Terraform and job run trigger from Airflow/Composer.

After creation, prepare the following information. (ref: https://airflow.apache.org/docs/apache-airflow-providers-dbt-cloud/stable/connections.html#default-connection-id)

* Account Id: 
* An API token: recommended using a service token with Account Admin permission
* Access URL: something like https://ab110.us1.dbt.com/
* Tenant domain: something like ab110.us1.dbt.com


### DBT github repository

We maintain a separate github repo for developing the dbt project: https://github.com/phucdoitoan/GH_Archive_data_pipeline . <br>

Terraform creates a "place holder" project on dbt cloud. The content of that project is pulled from this separated github repo.
These two projects will be linked by setting `Deploy Keys` https://github.com/phucdoitoan/GH_Archive_data_pipeline/settings/keys with the ssh key from the dbt cloud project. 
The ssh key is returned by terraform upon finishing resource creation, i.e. when `terraform apply` finishes successfully, or can be retrieved from the dbt cloud project on dbt cloud (see: https://docs.getdbt.com/docs/cloud/git/import-a-project-by-git-url).

NOTE: terraform cannot set "development credentials" for development environmnet of a dbt project (see: https://github.com/dbt-labs/terraform-provider-dbtcloud/issues/541).
So after creation, in order to continue developing dbt models, we need to manually set up the credential for development environment (see: https://docs.getdbt.com/docs/dbt-cloud-environments).
No need for setting this up if we only want to run the existing dbt models in Production environment since the credentials for prod env are already set up with terraform.







## Google Composer/Airflow

### Cost Saving with Save and Load snapshots:
All the information of a composer env (env vars, env config, airflow states, runs, etc) can be saved into a snapshots. 

These saved snapshots can be load back again to a newly created Composer environment.

This is very convenient as we can completely destroy all computing resources on GCP (composer/airflow, dataproc cluster, vm instances) and only keep necessary data in GSC buckets / Bigquery dataset. Only when need to run the pipeline, we can create the compute resource again and restored all previous state with snapshots. This helps __reduce cost__.


## Terraform

Go into the dir with `main.tf` file and run needed commands accordingly.
Basic commands (see: https://developer.hashicorp.com/terraform/cli/commands): <br>
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply`
* `terraform destroy`

### Terraform codes

The necessary resources for each component of the pipeline are defined in corresponding terraform files.


## Dataproc / Pyspark job

Here

## Composer / Airflow DAGs

Here

## Credentials as env vars in .envrc

Set credentials to corresponding env var in the .envrc file.