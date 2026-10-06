variable "base_template" {
  type = string
}

variable "k8s_version" {
  type = string
  # renovate: datasource=github-releases depName=kubernetes/kubernetes
  default = "1.37.1"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.k8s_version))
    error_message = "Значение k8s_version должно быть в формате X.Y.Z."
  }
}

variable "k8s_package_revision" {
  type    = string
  default = "1.1"
}
