## App Config
variable "app_name" {
    description = "Name of this application"
    type = "string"
}

##  Environment Config
variable "env_name" {
    description = "Name of this environment"
    type = "string"
}

variable "az_location" {
    description = "Azure location for this application"
    type = "string"
}

variable "department" {
    description = "Name of this department"
    type = "string"
}

variable "az_container_registry" {
    description = "The container registry where our docker app is stored, does not have to be in this apps location"
    type = "string"
}

variable "az_storage_account_key" {
    description = "Azure storage account key"
    type = "string"
}

## DB Config
variable "db_admin_username" {
    description = "Admin login username for DB Server"
    type = "string"    
}

variable "db_admin_password" {
    description = "Admin login password for DB Server"
    type = "string"
}
