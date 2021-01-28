provider "boundary" {
  addr                            = "http://127.0.0.1:9200"
  auth_method_id                  = "ampw_1234567890"
  password_auth_method_login_name = "admin"
  password_auth_method_password   = "password"
}

resource "boundary_scope" "global" {
  global_scope = true
  description  = "Global scope"
  scope_id     = "global"
}

resource "boundary_scope" "corp" {
  name                     = "Corp One"
  description              = "My first scope"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_auth_method" "password" {
  name     = "Corp Password"
  scope_id = boundary_scope.corp.id
  type     = "password"
}

resource "boundary_account" "users_acct" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  type           = "password"
  login_name     = lower(each.key)
  password       = "password"
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_user" "users" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  scope_id    = boundary_scope.corp.id
}

resource "boundary_user" "readonly_users" {
  for_each    = var.read_only_users
  name        = each.key
  description = "User resource for ${each.key}"
  scope_id    = boundary_scope.corp.id
}

resource "boundary_group" "readonly_group" {
  name        = "read-only"
  description = "Organization group for readonly users"
  member_ids  = [for user in boundary_user.readonly_users : userid]
  scope_id    = boundary_scope.corp.id
}

resource "boundary_role" "organization_readonly" {
  name          = "Read-Only"
  description   = "read only role"
  principal_ids = [boundary_group.readonly.id]
  grant_strings = ["id=*;type=*;actions=read"]
  scope_id      = boundary_scope.corp.id
}

resource "boundary_role" "organization_admin" {
  name          = "admin"
  description   = "Administrator Role"
  principal_ids = [concat([for user in boundary_user.users : user.id])]
  grant_strings = ["id=*;type=*;actions=create,read,update,delete"]
  scope_id      = boundary_scope.corp.id
}

resource "boundary_scope" "corp_infra" {
  name                   = "Core infrastructure"
  description            = "My first project!"
  scope_id               = boundary_scope.corp.id
  auto_create_admin_role = true
}

resource "boundary_host_catalog" "backend_servers_list" {
  name        = "backend_servers"
  description = "Backend Servers Host Catalog"
  type        = "static"
  scope_id    = boundary_scope.core_infra.id
}

resource "boundary_host" "backend_servers" {
  name            = "backend_server_service_${each.key}"
  for_each        = var.backend_server_ips
  type            = "static"
  description     = "Backend Server Host"
  address         = each.key
  host_catalog_id = boundary_host_catalog.backend_servers_list.id
}

resource "boundary_host_set" "backend_servers_ssh" {
  type            = "static"
  name            = "backend_servers_ssh"
  description     = "Backend Servers Host Set"
  host_catalog_id = boundary_host_catalog.backend_servers_list.id
  host_ids        = [for host in boundary_host.backend_servers : host.id]
}

# create target for accessing backend servers on port 8080
resource "boundary_target" "backend_servers_service" {
  type = "tcp"
  name = "Backend Service"
  description = "Backend Service Target"
  scope_id = boundary_scope.core_infra.id
  default_port = "8080"

  host_set_ids = [
      boundary_host_set.backend_servers_ssh.id
  ]
}

# create target for accessing backend servers on port 22
resource "boundary_target" "backend_servers_ssh" {
  type = "tcp"
  name = "Backend Servers"
  description = "Backend SSH Target"
  scope_id = boundary_scope.core_infra.id
  default_port = "22"

  host_set_ids = [
      boundary_host_set.backend_servers_ssh.id
  ]
}