#!/bin/bash
# Run all SIEM-Plus tests

set -e

echo "🧪 Running SIEM-Plus Test Suite"
echo "================================"
echo ""

FAILED=0

# Test Agent
echo "Testing Agent..."
cd agent
if cargo test; then
    echo "✅ Agent tests passed"
else
    echo "❌ Agent tests failed"
    ((FAILED++))
fi
cd ..

# Test Detection Engine
echo ""
echo "Testing Detection Engine..."
cd detect
if cargo test; then
    echo "✅ Detection Engine tests passed"
else
    echo "❌ Detection Engine tests failed"
    ((FAILED++))
fi
cd ..

# Test Manager API
echo ""
echo "Testing Manager API..."
cd manager
if go test ./...; then
    echo "✅ Manager API tests passed"
else
    echo "❌ Manager API tests failed"
    ((FAILED++))
fi
cd ..

# Test UI
echo ""
echo "Testing UI..."
cd ui
npm install --silent
if npm run build; then
    echo "✅ UI build successful"
else
    echo "❌ UI build failed"
    ((FAILED++))
fi
cd ..

echo ""
echo "================================"
if [ $FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAILED test suite(s) failed"
    exit 1
fi
