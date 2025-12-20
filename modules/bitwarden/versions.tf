terraform {
  required_version = ">= 1.0"

  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.16.0"
    }
  }
}
