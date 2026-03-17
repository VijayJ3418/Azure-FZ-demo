#!/bin/bash

# Generate self-signed certificates for testing
# For production, use proper CA-signed certificates

CERT_DIR="./certificates"
DOMAIN="jenkins-azure.dglearn.online"
COMMON_NAME=$DOMAIN

mkdir -p $CERT_DIR

echo "Generating private key..."
openssl genrsa -out "$CERT_DIR/jenkins.key" 2048

echo "Generating certificate signing request (CSR)..."
openssl req -new \
  -key "$CERT_DIR/jenkins.key" \
  -out "$CERT_DIR/jenkins.csr" \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=$COMMON_NAME"

echo "Generating self-signed certificate (1 year validity)..."
openssl x509 -req -days 365 \
  -in "$CERT_DIR/jenkins.csr" \
  -signkey "$CERT_DIR/jenkins.key" \
  -out "$CERT_DIR/jenkins.crt"

echo "Generating root CA certificate (for full chain)..."
openssl req -new -x509 -days 3650 -nodes \
  -out "$CERT_DIR/root-ca.crt" \
  -keyout "$CERT_DIR/root-ca.key" \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Root-CA"

echo "Creating certificate chain..."
cat "$CERT_DIR/jenkins.crt" "$CERT_DIR/root-ca.crt" > "$CERT_DIR/jenkins-chain.crt"

# Set proper permissions
chmod 600 "$CERT_DIR/jenkins.key"
chmod 644 "$CERT_DIR/jenkins.crt"
chmod 644 "$CERT_DIR/jenkins-chain.crt"

echo "Certificates generated in $CERT_DIR:"
ls -lah $CERT_DIR/

echo ""
echo "NOTE: These are self-signed certificates for testing only."
echo "For production, use certificates from a trusted Certificate Authority."
echo ""
echo "Update terraform.tfvars with:"
echo "certificate_path = \"./certificates/jenkins-chain.crt\""
echo "certificate_key_path = \"./certificates/jenkins.key\""
