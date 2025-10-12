# output "public_ip" {
#     value = google_compute_instance.gh_archive_compute_vm.network_interface[0].access_config[0].nat_ip
# }

output "dbt_git_deploy_key" {
    value = dbtcloud_repository.deploy_github_repo.deploy_key
}
