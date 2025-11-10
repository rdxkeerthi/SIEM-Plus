#!/bin/bash
# Configure SIEM-Plus Integrations

set -e

echo "🔌 SIEM-Plus Integration Configuration"
echo "======================================"

NAMESPACE="${NAMESPACE:-siem-plus}"
CONFIG_FILE="config/integrations.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Slack Configuration
echo ""
echo "Slack Integration"
echo "================="
read -p "Enable Slack integration? (y/n): " enable_slack
if [ "$enable_slack" = "y" ]; then
    read -p "Slack Webhook URL: " slack_webhook
    kubectl create secret generic slack-config \
        --from-literal=webhook-url="$slack_webhook" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Slack configured"
fi

# JIRA Configuration
echo ""
echo "JIRA Integration"
echo "================"
read -p "Enable JIRA integration? (y/n): " enable_jira
if [ "$enable_jira" = "y" ]; then
    read -p "JIRA URL: " jira_url
    read -p "JIRA Username: " jira_username
    read -sp "JIRA API Token: " jira_token
    echo
    kubectl create secret generic jira-config \
        --from-literal=url="$jira_url" \
        --from-literal=username="$jira_username" \
        --from-literal=api-token="$jira_token" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ JIRA configured"
fi

# Email Configuration
echo ""
echo "Email Integration"
echo "================="
read -p "Enable Email integration? (y/n): " enable_email
if [ "$enable_email" = "y" ]; then
    read -p "SMTP Host: " smtp_host
    read -p "SMTP Port (587): " smtp_port
    smtp_port=${smtp_port:-587}
    read -p "SMTP Username: " smtp_username
    read -sp "SMTP Password: " smtp_password
    echo
    kubectl create secret generic email-config \
        --from-literal=smtp-host="$smtp_host" \
        --from-literal=smtp-port="$smtp_port" \
        --from-literal=smtp-username="$smtp_username" \
        --from-literal=smtp-password="$smtp_password" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Email configured"
fi

# PagerDuty Configuration
echo ""
echo "PagerDuty Integration"
echo "===================="
read -p "Enable PagerDuty integration? (y/n): " enable_pagerduty
if [ "$enable_pagerduty" = "y" ]; then
    read -p "PagerDuty Integration Key: " pagerduty_key
    kubectl create secret generic pagerduty-config \
        --from-literal=integration-key="$pagerduty_key" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ PagerDuty configured"
fi

# Create ConfigMap with integration settings
echo ""
echo "Creating integration ConfigMap..."
kubectl create configmap integration-config \
    --from-file=$CONFIG_FILE \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Integration configuration complete!"
echo ""
echo "To apply changes, restart the SOAR pods:"
echo "kubectl rollout restart deployment/siem-plus-soar -n $NAMESPACE"
