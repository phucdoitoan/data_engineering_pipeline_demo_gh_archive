terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "7.5.0"
        }

        dbtcloud = {
        source  = "dbt-labs/dbtcloud"
        version = "1.2.2"
        }
    }
}

provider "google" {
    zone = var.zone
}

provider "google-beta" {
    zone = var.zone
}

provider "dbtcloud" {
    account_id = var.dbt_account_id
    token = var.dbt_token
    host_url = var.dbt_host_url
}

