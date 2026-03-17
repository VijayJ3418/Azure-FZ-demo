# Project Directory Structure

```
Azure-Code-Updated/
│
├── README.md                           # 📖 Main documentation with architecture overview
├── SUMMARY.md                          # 📋 Project delivery summary & quick reference
├── DEPLOYMENT.md                       # 🚀 Step-by-step deployment guide (7 phases)
├── TROUBLESHOOTING.md                  # 🔧 Common issues & solutions
├── TERRAFORM_CLOUD.md                  # ☁️  Terraform Cloud integration & CI/CD
├── CHECKLIST.md                        # ✅ Pre/post-deployment verification checklist
├── .gitignore                          # 🚫 Git ignore configuration
│
├── terraform/
│   │
│   ├── environments/
│   │   └── production/                 # Production environment configuration
│   │       ├── main.tf                 # 🏗️  Main infrastructure orchestration
│   │       │                           # - Resource groups (3x)
│   │       │                           # - Module instantiation
│   │       │                           # - Private DNS zone & records
│   │       │                           # - DNS zone VNet linking
│   │       │
│   │       ├── variables.tf            # 📝 Input variable definitions
│   │       │                           # - Networking variables
│   │       │                           # - Jenkins variables
│   │       │                           # - Firezone variables
│   │       │                           # - Certificate paths
│   │       │
│   │       ├── outputs.tf              # 📤 Output values for reference
│   │       │                           # - Resource group names
│   │       │                           # - VNet & subnet IDs
│   │       │                           # - VM & LB IPs
│   │       │                           # - DNS FQDNs
│   │       │
│   │       ├── terraform.tfvars        # ⚙️  EDIT THIS FIRST!
│   │       │                           # - Firezone enrollment token
│   │       │                           # - SSH key path
│   │       │                           # - Certificate file paths
│   │       │                           # - Azure region & project name
│   │       │
│   │       └── .terraform.lock.hcl     # 🔒 Dependency lock file (auto-managed)
│   │
│   └── modules/
│       │
│       ├── networking/                 # Network layer module
│       │   ├── main.tf                 # VNets, subnets, peering, NSGs
│       │   │                           # - VNet1 (Transit Hub): 10.10.10.0/16
│       │   │                           # - VNet2 (Core IT): 30.30.30.0/16
│       │   │                           # - Bidirectional VNet peering
│       │   │                           # - Network Security Groups
│       │   │                           # - Route tables for inter-VNet traffic
│       │   ├── variables.tf            # Module input variables
│       │   └── outputs.tf              # Module outputs
│       │
│       ├── jenkins/                    # Jenkins application stack module
│       │   ├── main.tf                 # VM, disks, ILB, DNS, Key Vault
│       │   │                           # - Rocky Linux 8 VM (Standard_D2s_v3)
│       │   │                           # - OS disk (50GB) + Data disk (100GB)
│       │   │                           # - Internal Load Balancer (ILB)
│       │   │                           # - HTTPS config (port 443)
│       │   │                           # - End-to-end encryption
│       │   │                           # - Azure Key Vault for certificates
│       │   │
│       │   ├── variables.tf            # Module input variables
│       │   ├── outputs.tf              # Module outputs
│       │   │
│       │   └── scripts/
│       │       └── jenkins-init.sh     # Jenkins installation & configuration
│       │                               # - System updates & Java setup
│       │                               # - Data disk mounting & formatting
│       │                               # - Jenkins installation from repo
│       │                               # - Nginx reverse proxy setup
│       │                               # - HTTPS certificate installation
│       │
│       └── firezone/                   # Firezone VPN Gateway module
│           ├── main.tf                 # VM, NSG, storage
│           │                           # - Rocky Linux 8 VM (Standard_B2s)
│           │                           # - Network Security Group config
│           │                           # - WireGuard UDP 51820
│           │                           # - HTTPS 443 for API & control
│           │                           # - Azure Storage for logs
│           │
│           ├── variables.tf            # Module input variables
│           ├── outputs.tf              # Module outputs
│           │
│           └── scripts/
│               └── firezone-init.sh    # Firezone installation & configuration
│                                       # - System setup (IP forwarding, etc)
│                                       # - WireGuard installation
│                                       # - Firezone Gateway download
│                                       # - Systemd service setup
│                                       # - Auto-enrollment with token
│
├── scripts/                            # Operational automation scripts
│   ├── generate-certificates.sh        # 🔐 SSL certificate generation
│   │                                   # - Self-signed cert generation (testing)
│   │                                   # - Root CA certificate
│   │                                   # - Full certificate chain creation
│   │                                   # - Proper permission setup
│   │
│   ├── setup-wif.sh                    # 🔑 Workload Identity Federation
│   │                                   # - Azure AD app creation
│   │                                   # - Service principal setup
│   │                                   # - Managed identity creation
│   │                                   # - Role assignments
│   │                                   # - Federated credentials config
│   │
│   └── setup-saml.sh                   # 🔐 SAML authentication setup
│                                       # - Jenkins SAML plugin config
│                                       # - Azure AD / Entra ID setup
│                                       # - Firezone SAML configuration
│                                       # - User & group mapping
│                                       # - Troubleshooting guidance
│
├── certificates/                       # 📁 SSL Certificate storage
│   ├── jenkins.crt                     # (Empty - add your certificate)
│   └── jenkins.key                     # (Empty - add your private key)
│
└── docs/ (Optional folder for additional docs)
    ├── ARCHITECTURE.md                 # Detailed architecture documentation
    ├── NETWORKING.md                   # Network design specifics
    ├── SECURITY.md                     # Security implementation details
    └── OPERATIONS.md                   # Daily operations guide

```

## 📂 File Type Legend

- `main.tf` - Primary Terraform resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `*.tfvars` - Variable values (actual configuration)
- `.tfstate` - Terraform state file (auto-managed, don't edit)
- `.sh` - Bash shell scripts for automation
- `.md` - Markdown documentation
- `.gitignore` - Git ignore patterns

## 🎯 Key Files to Edit

### Before First Deployment
1. **`terraform/environments/production/terraform.tfvars`** ⭐⭐⭐
   - Must update: Firezone enrollment token
   - Must update: SSH public key path
   - Must update: Certificate paths
   - Must update: Firezone API URL

### During Deployment
2. **`terraform/environments/production/main.tf`**
   - Reference for understanding infrastructure
   - Edit only if changing core architecture

### Post-Deployment
3. **`scripts/setup-saml.sh`**
   - Execute for SAML configuration
   - Follow the printed instructions

4. **`scripts/setup-wif.sh`**
   - Execute for WIF setup (optional)
   - Recommended for Terraform Cloud

## 📖 Documentation Quick Links

| Need | Document |
|------|----------|
| Overview | [README.md](./README.md) |
| Getting Started | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| Verification Checklist | [CHECKLIST.md](./CHECKLIST.md) |
| Problem Solving | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) |
| Cloud Integration | [TERRAFORM_CLOUD.md](./TERRAFORM_CLOUD.md) |
| Quick Summary | [SUMMARY.md](./SUMMARY.md) |

## 🚀 Deployment Steps Quick Links

1. **Initialize**: `terraform init` in `terraform/environments/production/`
2. **Validate**: `terraform validate`
3. **Plan**: `terraform plan -out=tfplan`
4. **Apply**: `terraform apply tfplan`
5. **Verify**: `terraform output`

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed walkthrough.

## 🔗 Module Relationships

```
main.tf (Orchestration)
├── module.networking (VNet, peering, NSG, routing)
│   └── Outputs: VNet IDs, subnet IDs, NSG IDs
│
├── module.jenkins_stack (VM, ILB, DNS, certificates)
│   ├── Depends on: networking module (subnet_id)
│   └── Outputs: VM IP, ILB IP, DNS FQDN
│
└── module.firezone_gateway (VM, NSG, WireGuard)
    ├── Depends on: networking module (subnet_id)
    └── Outputs: VM IP, gateway status

Private DNS Zone (main.tf)
├── Depends on: Both VNets (for linking)
├── A Record: jenkins-azure → ILB IP
└── Links: Both VNets for DNS resolution
```

## 💾 Storage & State

```
Azure Storage Account (for Terraform state)
└── Container: tfstate
    └── Blob: prod/terraform.tfstate (with versioning)

Azure Key Vault (in Jenkins module)
└── Certificates: jenkins.crt, jenkins.key

Azure Storage Account (in Firezone module)
└── Container: firezone-gateway-logs
```

## 🔐 Sensitive Data Locations

**⚠️ DO NOT COMMIT TO GIT:**
- `terraform.tfvars` (contains sensitive values)
- `*.tfvars` (if contains secrets)
- `certificates/*.key` (private keys)
- Enrollment tokens
- API keys/secrets
- SSH private keys

**✅ PROTECTED BY .gitignore:**
- `.tfstate` files
- `.terraform/` directories
- `.key` files
- `.tfvars` files
- Local overrides

## 📊 Resource Organization

### By Terraform Module
```
Networking Module (6 resources)
├── 2 VNets
├── 3 Subnets
├── 2 VNet Peerings
├── 3 NSGs
├── 2 Route Tables
└── NSG Associations

Jenkins Module (9 resources)
├── 1 NIC
├── 1 NSG
├── 1 VM
├── 2 Disks
├── 1 ILB
├── 1 Backend Pool
├── 1 Health Probe
├── 1 LB Rule
├── 1 Key Vault
└── Additional resources

Firezone Module (5 resources)
├── 1 NIC
├── 1 NSG
├── 1 VM
├── 1 Storage Account
└── 1 Storage Container
```

### By Azure Resource Group
```
rg-firezone-networking-prod
├── VNet1 (Networking-Global)
├── Subnets
├── NSGs
└── Route Tables

rg-firezone-jenkins-prod
├── VNet2 (Core-IT-Infrastructure)
├── Jenkins VM
├── Load Balancer
├── Key Vault
├── DNS Zone
└── Disks

rg-firezone-firezone-prod
├── Firezone Gateway VM
├── NSG
└── Storage Account
```

## ✨ Next Steps

1. **Read**: [README.md](./README.md) - Understand architecture
2. **Edit**: `terraform.tfvars` - Configure values
3. **Generate**: Run `scripts/generate-certificates.sh`
4. **Deploy**: Follow [DEPLOYMENT.md](./DEPLOYMENT.md)
5. **Verify**: Use [CHECKLIST.md](./CHECKLIST.md)
6. **Configure**: Run `scripts/setup-saml.sh`
7. **Operate**: Reference docs as needed

---

**Project Navigation**: Start with [README.md](./README.md) or [SUMMARY.md](./SUMMARY.md)
