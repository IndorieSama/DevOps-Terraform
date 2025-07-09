terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = ""
  tenant_id       = ""
  client_id       = ""
  client_secret   = ""
}

# Générer un mot de passe aléatoire pour l'admin de la BDD
resource "random_password" "mysql_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Définir les chemins des fichiers ZIP pour l'application
locals {
  backend_zip_path  = "${path.root}/dummy-backend.zip"
  frontend_zip_path = "${path.root}/dummy-frontend.zip"
}

resource "azurerm_resource_group" "rg" {
  name     = "DummyApp-RG"
  location = "France Central"
}

# Service Plan pour les deux App Services
resource "azurerm_service_plan" "app_service_plan" {
  name                = "dummy-app-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1" # Standard tier pour de meilleures performances
}

# --- Déploiement Backend PHP (Dummy) ---

# 1. Créer l'archive ZIP du backend
data "archive_file" "dummy_backend" {
  type        = "zip"
  source_dir  = "${path.root}/dummy-app/backend"
  output_path = local.backend_zip_path
}

# 2. Déployer l'App Service Backend
resource "azurerm_linux_web_app" "dummy_backend_app" {
  name                = "app-dummy-backend-test-deploy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    application_stack {
      php_version = "8.1"
    }
    always_on = false
  }
  
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "MYSQL_HOST"     = azurerm_mysql_flexible_server.mysql_server.fqdn
    "MYSQL_USERNAME" = azurerm_mysql_flexible_server.mysql_server.administrator_login
    "MYSQL_PASSWORD" = random_password.mysql_admin_password.result
    "MYSQL_DATABASE" = azurerm_mysql_flexible_database.mysql_db.name
  }
}

# 3. Déployer le code via az cli pour éviter les timeouts
resource "null_resource" "deploy_backend" {
  triggers = {
    # Se redéclenche si le contenu du zip change
    zip_hash = data.archive_file.dummy_backend.output_sha
  }

  depends_on = [azurerm_linux_web_app.dummy_backend_app]

  provisioner "local-exec" {
    command = <<EOF
      az webapp deploy \
        --resource-group "${azurerm_resource_group.rg.name}" \
        --name "${azurerm_linux_web_app.dummy_backend_app.name}" \
        --src-path "${data.archive_file.dummy_backend.output_path}" \
        --type zip \
        --timeout 900
    EOF
  }
}


# --- Base de données MySQL ---

resource "azurerm_mysql_flexible_server" "mysql_server" {
  name                   = "dummydb-server-exam"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  
  administrator_login    = "mysqladmin"
  administrator_password = random_password.mysql_admin_password.result
  
  sku_name   = "B_Standard_B1ms" # Burstable, économique pour le dev/test
  version    = "8.0.21"
  
  storage {
    size_gb = 20
  }
}

resource "azurerm_mysql_flexible_database" "mysql_db" {
  name                = "productsdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Récupérer l'IP publique de la machine exécutant Terraform
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Ajouter une règle de pare-feu pour autoriser l'accès depuis l'IP locale
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_my_ip" {
  name                = "allow-my-ip-for-init"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  start_ip_address    = chomp(data.http.myip.response_body)
  end_ip_address      = chomp(data.http.myip.response_body)
}

# Ajouter une règle de pare-feu pour autoriser l'accès depuis les services Azure
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}


# --- Déploiement Frontend HTML (Dummy) ---

# 1. Créer l'archive ZIP du frontend
data "archive_file" "dummy_frontend" {
  type        = "zip"
  source_dir  = "${path.root}/dummy-app/frontend"
  output_path = local.frontend_zip_path
}

# 2. Déployer l'App Service Frontend
resource "azurerm_linux_web_app" "dummy_frontend_app" {
  name                = "app-dummy-frontend-test-deploy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    application_stack {
      php_version = "8.1" 
    }
    always_on = false
    default_documents = ["index.html"]
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
}

# 3. Déployer le code via az cli pour éviter les timeouts
resource "null_resource" "deploy_frontend" {
  triggers = {
    zip_hash = data.archive_file.dummy_frontend.output_sha
  }

  depends_on = [azurerm_linux_web_app.dummy_frontend_app]

  provisioner "local-exec" {
    command = <<EOF
      az webapp deploy \
        --resource-group "${azurerm_resource_group.rg.name}" \
        --name "${azurerm_linux_web_app.dummy_frontend_app.name}" \
        --src-path "${data.archive_file.dummy_frontend.output_path}" \
        --type zip \
        --timeout 900
    EOF
  }
}

# --- Outputs ---

output "frontend_url" {
  description = "URL of the frontend application"
  value       = azurerm_linux_web_app.dummy_frontend_app.default_hostname
}

output "backend_url" {
  description = "URL of the backend application"
  value       = azurerm_linux_web_app.dummy_backend_app.default_hostname
}

output "mysql_server_fqdn" {
  description = "The FQDN of the MySQL server."
  value       = azurerm_mysql_flexible_server.mysql_server.fqdn
}

output "mysql_server_admin_login" {
  description = "The admin login for the MySQL server."
  value       = azurerm_mysql_flexible_server.mysql_server.administrator_login
}

output "mysql_server_admin_password" {
  description = "The admin password for the MySQL server."
  value       = random_password.mysql_admin_password.result
  sensitive   = true
}

output "mysql_database_name" {
  description = "The name of the MySQL database."
  value       = azurerm_mysql_flexible_database.mysql_db.name
}