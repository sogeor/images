locals {
  image_name    = "ubuntu-2404-k8s"
  template_name = "${local.image_name}-v${var.build_version}"
  k8s_minor     = join("-", slice(split(".", var.k8s_version), 0, 2))
  scripts       = "${var.repo_root}/scripts"
  reports       = "${var.repo_root}/reports/${local.template_name}"
}

source "proxmox-clone" "k8s" {
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  clone_vm   = var.base_template
  full_clone = true

  vm_id                = var.vm_id
  vm_name              = local.template_name
  template_name        = local.template_name
  template_description = "Ubuntu 24.04 + Kubernetes ${var.k8s_version}, base ${var.base_template}, build ${var.build_version}, git ${var.git_sha}"
  tags                 = "packer;ubuntu-2404;k8s;k8s-${local.k8s_minor};v${var.build_version}"

  os       = "l26"
  cpu_type = "host"
  cores    = 2
  memory   = 4096

  scsi_controller = "virtio-scsi-single"
  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  qemu_agent              = true
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool
  ipconfig {
    ip      = var.build_ip_cidr
    gateway = var.build_gateway
  }
  nameserver = join(" ", var.build_nameservers)

  ssh_host     = local.ssh_host
  ssh_port     = var.ssh_port
  ssh_username = var.ssh_username
  ssh_timeout  = "15m"
}

build {
  name    = local.image_name
  sources = ["source.proxmox-clone.k8s"]

  provisioner "shell" {
    inline = ["sudo cloud-init status --wait || true"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    environment_vars = [
      "K8S_VERSION=${var.k8s_version}",
      "K8S_PACKAGE_REVISION=${var.k8s_package_revision}",
    ]
    scripts = [
      "${local.scripts}/debian-family/update.sh",
      "${local.scripts}/debian-family/kubernetes.sh",
    ]
  }

  provisioner "file" {
    source      = "${var.repo_root}/tests/goss/k8s.yaml"
    destination = "/tmp/goss.yaml"
  }
  provisioner "file" {
    source      = "${var.repo_root}/.cache/artifacts/"
    destination = "/tmp/artifacts"
  }
  provisioner "file" {
    source      = "${var.repo_root}/tests/openscap/"
    destination = "/tmp/openscap"
  }
  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    environment_vars = [
      "REPORT_PREFIX=${local.template_name}",
      "GOSS_VARS_K8S_VERSION=${var.k8s_version}",
    ]
    scripts = [
      "${local.scripts}/common/run-goss.sh",
      "${local.scripts}/common/scan-openscap.sh",
      "${local.scripts}/common/scan-trivy.sh",
    ]
  }
  provisioner "file" {
    direction   = "download"
    source      = "/tmp/reports/"
    destination = "${local.reports}/"
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    scripts = [
      "${local.scripts}/debian-family/cleanup.sh",
      "${local.scripts}/common/cloud-init-reset.sh",
    ]
  }

  provisioner "shell" {
    execute_command  = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    environment_vars = ["BUILD_USER=${var.ssh_username}"]
    script           = "${local.scripts}/common/remove-build-user.sh"
    skip_clean       = true
  }

  post-processor "manifest" {
    output     = "${var.repo_root}/manifest/${local.image_name}.json"
    strip_path = true
    custom_data = {
      template_name = local.template_name
      base_template = var.base_template
      k8s_version   = var.k8s_version
      build_version = var.build_version
      git_sha       = var.git_sha
    }
  }
}
