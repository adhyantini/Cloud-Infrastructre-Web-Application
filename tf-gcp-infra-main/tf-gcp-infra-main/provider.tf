terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.21.0"
    }
  }
}

provider "google" {
  project = var.project_name
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                            = var.network_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

data "google_storage_project_service_account" "gcs_service_account" {}

resource "google_compute_firewall" "rules" {
  name    = var.firewall_name
  network = google_compute_network.vpc_network.name

  allow {
    protocol = var.firewall_allowed_protocol1
    ports    = ["80", "8080", "5432", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# resource "google_compute_subnetwork" "db_subnet" {
#   name                     = var.dbsub_name
#   region                   = var.region
#   network                  = google_compute_network.vpc_network.id
#   ip_cidr_range            = var.ip_cidr_range_db
#   private_ip_google_access = true
# }

resource "google_compute_global_address" "private_service_connection_range" {
  name          = var.private_service_connection_range_name
  purpose       = var.private_service_connection_range_purpose
  address_type  = var.private_service_connection_range_addressType
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = var.private_vpc_connection_service
  reserved_peering_ranges = [google_compute_global_address.private_service_connection_range.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance-${random_id.db_name_suffix.hex}"
  database_version = var.postgres_database_version
  region           = var.region

  settings {
    tier              = var.postgres_tier
    availability_type = var.postgres_availability_type
    disk_type         = var.postgres_disk_type
    disk_size         = var.postgres_disk_size
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
      # enable_private_path_for_google_cloud_services = true
    }
  }
  encryption_key_name = google_kms_crypto_key.my_crypto_key_sql_instance.id

  deletion_protection = false
  depends_on = [google_service_networking_connection.private_vpc_connection, google_kms_crypto_key_iam_binding.crypto_key-sql]
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = var.password_override
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "users" {
  name     = var.db_user_name
  instance = google_sql_database_instance.postgres.name
  password = random_password.password.result

}


resource "google_service_account" "service_account" {
  account_id   = var.service_account_ID
  display_name = var.service_account_displayName
}

resource "google_project_iam_binding" "logging" {
  project = var.project_name
  role    = var.role_logging_admin

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "metricWriter" {
  project = var.project_name
  role    = var.role_metric_writer

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_kms_key_ring" "key_ring" {
  name     = "ring4"
  location = var.region
}

resource "google_kms_crypto_key" "my_crypto_key_sql_instance" {
  name            = var.crypto_key_sql
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = var.crypto_key_rotation_period
  version_template {
    algorithm = var.crypto_key_algorithm
  }
}

resource "google_kms_crypto_key" "my_crypto_key_cloud_storage_bucket" {
  name            = var.crypto_key_cloud_storage
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = var.crypto_key_rotation_period
  version_template {
    algorithm = var.crypto_key_algorithm
  }
}

resource "google_kms_crypto_key" "my_crypto_key_vm_instances" {
  name            = var.crypto_key_vm
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = var.crypto_key_rotation_period
  version_template {
    algorithm = var.crypto_key_algorithm
  }
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project = var.project_name
  service = var.gcp_sa_cloud_sql
}
resource "google_kms_crypto_key_iam_binding" "crypto_key-sql" {
  crypto_key_id = google_kms_crypto_key.my_crypto_key_sql_instance.id
  role          = var.crypto_key_role
  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "crypto_key-storage-bucket" {
  crypto_key_id = google_kms_crypto_key.my_crypto_key_cloud_storage_bucket.id
  role          = var.crypto_key_role
   members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_service_account.email_address}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "crypto_key-vm" {
  crypto_key_id = google_kms_crypto_key.my_crypto_key_vm_instances.id
  role          = var.crypto_key_role
    members = [
    var.crypto_key_vm_service_role
  ]
}

resource "google_compute_subnetwork" "loadBalancer_subnet" {
  name                     = var.loadbalancersub_name
  ip_cidr_range            = var.ip_cidr_range_load_balancer
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_route" "vm_internet_access" {
  name             = var.route_name
  network          = google_compute_network.vpc_network.id
  dest_range       = var.ip_destination_range
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_compute_region_instance_template" "vm_instance" {
  name                 = var.vm_instance_name
  description          = var.compute_region_instance_template_description
  instance_description = var.compute_region_instance_template_instance_description

  machine_type = var.vm_machine_type

  can_ip_forward = false

  // Create a new boot disk from an image
  disk {
    source_image = var.vm_image_name
    auto_delete  = true
    boot         = true
    disk_type    = var.vm_bootdisk_type
    disk_size_gb = var.vm_bootdisk_size

  }

  network_interface {
    subnetwork = google_compute_subnetwork.loadBalancer_subnet.name
  }

  metadata_startup_script = <<-EOF
   #!/bin/bash
    sudo -u csye6225 bash -c 'cat <<EOF2 > /tmp/webapp/.env
      DB_USER=${google_sql_user.users.name}
      DB_PASSWORD=${google_sql_user.users.password}
      DB_HOST=${google_sql_database_instance.postgres.private_ip_address}
      DB_NAME=${google_sql_database.database.name}
      PORT=8080
      EOF2'
    EOF

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
  tags       = ["load-balanced-backend"]
  depends_on = [google_compute_subnetwork.loadBalancer_subnet, google_sql_database_instance.postgres]
}

resource "google_compute_health_check" "database_health_check" {
  name        = var.health_check_name
  description = var.health_check_description

  timeout_sec         = var.health_check_timeout_second
  check_interval_sec  = var.health_check_check_interval_second
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  http_health_check {
    port               = var.health_check_port
    port_specification = var.health_check_port_spec
    request_path       = var.health_check_request_path
    response           = var.health_check_response
  }
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = var.autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.appserver.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_max_replicas
    min_replicas    = var.autoscaler_min_replicas
    cooldown_period = var.autoscaler_cooldown_period

    cpu_utilization {
      target = var.autoscaler_target_cpu_utilization
    }
  }
}

resource "google_compute_region_instance_group_manager" "appserver" {
  name = var.instance_group_manager_name

  base_instance_name        = var.instance_group_manager_base_instance_name
  region                    = var.region
  distribution_policy_zones = ["us-central1-a", "us-central1-f"]

  version {
    instance_template = google_compute_region_instance_template.vm_instance.self_link
  }

  named_port {
    name = var.instance_group_manager_port_name
    port = var.instance_group_manager_port_number
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.database_health_check.id
    initial_delay_sec = var.instance_group_manager_initial_delay_sec
  }
}

resource "google_compute_firewall" "health-check" {
  name = var.firewall_health_check
  allow {
    protocol = var.firewall_allowed_protocol1
    ports    = ["80", "443", "8080"]
  }
  direction     = var.firewall_direction
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["load-balanced-backend"]
}


resource "google_compute_global_address" "default" {
  name         = var.compute_global_address_name
  address_type = var.compute_global_address_type
}

resource "google_compute_backend_service" "default" {
  name                  = var.backend_service_name
  load_balancing_scheme = var.backend_service_load_balancing_scheme
  locality_lb_policy    = var.backend_service_locality_lb_policy
  health_checks         = [google_compute_health_check.database_health_check.id]
  protocol              = var.backend_service_protocol
  port_name             = var.backend_service_port_name
  session_affinity      = var.backend_service_session_affinity
  timeout_sec           = var.backend_service_timeout_sec
  backend {
    group           = google_compute_region_instance_group_manager.appserver.instance_group
    balancing_mode  = var.backend_service_balancing_mode
    capacity_scaler = var.backend_service_capacity_scaler
  }
}

resource "google_compute_url_map" "default" {
  name            = var.compute_url_map_name
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "default" {
  name    = var.target_proxy_name
  url_map = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = var.forwarding_rule_name
  ip_protocol           = var.forwarding_rule_ip_protocol
  load_balancing_scheme = var.forwarding_rule_load_balancing_scheme
  port_range            = var.forwarding_rule_port_range
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_managed_ssl_certificate" "lb_default" {
  name = var.ssl_cert_name
  managed {
    domains = [var.ssl_cert_domain]
  }
}

resource "google_dns_record_set" "a" {
  name         = var.dns_record_name
  managed_zone = var.dns_record_managed_zone
  type         = var.dns_record_type
  ttl          = var.dns_record_ttl
  rrdatas      = [google_compute_global_address.default.address]
  depends_on   = [google_compute_backend_service.default]
}

resource "google_pubsub_topic" "verify_email_topic" {
  name                       = var.pubsub_topic_name
  message_retention_duration = var.pubsub_topic_message_rentention
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  name     = "cf-bucket-${random_id.bucket_suffix.hex}"
  location = var.google_storage_bucket_location
  encryption {
    default_kms_key_name = google_kms_crypto_key.my_crypto_key_cloud_storage_bucket.id
  }
  depends_on = [ google_kms_crypto_key_iam_binding.crypto_key-storage-bucket ]
}

data "archive_file" "default" {
  type        = var.archive_file_type
  output_path = var.archive_file_output_path
  source_dir  = var.archive_file_source_dir
}

resource "google_storage_bucket_object" "archive" {
  name   = var.google_storage_bucket_object_name
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.default.output_path
}

resource "google_vpc_access_connector" "my_connector" {
  name          = var.vpc_connector_name
  region        = var.region
  network       = var.network_name
  ip_cidr_range = var.vpc_connector_ip_cidr_range
}

resource "google_cloudfunctions_function" "function" {
  name                = var.google_cloudfunctions_function_name
  description         = var.google_cloudfunctions_function_description
  runtime             = var.google_cloudfunctions_function_runtime
  available_memory_mb = var.google_cloudfunctions_function_available_memory
  timeout             = var.google_cloudfunctions_function_timeout
  entry_point         = var.google_cloudfunctions_function_entry_point
  vpc_connector       = google_vpc_access_connector.my_connector.name

  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  event_trigger {
    event_type = var.google_cloudfunctions_function_event_trigger_type
    resource   = google_pubsub_topic.verify_email_topic.id
    failure_policy {
      retry = true
    }
  }

  environment_variables = {
    DB_USER         = google_sql_user.users.name
    DB_PASSWORD     = google_sql_user.users.password
    DB_HOST         = google_sql_database_instance.postgres.private_ip_address
    DB_NAME         = google_sql_database.database.name
    MAILGUN_API_KEY = var.mailgun_api_key
  }
}

resource "google_pubsub_topic_iam_binding" "viewer" {
  project = google_pubsub_topic.verify_email_topic.project
  topic   = google_pubsub_topic.verify_email_topic.name
  role    = var.google_pubsub_topic_iam_binding
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "compute_security_admin" {
  project = google_pubsub_topic.verify_email_topic.project

  role = var.security_admin_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "compute_network_admin" {
  project = google_pubsub_topic.verify_email_topic.project
  role    = var.network_admin_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_cloudfunctions_function_iam_binding" "cloud_function_viewer" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = var.google_cloudfunctions_function_iam_binding
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "local_file" "output_file" {
  content = jsonencode({
    db_host            = google_sql_database_instance.postgres.private_ip_address
    db_user            = google_sql_user.users.name
    db_password        = google_sql_user.users.password
    db_name            = google_sql_database.database.name
    service_account_id = google_service_account.service_account.email
    kms_crypto_key_id_vm = google_kms_crypto_key.my_crypto_key_vm_instances.id
  })
  filename = "outputs.json"
}
