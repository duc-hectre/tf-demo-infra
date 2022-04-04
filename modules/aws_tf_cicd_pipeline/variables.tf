# -----------------------------------------------------------------------------
# Variables: General
# -----------------------------------------------------------------------------

variable "environment" {
  description = "AWS resource environment/prefix"
}

variable "region" {
  description = "AWS region"
}

variable "resource_tag_name" {
  description = "Resource tag name for cost tracking"
}


# -----------------------------------------------------------------------------
# Variables: Lambda
# -----------------------------------------------------------------------------

variable "cicd_name" {
  description = "AWS resource name"
}

variable "codestar_connector_credentials" {
  description = "codestar_connector_credentials"
}
variable "pipeline_artifact_bucket" {
  description = "pipeline_artifact_bucket name"
}
