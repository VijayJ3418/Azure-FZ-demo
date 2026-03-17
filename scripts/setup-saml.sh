#!/bin/bash

# Script to configure SAML 2.0 authentication for Jenkins and Firezone
# This script provides guidance for setting up SSO with Azure AD/Entra ID

echo "=========================================="
echo "SAML 2.0 Authentication Setup Guide"
echo "=========================================="
echo ""

echo "1. JENKINS SAML CONFIGURATION"
echo "==============================="
echo ""
echo "Prerequisites:"
echo "  - Jenkins installed and running on HTTPS"
echo "  - SAML plugin: https://plugins.jenkins.io/saml/"
echo ""
echo "Installation Steps:"
echo "  1. Go to Jenkins Dashboard > Manage Jenkins > Manage Plugins"
echo "  2. Search for 'SAML' and install the SAML plugin"
echo "  3. Restart Jenkins"
echo ""
echo "Configuration:"
echo "  1. Go to Jenkins Dashboard > Manage Jenkins > Configure System"
echo "  2. Scroll to 'SAML' section"
echo "  3. Configure the following:"
echo ""
cat > /tmp/jenkins-saml-config.md <<'EOF'
### Jenkins SAML Configuration

- **Binding**: Redirect
- **IdP Metadata Configuration**: 
  - URL: https://login.microsoftonline.com/common/federationmetadata/2007-06/federationmetadata.xml
  OR
  - Upload federation metadata XML from Azure AD

- **IdP Entity ID**: https://sts.windows.net/{TENANT_ID}/
- **IdP SSO Target URL**: https://login.microsoftonline.com/{TENANT_ID}/saml2
- **IdP SLO Target URL**: https://login.microsoftonline.com/{TENANT_ID}/saml2/logout

- **Service Provider (SP) Details**:
  - Entity ID: https://jenkins-azure.dglearn.online/saml/sp
  - Assertion Consumer Service URL: https://jenkins-azure.dglearn.online/saml/acs
  - Single Logout Service URL: https://jenkins-azure.dglearn.online/saml/logo

- **Attribute Mappings**:
  - Display Name Attribute: displayName
  - Email Attribute: mail
  - Username Attribute: sAMAccountName or userPrincipalName
  - Group Attribute: memberOf

- **Advanced**:
  - Enable Encrypted Assertion: Yes
  - Enable Signed Response: Yes
  - Request Certificates**: Use Jenkins generated certificate

EOF

cat /tmp/jenkins-saml-config.md

echo ""
echo "2. AZURE AD / ENTRA ID CONFIGURATION"
echo "====================================="
echo ""
echo "Steps to configure Azure AD for SAML SSO:"
echo ""
cat > /tmp/azure-saml-config.md <<'EOF'
### Azure AD / Entra ID Setup

1. **Create Enterprise Application**:
   - Go to Azure Portal > Azure Active Directory > Enterprise Applications
   - Click "New Application"
   - Create custom SAML application for Jenkins
   - Name: "Jenkins-Firezone"

2. **Configure Single Sign-On (SAML)**:
   - Set Application ID (Entity ID): https://jenkins-azure.dglearn.online/saml/sp
   - Set Reply URL (ACS): https://jenkins-azure.dglearn.online/saml/acs
   - Set Sign On URL: https://jenkins-azure.dglearn.online
   - Set Logout URL: https://jenkins-azure.dglearn.online/saml/logo

3. **Configure Attributes & Claims**:
   - mail -> mail (user's email)
   - displayName -> displayName
   - sAMAccountName -> sAMAccountName (username)
   - memberOf -> groups (user groups)

4. **Download Federation Metadata**:
   - Go to "SAML Signing Certificate"
   - Copy "Federation Metadata XML URL"
   - Use this URL in Jenkins SAML plugin configuration

5. **Configure Users & Groups**:
   - Go to "Users and Groups"
   - Assign users/groups who should have Jenkins access

6. **User Provisioning (Optional)**:
   - Configure automatic provisioning if using Azure AD provisioning

EOF

cat /tmp/azure-saml-config.md

echo ""
echo "3. FIREZONE SAML CONFIGURATION"
echo "==============================="
echo ""
echo "In Firezone Admin Console:"
echo ""
cat > /tmp/firezone-saml-config.md <<'EOF'
### Firezone SAML Setup

1. **Create Resources**:
   - Go to Firezone Admin Console > Resources
   - Create new Resource:
     - Name: Jenkins
     - URL: https://jenkins-azure.dglearn.online
     - Icon: Jenkins logo (optional)

2. **Configure SAML Authentication**:
   - Go to Settings > Authentication
   - Enable SAML 2.0
   - Provide Identity Provider Details:
     - Issuer (Entity ID): https://sts.windows.net/{TENANT_ID}/
     - SSO URL: https://login.microsoftonline.com/{TENANT_ID}/saml2
     - Certificate: Download from Azure AD federation metadata
     - NameID Format: emailAddress or persistent

3. **Configure Resource Access**:
   - Go to Resources > Jenkins
   - Set Access Control > SAML Groups
   - Add AD groups that should have access
   - Example: Jenkins-Admins, Jenkins-Users

4. **Test SAML Integration**:
   - Logout from Firezone
   - Click "Sign in with SAML"
   - Should redirect to Azure AD login
   - Check user attributes are properly mapped

EOF

cat /tmp/firezone-saml-config.md

echo ""
echo "4. CLIENT CONFIGURATION"
echo "======================="
echo ""
echo "After setup, users with Firezone client will:"
echo "  1. Install Firezone client on their machine"
echo "  2. Click 'Sign In'"
echo "  3. Get redirected to Azure AD SAML login"
echo "  4. After auth, client receives .intranet domain intercept rules"
echo "  5. Traffic to jenkins-azure.dglearn.online routes through Firezone Gateway"
echo ""

echo "5. TROUBLESHOOTING"
echo "=================="
echo ""
cat > /tmp/troubleshooting.md <<'EOF'
**Common Issues**:

1. **SAML Login Fails**
   - Check Azure AD federation metadata URL is accessible
   - Verify ACS URL matches in Jenkins and Azure AD
   - Check Jenkins SAML plugin logs: /var/log/jenkins/jenkins.log

2. **User Groups Not Mapping**
   - Ensure memberOf attribute is included in SAML response
   - Verify group names in Firezone match Azure AD group names
   - Check Azure AD app has "Groups" claim configured

3. **Certificate Errors**
   - Generate valid SSL certificates from trusted CA
   - Convert between certificate formats if needed: 
     openssl x509 -inform DER -in cert.cer -out cert.pem

4. **Connection Issues Between Firezone and Jenkins**
   - Check NSG rules allow port 443 from Firezone subnet
   - Verify firewall rules in Jenkins VM allow traffic
   - Check internal LB health probe configuration

EOF

cat /tmp/troubleshooting.md

echo ""
echo "Configuration files saved to /tmp/ for reference"
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
