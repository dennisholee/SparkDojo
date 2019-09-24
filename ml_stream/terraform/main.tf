provider "google" {
  project = "${var.project_id}"
}

locals {
  region          = "asia-east2"
  vpc_name        = "ml"
  ip_cidr_range   = "192.168.0.0/24"
  app             = "ml"
  bucket          = "${var.project_id}"
}

#-------------------------------------------------------------------------------
# Service Account
#-------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id   = "${local.app}-app-sa"
  display_name = "${local.app}-app-sa"
}

resource "google_project_iam_binding" "sa-dataproc-iam" {
  role   = "roles/dataproc.worker"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}


resource "google_project_iam_binding" "sa-pubsub-iam" {
  role   = "roles/pubsub.subscriber"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}

#-------------------------------------------------------------------------------
# Network
#-------------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${local.vpc_name}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${local.vpc_name}-subnet"
  region                   = "${local.region}"
  ip_cidr_range            = "${local.ip_cidr_range}"
  network                  = "${google_compute_network.vpc.self_link}"
  private_ip_google_access = true
}


#-------------------------------------------------------------------------------
# Firewall 
#-------------------------------------------------------------------------------

resource "google_compute_firewall" "fw-dataproc" {
  name          = "fw-dataproc"
  network       = "${google_compute_network.vpc.self_link}"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "udp"
    ports    = ["0-65335"]
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65335"]
  }

  allow {
    protocol = "icmp"
  }

  target_tags = ["fw-dataproc"]
}


#-------------------------------------------------------------------------------
# PubSub
#-------------------------------------------------------------------------------

resource "google_pubsub_topic" "msg-src-topic" {
  name = "${local.app}-msg-src-topic"
}

resource "google_pubsub_subscription" "msg-src-subscription" {
  name  = "${local.app}-msg-src-subscription"
  topic = "${google_pubsub_topic.msg-src-topic.name}"

  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

#-------------------------------------------------------------------------------
# Dataproc
#-------------------------------------------------------------------------------

resource "google_dataproc_cluster" "cluster" {
    name       = "${local.app}-cluster"
    region     = "${local.region}"

    labels = {
        function = "machine-learning"
    }

    cluster_config {
        staging_bucket        = "${local.bucket}"

        master_config {
            num_instances     = 1
            machine_type      = "n1-standard-1"
            disk_config {
                boot_disk_type = "pd-ssd"
                boot_disk_size_gb = 15
            }
        }

        worker_config {
            num_instances     = 2
            machine_type      = "n1-standard-1"
            disk_config {
                boot_disk_size_gb = 15
                num_local_ssds    = 1
            }
        }

        preemptible_worker_config {
            num_instances     = 0
        }

        # Override or set some custom properties
        software_config {
            image_version       = "1.3.7-deb9"
            override_properties = {
                "dataproc:dataproc.allow.zero.workers" = "true"
            }
        }

        gce_cluster_config {
            #network        = "${google_compute_network.dataproc_network.name}"
            subnetwork      = "${google_compute_subnetwork.subnet.self_link}"
            service_account = "${google_service_account.sa.email}" 
            service_account_scopes = [
              "https://www.googleapis.com/auth/pubsub", 
              "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
              "https://www.googleapis.com/auth/devstorage.read_write",
              "https://www.googleapis.com/auth/logging.write"
            ]
            tags = ["fw-dataproc"]
        }

        # You can define multiple initialization_action blocks
        #initialization_action {
        #    script      = "gs://dataproc-initialization-actions/stackdriver/stackdriver.sh"
        #    timeout_sec = 500
        #}
    }
}
