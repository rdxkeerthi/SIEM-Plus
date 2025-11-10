#!/bin/bash
# Import Sigma Rules from Repository

set -e

echo "📥 SIEM-Plus Sigma Rule Importer"
echo "================================"

NAMESPACE="${NAMESPACE:-siem-plus}"
SIGMA_REPO="https://github.com/SigmaHQ/sigma.git"
TEMP_DIR="/tmp/sigma-rules"
RULES_DIR="marketplace/rules"

# Clone Sigma repository
echo "Cloning Sigma rule repository..."
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

git clone --depth 1 "$SIGMA_REPO" "$TEMP_DIR"

echo "✅ Sigma repository cloned"

# Categories to import
declare -a CATEGORIES=(
    "windows/process_creation"
    "windows/powershell"
    "linux/process_creation"
    "network"
    "web"
)

# Import rules
echo ""
echo "Importing rules..."
IMPORTED_COUNT=0

for category in "${CATEGORIES[@]}"; do
    SOURCE_PATH="$TEMP_DIR/rules/$category"
    
    if [ -d "$SOURCE_PATH" ]; then
        echo "Processing category: $category"
        
        # Create destination directory
        DEST_PATH="$RULES_DIR/$category"
        mkdir -p "$DEST_PATH"
        
        # Copy rules
        find "$SOURCE_PATH" -name "*.yml" -type f | while read rule_file; do
            filename=$(basename "$rule_file")
            cp "$rule_file" "$DEST_PATH/$filename"
            ((IMPORTED_COUNT++))
            echo "  ✓ Imported: $filename"
        done
    fi
done

echo ""
echo "✅ Imported $IMPORTED_COUNT Sigma rules"

# Convert rules to SIEM-Plus format
echo ""
echo "Converting rules to SIEM-Plus format..."

python3 << 'EOF'
import os
import yaml
import glob

rules_dir = "marketplace/rules"
converted_count = 0

for rule_file in glob.glob(f"{rules_dir}/**/*.yml", recursive=True):
    try:
        with open(rule_file, 'r') as f:
            rule = yaml.safe_load(f)
        
        # Convert to SIEM-Plus format
        siem_rule = {
            'id': rule.get('id', ''),
            'name': rule.get('title', ''),
            'description': rule.get('description', ''),
            'severity': rule.get('level', 'medium'),
            'enabled': True,
            'detection': {
                'selection': [],
                'condition': rule.get('detection', {}).get('condition', '')
            },
            'tags': rule.get('tags', []),
            'mitre_attack': []
        }
        
        # Extract MITRE ATT&CK tags
        for tag in rule.get('tags', []):
            if tag.startswith('attack.t'):
                technique = tag.replace('attack.', '').upper()
                siem_rule['mitre_attack'].append(technique)
        
        # Save converted rule
        with open(rule_file, 'w') as f:
            yaml.dump(siem_rule, f, default_flow_style=False)
        
        converted_count += 1
    except Exception as e:
        print(f"Error converting {rule_file}: {e}")

print(f"✅ Converted {converted_count} rules")
EOF

# Upload rules to Kubernetes
echo ""
echo "Uploading rules to Kubernetes..."

# Create ConfigMap with rules
kubectl create configmap sigma-rules \
    --from-file=$RULES_DIR \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Rules uploaded to Kubernetes"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "========================================="
echo "Sigma Rule Import Complete!"
echo "========================================="
echo ""
echo "Imported rules are available in: $RULES_DIR"
echo ""
echo "To reload rules in the detection engine:"
echo "kubectl rollout restart deployment/siem-plus-detect -n $NAMESPACE"
