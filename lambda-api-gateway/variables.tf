variable "base_domain_name" {
  description = "Domain name"
  type        = string
}

variable "api_domain_name" {
  description = "API Domain name"
  type        = string
}

variable "function_zip" {
  description = "Function ZIP archive"
  type        = string
}

variable "function_layers" {
  description = "List of function layers"
  type        = list(string)
  default     = []
}

variable "api_origins" {
  description = "List API origins"
  type        = list(string)
  default     = []
}
