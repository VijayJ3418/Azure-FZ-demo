# Terraform Cloud Integration Guide

This guide covers setting up Terraform Cloud for centralized state management and CI/CD automation.

## Overview

Terraform Cloud provides:
- **Remote State**: Secure, versioned state storage
- **Run Management**: Plan/apply visibility and control
- **Team Collaboration**: Role-based access and approval workflows
- **VCS Integration**: Auto-plan on PR, auto-apply on merge
- **Workload Identity Federation**: No static credentials needed
- **Cost Estimation**: Pre-apply cost analysis
- **Sentinel Policy**: Governance and compliance

## Prerequisites

- Terraform Cloud account (free tier available)
- Organization in Terraform Cloud
- VCS repository access (GitHub, GitLab, etc.)
- Azure subscription with appropriate permissions
- Git CLI installed locally

## Step 1: Create Terraform Cloud Account

1. Visit https://app.terraform.io
2. Sign up or login
3. Create organization: "your-org-name"
4. Note your organization name for configuration

## Step 2: Create API Token

1. Go to Settings > (User Icon) > Tokens
2. Click "Create an API token"
3. Name: "Firezone Azure Terraform"
4. Copy token (save securely)

## Step 3: Configure Local Authentication

```bash
# Create Terraform credentials
cat > ~/.terraform/credentials.tfrc.json <<'EOF'
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR_API_TOKEN_HERE"
    }
  }
}
EOF

chmod 600 ~/.terraform/credentials.tfrc.json
```

## Step 4: Create Workspace in Terraform Cloud

```bash
# Option 1: Via Web UI
# https://app.terraform.io/app/YOUR_ORG/workspaces
# Create workspace: "firezone-azure-prod"
# Set VCS (optional)

# Option 2: Via Terraform
cd terraform/environments/production

# Update main.tf cloud block
cat >> main.tf <<'EOF'
terraform {
  cloud {
    organization = "your-org-name"
    
    workspaces {
      name = "firezone-azure-prod"
    }
  }
}
EOF
```

## Step 5: Configure Workspace Settings

In Terraform Cloud UI:

1. **General Settings**:
   - Terraform Version: 1.5 or latest
   - Auto-approve: Disable (require manual review)
   - Working Directory: `terraform/environments/production/`

2. **VCS Settings** (optional):
   - Provider: GitHub/GitLab
   - Repository: your-org/firezone-azure
   - VCS Branch: main
   - Auto-plan: Enabled
   - Auto-apply: Disabled (require review)

3. **Run Triggers** (optional):
   - Trigger on: VCS events
   - Trigger module updates: Enabled

## Step 6: Set Environment Variables

In Terraform Cloud workspace settings:

### Azure Authentication (WIF - Preferred)

```
ARM_OIDC_TOKEN_FILE_PATH: /path/to/oidc/token
ARM_CLIENT_ID: your-client-id
ARM_TENANT_ID: your-tenant-id
ARM_SUBSCRIPTION_ID: your-subscription-id
```

### Azure Authentication (Alternative - Credentials)

```
ARM_SUBSCRIPTION_ID: your-subscription-id
ARM_TENANT_ID: your-tenant-id  
ARM_CLIENT_ID: your-azure-app-id
ARM_CLIENT_SECRET: your-azure-secret (mark as sensitive)
```

### Firezone Configuration

```
TF_VAR_firezone_api_url: https://api.firezone.dev
TF_VAR_firezone_enrollment_token: your-enrollment-token (mark as sensitive)
```

### SSH Configuration

```
TF_VAR_ssh_public_key_path: ~/.ssh/id_rsa.pub
```

## Step 7: Configure Workload Identity Federation

For production, use WIF instead of static credentials:

### 7.1 Create Azure AD Application for WIF

```bash
# Run WIF setup script
cd scripts
bash setup-wif.sh
```

### 7.2 Add Federated Credentials

```bash
az ad app federated-credential create \
  --id YOUR_CLIENT_ID \
  --parameters '{
    "name": "terraform-cloud-wif",
    "issuer": "https://app.terraform.io",
    "subject": "organization:your-org:project:my-project:workspace:firezone-azure-prod:run_phase:plan",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Add second credential for apply phase
az ad app federated-credential create \
  --id YOUR_CLIENT_ID \
  --parameters '{
    "name": "terraform-cloud-wif-apply",
    "issuer": "https://app.terraform.io",
    "subject": "organization:your-org:project:my-project:workspace:firezone-azure-prod:run_phase:apply",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 7.3 Configure WIF Environment Variables

In Terraform Cloud workspace (mark as sensitive):

```
ARM_OIDC_TOKEN: from-terraform-cloud-provider
ARM_CLIENT_ID: your-app-client-id
ARM_TENANT_ID: your-tenant-id
ARM_SUBSCRIPTION_ID: your-subscription-id
ARM_USE_OIDC: true
```

## Step 8: Link VCS Repository (Optional)

### 8.1 GitHub Integration

1. In Terraform Cloud workspace, go to VCS Settings
2. Click "Connect to VCS"
3. Select "GitHub" 
4. Authorize Terraform Cloud access
5. Select repository: `your-org/firezone-azure`
6. Configure run settings:
   - VCS branch: main
   - Working directory: `terraform/environments/production/`
   - Auto-plan: On pull request
   - Auto-apply: On merge to main

### 8.2 GitHub Actions Integration (Optional)

Create `.github/workflows/terraform-plan.yml`:

```yaml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'terraform/**'

env:
  TF_CLOUD_ORGANIZATION: "your-org-name"
  TF_WORKSPACE: "firezone-azure-prod"
  TF_TOKEN_APP_TERRAFORM_IO: ${{ secrets.TF_API_TOKEN }}

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Format
        run: terraform fmt -check -recursive
        working-directory: terraform/environments/production
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/production
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: terraform/environments/production
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

## Step 9: Configure Policy as Code (Sentinel - Optional)

Sentinel allows enforcement of policies on all runs.

### 9.1 Create Policy

Create `sentinel/enforce-https.sentinel`:

```sentinel
import "tfplan"
import "tfplan/v2" as tfplan

# Enforce HTTPS on load balancers
forbidden_protocols = ["HTTP"]

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is not "azurerm_lb_rule" or
    rc.change.after.protocol not in forbidden_protocols
  }
}
```

### 9.2 Add Policy to Workspace

```bash
# Create policy file
mkdir -p policies
cp sentinel/enforce-https.sentinel policies/

# In Terraform Cloud UI:
# Go to Settings > Policies
# Create policy set and add policy
```

## Step 10: First Run via Terraform Cloud

### 10.1 Initial Setup

```bash
# Login to Terraform Cloud
terraform cloud-init

# Initialize with cloud backend
cd terraform/environments/production
terraform init

# Update config for cloud backend
# Uncomment cloud block in main.tf
terraform init  # Migrate state to cloud
```

### 10.2 First Plan

```bash
# Plan via Terraform Cloud
terraform plan

# Output shows plan running in TF Cloud
# Check https://app.terraform.io for details
```

### 10.3 First Apply

```bash
# Apply requires approval in UI
# Go to Terraform Cloud workspace
# Review plan and click "Confirm & Apply"

# Or apply via CLI (if auto-apply enabled)
terraform apply
```

## Workflow: PR → Plan → Review → Apply

### 1. Create Feature Branch

```bash
git checkout -b feature/add-monitoring
# Make changes to terraform files
git commit -m "Add monitoring for Jenkins VM"
git push origin feature/add-monitoring
```

### 2. Create Pull Request

- Push branch to GitHub/GitLab
- Create PR with description of changes
- Auto-triggers Terraform Cloud plan

### 3. Review Plan

- Terraform Cloud shows plan in PR comments
- Review resources being created/modified/destroyed
- Check cost implications
- Request changes if needed

### 4. Approve & Merge

```bash
# After approval, merge to main
# Auto-triggers apply in Terraform Cloud (if enabled)
# Monitor in TF Cloud UI

# Or manually approve:
# Go to Terraform Cloud workspace
# Click "Confirm & Apply"
```

### 5. Verify

```bash
# After apply completes:
terraform output

# Verify in Azure
az resource list -g rg-firezone-networking-prod
```

## Managing State

### View Remote State

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show azurerm_virtual_network.vnet1

# View via Terraform Cloud UI
# Organization > Workspace > State > History
```

### State Backups

Terraform Cloud automatically:
- Versions all state
- Keeps 30-day history
- Encrypts at rest
- Encrypts in transit

### Lock State

```bash
# TF Cloud automatically locks state during runs
# Manual lock (via UI):
# Workspace > States > Manually lock state

# Via API:
curl --request POST \
  --header "Authorization: Bearer $TOKEN" \
  https://app.terraform.io/api/v2/state-locks
```

## Monitoring & Logs

### Run History

In Terraform Cloud:
- Organization > Workspace > Runs
- Filter by status (planned, applied, failed)
- View logs for each run

### Cost Estimation

Before each apply, Terraform Cloud shows:
- Resource cost changes
- Estimated monthly cost
- Cost comparison with current

### Notifications

Configure alerts for:
- Runs scheduled
- Planned state changes
- Failed runs
- Policy violations

Set via:
- Email notifications
- Slack integration
- Webhooks

## Troubleshooting Terraform Cloud

### Issue: Plan fails with permissions error

```bash
# Verify Azure credentials
terraform login app.terraform.io  # Re-authenticate

# Check environment variables set correctly
echo $ARM_SUBSCRIPTION_ID
echo $ARM_TENANT_ID
```

### Issue: State lock timeout

```bash
# Manual unlock (via UI):
# Workspace > Settings > State Locking > Force Unlock

# Or via API
curl --request DELETE 
  --header "Authorization: Bearer $TOKEN" \
  https://app.terraform.io/api/v2/state-locks/{lock-id}
```

### Issue: VCS webhook not triggering plans

```bash
# Verify VCS connection
# Workspace > VCS Settings
# Click "Reconnect to VCS"

# Or manually trigger run via CLI/API
terraform apply
```

## Best Practices

1. **Always review plans before applying**
   - Disable auto-apply in workspace
   - Use PR-based workflow
   - Require approvals for production

2. **Use cost estimation**
   - Review costs before apply
   - Set up budget alarms
   - Monitor monthly spending

3. **Implement policy governance**
   - Create Sentinel policies
   - Enforce security standards
   - Require compliance

4. **Maintain state security**
   - Enable remote state only
   - Use WIF instead of credentials
   - Audit state access

5. **Version control best practices**
   - Review all changes via PR
   - Require code review
   - Enforce branch protection
   - Use descriptive commit messages

## Cost Considerations

Terraform Cloud pricing:
- **Free tier**: 1 workspace, limited team cooperation
- **Standard**: $20/month per workspace
- **Plus**: Custom VCS integration, team management
- **Business**: Advanced features, compliance

For single workspace production: ~$20-40/month

## Security Considerations

✓ **Do**:
- Use Workload Identity Federation
- Rotate API tokens regularly
- Enable audit logging
- Use RBAC in Terraform Cloud
- Store secrets in environment variables

✗ **Don't**:
- Store credentials in `.tf` files
- Commit `.tfvars` with secrets
- Share API tokens
- Use same credentials for multiple workspaces
- Store certificate private keys in version control

## Next Steps

1. ✓ Setup Terraform Cloud account
2. ✓ Configure workspace settings
3. ✓ Link VCS repository (optional)
4. ✓ Test first plan and apply
5. ✓ Create Sentinel policies
6. ✓ Configure team permissions
7. ✓ Setup cost alerts
8. ✓ Document team workflows

---

**Resources**:
- Terraform Cloud Docs: https://www.terraform.io/cloud-docs
- WIF Setup: https://www.terraform.io/cloud-docs/getting-started/oidc/azure
- Sentinel Policies: https://www.terraform.io/cloud-docs/policy-enforcement/sentinel
- Best Practices: https://www.terraform.io/cloud-docs/guides

