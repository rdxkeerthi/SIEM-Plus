#!/bin/bash
# SIEM-Plus Kubernetes Deployment Script

set -e

echo "🚀 SIEM-Plus Kubernetes Deployment"
echo "===================================="

# Configuration
NAMESPACE="${NAMESPACE:-siem-plus}"
RELEASE_NAME="${RELEASE_NAME:-siem-plus}"
HELM_CHART="./infra/helm-charts/siem-plus"
VALUES_FILE="${VALUES_FILE:-values-prod.yaml}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm not found. Please install Helm 3.${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please configure kubectl.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Create namespace
echo -e "${YELLOW}Creating namespace: ${NAMESPACE}${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
echo -e "${YELLOW}Creating secrets...${NC}"

# Database secret
read -sp "Enter PostgreSQL password: " DB_PASSWORD
echo
kubectl create secret generic siem-plus-secrets \
  --from-literal=database-url="postgres://siem_admin:${DB_PASSWORD}@siem-plus-postgresql:5432/siem_plus?sslmode=disable" \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# JWT secret
JWT_SECRET=$(openssl rand -base64 32)
kubectl create secret generic siem-plus-jwt \
  --from-literal=jwt-secret="${JWT_SECRET}" \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Secrets created${NC}"

# Add Helm repositories for dependencies
echo -e "${YELLOW}Adding Helm repositories...${NC}"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

echo -e "${GREEN}✅ Helm repositories updated${NC}"

# Install/Upgrade SIEM-Plus
echo -e "${YELLOW}Deploying SIEM-Plus...${NC}"

if [ -f "${VALUES_FILE}" ]; then
    echo "Using values file: ${VALUES_FILE}"
    helm upgrade --install ${RELEASE_NAME} ${HELM_CHART} \
      --namespace=${NAMESPACE} \
      --values=${VALUES_FILE} \
      --wait \
      --timeout=10m
else
    echo "Using default values"
    helm upgrade --install ${RELEASE_NAME} ${HELM_CHART} \
      --namespace=${NAMESPACE} \
      --wait \
      --timeout=10m
fi

echo -e "${GREEN}✅ SIEM-Plus deployed successfully${NC}"

# Wait for pods to be ready
echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=${RELEASE_NAME} \
  --namespace=${NAMESPACE} \
  --timeout=5m

# Display deployment info
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SIEM-Plus Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get service endpoints
echo "Service Endpoints:"
echo "==================="

# Get LoadBalancer IP/Hostname
LB_IP=$(kubectl get svc ${RELEASE_NAME}-ui -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
LB_HOSTNAME=$(kubectl get svc ${RELEASE_NAME}-ui -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$LB_IP" ]; then
    echo -e "UI: ${GREEN}http://${LB_IP}${NC}"
elif [ -n "$LB_HOSTNAME" ]; then
    echo -e "UI: ${GREEN}http://${LB_HOSTNAME}${NC}"
else
    echo "UI: Pending... (run 'kubectl get svc -n ${NAMESPACE}' to check)"
fi

# Get Ingress
INGRESS_HOST=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)
if [ -n "$INGRESS_HOST" ]; then
    echo -e "Ingress: ${GREEN}https://${INGRESS_HOST}${NC}"
fi

echo ""
echo "Useful Commands:"
echo "================"
echo "View pods:       kubectl get pods -n ${NAMESPACE}"
echo "View services:   kubectl get svc -n ${NAMESPACE}"
echo "View logs:       kubectl logs -f deployment/${RELEASE_NAME}-manager -n ${NAMESPACE}"
echo "Port forward:    kubectl port-forward svc/${RELEASE_NAME}-ui 8080:80 -n ${NAMESPACE}"
echo ""
echo "Default Credentials:"
echo "===================="
echo "Email:    admin@siem-plus.io"
echo "Password: admin123"
echo ""
echo -e "${YELLOW}⚠️  Remember to change default credentials!${NC}"
