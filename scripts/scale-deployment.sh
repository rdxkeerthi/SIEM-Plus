#!/bin/bash
# Scale SIEM-Plus Deployment

NAMESPACE="${NAMESPACE:-siem-plus}"

echo "📈 Scaling SIEM-Plus Deployment"

# Scale detection engine
kubectl scale deployment siem-plus-detect --replicas=10 -n $NAMESPACE

# Scale manager API
kubectl scale deployment siem-plus-manager --replicas=5 -n $NAMESPACE

echo "✅ Scaling complete"
kubectl get pods -n $NAMESPACE
