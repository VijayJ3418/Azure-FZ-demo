#!/bin/bash

# Script to configure Workload Identity Federation (WIF) for Azure
# This allows Terraform Cloud to authenticate to Azure without storing credentials

set -e

echo "Setting up Workload Identity Federation for Azure..."

# Configuration variables
PROJECT_NAME="firezone"
TERRAFORM_CLOUD_ORG="your-org-name"  # Replace with your Terraform Cloud org
TERRAFORM_CLOUD_WORKSPACE="firezone-azure-prod"
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
AZURE_RESOURCE_GROUP="rg-${PROJECT_NAME}-wif"

# Create Resource Group for WIF
echo "Creating resource group: $AZURE_RESOURCE_GROUP"
az group create \
  --name $AZURE_RESOURCE_GROUP \
  --location eastus

# Register the app for WIF
echo "Creating Azure AD application for WIF..."
APP_NAME="${PROJECT_NAME}-terraform-cloud-wif"
APP=$(az ad app create --display-name "$APP_NAME" --query id -o tsv)
echo "App ID: $APP"

# Create service principal
echo "Creating service principal..."
SP=$(az ad sp create --id $APP --query id -o tsv)
echo "Service Principal ID: $SP"

# Create a managed identity
echo "Creating managed identity..."
IDENTITY=$(az identity create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name "${PROJECT_NAME}-ti-identity" \
  --query id -o tsv)
echo "Managed Identity: $IDENTITY"

# Get the Object ID of the service principal
SP_OBJECT_ID=$(az ad sp show --id $APP --query id -o tsv)

# Create role assignment for the service principal
echo "Assigning Contributor role to service principal..."
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID"

# Configure Federated Credentials for Workload Identity Federation
# This allows Terraform Cloud to authenticate without a shared secret
echo "Creating federated credentials for Terraform Cloud..."

TERRAFORM_CLOUD_URL="https://app.terraform.io"
TERRAFORM_WIF_CONFIG=$(cat <<EOF
{
  "issuer": "$TERRAFORM_CLOUD_URL",
  "subject": "organization:$TERRAFORM_CLOUD_ORG:project:my-project:workspace:$TERRAFORM_CLOUD_WORKSPACE:run_phase:apply",
  "description": "Terraform Cloud WIF for $PROJECT_NAME",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF
)

# Add federated credentials via REST API
echo "Please configure federated credentials manually or via Azure CLI:"
echo ""
echo "az ad app federated-credential create \\"
echo "  --id $APP \\"
echo "  --parameters '{\"name\": \"terraform-wif\", \"issuer\": \"$TERRAFORM_CLOUD_URL\", \"subject\": \"organization:$TERRAFORM_CLOUD_ORG:project:my-project:workspace:$TERRAFORM_CLOUD_WORKSPACE:run_phase:apply\", \"audiences\": [\"api://AzureADTokenExchange\"]}'"

echo ""
echo "WIF Configuration Summary:"
echo "========================================="
echo "Azure Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Azure Tenant ID: $AZURE_TENANT_ID"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo "App ID (Client ID): $APP"
echo "Service Principal ID: $SP"
echo "Managed Identity: $IDENTITY"
echo ""
echo "Configure these in Terraform Cloud environment variables:"
echo "  ARM_SUBSCRIPTION_ID = $AZURE_SUBSCRIPTION_ID"
echo "  ARM_TENANT_ID = $AZURE_TENANT_ID"
echo "  ARM_CLIENT_ID = $APP"
echo ""
echo "For WIF, use instead of static credentials in Terraform Cloud"
