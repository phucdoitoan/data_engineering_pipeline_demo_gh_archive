# To create a VM instance with a service account and firewall rules

# resource "google_service_account" "gh-vm-sa" {
#   account_id   = "gh-vm-sa" # TODO: provide a unique id
#   display_name = "GitHub Archive VM Instance Service Account"
# }


# data "google_compute_image" "ubuntu24-04" {
#   family = "ubuntu-2404-lts-amd64"
#   project = "ubuntu-os-cloud"
# }

# resource "google_compute_instance" "gh_archive_compute_vm" {
#     name = "gh-archive-vm"
#     machine_type = "n2-standard-2"
#     zone = "europe-west1-b"

#     tags = ["ssh", "http"]

#     boot_disk {
#         initialize_params {
#             image = data.google_compute_image.ubuntu24-04.self_link
#             size = 100 #GB
#         }
#     }

#     metadata_startup_script = file(
#         "${path.module}/scripts/vm_startup.sh" # TODO: provide the relative path to your bash script
#     )

#     network_interface {
#         network = "default"

#         access_config {
#             // Ephemeral public IP
#         }
#     }

#     metadata = {
#         ssh-keys = "phucdoitoan:${file("~/.ssh/google_compute_engine.pub")}"
#     }

#     service_account {
#         email = google_service_account.gh-vm-sa.email
#         scopes = ["cloud-platform"]
#     }

# }

# resource "google_compute_firewall" "ssh" {
#     name = "ssh-access"
#     network = "default"

#     allow {
#       protocol = "tcp"
#       ports    = ["22"]
#     }
    
#     target_tags = ["ssh"]
#     source_ranges = ["0.0.0.0/0"]

#   }

# resource "google_compute_firewall" "http" {
#     name = "http-access"
#     network = "default"

#     allow {
#       protocol = "tcp"
#       ports    = ["80"]
#     }
    
#     target_tags = ["http"]
#     source_ranges = ["0.0.0.0/0"]

#   }

