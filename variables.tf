variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
  default = "resource-group"
}

variable "location" {
    description = "Name of the location"
    type = string
    default = "East-US"
}

variable "tags" {
    description = "Tags for the resources"
    type = map(string)
    default = {
       Environment = "Dev"
       project = "terraformDemo"
    }
}