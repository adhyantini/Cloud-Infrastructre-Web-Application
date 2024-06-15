packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

locals {
  timestamp = "${formatdate("YYYYMMDDHHmmss", timestamp())}"
}

source "googlecompute" "centos8" {
  project_id              = var.project_id
  zone                    = var.zone
  source_image_family     = var.source_image_family
  source_image_project_id = ["centos-cloud"]
  ssh_username            = var.ssh_username
  machine_type            = var.machine_type
  disk_size               = var.disk_size
  disk_type               = var.disk_type
  image_name              = "centos-8-packer-${local.timestamp}"
}

build {
  sources = ["source.googlecompute.centos8"]

  // provisioner "shell" {
  //   inline = [
  //     "sudo yum update -y"
  //   ]
  // }

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "pwd"
    ]
  }

  provisioner "file" {
    source      = "applicationConfigurations.sh"
    destination = "/tmp/applicationConfigurations.sh"
  }

  provisioner "shell" {
    inline = [
      "pwd",
      "sudo chmod +x /tmp/applicationConfigurations.sh",
      "sudo /tmp/applicationConfigurations.sh"
    ]
  }

  provisioner "file" {
    source      = "./webapp.zip"
    destination = "/tmp/webapp.zip"
  }

  provisioner "shell" {
    inline = [
      "unzip /tmp/webapp.zip -d /tmp/webapp && cd /tmp/webapp"
    ]
  }

  provisioner "shell" {
    inline = [
      "cd /tmp/webapp && npm i"
    ]
  }

  provisioner "file" {
    source      = "serviceStartup.service"
    destination = "/tmp/serviceStartup.service"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/webapp/packerTemplates/config.yaml /etc/google-cloud-ops-agent/config.yaml ",
      "sudo systemctl restart google-cloud-ops-agent"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo chown -R csye6225:csye6225 /tmp/webapp",
      "sudo chmod -R 770 /tmp/webapp"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo touch /var/log/webapp.log",
      "sudo chown csye6225:csye6225 /var/log/webapp.log"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/serviceStartup.service /etc/systemd/system/serviceStartup.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable serviceStartup.service"
    ]
  }


}