# AWS DevOps Assignment — Days 1–5

A hands-on AWS DevOps assignment covering EC2, Nginx, AMI, ALB, Auto Scaling, S3, IAM, Bastion Host, private subnets, NAT Gateway, and path-based routing.

> **Status:** Days 1–5 completed
> **Day 6:** Skipped due to cdn
> **Primary AWS Region:** `ap-south-1`

---

##  Project Overview

This assignment was completed manually through the AWS Management Console to understand how common AWS infrastructure and DevOps components work together.

The work was divided into multiple days:

| Day | Main Topics | Status |
|---|---|---|
| Day 1 | EC2, Nginx, AMIs, ALB, ASG, Scaling, Rollback |
| Day 2 | Git, Nginx Website, S3 Images, IAM Role |
| Day 3 | ASG Self-Healing / Instance Replacement |
| Day 4 | VPC, Bastion, Private EC2, ALB, Target Groups, Path Routing |
| Day 5 | S3, IAM User, IAM Policy, IAM Role |
| Day 6 | CDN / IAM Trust Relationship |

---

# Day 1 — EC2, AMI, ALB and Auto Scaling

## Objective

Build an Nginx-based infrastructure, create multiple AMI versions, place the application behind an Application Load Balancer, and use an Auto Scaling Group.

## Work Completed

### 1. Nginx EC2

Created an Ubuntu EC2 instance and installed Nginx.

Nginx was used to serve a simple web page.

### 2. AMI-1 / Version 1

Created the first AMI from the initial Nginx server.

**AMI-1 = Nginx Version 1**

### 3. Modified the Server

The Nginx server was modified to create a new version.

### 4. AMI-2 / Version 2

Created a second AMI after the modification.

**AMI-2 = Nginx Version 2**

Both AMIs were retained for later use.

### 5. Application Load Balancer

Created an ALB and connected it to an Nginx target group.

### 6. Auto Scaling Group

Created an ASG using the Nginx launch template.

Configured:

- Minimum capacity
- Desired capacity
- Maximum capacity
- Target group attachment
- EC2 health checks
- ELB health checks

### 7. Scaling

Configured scaling behavior and performed load testing to understand how Auto Scaling responds to workload.

### 8. Version Upgrade and Rollback

Tested moving the infrastructure from the older Nginx version to the newer AMI version and verified rollback behavior.

---

# Day 2 — Git + Nginx + S3

## Objective

Host a webpage using Nginx, maintain the website source in Git, and serve images directly from S3.

## Architecture

```text
GitHub Repository
       |
       | git clone
       v
     EC2
       |
       v
     Nginx
       |
       | HTML page
       |
       +----------------------+
                              |
                              v
                         Amazon S3
                         /images/*
```

## Work Completed

### 1. Git Repository

Created a GitHub repository:

`day2-nginx-website`

The website HTML was maintained in the repository.

### 2. EC2 + Nginx

Created an Ubuntu EC2 instance and installed:

- Git
- Nginx

The repository was cloned onto the EC2 instance.

### 3. Website

Created an `index.html` page and hosted it using Nginx.

### 4. S3

Created an S3 bucket and uploaded website images under:

```text
images/
```

The HTML page referenced the S3 object URLs directly.

Therefore, the browser loads:

```text
Website HTML → Nginx
Website Images → S3
```

### 5. IAM Role

An IAM role was attached to the EC2 instance so AWS CLI could access S3 without storing AWS access keys on the server.

The identity was verified using:

```bash
aws sts get-caller-identity
```

No `aws configure` access-key setup was required for the EC2 instance.

---

# Day 3 — Auto Scaling Self-Healing

## Objective

Verify that an Auto Scaling Group can detect an unhealthy instance and replace it automatically.

## Infrastructure

```text
              ALB
               |
          Target Group
               |
        +------+------+
        |             |
      EC2-1         EC2-2
        |
        | Nginx stopped
        v
     Unhealthy
        |
        v
   ASG replaces it
```

## Test Performed

Connected to an ASG-managed Nginx instance and stopped Nginx:

```bash
sudo systemctl stop nginx
```

The target became unhealthy.

The Auto Scaling Group detected the unhealthy instance and launched a replacement instance.

The desired capacity returned to:

```text
2 instances
```

## Result

 ASG self-healing successfully verified.

---

# Day 4 — Private Nginx Servers + Bastion + ALB Path Routing

## Objective

Create a secure two-server Nginx architecture using private subnets, a Bastion Host, an Application Load Balancer, two target groups, and path-based routing.

---

## Architecture

```text
                         YOUR PUBLIC IP
                              |
                 +------------+------------+
                 |                         |
              SSH :22                   HTTP :80
                 |                         |
          +------+-----+             +-----+------+
          |  Bastion   |             |    ALB     |
          |   EC2      |             |    :80     |
          | Public     |             | Public     |
          +------+-----+             +-----+------+
                 |                         |
              SSH :22              Path-Based Routing
                 |                    /          \
                 |                   /            \
                 |              /ninja1*       /ninja2*
                 |                  |              |
          +------+-------+     +----+-----+   +----+-----+
          |              |     | Target   |   | Target   |
          | Private      |     | Group 1  |   | Group 2  |
          | Subnet       |     +----+-----+   +----+-----+
          |              |          |              |
          | Nginx-1      |       Nginx-1         Nginx-2
          +--------------+       Private         Private

                         +----------------------+
                         | NAT Gateway          |
                         | 1 NAT for both       |
                         | private subnets      |
                         +----------------------+
```

---

## 1. VPC

Created a new VPC from scratch using **VPC and more**.

Configuration:

```text
VPC CIDR: 10.0.0.0/16
Availability Zones: 2
Public Subnets: 2
Private Subnets: 2
NAT Gateways: 1
Region: ap-south-1
```

A single NAT Gateway was intentionally used to reduce cost.

### Trade-off

Using one NAT Gateway saves money but does not provide NAT high availability across AZs.

---

## 2. Public Subnets

Two public subnets were created in different Availability Zones.

Used for:

- Bastion Host
- Application Load Balancer
- NAT Gateway

---

## 3. Private Subnets

Two private subnets were created in different Availability Zones.

Used for:

- Nginx Server 1
- Nginx Server 2

Both Nginx instances were launched without public IP addresses.

---

# 4. Security Groups

Three Security Groups were created.

## Bastion Security Group

```text
Inbound:
SSH :22 ← My IP only

Outbound:
All traffic
```

Purpose:

Allow only the user's public IP to SSH into the Bastion.

---

## Nginx Security Group

```text
Inbound:
SSH :22  ← Bastion Security Group
HTTP :80 ← ALB Security Group

Outbound:
All traffic
```

This prevents direct public access to the private Nginx servers.

---

## ALB Security Group

```text
Inbound:
HTTP :80 ← My IP only

Outbound:
All traffic
```

This restricts access to the ALB to the user's public IP.

---

# 5. Bastion Host

Created one Ubuntu EC2 instance in a public subnet.

Purpose:

```text
Laptop
   |
 SSH
   |
Bastion
   |
 SSH
   |
Private Nginx Servers
```

The Bastion provides controlled SSH access to the private servers.

---

# 6. Private Nginx Servers

Created two Ubuntu EC2 instances:

```text
day4-nginx-1 → Private Subnet 1
day4-nginx-2 → Private Subnet 2
```

Both servers:

- Use private IP addresses
- Have no public IP
- Run Nginx
- Can be reached through the Bastion
- Accept HTTP traffic only from the ALB

---

# 7. Nginx Configuration

## Nginx Server 1

Created:

```text
/var/www/html/ninja1/index.html
```

The page identifies itself as:

```text
Ninja 1 - Nginx Server 1
```

Test:

```bash
curl http://localhost/ninja1/
```

---

## Nginx Server 2

Created:

```text
/var/www/html/ninja2/index.html
```

The page identifies itself as:

```text
Ninja 2 - Nginx Server 2
```

Test:

```bash
curl http://localhost/ninja2/
```

---

# 8. Target Groups

Two target groups were created.

## Target Group 1

```text
Name: day4-nginx1-tg
Protocol: HTTP
Port: 80
Target: Nginx Server 1
Health Check Path: /ninja1/
```

## Target Group 2

```text
Name: day4-nginx2-tg
Protocol: HTTP
Port: 80
Target: Nginx Server 2
Health Check Path: /ninja2/
```

Both target groups use **HTTP port 80**.

This is valid because target groups are not separate ALB listeners.

---

# 9. Application Load Balancer

Created one Internet-facing Application Load Balancer.

Configuration:

```text
Name: day4-alb
Scheme: Internet-facing
IP: IPv4
VPC: day4-vpc
Subnets: 2 public subnets
Listener: HTTP :80
Security Group: day4-alb-sg
```

---

# 10. Path-Based Routing

The ALB uses a single HTTP port 80 listener.

The listener contains path-based rules:

```text
/ninja1* → day4-nginx1-tg

/ninja2* → day4-nginx2-tg
```

Therefore:

```text
http://ALB-DNS/ninja1
        ↓
Nginx Server 1
```

and:

```text
http://ALB-DNS/ninja2
        ↓
Nginx Server 2
```

Both routes were successfully tested.

### Important

The two target groups both use:

```text
HTTP :80
```

There is only **one ALB listener on HTTP:80**.

The target groups are selected by the URL path.

---

# Day 4 Security Flow

```text
YOUR IP
   |
   +---- SSH :22 ----> Bastion
   |
   +---- HTTP :80 ---> ALB
                          |
                          +---- HTTP :80 ---> Nginx-1
                          |
                          +---- HTTP :80 ---> Nginx-2

Bastion
   |
   +---- SSH :22 ----> Nginx-1
   |
   +---- SSH :22 ----> Nginx-2
```

This prevents:

- Direct SSH access to private servers
- Direct HTTP access to private servers
- Public access to the Nginx instances

---

# Day 5 — S3 + IAM

## Objective

Use the existing S3 bucket and implement separate `prod` and `nonprod` areas with IAM permissions.

The existing bucket is in:

```text
Region: ap-south-1
```

---

# 1. S3 Folder Structure

Created:

```text
existing-bucket/
├── prod/
└── nonprod/
```

---

# 2. IAM User

Created:

```text
day5-s3-user
```

The user was intentionally created without attaching broad AWS managed permissions.

---

# 3. Non-Production Policy

Created a custom policy:

```text
day5-nonprod-access
```

The policy allows access to:

```text
nonprod/*
```

Allowed actions include:

```text
s3:GetObject
s3:PutObject
s3:DeleteObject
```

and restricted bucket listing using:

```text
s3:ListBucket
```

with a prefix condition for:

```text
nonprod
nonprod/*
```

The policy does **not** grant object access to:

```text
prod/*
```

---

# 4. IAM User Permissions

The policy:

```text
day5-nonprod-access
```

was attached to:

```text
day5-s3-user
```

Result:

```text
nonprod → Allowed
prod    → Not allowed
```

This demonstrates least-privilege access.

---

# 5. IAM Role

Created:

```text
day5-s3-role
```

Trusted entity:

```text
AWS Service / EC2
```

An inline S3 policy was attached to the role for the assignment's role-based S3 access requirement.

---

# IAM Concepts Demonstrated

This day demonstrated the difference between:

### IAM User

Used for a person or long-term identity.

```text
User → Policy → Permissions
```

### IAM Role

Used by AWS services/resources and provides temporary credentials.

```text
EC2 → Assume Role → Temporary Credentials → S3
```

### Least Privilege

The IAM user was not given unrestricted S3 access.

Instead, access was limited to the required:

```text
nonprod/
```

area.

---


#  Final Architecture Summary

The most important architecture created during the assignment was the Day 4 private Nginx environment:

```text
                         Internet
                            |
                     YOUR PUBLIC IP
                       /         \
                    SSH           HTTP
                     |             |
                 Bastion          ALB
                 Public          Public
                                  |
                         HTTP :80 Listener
                           /            \
                    /ninja1*          /ninja2*
                         |                |
                       TG-1             TG-2
                         |                |
                      Nginx-1          Nginx-2
                     Private-1        Private-2
                         \                /
                          \              /
                           NAT Gateway
                                |
                           Internet GW
```

---

