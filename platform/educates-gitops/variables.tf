variable "gitopsApp"{
  type = object({
    namespace = optional(string, "workshop-gitops")
    configFile = optional(string, "workshop-gitops-config.yaml")
  })
  default = {
  }
}

variable "gitopsConfig"{
  type = object({
    configRepo = optional(string, "https://github.com/educates/educates-workshop-gitops-configurer")
    environment = optional(string, "sample-environment")
    ref = optional(string, "origin/main")
    subPathPrefix = optional(string, "config")
    syncPeriod = optional(string, "0h10m0s")
    overlaysBundle = optional(string, "ghcr.io/educates/educates-workshop-gitops-configurer:main")
    github = optional(object({
      username = optional(string, "")
      password = optional(string, "")
    }))
    themeFile = optional(string, "theme.yaml")
  })
  default = {
    github = {
    }
  }


  validation {
    condition     = can(regex("^(\\d{1,2})h(\\d{1,2})m(\\d{1,2})s", var.gitopsConfig.syncPeriod))
    error_message = "gitops_config_syncperiod must be a valid kapp-controller sync period (e.g. 12h0m0s or 1h or 10m) and always greater that 30s"
  }
}