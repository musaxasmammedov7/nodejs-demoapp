#!/bin/bash
###############################################################################
# Cost Estimation Script
# Runs Terragrunt plan with Infracost for cost estimation
###############################################################################

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Cost Estimation for: ${ENVIRONMENT}"
echo "============================================"

# Check if infracost is installed
if ! command -v infracost &> /dev/null; then
    echo "Infracost is not installed."
    echo "Install it with:"
    echo "  brew install infracost"
    echo ""
    echo "Or use the Docker version:"
    echo "  docker run --rm -it infracost/infracost breakdown --path ."
    exit 1
fi

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    echo "Terragrunt is not installed."
    echo "Install it with:"
    echo "  brew install terragrunt"
    exit 1
fi

# Run terragrunt plan and capture the plan file
echo ""
echo "Running Terragrunt plan for ${ENVIRONMENT}..."
echo ""

cd "${SCRIPT_DIR}/${ENVIRONMENT}"

# Run plan for each module in dependency order
for module in vpc app/sg app/alb app/ec2 app/cloudwatch; do
    echo "Planning ${module}..."
    cd "${SCRIPT_DIR}/${ENVIRONMENT}/${module}"
    terragrunt plan -out=tfplan 2>/dev/null || true
    cd "${SCRIPT_DIR}/${ENVIRONMENT}"
done

# Run infracost breakdown on the generated plans
echo ""
echo "============================================"
echo "  Infracost Cost Breakdown"
echo "============================================"

cd "${SCRIPT_DIR}"
infracost breakdown --config infracost.yml

echo ""
echo "============================================"
echo "  Cost estimation complete!"
echo "============================================"
