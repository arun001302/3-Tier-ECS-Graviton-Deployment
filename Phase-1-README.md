# ☁️ AWS Graviton 3-Tier Web App on EKS

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

## 📖 Project Overview
This project demonstrates a production-grade **3-Tier Architecture** deployed on **AWS EKS (Elastic Kubernetes Service)**. Unlike standard x86 deployments, this infrastructure is fully optimized for cost and performance using **AWS Graviton (ARM64)** processors for both the Compute and Database tiers.

The architecture ensures high availability through Multi-AZ deployment and strict security using private subnets and distinct Security Group chaining.

### 🏗️ Architecture
* **Tier 1 (Public):** Network Load Balancer (NLB) handling ingress traffic.
* **Tier 2 (Private):** Python Flask Application running on EKS Nodes (**Graviton t4g.medium**).
* **Tier 3 (Private):** Amazon RDS MySQL Database (**Graviton db.t4g.micro**) in Multi-AZ configuration.



---

## 🛠️ Tech Stack
* **Cloud Provider:** AWS (US-East-1)
* **Orchestration:** Amazon EKS v1.31
* **Compute:** AWS Graviton2 (ARM64 Architecture)
* **Database:** Amazon RDS for MySQL (8.0)
* **Containerization:** Docker (Multi-Arch Build)
* **Language:** Python 3.9 (Flask)
* **Infrastructure:** Custom VPC, Private Subnets, NAT Gateways, Route 53

---

## 🚀 Key Features
* **Cross-Platform Build:** Application containerized specifically for ARM64 architecture using `docker buildx`.
* **Security First:** Database and Application nodes are isolated in Private Subnets with no direct internet access.
* **Cost Optimization:** Utilized Graviton instances (`t4g`) offering up to 40% better price-performance over comparable x86 instances.
* **High Availability:** Database deployed with a standby replica in a secondary Availability Zone.

---

## 📸 Proof of Concept
**Visitor Counter JSON Response:**
The application connects to the private RDS instance, increments a visitor counter, and returns the serving container ID and underlying CPU architecture.

```json
{
  "architecture": "aarch64",
  "message": "Hello from AWS Graviton!",
  "served_by_container": "eks-graviton-app-567bd866fb-nclq4",
  "visit_count": 1
}
