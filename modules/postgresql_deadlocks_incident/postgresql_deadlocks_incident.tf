resource "shoreline_notebook" "postgresql_deadlocks_incident" {
  name       = "postgresql_deadlocks_incident"
  data       = file("${path.module}/data/postgresql_deadlocks_incident.json")
  depends_on = [shoreline_action.invoke_increase_max_connections,shoreline_action.invoke_detect_deadlocks]
}

resource "shoreline_file" "increase_max_connections" {
  name             = "increase_max_connections"
  input_file       = "${path.module}/data/increase_max_connections.sh"
  md5              = filemd5("${path.module}/data/increase_max_connections.sh")
  description      = "Increase the number of connections allowed to the database to reduce contention."
  destination_path = "/agent/scripts/increase_max_connections.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "detect_deadlocks" {
  name             = "detect_deadlocks"
  input_file       = "${path.module}/data/detect_deadlocks.sh"
  md5              = filemd5("${path.module}/data/detect_deadlocks.sh")
  description      = "Identify the deadlocked queries and kill."
  destination_path = "/agent/scripts/detect_deadlocks.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_increase_max_connections" {
  name        = "invoke_increase_max_connections"
  description = "Increase the number of connections allowed to the database to reduce contention."
  command     = "`chmod +x /agent/scripts/increase_max_connections.sh && /agent/scripts/increase_max_connections.sh`"
  params      = ["DATABASE_USER","NEW_MAX_CONNECTIONS","DATABASE_PASSWORD","DATABASE_NAME"]
  file_deps   = ["increase_max_connections"]
  enabled     = true
  depends_on  = [shoreline_file.increase_max_connections]
}

resource "shoreline_action" "invoke_detect_deadlocks" {
  name        = "invoke_detect_deadlocks"
  description = "Identify the deadlocked queries and kill."
  command     = "`chmod +x /agent/scripts/detect_deadlocks.sh && /agent/scripts/detect_deadlocks.sh`"
  params      = []
  file_deps   = ["detect_deadlocks"]
  enabled     = true
  depends_on  = [shoreline_file.detect_deadlocks]
}

