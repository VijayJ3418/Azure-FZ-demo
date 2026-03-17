# Deployment Guide

Step-by-step instructions for deploying the Firezone infrastructure on Azure.

## Phase 1: Pre-Deployment (Day 1)

### 1.1 Azure Account Preparation

```bash
# Login to Azure
az login

# Create resource group for Terraform state
az group create \
  --name terraform-state-rg \
  --location eastus

# Create storage account
az storage account create \
  --name tfstateprodaccount \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS \
  --access-tier Hot

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstateprodaccount \
  --public-access off

# Enable versioning and soft delete
az storage account blob-service-properties update \
  --account-name tfstateprodaccount \
  --enable-change-feed true \
  --enable-versioning true
```

### 1.2 Generate SSH Key Pair

```bash
# If you don't already have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Verify
cat ~/.ssh/id_rsa.pub
```

### 1.3 Firezone Setup

1. Visit https://console.firezone.dev
2. Create account and organization
3. Go to Admin Console > Gateways
4. Click "Add Gateway"
5. Select "Linux" and copy the enrollment token
6. Save the token securely (you'll need it for Terraform)

Also note:
- Your Firezone API URL (typically `https://api.firezone.dev`)
- Your organization ID

### 1.4 Prepare SSL Certificates

**Option A: Self-Signed (Testing)**

```bash
cd /path/to/Azure-Code-Updated/scripts
bash generate-certificates.sh

# Certificates created in ../certificates/
```

**Option B: Production Certificates**

1. Obtain valid SSL certificate from CA (Let's Encrypt, DigiCert, etc.)
2. Format as PEM
3. Place in `certificates/` directory:
   - `jenkins.crt` (full chain: root + intermediate + leaf)
   - `jenkins.key` (private key)

### 1.5 Configure Variables

```bash
cd terraform/environments/production

# Copy and edit
cp terraform.tfvars terraform.tfvars.local

# Edit configuration
# nano terraform.tfvars

# Critical fields to update:
# - firezone_api_url = "https://api.firezone.dev"
# - firezone_enrollment_token = "your-enrollment-token"
# - certificate_path = "./certificates/jenkins.crt"
# - certificate_key_path = "./certificates/jenkins.key"
# - ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

### 1.6 Setup Workload Identity Federation (Optional but Recommended)

```bash
cd scripts
bash setup-wif.sh

# Follow prompts to configure WIF in Azure AD
# This eliminates need for storing credentials in Terraform Cloud
```

## Phase 2: Infrastructure Deployment (Day 2)

### 2.1 Initialize Terraform

```bash
cd terraform/environments/production

# Initialize
terraform init

# Should show backend configured successfully
```

### 2.2 Validate Configuration

```bash
# Check syntax
terraform validate

# Should complete without errors
```

### 2.3 Plan Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review resources being created:
# - Resource groups
# - VNets and subnets
# - VNet peering
# - Network security groups
# - VMs and disks
# - Load balancer
# - DNS zone
# - Key Vault

# Verify costs and resource count
```

### 2.4 Apply Configuration

```bash
# Deploy (this takes 10-15 minutes)
terraform apply tfplan

# Wait for completion...
# Should see all resource creation messages

# Verify deployment
terraform output
```

### 2.5 Verify Resource Creation

```bash
# In Azure Portal or CLI:

# Check resource groups
az group list --output table

# Check VNets
az network vnet list --output table

# Check VMs (should see Jenkins & Firezone)
az vm list --output table | grep vm-

# Check load balancer
az network lb list --output table

# Check private DNS
az network private-dns zone list --output table
```

## Phase 3: Service Configuration (Day 2-3)

### 3.1 Wait for VM Initialization

VMs run user data scripts during startup. Check status:

```bash
# Connect to Firezone Gateway (requires bastion or custom network setup)
# OR use Azure Bastion if configured

# Check Firezone Gateway logs
az vm boot-diagnostics get-boot-log --resource-group rg-firezone-firezone-prod \
  --name vm-firezone-firezone-gateway --output table

# Check Jenkins VM logs
az vm boot-diagnostics get-boot-log --resource-group rg-firezone-jenkins-prod \
  --name vm-firezone-jenkins --output table
```

### 3.2 Verify Jenkins Installation

```bash
# Get Jenkins VM private IP
terraform output jenkins_vm_private_ip

# Jenkins should be running on:
# https://jenkins-azure.dglearn.online (via Firezone)
# http://30.30.30.10:8080 (internal only, direct)
```

### 3.3 Verify Firezone Gateway

```bash
# Get Firezone Gateway private IP
terraform output firezone_gateway_private_ip

# In Firezone Admin Console:
# - Gateways > should show gateway as "Connected"
# - Status: Online
# - Synced: Yes
```

## Phase 4: SAML Authentication Setup (Day 3)

### 4.1 Setup Azure AD Application

```bash
# Run SAML setup guide
cd scripts
bash setup-saml.sh

# Follow instructions for:
# 1. Creating Enterprise Application in Azure AD
# 2. Configuring SAML SSO
# 3. Mapping user attributes
# 4. Setting up groups for access control
```

### 4.2 Configure Jenkins SAML

1. **Install SAML Plugin**
   ```
   Jenkins > Manage Jenkins > Manage Plugins
   Search: "SAML"
   Install: "SAML Plugin"
   Restart Jenkins
   ```

2. **Configure SAML**
   ```
   Jenkins > Manage Jenkins > Configure System
   Scroll to "SAML"
   
   - IdP Metadata: Use Azure AD federation metadata URL
   - Entity ID: https://jenkins-azure.dglearn.online/saml/sp
   - ACS URL: https://jenkins-azure.dglearn.online/saml/acs
   
   - Attribute Mappings:
     - Display Name: displayName
     - Email: mail
     - Username: sAMAccountName
     - Groups: memberOf
   
   Save configuration
   ```

3. **Test SAML Login**
   ```
   Logout from Jenkins
   Click "Login via SAML"
   Should redirect to Azure AD
   Login with Azure credentials
   Should return to Jenkins authenticated
   ```

### 4.3 Configure Firezone SAML

1. **Create Resources**
   ```
   Firezone Console > Resources > New
   Name: Jenkins-Production
   URL: https://jenkins-azure.dglearn.online
   Authentication: SAML
   ```

2. **Enable SAML**
   ```
   Settings > Authentication > SAML 2.0
   Issuer: https://sts.windows.net/{TENANT_ID}/
   SSO URL: https://login.microsoftonline.com/{TENANT_ID}/saml2
   Certificate: (download from Azure AD)
   ```

3. **Configure Access**
   ```
   Resources > Jenkins-Production > Access
   SAML Groups: Add Azure AD groups
   Example: Jenkins-Admins, Jenkins-Users
   ```

## Phase 5: Client Setup (Day 3-4)

### 5.1 Install Firezone Client

Download from https://firezone.dev/download for your OS:
- macOS
- Windows
- Linux

### 5.2 Client Configuration

1. **Launch Firezone Client**
2. **Sign In**
   - URL: Your Firezone instance
   - Click "Sign in with SAML"
   - Authenticate with Azure AD
3. **Approve MFA** (if configured)
4. **Access Resources**
   - Client automatically routes .intranet domains through gateway
   - Visit https://jenkins-azure.dglearn.online

### 5.3 Test End-to-End Access

```bash
# From client machine:

# Test DNS resolution
nslookup jenkins-azure.dglearn.online
# Should resolve to ILB private IP: 30.30.30.100

# Test HTTPS connectivity
curl -v https://jenkins-azure.dglearn.online
# Should return Jenkins page

# Test Jenkins UI
# Open browser to https://jenkins-azure.dglearn.online
# Should show Jenkins login
# Login with Azure AD credentials via SAML
```

## Phase 6: Post-Deployment Validation (Day 4)

### 6.1 Verify All Components

```bash
# Terraform state
terraform show

# Resource group contents
az resource list --resource-group rg-firezone-networking-prod --output table
az resource list --resource-group rg-firezone-jenkins-prod --output table
az resource list --resource-group rg-firezone-firezone-prod --output table

# Network connectivity
# - VNet peering: both directions active
# - NSG rules: allow required traffic
# - Route tables: routes to remote VNet

# VM status
az vm get-instance-view --resource-group rg-firezone-jenkins-prod \
  --name vm-firezone-jenkins --query "instanceView.statuses" --output table

# Load balancer health
az network lb show --resource-group rg-firezone-jenkins-prod \
  --name ilb-firezone-jenkins
```

### 6.2 Monitor Performance

```bash
# In Azure Portal:
# 1. Navigate to each resource group
# 2. Check "Monitoring" > "Metrics"
# 3. Verify:
#    - CPU usage normal
#    - Network throughput expected
#    - Disk I/O reasonable
#    - No errors in activity logs
```

### 6.3 Security Audit

- [ ] All VMs have private IPs only
- [ ] Public IPs removed (if any created)
- [ ] NSGs restrictive (SSH/WireGuard/HTTPS only)
- [ ] Certificates valid and installed
- [ ] SAML authentication working
- [ ] Azure AD groups configured
- [ ] Key Vault access policies correct
- [ ] Terraform state encrypted
- [ ] Audit logging enabled

## Phase 7: Documentation & Handoff (Day 4-5)

### 7.1 Document Access Procedures

Create runbook covering:
- Client installation and setup
- SAML login procedure
- Accessing Jenkins resources
- Troubleshooting common issues
- Emergency access procedures

### 7.2 Backup Critical Data

```bash
# Export Terraform state (secure location)
terraform state pull > terraform.state.backup

# Back up certificates
cp -r certificates/ /secure/backup/location/

# Document Firezone enrollment token (secure storage)
# Document admin credentials (password manager)
```

### 7.3 Setup Monitoring Alerts

In Azure Monitor:
- VM CPU > 80%
- Network bytes in/out anomalies
- Load balancer unhealthy backends
- Certificate expiration warnings
- Key Vault access anomalies
- Jenkins disk space alerts

### 7.4 Configure Backup & Disaster Recovery

```bash
# Enable Azure Backup for Jenkins VM
az backup vault create \
  --resource-group rg-firezone-jenkins-prod \
  --name firezonevault

# Configure daily backups
# Enable soft delete on Key Vault
# Enable point-in-time recovery for DNS
```

## Rollback Procedure

If deployment needs to be reversed:

```bash
# Backup current state (important!)
terraform state pull > terraform.state.rollback

# Destroy infrastructure
terraform destroy

# Confirm when prompted
# Takes 5-10 minutes

# Clean up storage (if not reusing)
az storage account delete \
  --name tfstateprodaccount \
  --resource-group terraform-state-rg
```

## Next Steps

### Immediate (Week 1)
- [ ] Verify all services operational
- [ ] Conduct security audit
- [ ] Document operational procedures
- [ ] Train users on Firezone client

### Short-term (Month 1)
- [ ] Monitor resource utilization
- [ ] Optimize VM sizing if needed
- [ ] Collect user feedback
- [ ] Set up automated backups
- [ ] Configure additional monitoring

### Medium-term (Month 2-3)
- [ ] Scale additional applications via same infrastructure
- [ ] Implement disaster recovery testing
- [ ] Optimize Firezone Gateway performance
- [ ] Evaluate certificate management strategy
- [ ] Plan capacity for growth

---

**Deployment Checklist Summary**:
- [ ] Prerequisites installed and verified
- [ ] Azure account prepared with storage backends
- [ ] SSH keys generated
- [ ] Firezone account created, enrollment token obtained
- [ ] SSL certificates prepared
- [ ] Terraform variables configured
- [ ] Infrastructure deployed via Terraform
- [ ] Services verified running
- [ ] Azure AD/SAML authentication configured
- [ ] Client deployed and tested
- [ ] End-to-end access verified
- [ ] Monitoring and alerting configured
- [ ] Documentation complete
- [ ] Team trained
