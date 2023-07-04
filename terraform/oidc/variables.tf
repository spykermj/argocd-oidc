variable "app_roles" {
  description = "A list of the app roles required for this application"
  type = list(object({
    description  = string
    display_name = string
    value        = string
  }))
}

variable "app_name" {
  description = "Name of this OIDC application"
  type = string
}

# https://learn.microsoft.com/en-us/graph/permissions-reference
variable "graph_api_scopes" {
  description = "The list of graph api permissions needed by the application"
  type        = list(string)
  default = [
    "37f7f235-527c-4136-accd-4a02d197296e", # openid
    "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0", # email
    "14dad69e-099b-42c9-810b-d002981feec1", # profile
  ]
}

variable "hostname" {
  description = "The host name of the application"
  type = string
}

variable "logo" {
  description = "Path to the png image to use in the gallery for this application"
  type = string
}

variable "logout_path" {
  description = "The path for the application logout. The hostname is already defined."
  type = string
}

variable "redirect_paths" {
  description = "List of redirect paths. The hostname is already defined."
  type = list(string)
}
