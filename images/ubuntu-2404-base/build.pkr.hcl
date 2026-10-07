locals {
  image_name    = "ubuntu-2404-base"
  template_name = "${local.image_name}-v${var.build_version}"
  scripts       = "${var.repo_root}/scripts"
  reports       = "${var.repo_root}/reports/${local.template_name}"
}

source "proxmox-iso" "ubuntu" {
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  vm_id                = var.vm_id
  vm_name              = local.template_name
  template_name        = local.template_name
  template_description = "Ubuntu 24.04 base, build ${var.build_version}, git ${var.git_sha}"
  tags                 = "packer;ubuntu-2404;base;v${var.build_version}"

  boot_iso {
    type             = "scsi"
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_storage_pool = var.iso_storage_pool
    iso_download_pve = true
    unmount          = true
  }

  additional_iso_files {
    type             = "scsi"
    cd_label         = "cidata"
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
    cd_content = {
      "meta-data" = ""
      "user-data" = templatefile("${path.root}/cidata/user-data.pkrtpl.yaml", {
        ip_cidr        = var.build_ip_cidr
        gateway        = var.build_gateway
        nameservers    = var.build_nameservers
        ssh_username   = var.ssh_username
        ssh_public_key = var.ssh_public_key
        apt_mirror     = var.apt_mirror
      })
    }
  }

  os       = "l26"
  machine  = "q35"
  bios     = "ovmf"
  cpu_type = "host"
  cores    = 2
  memory   = 2048

  efi_config {
    efi_storage_pool  = var.storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    storage_pool = var.storage_pool
    disk_size    = var.disk_size
    io_thread    = true
    discard      = true
  }

  network_adapters {
    model  = "virtio"
    bridge = var.network_bridge
  }

  qemu_agent              = true
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool

  boot_wait = "10s"
  boot_command = [
    "<wait3>e<wait2>",
    "<down><down><down><end>",
    " autoinstall",
    "<f10>",
  ]

  ssh_host             = local.ssh_host
  ssh_port             = var.ssh_port
  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "30m"
}

build {
  name    = local.image_name
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "shell" {
    inline = ["sudo cloud-init status --wait || true"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    scripts = [
      "${local.scripts}/debian-family/update.sh",
      "${local.scripts}/debian-family/packages.sh",
    ]
  }

  provisioner "ansible" {
    playbook_file   = "${var.repo_root}/ansible/image.yml"
    galaxy_file     = "${var.repo_root}/ansible/requirements.yml"
    user            = var.ssh_username
    use_proxy       = false
    extra_arguments = ["--extra-vars", "hardening_profile=image"]
  }

  provisioner "file" {
    source      = "${var.repo_root}/tests/goss/base.yaml"
    destination = "/tmp/goss.yaml"
  }
  provisioner "file" {
    source      = "${var.repo_root}/tests/openscap/"
    destination = "/tmp/openscap"
  }
  provisioner "shell" {
    execute_command  = "sudo env {{ .Vars }} bash '{{ .Path }}'"
    environment_vars = ["REPORT_PREFIX=${local.template_name}"]
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
      build_version = var.build_version
      git_sha       = var.git_sha
    }
  }
}
