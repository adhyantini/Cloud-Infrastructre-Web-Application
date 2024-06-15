variable "project_name" {
  description = "csye-assignment"
}

variable "region" {
  description = "us-east1"
}

variable "zone" {
  description = "us-east1-c"
}

variable "network_name" {
  description = "terraform-network"
}

variable "loadbalancersub_name" {
  description = "webapp"
}

variable "dbsub_name" {
  description = "db"
}

variable "route_name" {
  description = "webapp-internet-access"
}

variable "ip_cidr_range_load_balancer" {
  description = "webapp-ip cidr range"
}
variable "ip_cidr_range_db" {
  description = "db-ip cidr range"
}
variable "ip_destination_range" {
  description = "webapp-default route range"
}
variable "routing_mode" {
  description = "REGIONAL"
}
variable "firewall_name" {
  description = "test-firewall"
}

variable "firewall_allowed_protocol1" {
  description = "tcp"
}

variable "vm_instance_name" {
  description = "centos1"
}

variable "vm_machine_type" {
  description = "e2-medium"
}

variable "vm_zone" {
  description = "us-central1-a"
}

variable "vm_image_name" {
  description = "us-central1-a"
}

variable "vm_bootdisk_type" {
  description = "pd-balanced"
}

variable "vm_bootdisk_size" {
  description = "100"
}

variable "vm_networkInterface_subnetwork" {
  description = "projects/dev-gcp-414621/regions/us-central1/subnetworks/webapp"
}

variable "private_service_connection_range_name" {
  description = "psc-range-name"
}

variable "private_service_connection_range_purpose" {
  description = "VPC_PEERING"
}

variable "private_service_connection_range_addressType" {
  description = "INTERNAL"
}

variable "private_vpc_connection_service" {
  description = "servicenetworking.googleapis.com"
}

variable "postgres_database_version" {
  description = "POSTGRES_15"
}

variable "postgres_tier" {
  description = "db-f1-micro"
}

variable "postgres_availability_type" {
  description = "REGIONAL"
}

variable "postgres_disk_type" {
  description = "pd-ssd"
}

variable "postgres_disk_size" {
  description = "100"
}

variable "password_override" {
  description = "!#$%&*()-_=+[]{}<>:?"
}

variable "db_name" {
  description = "webapp"
}

variable "db_user_name" {
  description = "webapp"
}

variable "service_account_ID" {
  description = "csye-adhyantini"
}

variable "service_account_displayName" {
  description = "Service Account"
}

variable "role_logging_admin" {
  description = "roles/logging.admin"
}

variable "role_metric_writer" {
  description = "roles/monitoring.metricWriter"
}

variable "dns_record_name" {
  description = "adhyantini.me."
}

variable "dns_record_managed_zone" {
  description = "csye"
}

variable "dns_record_type" {
  description = "A"
}

variable "dns_record_ttl" {
  description = "21600"
}

variable "mailgun_api_key" {
  description = "mailgun api key"
}

variable "pubsub_topic_name" {
  description = "verify_email"
}

variable "pubsub_topic_message_rentention" {
  description = "604800s"
}

variable "google_storage_bucket_location" {
  description = "US"
}

variable "archive_file_type" {
  description = "zip"
}

variable "archive_file_output_path" {
  description = "/tmp/function-source.zip"
}

variable "archive_file_source_dir" {
  description = "D:/NEU/Cloud/Assignment6/serverless-fork"
}

variable "google_storage_bucket_object_name" {
  description = "index.zip"
}

variable "google_cloudfunctions_function_name" {
  description = "function-email"
}

variable "google_cloudfunctions_function_description" {
  description = "My function triggered by Pub/Sub"
}

variable "google_cloudfunctions_function_runtime" {
  description = "nodejs16"
}

variable "google_cloudfunctions_function_available_memory" {
  description = "128"
}

variable "google_cloudfunctions_function_timeout" {
  description = "60"
}

variable "google_cloudfunctions_function_entry_point" {
  description = "processPubSubMessage"
}

variable "google_cloudfunctions_function_event_trigger_type" {
  description = "google.pubsub.topic.publish"
}

variable "google_pubsub_topic_iam_binding" {
  description = "roles/pubsub.publisher"
}

variable "google_cloudfunctions_function_iam_binding" {
  description = "roles/viewer"
}

variable "vpc_connector_name" {
  description = "my-vpc-connector"
}

variable "vpc_connector_ip_cidr_range" {
  description = "10.8.0.0/28"
}

variable "compute_region_instance_template_description" {
  description = "This template is used to create webapp server instances."
}

variable "compute_region_instance_template_instance_description" {
  description = "VM instance running webapp"
}

variable "health_check_name" {
  description = "healthz"
}

variable "health_check_description" {
  description = "Health check via http"
}

variable "health_check_timeout_second" {
  description = "1"
}

variable "health_check_check_interval_second" {
  description = "4"
}

variable "health_check_healthy_threshold" {
  description = "4"
}

variable "health_check_unhealthy_threshold" {
  description = "2"
}

variable "health_check_port" {
  description = "8080"
}

variable "health_check_port_spec" {
  description = "USE_FIXED_PORT"
}

variable "health_check_request_path" {
  description = "/v1/healthz"
}

variable "health_check_response" {
  description = ""
}

variable "autoscaler_name" {
  description = "my-webapp-region-autoscaler"
}

variable "autoscaler_max_replicas" {
  description = "9"
}

variable "autoscaler_min_replicas" {
  description = "3"
}

variable "autoscaler_cooldown_period" {
  description = "60"
}

variable "autoscaler_target_cpu_utilization" {
  description = "0.05"
}

variable "instance_group_manager_name" {
  description = "appserver-igm"
}

variable "instance_group_manager_base_instance_name" {
  description = "webapp"
}

variable "instance_group_manager_port_name" {
  description = "http"
}

variable "instance_group_manager_port_number" {
  description = "8080"
}

variable "instance_group_manager_initial_delay_sec" {
  description = "300"
}

variable "firewall_health_check" {
  description = "fw-allow-health-check"
}

variable "firewall_direction" {
  description = "INGRESS"
}

variable "compute_global_address_name" {
  description = "address-name"
}

variable "compute_global_address_type" {
  description = "EXTERNAL"
}

variable "backend_service_name" {
  description = "l7-xlb-backend-service"
}

variable "backend_service_load_balancing_scheme" {
  description = "EXTERNAL_MANAGED"
}

variable "backend_service_locality_lb_policy" {
  description = "ROUND_ROBIN"
}

variable "backend_service_protocol" {
  description = "HTTP"
}

variable "backend_service_port_name" {
  description = "http"
}

variable "backend_service_session_affinity" {
  description = "NONE"
}

variable "backend_service_timeout_sec" {
  description = "30"
}

variable "backend_service_balancing_mode" {
  description = "UTILIZATION"
}

variable "backend_service_capacity_scaler" {
  description = "1.0"
}

variable "compute_url_map_name" {
  description = "l7-xlb-map"
}

variable "target_proxy_name" {
  description = "l7-xlb-proxy"
}

variable "forwarding_rule_name" {
  description = "l7-xlb-forwarding-rule"
}

variable "forwarding_rule_ip_protocol" {
  description = "TCP"
}

variable "forwarding_rule_load_balancing_scheme" {
  description = "EXTERNAL_MANAGED"
}

variable "forwarding_rule_port_range" {
  description = "443"
}

variable "ssl_cert_name" {
  description = "myservice-ssl-cert"
}

variable "ssl_cert_domain" {
  description = "adhyantini.me."
}

variable "security_admin_role" {
  description = "roles/compute.securityAdmin"
}

variable "network_admin_role" {
  description = "roles/compute.networkAdmin"
}

variable "crypto_key_sql" {
  description = "my-crypto-key-sql"
}

variable "crypto_key_rotation_period" {
  description = "86400s"
}

variable "crypto_key_algorithm" {
  description = "GOOGLE_SYMMETRIC_ENCRYPTION"
}

variable "crypto_key_cloud_storage" {
  description = "my-crypto-key-cloud-storage"
}

variable "crypto_key_vm" {
  description = "my-crypto-key-vm"
}

variable "gcp_sa_cloud_sql" {
  description = "sqladmin.googleapis.com"
}

variable "crypto_key_role" {
  description = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

variable "crypto_key_vm_service_role" {
  description = "serviceAccount:service-144604492908@compute-system.iam.gserviceaccount.com"
}