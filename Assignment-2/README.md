# Assignment 2: AWS Deployment Strategies & Static Asset Offloading

This repository contains full documentation, architectural details, and step-by-step verification procedures for **Assignment 2: Application Deployment Optimization & Strategy Implementation**.

---

## Technical Stack & Infrastructure Overview

| Component | Specification |
| :--- | :--- |
| **AWS Region** | `ap-south-1` (Mumbai) |
| **Operating System** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Runtime & Framework** | OpenJDK 8 (`1.8.0_402`), Apache Tomcat `v9.0.85` |
| **Build Tool & Tooling** | Apache Maven, AWS CLI v2 |
| **AWS Core Services** | EC2, S3, Application Load Balancer (ALB), Auto Scaling Group (ASG), IAM |
| **S3 Deployment Bucket** | `spring3app-rolling-deployment-391912982531-ap-south-1-an` |
| **S3 Static Asset Bucket** | `spring3app-static-assets-391912982531` |
| **IAM Service Roles** | `Bastion-S3-Role` (Full Access), `EC2-S3-ReadOnly-Role` (Read Only) |

---

## Architectural Workflow

```
                   +---------------------------------------+
                   |       User / Web Browser              |
                   +-------------------+-------------------+
                                       |
                   +-------------------v-------------------+
                   |     Application Load Balancer (ALB)   |
                   +-------------------+-------------------+
                                       |
                   +-------------------v-------------------+
                   |      Auto Scaling Group (ASG)         |
                   |   (Private App Subnets - Port 8080)   |
                   +---------+-------------------+---------+
                             |                   |
                             | (Pulls WAR)       | (Fetches Assets)
                             v                   v
            +----------------+----+     +--------+----------------+
            |  S3 Deployment      |     |  S3 Static Asset        |
            |  Artifact Bucket    |     |  Public Bucket          |
            +---------------------+     +-------------------------+
```

---

## Task A: Recreate Deployment + S3 Static Asset Offloading

### 1. Concept & Objective
A **Recreate Deployment** strategy intentionally shuts down all active instances running the old version before launching new instances. This introduces a controlled service window (downtime) but guarantees zero version mismatch or state conflicts during deployment.

Additionally, static assets (`logo.jpeg`, CSS, JS) are offloaded to an S3 bucket configured for public read access to reduce server CPU load and bandwidth consumption on the EC2 instances.

### 2. Implementation Steps

1. **Static Asset Bucket Setup:**
   * Created public S3 bucket: `spring3app-static-assets-391912982531`.
   * Unchecked "Block all public access".
   * Configured public read bucket policy:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "PublicReadGetObject",
           "Effect": "Allow",
           "Principal": "*",
           "Action": "s3:GetObject",
           "Resource": "arn:aws:s3:::spring3app-static-assets-391912982531/*"
         }
       ]
     }
     ```
   * Uploaded static assets (`logo.jpeg`) to S3 using AWS CLI:
     ```bash
     aws s3 cp ~/spring3hibernate/src/main/webapp/static/logo.jpeg s3://spring3app-static-assets-391912982531/static/logo.jpeg
     ```

2. **Golden AMI Creation:**
   * Took an EC2 AMI snapshot (`Spring3App-Golden-AMI-v1`) from a fully configured, healthy application instance running Java 8 and Tomcat 9.

3. **Recreate Execution:**
   * Scaled ASG capacity to `Desired=0, Min=0, Max=0` to terminate all existing instances and simulate intentional deployment downtime.
   * Launched a new application instance directly from `Spring3App-Golden-AMI-v1` into the custom VPC private subnet with the Application Security Group.
   * Registered the instance with the ALB Target Group on port `8080`.

### 3. Verification Criteria
* **Service Outage:** ALB returned `502 Bad Gateway` / `503 Service Unavailable` while capacity was zero.
* **Direct Asset Delivery:** Browsing to the application URL and inspecting the Network tab (`F12`) confirms `logo.jpeg` is served directly from `https://spring3app-static-assets-391912982531.s3.ap-south-1.amazonaws.com/static/logo.jpeg`.

---

## Task B: Rolling Deployment + S3 Artifact Management

### 1. Concept & Objective
A **Rolling Deployment** replaces running application instances incrementally with new ones. By enforcing a **Minimum Healthy Percentage (50%)**, at least one instance remains online and healthy to serve live user traffic, achieving **zero downtime**.

To optimize instance boot times, the project `.war` file is pre-compiled on a Bastion Host and uploaded to S3. EC2 instances pull the pre-built `.war` directly upon startup rather than compiling source code with Maven on every launch.

### 2. Implementation Steps

1. **Artifact Compilation & S3 Offload (Bastion Host):**
   * Built application package using Maven:
     ```bash
     cd ~/spring3hibernate
     mvn clean package -DskipTests -Dcheckstyle.skip=true -Dfindbugs.skip=true -Dpmd.skip=true
     ```
   * Attached IAM Role `Bastion-S3-Role` (`AmazonS3FullAccess`) to Bastion Host.
   * Uploaded compiled artifact to S3:
     ```bash
     aws s3 cp target/Spring3HibernateApp.war s3://spring3app-rolling-deployment-391912982531-ap-south-1-an/Spring3HibernateApp.war
     ```

2. **EC2 IAM Role & Launch Template Configuration:**
   * Created IAM Role `EC2-S3-ReadOnly-Role` with `AmazonS3ReadOnlyAccess`.
   * Created Launch Template (`spring3-app-lt-v2`) attaching `EC2-S3-ReadOnly-Role` and updating User Data to fetch `.war` from S3 directly:
     ```bash
     #!/bin/bash
     exec > /var/log/user-data.log 2>&1
     set -x

     sudo apt-get update -y
     sudo apt-get install -y openjdk-8-jdk wget unzip curl
     sudo update-java-alternatives -s java-1.8.0-openjdk-amd64 || true

     curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
     unzip /tmp/awscliv2.zip -d /tmp
     sudo /tmp/aws/install
     rm -rf /tmp/awscliv2.zip /tmp/aws

     cd /tmp
     wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz
     sudo tar -xzf apache-tomcat-9.0.85.tar.gz -C /opt/
     sudo mv /opt/apache-tomcat-9.0.85 /opt/tomcat9

     sudo useradd -r -s /bin/false tomcat || true
     sudo chown -R tomcat:tomcat /opt/tomcat9

     sudo rm -rf /opt/tomcat9/webapps/ROOT*
     aws s3 cp s3://spring3app-rolling-deployment-391912982531-ap-south-1-an/Spring3HibernateApp.war /opt/tomcat9/webapps/ROOT.war
     sudo chown -R tomcat:tomcat /opt/tomcat9/webapps/

     cat << 'EOF' | sudo tee /etc/systemd/system/tomcat9.service
     [Unit]
     Description=Apache Tomcat 9 Web Application Server
     After=network.target

     [Service]
     Type=forking
     User=tomcat
     Group=tomcat
     Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
     Environment="CATALINA_PID=/opt/tomcat9/temp/tomcat.pid"
     Environment="CATALINA_HOME=/opt/tomcat9"
     Environment="CATALINA_BASE=/opt/tomcat9"
     ExecStart=/opt/tomcat9/bin/startup.sh
     ExecStop=/opt/tomcat9/bin/shutdown.sh

     [Install]
     WantedBy=multi-user.target
     EOF

     sudo systemctl daemon-reload
     sudo systemctl enable tomcat9
     sudo systemctl start tomcat9
     ```

3. **Rolling Update Execution (Instance Refresh):**
   * Updated Auto Scaling Group to use `spring3-app-lt-v2`.
   * Triggered **Instance Refresh** with `MinimumHealthyPercentage = 50%`.

### 3. Verification Criteria
* **Zero Downtime:** Target Group maintained active healthy targets throughout the entire replacement cycle.
* **Boot Time Acceleration:** Instance registration and health check pass duration dropped significantly because Maven source compilation was eliminated.

---

## Comparison: Recreate vs. Rolling Deployments

| Metric | Task A: Recreate Deployment | Task B: Rolling Deployment |
| :--- | :--- | :--- |
| **Downtime** | Yes (Deliberate downtime window) | **Zero Downtime** |
| **Minimum Healthy Capacity** | $0\%$ | $50\%$ |
| **Deployment Speed** | Instantaneous cutover once image boots | Sequential instance replacement |
| **Artifact Delivery** | Packaged directly inside Golden AMI | Pulled dynamically from S3 Bucket |
| **Static Asset Strategy** | Offloaded to Public S3 Bucket | Direct application packaging / local |
| **Ideal Use Case** | Major updates, database schema changes | Daily updates, continuous integration |