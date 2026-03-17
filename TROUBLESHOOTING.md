# Troubleshooting Guide

Common issues and solutions for Firezone Azure deployment.

## Network & Connectivity Issues

### Problem: Cannot connect to Jenkins ILB

**Symptoms**:
- Cannot reach `jenkins-azure.dglearn.online`
- Timeout on DNS resolution
- Connection refused

**Investigation**:
```bash
# Check DNS resolution
nslookup jenkins-azure.dglearn.online
# Should resolve to 30.30.30.100 (ILB private IP)

# Check ILB health
az network lb show -g rg-firezone-jenkins-prod -n ilb-firezone-jenkins

# Check backend pool status
az network lb address-pool list -g rg-firezone-jenkins-prod --lb-name ilb-firezone-jenkins

# Check probe results
az network lb probe show -g rg-firezone-jenkins-prod --lb-name ilb-firezone-jenkins -n https-probe
```

**Solutions**:
1. **DNS not resolving**: Check private DNS zone and A record
   ```bash
   az network private-dns zone show -g rg-firezone-jenkins-prod -n dglearn.online
   az network private-dns record-set list -g rg-firezone-jenkins-prod -z dglearn.online
   ```

2. **ILB backend unhealthy**: Check health probe
   - Verify Jenkins is listening on port 443
   - Check certificate validity
   - Review NSG rules

3. **Network peering issue**: Verify peering enabled
   ```bash
   az network vnet peering show -g rg-firezone-networking-prod \
     --vnet-name Networking-Global \
     --name Networking-Global-to-Core-IT-Infrastructure
   ```

### Problem: VMs cannot communicate across VNets

**Symptoms**:
- Ping/curl between VNets fails
- Firewall-like behavior

**Investigation**:
```bash
# Check VNet peering status
az network vnet peering list --vnet-name Networking-Global -g rg-firezone-networking-prod

# Check route tables
az network route-table show -g rg-firezone-networking-prod -n Networking-Global-routes

# Check NSG rules
az network nsg rule list -g rg-firezone-networking-prod --nsg-name Networking-Global-gateway-nsg
```

**Solutions**:
1. **Peering not active**: 
   ```bash
   terraform apply -target=module.networking.azurerm_virtual_network_peering.vnet1_to_vnet2
   ```

2. **Routes not created**: Check route tables in Terraform
   ```bash
   terraform apply -target=module.networking.azurerm_route_table
   ```

3. **NSG blocking traffic**: Update security rules
   ```bash
   # Review NSG rules
   az network nsg show -g rg-firezone-networking-prod -n Networking-Global-gateway-nsg
   ```

## Firezone Gateway Issues

### Problem: Firezone Gateway shows "Offline"

**Symptoms**:
- Firezone console shows gateway as offline
- No client can connect

**Investigation**:
```bash
# Check VM running
az vm get-instance-view -g rg-firezone-firezone-prod -n vm-firezone-firezone-gateway

# SSH to gateway and check service
systemctl status firezone-gateway
journalctl -u firezone-gateway -n 50

# Check logs
tail -f /var/log/messages
```

**Solutions**:
1. **Service not running**:
   ```bash
   # SSH to VM
   ssh -i ~/.ssh/id_rsa azureuser@<gateway-private-ip>
   
   # Start service
   sudo systemctl start firezone-gateway
   sudo systemctl enable firezone-gateway
   
   # Monitor
   sudo journalctl -u firezone-gateway -f
   ```

2. **Enrollment token expired**: 
   - Generate new token in Firezone console
   - Update Terraform variables
   - Redeploy: `terraform apply -target=module.firezone_gateway`

3. **Network connectivity**:
   - Verify outbound HTTPS (443) allowed in NSG
   - Check firewall rules
   - Verify DNS resolution works

### Problem: Firezone enrollment fails

**Symptoms**:
- Boot logs show enrollment token rejected
- "Invalid token" or "Authorization failed"

**Solutions**:
1. **Verify token is current**:
   - Firezone console may have time-limited tokens
   - Generate new token if expired

2. **Check API URL**:
   ```bash
   # Verify in terraform.tfvars
   echo $TF_VAR_firezone_api_url
   
   # Should be https://api.firezone.dev or your instance
   ```

3. **Network access to Firezone API**:
   ```bash
   # From gateway VM
   curl -v https://api.firezone.dev/health
   ```

## Jenkins Issues

### Problem: Jenkins won't start

**Symptoms**:
- Jenkins process not running
- Port 8080 not listening
- Nginx proxy returns 502

**Investigation**:
```bash
# SSH to Jenkins VM
ssh -i ~/.ssh/id_rsa azureuser@<jenkins-private-ip>

# Check Jenkins service
sudo systemctl status jenkins
sudo systemctl status nginx

# Check logs
sudo tail -f /var/log/jenkins/jenkins.log
sudo tail -f /var/log/nginx/error.log

# Check disk space
df -h
du -sh /var/lib/jenkins/
```

**Solutions**:
1. **Out of disk space**:
   ```bash
   # Expand data disk in Azure
   terraform apply -var='jenkins_data_disk_size_gb=200'
   
   # In VM: resize filesystem
   sudo resize2fs /dev/sdc1
   ```

2. **Java heap issues**:
   ```bash
   # Increase heap size
   sudo sed -i 's/-Xmx512m/-Xmx1g/' /etc/sysconfig/jenkins
   sudo systemctl restart jenkins
   ```

3. **Broken installation**:
   ```bash
   # Reinstall
   sudo yum remove -y jenkins
   sudo yum install -y jenkins
   sudo systemctl start jenkins
   ```

### Problem: Cannot access Jenkins UI

**Symptoms**:
- Browser shows connection timeout
- 502 Bad Gateway from Nginx
- HTTPS certificate error

**Investigation**:
```bash
# Check Jenkins health probe status
az network lb probe show -g rg-firezone-jenkins-prod \
  --lb-name ilb-firezone-jenkins -n https-probe

# Test Jenkins directly (from Firezone or bastion)
curl -k https://30.30.30.10:443/jenkins
# or
curl http://30.30.30.10:8080

# Check Nginx reverse proxy
sudo curl -k https://localhost/jenkins
sudo tail -f /var/log/nginx/access.log
```

**Solutions**:
1. **Certificate issues**:
   ```bash
   # Verify certificate
   openssl x509 -in certificates/jenkins.crt -text -noout
   
   # Update if expired
   ./scripts/generate-certificates.sh
   terraform apply -target=module.jenkins_stack.azurerm_linux_virtual_machine.jenkins
   ```

2. **Nginx configuration**:
   ```bash
   # Verify configuration
   sudo nginx -t
   
   # Restart
   sudo systemctl restart nginx
   
   # Check upstream
   sudo netstat -tlnp | grep java  # Should show 8080
   ```

## Certificate Issues

### Problem: SSL Certificate Error

**Symptoms**:
- "Certificate not trusted" browser warning
- "SSL_ERROR_BAD_CERT_DOMAIN"
- Certificate mismatch errors

**Investigation**:
```bash
# Verify certificate details
openssl x509 -in certificates/jenkins.crt -text -noout

# Check certificate validity dates
openssl x509 -in certificates/jenkins.crt -noout -dates

# Verify certificate matches key
openssl x509 -in certificates/jenkins.crt -noout -modulus | openssl md5
openssl rsa -in certificates/jenkins.key -noout -modulus | openssl md5
# Should match

# Verify CN matches domain
openssl x509 -in certificates/jenkins.crt -noout -subject
# Should contain jenkins-azure.dglearn.online
```

**Solutions**:
1. **Self-signed certificate in production**:
   - Configure clients to trust self-signed cert
   - Replace with CA-signed certificate for production

2. **Expired certificate**:
   ```bash
   # Generate new certificate or renew
   ./scripts/generate-certificates.sh
   
   # Update Key Vault
   terraform apply -target=module.jenkins_stack.azurerm_key_vault_certificate
   ```

3. **Domain mismatch**:
   - Certificate CN must match: `jenkins-azure.dglearn.online`
   - Regenerate with correct domain

## SAML Authentication Issues

### Problem: SAML Login Fails

**Symptoms**:
- "Authentication failed" message
- No SAML option on Jenkins login
- Redirect loop to Azure AD

**Investigation**:
```bash
# Check Jenkins SAML plugin installed
# Jenkins > Manage Plugins > Installed > Filter "saml"

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log | grep -i saml

# Check Azure AD federation metadata
curl -s https://login.microsoftonline.com/common/federationmetadata/2007-06/federationmetadata.xml | head -20
```

**Solutions**:
1. **Plugin not installed**:
   ```
   Jenkins > Manage Jenkins > Manage Plugins
   Available > Search "SAML"
   Install "SAML Plugin"
   Restart Jenkins
   ```

2. **Incorrect SAML configuration**:
   - Verify ACS URL matches: `https://jenkins-azure.dglearn.online/saml/acs`
   - Check Entity ID: `https://jenkins-azure.dglearn.online/saml/sp`
   - Verify IdP endpoint is accessible
   - Check certificate in federation metadata

3. **Azure AD not returning user attributes**:
   ```
   Azure AD > Applications > Jenkins-Enterprise
   SAML-based Sign-on > User Attributes & Claims
   
   Verify claims configured:
   - mail (user email)
   - displayName (user display name)
   - sAMAccountName (username)
   - memberOf (groups)
   ```

### Problem: SAML attributes not populated

**Symptoms**:
- User logs in but username/email missing
- No group memberships recognized

**Solutions**:
1. **Add missing attribute claim**:
   ```
   Azure AD > App > Attributes & Claims
   Edit > Add new claim
   Name: mail, source: Attribute, value: user.mail
   ```

2. **Configure group claims**:
   ```
   Azure AD > App > Token claims
   Configure group claims for SAML
   Select: "Groups assigned to the application"
   ```

## Firezone Client Issues

### Problem: Client won't authenticate

**Symptoms**:
- "Authentication failed" in client
- No SAML redirect
- "Resource InaccessibleException"

**Investigation**:
```bash
# Check client logs (depends on OS)
# macOS: ~/Library/Logs/Firezone/
# Windows: %APPDATA%/Firezone/logs/
# Linux: ~/.local/share/firezone/logs/

# Verify Firezone server accessible
curl https://<your-firezone-instance>/api/health
```

**Solutions**:
1. **Invalid Firezone URL**:
   - Verify correct server address
   - Check DNS resolution: `nslookup your-firezone-instance.domain`

2. **Certificate trust issues**:
   - Ensure client trusts Firezone server certificate
   - Windows: Install certificate in trust store

3. **SAML configuration mismatch**:
   - Verify client redirect URI matches Firezone SAML config
   - Check Firezone console logs for auth failures

### Problem: DNS intercept not working

**Symptoms**:
- Can reach Jenkins but DNS shows public IP
- .intranet domains not intercepting
- Manual IP access works, DNS doesn't

**Solutions**:
1. **Check DNS resolver**:
   ```bash
   # Force DNS refresh
   # Usually requires client reconnect
   
   # On Linux:
   systemctl restart systemd-resolved
   
   # On macOS:
   sudo dscacheutil -flushcache
   ```

2. **Verify Private DNS zone linked**:
   ```bash
   az network private-dns zone virtual-network-link list \
     -g rg-firezone-jenkins-prod -z dglearn.online
   ```

3. **Check A record**:
   ```bash
   az network private-dns record-set a show \
     -g rg-firezone-jenkins-prod -z dglearn.online -n jenkins-azure
   ```

## Performance Issues

### Problem: Slow Jenkins performance

**Symptoms**:
- Jenkins UI slow to load
- Builds take longer than expected
- High CPU/memory usage

**Investigation**:
```bash
# Check VM resources
az monitor metrics list-definitions -g rg-firezone-jenkins-prod --namespace Microsoft.Compute/virtualMachines

# In VM:
ssh azureuser@<ip>
top
df -h
free -h
```

**Solutions**:
1. **Scale up VM**:
   ```bash
   terraform apply -var='jenkins_vm_size=Standard_D4s_v3'
   ```

2. **Optimize Jenkins**:
   - Increase heap size
   - Enable plugin optimization
   - Clean up old logs: `sudo rm -rf /var/log/jenkins/*`

3. **Check ILB performance**:
   - Verify health probes passing
   - Check backend pool connectivity

## Cost-Related Issues

### Problem: Unexpected high costs

**Investigation**:
```bash
# Check data transfer costs
az monitor metrics list -g rg-firezone-jenkins-prod \
  --resource-type Microsoft.Network/publicIPAddresses

# Check storage costs
az storage account show-usage -n tfstateprodaccount

# Check VM sizing
terraform plan | grep machine_type
```

**Solutions**:
1. **Reduce VM size if over-provisioned**:
   ```bash
   terraform apply -var='jenkins_vm_size=Standard_D2s_v3'
   ```

2. **Enable auto-shutdown** (if applicable)
3. **Review storage retention** (logs, snapshots)

## Emergency Procedures

### Quick VM Restart
```bash
az vm restart -g rg-firezone-jenkins-prod -n vm-firezone-jenkins

# For Firezone Gateway
az vm restart -g rg-firezone-firezone-prod -n vm-firezone-firezone-gateway
```

### Emergency Certificate Replacement
```bash
# Generate new certificate
openssl req -x509 -newkey rsa:4096 -keyout certs/jenkins.key -out certs/jenkins.crt -days 365 -nodes

# Update and redeploy
cd terraform/environments/production
terraform apply -target=module.jenkins_stack
```

### Revert to Previous State
```bash
# If something goes wrong and you have a backup
terraform state pull > current.state.backup
terraform state push previous.state.backup
terraform apply
```

## Getting Help

If issue persists:

1. **Collect diagnostics**:
   ```bash
   terraform show > diagnostics/tf-state.txt
   terraform output > diagnostics/outputs.txt
   az resource list -g rg-firezone-networking-prod > diagnostics/resources.json
   ```

2. **Check logs**:
   - Jenkins: `/var/log/jenkins/jenkins.log`
   - Nginx: `/var/log/nginx/error.log`
   - Firezone Gateway: `journalctl -u firezone-gateway`
   - System: `/var/log/messages`

3. **Contact Support**:
   - Firezone: https://discord.gg/firezone
   - Azure Support: https://portal.azure.com > Help + support
   - Jenkins: https://www.jenkins.io/support/

---

**Last Updated**: March 2026
