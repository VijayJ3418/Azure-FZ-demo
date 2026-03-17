# Azure Firezone Infrastructure as Code

Complete Terraform implementation for deploying a secure, enterprise-grade Firezone VPN infrastructure on Azure with Jenkins application stack.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
└─────────────────────────────────────────────────────────────┘
         │
         │
    ┌────┴──────────────────────────────────────────┐
    │                                                 │
    ▼                                                 ▼
┌──────────────────────────┐        ┌──────────────────────────┐
│  VNet1: Networking-Global│        │ VNet2: Core-IT-Infra    │
│  CIDR: 10.10.10.0/16     │◄────────►  CIDR: 30.30.30.0/16   │
│  ┌──────────────────┐    │ Peering  │ ┌──────────────────┐      │
│  │ Firezone Gateway │    │          │ │  Jenkins VM      │      │
│  │ IP: 10.10.10.10  │    │          │ │  IP: 30.30.30.10 │     │
│  │ WireGuard: 51820 │    │          │ │                  │      │
│  └──────────────────┘    │          │ ├──────────────────┤    │
│                          │          │ │  Internal LB     │      │
│  NSG Rules:             │          │ │  IP: 30.30.30.100│     │
│  - SSH (22): Inbound    │          │ │  HTTPS (443)     │      │
│  - WireGuard (51820)    │          │ └──────────────────┘    │
│  - HTTPS Egress to VNet2│          │                          │
└──────────────────────────┘        │ NSG Rules:               │
                                    │ - SSH from VNet1 (22)   │
                                    │ - HTTPS from VNet1 (443)│
                                    └──────────────────────────┘
         │                                       │
         └───────────────────┬───────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  Private DNS Zone│
                    │  dglearn.online  │
                    │                  │
                    │ jenkins-azure    │
                    │ → 30.30.30.100   │
                    └──────────────────┘
```

## Key Components

### 1. Networking (VNet1 - Networking-Global)
- **VNet**: 10.10.10.0/16
- **Subnets**:
  - Gateway Subnet: 10.10.10.0/24 (Firezone Gateway)
  - Management Subnet: 10.10.11.0/24
- **Security**: NSG with SSH and WireGuard access
- **Peering**: Bidirectional with VNet2 for resource visibility

### 2. Firezone Gateway (VNet1)
- **VM**: Rocky Linux 8 (Standard_B2s)
- **Private IP**: 10.10.10.10
- **WireGuard**: UDP 51820 for VPN tunneling
- **Features**:
  - Auto-registers with Firezone Control Plane
  - Encrypts traffic between clients and resources
  - Routes .intranet domain traffic through gateway
  - Integrated logging via Azure Storage

### 3. Compute & Storage (VNet2 - Core-IT-Infrastructure)
- **VNet**: 30.30.30.0/16
- **Subnet**: 30.30.30.0/24
- **Jenkins VM**: Rocky Linux 8 (Standard_D2s_v3)
  - OS Disk: 50 GB (Premium SSD)
  - Data Disk: 100 GB (mounted at /var/lib/jenkins)
  - Private IP: 30.30.30.10
  - No public IP (secure by default)

### 4. Load Balancing & HTTPS
- **Internal Load Balancer (ILB)**:
  - Private IP: 30.30.30.100
  - HTTPS (443) load balancing
  - End-to-end encryption (frontend & backend on port 443)
  - Health probes every 15 seconds
  - SSL certificate from Azure Key Vault

### 5. DNS & Certificate Management
- **Private DNS Zone**: dglearn.online
  - A Record: jenkins-azure → 30.30.30.100 (ILB)
  - VNet links: Both VNets can resolve
  - No public DNS exposure (private only)
- **Azure Key Vault**:
  - Stores SSL certificates
  - Managed access policies
  - Audit logging

### 6. Security Features
- **Network Security Groups**:
  - SSH (22) access for management
  - WireGuard (51820) for VPN clients
  - HTTPS (443) for Jenkins access
  - Egress rules for inter-VNet traffic only
- **Private Network**:
  - No public IPs on VMs
  - All traffic routes through Firezone Gateway
  - SAML authentication for Jenkins access
  - Azure AD integration via Firezone SAML

## Project Structure

```
terraform/
├── environments/
│   └── production/
│       ├── main.tf              # Main infrastructure
│       ├── variables.tf         # Variable definitions
│       ├── outputs.tf           # Output values
│       ├── terraform.tfvars     # Variable values
│       └── .terraform.lock.hcl  # Dependency lock
│
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── scripts/
│   │       └── jenkins-init.sh
│   │
│   └── firezone/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── scripts/
│           └── firezone-init.sh
│
└── .gitignore

scripts/
├── generate-certificates.sh     # SSL certificate generation
├── setup-wif.sh                # Workload Identity Federation
└── setup-saml.sh               # SAML authentication setup

certificates/
├── jenkins.crt                 # SSL certificate
├── jenkins.key                 # Private key
├── jenkins-chain.crt           # Full certificate chain
└── root-ca.crt                # Root CA (for testing)

docs/
├── README.md
├── DEPLOYMENT.md
├── FIREZONE_CONFIG.md
└── TROUBLESHOOTING.md
```

## Prerequisites

### Local Requirements
- Terraform >= 1.0
- Azure CLI >= 2.40
- SSH key pair (`~/.ssh/id_rsa.pub`)
- Azure subscription with Owner/Contributor role
- Valid SSL certificate and key (PEM format)

### Azure Setup
```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create storage account for Terraform state
az storage account create \
  --name tfstateprodaccount \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name tfstate \
  --account-name tfstateprodaccount
```

### Firezone Setup
1. Create account at https://console.firezone.dev
2. Create Organization
3. Create Gateway and obtain enrollment token
4. Save enrollment token for Terraform

## Quick Start

### 1. Prepare Certificates

```bash
# Generate self-signed certificates (testing only)
./scripts/generate-certificates.sh

# For production, use valid CA-signed certificates
# Update paths in terraform.tfvars
```

### 2. Configure Terraform Variables

```bash
cd terraform/environments/production

# Edit terraform.tfvars
# Update these critical values:
# - firezone_api_url (your Firezone API endpoint)
# - firezone_enrollment_token (from Firezone console)
# - ssh_public_key_path (your SSH public key)
# - azure_region (your preferred Azure region)
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 5. Apply Configuration

```bash
terraform apply tfplan
```

### 6. Verify Deployment

```bash
# Get output values
terraform output

# SSH to Firezone Gateway (via Bastion or custom setup)
# SSH to Jenkins via Firezone client

# Check Firezone Gateway status
systemctl status firezone-gateway

# Check Jenkins status
systemctl status jenkins
systemctl status nginx
```

## Environment Variables

Set these before running Terraform:

```bash
# Azure authentication
export ARM_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
export ARM_TENANT_ID="YOUR_TENANT_ID"
export ARM_CLIENT_ID="YOUR_CLIENT_ID"
export ARM_CLIENT_SECRET="YOUR_CLIENT_SECRET"

# OR use Workload Identity Federation (recommended)
export ARM_OIDC_TOKEN="JWT_TOKEN"
export ARM_CLIENT_ID="YOUR_CLIENT_ID"
export ARM_TENANT_ID="YOUR_TENANT_ID"
export ARM_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"

# Firezone enrollment token
export TF_VAR_firezone_enrollment_token="YOUR_ENROLLMENT_TOKEN"
```

## Terraform Cloud Integration

For centralized state management and automated deployments:

### 1. Setup Terraform Cloud

```bash
# Create account at https://app.terraform.io
# Create organization
# Create workspace: firezone-azure-prod
```

### 2. Configure Workload Identity Federation (Recommended)

```bash
# Setup WIF instead of storing credentials
./scripts/setup-wif.sh
```

### 3. Enable Cloud Integration

In `main.tf`, uncomment and update the `cloud` block:

```hcl
terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "firezone-azure-prod"
    }
  }
}
```

### 4. Configure VCS Integration (Optional)

- Connect GitHub/GitLab repository
- Enable auto-plan on PR
- Enable apply validation

## SAML Authentication Setup

### Jenkins SAML Configuration

```bash
# Run SAML setup guide
./scripts/setup-saml.sh
```

### Azure AD / Entra ID Configuration

1. Create Enterprise Application in Azure AD
2. Configure SAML Single Sign-On
3. Map user attributes (mail, displayName, groups)
4. Download federation metadata
5. Add users/groups to Jenkins application

### Firezone Resource Configuration

1. Create Resource in Firezone Console: `https://jenkins-azure.dglearn.online`
2. Enable SAML authentication
3. Add Azure AD groups for access control
4. Configure user provisioning (optional)

## Client Setup

### For End Users

```bash
# 1. Install Firezone Client
# Download from https://firezone.dev/download

# 2. Launch and sign in
# Click "Sign In"
# Authenticate via Azure AD SAML
# Approve MFA if required

# 3. Access Jenkins
# Browser: https://jenkins-azure.dglearn.online
# Client automatically intercepts DNS requests
# Traffic routes through Firezone Gateway
```

## Monitoring & Logging

### Azure Resources
- **Application Insights**: Monitor VM and LB metrics
- **Log Analytics**: Centralized logging from all components
- **Azure Monitor**: Alerts for resource health

### Firezone
- **Gateway Logs**: Azure Storage (firezone gateway logs container)
- **Console**: https://console.firezone.dev for event history
- **Metrics**: Dashboard in Firezone console

### Jenkins
- **Logs**: /var/log/jenkins/jenkins.log
- **Audit**: Jenkins audit log plugin
- **Metrics**: Jenkins metrics plugin

## Maintenance & Operations

### VM Management
```bash
# Scale Jenkins VM
terraform apply -var='jenkins_vm_size=Standard_D4s_v3'

# Expand data disk
# Update terraform.tfvars: jenkins_data_disk_size_gb = 200
terraform apply

# Reboot VM via Azure Portal if needed
```

### Certificate Rotation
```bash
# Update certificate files
cp /path/to/new/cert.crt certificates/jenkins.crt
cp /path/to/new/key.key certificates/jenkins.key

# Redeploy
terraform apply
```

### Firezone Gateway Updates
- Check Firezone console for updates
- Updates applied automatically via system package manager
- Monitor gateway status in Firezone console

### Backup & Recovery
- Configure Azure Backup for Jenkins VM
- Store certificate private keys in Azure Key Vault
- Terraform state stored in Azure Storage (versioning enabled)

## Troubleshooting

See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for:
- Connection issues
- Certificate errors
- SAML authentication failures
- Performance issues
- Log analysis

## Cost Optimization

- **VMs**: Standard_D2s_v3 and Standard_B2s (development sizing)
- **Storage**: Premium SSD for Jenkins VM (adjust if not needed)
- **Load Balancer**: Internal LB (lower cost than public)
- **DNS**: Azure Private DNS (no egress charges)
- **Key Vault**: Standard tier (sufficient for most use cases)

**Estimated Monthly Cost** (US East):
- Jenkins VM (D2s): ~$150
- Firezone Gateway (B2s): ~$50
- Storage: ~$20
- DNS/KV: ~$5
- **Total**: ~$225/month

## Security Best Practices

1. **Network Isolation**
   - Use VNet peering (no routing through internet)
   - NSGs restrict traffic to necessary ports
   - No public IPs on VMs

2. **Authentication**
   - SAML via Azure AD (MFA capable)
   - Firezone client authentication
   - SSH key-only VMs

3. **Encryption**
   - End-to-end HTTPS for Jenkins
   - WireGuard encryption for Firezone VPN
   - TLS for backend communication (443)
   - Azure Storage encryption at rest

4. **Compliance**
   - HIPAA, PCI-DSS, SOC 2 compatible architecture
   - Audit logging via Azure Monitor
   - Centralized credential management

## Support & Documentation

- **Firezone Docs**: https://docs.firezone.dev
- **Azure Terraform Provider**: https://registry.terraform.io/providers/hashicorp/azurerm
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Terraform Cloud**: https://app.terraform.io/docs

## License

This Terraform code is provided as-is. Firezone is open-source; see their license for details.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create feature branch
3. Test thoroughly
4. Submit pull request

---

**Last Updated**: March 2026  
**Terraform Version**: 1.0+  
**Azure Provider**: 3.85+
