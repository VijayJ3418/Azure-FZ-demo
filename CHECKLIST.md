# Project Implementation Checklist & Quick Reference

## Pre-Deployment Checklist

### Azure Preparation
- [ ] Azure subscription active and accessible
- [ ] Logged into Azure CLI: `az login`
- [ ] Azure region selected: `az account set --subscription "SUBSCRIPTION_ID"`
- [ ] Contributor/Owner role confirmed
- [ ] Storage account created for Terraform state
  - [ ] Storage container created
  - [ ] Versioning enabled
  - [ ] Soft delete enabled
- [ ] SSH key pair generated: `~/.ssh/id_rsa`

### Firezone Setup
- [ ] Firezone account created (https://console.firezone.dev)
- [ ] Organization created in Firezone
- [ ] Gateway created and enrollment token obtained
- [ ] Enrollment token saved securely
- [ ] Firezone API URL identified

### Local Environment
- [ ] Terraform >= 1.0 installed
- [ ] Azure CLI >= 2.40 installed
- [ ] Git installed and configured
- [ ] SSH client available
- [ ] Certificate files (or ready to generate)

### Certificates
- [ ] SSL certificate (full chain: root + intermediate + leaf)
- [ ] SSL private key (PEM format)
- [ ] Files placed in `certificates/` directory
  - [ ] `jenkins.crt` (or jenkins-chain.crt for full chain)
  - [ ] `jenkins.key` (private key)

### Repository Preparation
- [ ] Git repository initialized or cloned
- [ ] All Terraform files in place
- [ ] Scripts made executable: `chmod +x scripts/*.sh`
- [ ] Environment variables set up

## Configuration Checklist

### Terraform Variables
- [ ] `terraform.tfvars` configured with:
  - [ ] `firezone_api_url = "https://api.firezone.dev"`
  - [ ] `firezone_enrollment_token = "your-token"`
  - [ ] `ssh_public_key_path = "~/.ssh/id_rsa.pub"`
  - [ ] `certificate_path = "./certificates/jenkins.crt"`
  - [ ] `certificate_key_path = "./certificates/jenkins.key"`
  - [ ] `azure_region = "eastus"` (or your region)
  - [ ] Sensitive variables marked

### Backend Configuration
- [ ] `terraform.tfvars` matches:
  - [ ] `resource_group_name = "terraform-state-rg"`
  - [ ] `storage_account_name = "tfstateprodaccount"`
  - [ ] `container_name = "tfstate"`
  - [ ] `key = "prod/terraform.tfstate"`

### Azure Authentication
- [ ] Environment variables set:
  - [ ] `ARM_SUBSCRIPTION_ID`
  - [ ] `ARM_TENANT_ID`
  - [ ] `ARM_CLIENT_ID` (and `ARM_CLIENT_SECRET` if not using WIF)
  - [ ] OR Workload Identity Federation configured

## Deployment Checklist

### Initialization Phase
- [ ] Changed to correct directory: `terraform/environments/production/`
- [ ] Ran: `terraform init`
- [ ] Backend initialized successfully
- [ ] State configured in Azure Storage

### Validation Phase
- [ ] Ran: `terraform validate`
- [ ] No validation errors
- [ ] All modules load correctly

### Planning Phase
- [ ] Ran: `terraform plan -out=tfplan`
- [ ] Plan output reviewed:
  - [ ] Correct number of resources
  - [ ] No unintended deletions
  - [ ] All variables correctly applied
  - [ ] Resource groups created
  - [ ] VNets with correct CIDRS
  - [ ] VMs use correct images
  - [ ] Load balancer configured
  - [ ] DNS zone and records
  - [ ] Key Vault for certificates

### Approval Phase
- [ ] Plan reviewed with team
- [ ] Security implications understood
- [ ] Cost estimate acceptable
- [ ] No show-stopper issues

### Deployment Phase
- [ ] Ran: `terraform apply tfplan`
- [ ] Deployment completed without errors
- [ ] All resources created successfully
- [ ] Azure Portal shows all resources

### Verification Phase
- [ ] Ran: `terraform output`
- [ ] Output values reviewed:
  - [ ] Resource group names
  - [ ] VNet IDs and names
  - [ ] VM private IPs
  - [ ] Load balancer private IP
  - [ ] DNS FQDN
- [ ] Azure resources verified:
  - [ ] All 3 resource groups created
  - [ ] Both VNets created with correct CIDRS
  - [ ] VNet peering active (both directions)
  - [ ] NSG rules applied
  - [ ] Route tables configured
  - [ ] VMs running
  - [ ] Disks attached
  - [ ] ILB configured
  - [ ] DNS zone created
  - [ ] A records configured

## Post-Deployment Checklist

### Service Startup Verification (Wait 5-10 minutes)
- [ ] Firezone Gateway service running
  - [ ] Check: `systemctl status firezone-gateway`
  - [ ] Check Firezone console: Gateway shows "Connected"
  - [ ] Check: `systemctl status wireguard` (if applicable)
- [ ] Jenkins service running
  - [ ] Check: `systemctl status jenkins`
  - [ ] Check: `systemctl status nginx`
  - [ ] Jenkins accessible on port 8080 (internal)

### Network Verification
- [ ] VNet peering working:
  - [ ] Test connectivity from Firezone VM to Jenkins VM
  - [ ] Test reverse connectivity
- [ ] DNS resolution working:
  - [ ] `nslookup jenkins-azure.dglearn.online` returns 30.30.30.100
- [ ] Load balancer health:
  - [ ] Backend pool shows healthy targets
  - [ ] Health probe responding to hits

### Certificate Verification
- [ ] Certificate installed in Nginx
  - [ ] Check: `openssl s_client -connect 30.30.30.10:443`
- [ ] Certificate valid:
  - [ ] Not expired
  - [ ] CN matches domain
  - [ ] Chain complete
- [ ] Key Vault certificate stored:
  - [ ] Azure Portal > Key Vault > Certificates

### Security Verification
- [ ] NSG rules applied:
  - [ ] SSH allowed on port 22
  - [ ] WireGuard allowed on port 51820
  - [ ] HTTPS allowed on port 443
  - [ ] Unnecessary ports closed
  - [ ] Egress rules restrict to VNet/Internet only
- [ ] No public IPs:
  - [ ] Confirm all VMs have private IPs only
  - [ ] No public IP addresses created
- [ ] Firewall properly configured:
  - [ ] Azure Firewall rules (if using)

## Configuration Phase Checklist

### SAML Authentication Setup
- [ ] Azure AD application created
  - [ ] App name: "Jenkins-Firezone"
- [ ] SAML Single Sign-On configured:
  - [ ] Issuer (Entity ID): Set correctly
  - [ ] Reply URL: `https://jenkins-azure.dglearn.online/saml/acs`
  - [ ] Sign On URL: `https://jenkins-azure.dglearn.online`
  - [ ] Certificate uploaded
- [ ] User attributes/claims mapped:
  - [ ] email/mail claim
  - [ ] displayName claim
  - [ ] sAMAccountName (username) claim
  - [ ] memberOf (groups) claim
- [ ] Users assigned:
  - [ ] Test users added to application
  - [ ] Groups configured if using group-based access

### Jenkins SAML Configuration
- [ ] SAML plugin installed
  - [ ] Manage Jenkins > Manage Plugins > Search "SAML"
  - [ ] Installed and restarted
- [ ] SAML configured:
  - [ ] IdP metadata URL set
  - [ ] Entity ID configured
  - [ ] ACS URL configured
  - [ ] Attributes mapped
- [ ] SAML login tested:
  - [ ] Logout from Jenkins
  - [ ] Click "Sign in via SAML"
  - [ ] Redirects to Azure AD
  - [ ] Login successful
  - [ ] User information populated

### Firezone SAML Configuration
- [ ] SAML enabled in Firezone:
  - [ ] Settings > Authentication > SAML 2.0
  - [ ] Issuer set
  - [ ] SSO URL set
  - [ ] Certificate configured
- [ ] Resource created for Jenkins:
  - [ ] Resources > New Resource
  - [ ] Name: "Jenkins"
  - [ ] URL: `https://jenkins-azure.dglearn.online`
  - [ ] Authentication: SAML
- [ ] Access control configured:
  - [ ] Users/groups assigned to resource
  - [ ] Policies set up

## Client Setup Checklist

### Firezone Client Installation
- [ ] Download Firezone client from https://firezone.dev/download
- [ ] Install on client machine (macOS/Windows/Linux)
- [ ] Launch client

### Client Authentication
- [ ] Sign in with Firezone account
- [ ] Redirect to Azure AD authentication
- [ ] Login with corporate Azure AD credentials
- [ ] MFA approval (if configured)
- [ ] Return to Firezone client

### Network Verification
- [ ] DNS resolution working in client
  - [ ] `nslookup jenkins-azure.dglearn.online` (from client)
  - [ ] Should resolve to private IP
- [ ] Jenkins access test
  - [ ] Open browser: https://jenkins-azure.dglearn.online
  - [ ] Should see Jenkins login page
  - [ ] Login with Azure AD credentials (SAML)
  - [ ] Jenkins dashboard loads successfully

## Operational Readiness Checklist

### Monitoring & Logging
- [ ] Azure Monitor configured:
  - [ ] Metrics enabled for VMs
  - [ ] Alerts set for high CPU/memory
  - [ ] Log Analytics workspace configured
- [ ] Firezone logging:
  - [ ] Logs directed to Azure Storage
  - [ ] Retention policy set
- [ ] Jenkins logging:
  - [ ] Audit log plugin installed if needed
  - [ ] Logs persisted to data disk

### Backup & Disaster Recovery
- [ ] Terraform state backed up:
  - [ ] Azure Storage versioning enabled
  - [ ] Manual backup taken
- [ ] Jenkins data backed up:
  - [ ] Azure Backup configured for Jenkins VM
  - [ ] Retention policy set
  - [ ] Test restore procedure
- [ ] Certificates backed up:
  - [ ] Private keys secured in Key Vault
  - [ ] Manual backups in secure location
  - [ ] Expiration dates tracked

### Documentation
- [ ] Runbook created:
  - [ ] Client installation steps
  - [ ] Login procedures
  - [ ] Common troubleshooting
  - [ ] Escalation contacts
- [ ] Architecture diagram documented
- [ ] Network diagram documented
- [ ] Admin procedures documented:
  - [ ] VM restarts
  - [ ] Service management
  - [ ] Emergency procedures
- [ ] Credentials documented:
  - [ ] SSH keys stored securely
  - [ ] Admin passwords in password manager
  - [ ] API tokens documented (secure)
- [ ] Access control documented:
  - [ ] Who has what access
  - [ ] Azure RBAC roles assigned
  - [ ] Firezone user roles
  - [ ] Jenkins user roles

### Team Training
- [ ] Operations team trained:
  - [ ] System overview
  - [ ] Daily operations
  - [ ] Common issues
  - [ ] Escalation procedures
- [ ] User training completed:
  - [ ] Client installation
  - [ ] Login procedures
  - [ ] Resource access
  - [ ] Getting help
- [ ] Emergency procedures documented and practiced:
  - [ ] Incident response
  - [ ] Failover procedures
  - [ ] Communication plan

## Terraform Cloud Setup (If Using)

- [ ] Terraform Cloud account created
- [ ] Organization created: "your-org"
- [ ] Workspace created: "firezone-azure-prod"
- [ ] API token generated
- [ ] Local credentials configured: `~/.terraform/credentials.tfrc.json`
- [ ] Cloud block configured in `main.tf`
- [ ] Remote state migration: `terraform init`
- [ ] Environment variables set in TF Cloud:
  - [ ] ARM_SUBSCRIPTION_ID
  - [ ] ARM_TENANT_ID
  - [ ] ARM_CLIENT_ID
  - [ ] ARM_CLIENT_SECRET (or use WIF)
  - [ ] TF_VAR_firezone_enrollment_token
- [ ] WIF configured (recommended):
  - [ ] Azure AD app created
  - [ ] Federated credentials added
  - [ ] ARM_OIDC_TOKEN configured
- [ ] VCS integration configured (optional):
  - [ ] GitHub repo connected
  - [ ] Auto-plan enabled
  - [ ] Auto-apply configured (or requires review)
- [ ] First plan/apply via TF Cloud successful

## Quick Command Reference

### Common Terraform Commands

```bash
# Navigate to working directory
cd terraform/environments/production/

# Initialize (one time)
terraform init

# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply plan
terraform apply tfplan

# Apply specific resource
terraform apply -target=module.jenkins_stack

# Show current state
terraform show

# View outputs
terraform output

# View specific output
terraform output jenkins_vm_private_ip

# Destroy (full environment)
terraform destroy

# Destroy specific resource
terraform destroy -target=module.jenkins_stack
```

### Azure CLI Commands

```bash
# List resource groups
az group list --output table

# List VMs
az vm list --output table

# List VNets
az network vnet list --output table

# List Load Balancers
az network lb list --output table

# Get VM details
az vm show -g rg-firezone-jenkins-prod -n vm-firezone-jenkins

# Get VM diagnostics
az vm boot-diagnostics get-boot-log -g rg-firezone-jenkins-prod \
  -n vm-firezone-jenkins --output table

# Get outputs
terraform output -json | jq
```

## Troubleshooting Quick Links

- Can't reach Jenkins: See [TROUBLESHOOTING.md - Cannot connect to Jenkins ILB](#)
- SAML login fails: See [TROUBLESHOOTING.md - SAML Login Fails](#)
- Firezone offline: See [TROUBLESHOOTING.md - Firezone Gateway shows Offline](#)
- Certificate errors: See [TROUBLESHOOTING.md - SSL Certificate Error](#)
- Network issues: See [TROUBLESHOOTING.md - Cannot connect across VNets](#)

## Success Criteria

✅ **Deployment is successful when**:
1. All Terraform resources created without errors
2. Both VNets peered bidirectionally
3. Firezone Gateway registered and online
4. Jenkins running on https://jenkins-azure with valid certificate
5. DNS resolves jenkins-azure.dglearn.online to ILB IP
6. SAML authentication working (Azure AD SSO)
7. End-user can access Jenkins via Firezone client
8. Monitoring and logging enabled
9. Backups configured
10. Team trained and documented

## Contact & Escalation

**For Issues**:
- Terraform: https://registry.terraform.io/
- Azure: Azure Support Portal
- Firezone: https://discord.gg/firezone
- Jenkins: https://www.jenkins.io/support/

**Escalation Chain**:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review logs (see [Deployment Guide](./DEPLOYMENT.md))
3. Check community forums/Discord
4. Contact vendor support if needed

---

**Project Status**: ✅ Ready for Deployment  
**Last Updated**: March 2026  
**Terraform Version**: 1.0+  
**Azure Provider**: 3.85+
