variable "api_key" {
  description = "API key for authentication"
  type        = string
  sensitive   = true
}

variable "api_base_url" {
  description = "Base URL for the API endpoint"
  type        = string
}