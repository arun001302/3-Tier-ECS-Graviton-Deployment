#!/bin/bash
# =============================================================================
# ECS EC2 Instance User Data Script
# =============================================================================
# Configures the EC2 instance to join the ECS cluster
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configure ECS Agent
# -----------------------------------------------------------------------------

cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_ENI=true
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
EOF

# -----------------------------------------------------------------------------
# Install SSM Agent (for Session Manager access)
# -----------------------------------------------------------------------------
# Note: SSM Agent is pre-installed on Amazon Linux 2023 ECS-optimized AMI
# This ensures it's running and enabled

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# -----------------------------------------------------------------------------
# Install CloudWatch Agent (optional - for custom metrics)
# -----------------------------------------------------------------------------
# Uncomment if you want additional instance-level metrics
#
# yum install -y amazon-cloudwatch-agent
# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#   -a fetch-config \
#   -m ec2 \
#   -s

# -----------------------------------------------------------------------------
# System Optimizations
# -----------------------------------------------------------------------------

# Increase file descriptor limits for containers
cat <<'EOF' >> /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
EOF

# Optimize network settings for containers
cat <<'EOF' >> /etc/sysctl.conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
EOF

sysctl -p

# -----------------------------------------------------------------------------
# Signal successful initialization
# -----------------------------------------------------------------------------

echo "ECS instance initialization complete for cluster: ${cluster_name}"

# =============================================================================
# NOTES:
# =============================================================================
#
# ECS Configuration Options:
#   - ECS_CLUSTER: Name of the cluster to join
#   - ECS_ENABLE_CONTAINER_METADATA: Enables container metadata endpoint
#   - ECS_ENABLE_TASK_IAM_ROLE: Allows tasks to assume IAM roles
#   - ECS_ENABLE_TASK_ENI: Enables awsvpc network mode
#   - ECS_AVAILABLE_LOGGING_DRIVERS: Logging options for containers
#   - ECS_ENABLE_SPOT_INSTANCE_DRAINING: Graceful shutdown on Spot interruption
#
# SSM Agent:
#   - Enables AWS Systems Manager Session Manager
#   - Secure shell access without SSH keys or open ports
#   - Access via: aws ssm start-session --target <instance-id>
#
# System Optimizations:
#   - Increased file descriptors for high-concurrency workloads
#   - Network tuning for better container performance
#
# Troubleshooting:
#   - Check ECS agent logs: journalctl -u ecs
#   - Check cloud-init logs: /var/log/cloud-init-output.log
#   - Verify cluster registration: aws ecs list-container-instances --cluster ${cluster_name}
#
# =============================================================================