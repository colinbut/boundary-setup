variable "users" {
  type        = set(string)
  description = "A list of users"
  default = [
    "Jim",
    "Mike",
    "Todd",
    "Jeff",
    "Randy",
    "Susmitha"
  ]
}

variable "read_only_users" {
  type        = set(string)
  description = "A list of read only users"
  default = [
    "Chris",
    "Pete",
    "Justin"
  ]
}

variable "backend_server_ips" {
  type        = set(string)
  description = "backend servers ip addresses"
  default = [
    "10.1.0.1",
    "10.1.0.2"
  ]
}