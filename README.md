# Devops Project: video-converter
Converting mp4 videos to mp3 in a microservices architecture.

## Architecture

<p align="center">
  <img src="./Project documentation/ProjectArchitecture.png" width="600" title="Architecture" alt="Architecture">
  </p>

## Deploying a Python-based Microservice Application on AWS EKS

### Introduction

This project is a cloud-native Video-to-Audio Converter application built using a microservices architecture and deployed on Amazon EKS. Microservices : `auth-server`, `converter-module`, `database-server` (PostgreSQL and MongoDB), and `notification-server`. It demonstrates an end-to-end DevOps workflow, including CI/CD with Jenkins, GitOps using Argo CD, containerization with Docker, image management through Amazon ECR

### Prerequisites

Before setting up the project, ensure the following tools are installed and configured:

**Docker**
**Jenkins**
**Helm**
**kubectl**
**AWS CLI**

### High Level Flow of Application Deployment

Follow these steps to deploy your microservice application:

1. **MongoDB and PostgreSQL Setup:** Create databases and enable automatic connections to them.

2. **RabbitMQ Deployment:** Deploy RabbitMQ for message queuing, which is required for the `converter-module`.

3. **Create Queues in RabbitMQ:** Before deploying the `converter-module`, create two queues in RabbitMQ: `mp3` and `video`.

4. **Deploy Microservices:**
   - **auth-server:** Navigate to the `auth-server` manifest folder and apply the configuration.
   - **gateway-server:** Deploy the `gateway-server`.
   - **converter-module:** Deploy the `converter-module`. Make sure to provide your email and password in `converter/manifest/secret.yaml`.
   - **notification-server:** Configure email for notifications and two-factor authentication (2FA).

5. **Application Validation:** Verify the status of all components by running:
   ```bash
   kubectl get all
   ```

6. **Destroying the Infrastructure** 


### Low Level Steps

#### Cluster Creation

1. **Log in to AWS Console:**
   - Access the AWS Management Console with your AWS account credentials.

2. **EKS Cluster IAM Role**

   <p align="center">
  <img src="./Project documentation/ekscluster_role.png" width="600" title="ekscluster_role" alt="ekscluster_role">
  </p>

   - Please attach `AmazonEKS_CNI_Policy` explicitly if it is not attached by default

3. **Create Node Role - AmazonEKSNodeRole**
4. 
   - Your AmazonEKSNodeRole will look like this: 

<p align="center">
  <img src="./Project documentation/node_iam.png" width="600" title="Node_IAM" alt="Node_IAM">
  </p>

4. **Open EKS Dashboard:**
   - Navigate to the Amazon EKS service from the AWS Console dashboard.

5. **Create EKS Cluster:**
   - Click "Create cluster."
   - Choose a name for your cluster.
   - Configure networking settings (VPC, subnets).
   - Choose the `eksCluster` IAM role that was created above
   - Review and create the cluster.

#### Node Group Creation

Add Nodes as per needed (recommended one c7i-flex.large). Added the SG stated below  

#### Adding inbound rules in Security Group of Nodes

**NOTE:** Ensure that all the necessary ports are open in the node security group.

<p align="center">
  <img src="./Project documentation/inbound_rules_sg_.png" width="600" title="Inbound_rules_sg" alt="Inbound_rules_sg">
  </p>

#### Deploying your application on EKS Cluster

1. Clone the code from this repository.

2. Set the cluster context:
   ```
   aws eks update-kubeconfig --name <cluster_name> --region <aws_region>
   ```
3. Just to verify the cluster further for debugging and troubleshooting. Rest of the main flow will be handled by Jenkins Pipeline.

### Argo CD Setup

**On CLI, run these step by step to setup the Argo CD**
```
kubectl create namespace argocd
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo-cd/argo-cd --namespace argocd --set server.service.type=LoadBalancer
```

Also check on CLI - Make sure Argo pods are running
```
kubectl get pods -n argo cd
```
If Argo CD application fails. Check Argocd Pods and services are running safely.  

**Wait for 2-3 minuties, Check in Loadbalancer, ensure Argo CD Loadbalancer is UP.**
```
export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo "Argo CD URL: https://$ARGOCD_SERVER"

export ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: $ARGOCD_PWD"
```
**Open the Link for Argo CD -  Username (admin), Password (check output)**

1. Connect the Repo First
2. Create 4 applications respectively.
3. Ensure all of them are up and running
4. Also on CLI, ensure everything is up for all 4 applications. 
```
kubectl get all
```

### Jenkins Setup

***Here are some essential Jekins Credentials for managing your deployment:***

1. **Github credentials (Username and PAT)**
2. **AWS Credentials (Acces Key and Secret Key)**
3. **Postgres Credentials (User and Password)**
   - First add your own in - Helm_charts/Postgres/values.yaml
   - Then same in Jenkins Creds
4. **Email ID and Password (Check your init.sql)**

***Add Plugin - Pipeline stage view***

Once Done with these. Run the Pipelines. 

### Pipeline 1 - Database Setup

To install MongoDB, set the database username and password in `values.yaml`, then navigate to the MongoDB Helm chart folder and run:

This pipeline automates the deployment of the application's backend infrastructure on the Kubernetes cluster.

**Pipeline Flow:**

- Cleans the Jenkins workspace.
- Clones the latest source code from GitHub.
- Configures AWS CLI using Jenkins credentials.
- Updates the Kubernetes configuration for the Amazon EKS cluster.
- Deploys MongoDB using Helm.
- Deploys PostgreSQL using Helm.
- Copies the init.sql file into the PostgreSQL pod.
- Initializes the PostgreSQL database by executing the SQL script.
- Deploys RabbitMQ using Helm.

Try to Connect to the MongoDB, Postgres instance using:

```
mongosh mongodb://<username>:<pwd>@<nodeip>:30005/mp3s?authSource=admin
```
```
psql 'postgres://<username>:<pwd>@<nodeip>:30003/authdb'
```

Ensure you have created two queues in RabbitMQ named `mp3` and `video`. To create queues, visit `<nodeIp>:30004>` and use default username `guest` and password `guest`

Also check on CLI - Make sure Database pods are running
```
kubectl get all
```

**NOTE:** Ensure that all the necessary ports are open in the node security group.

### Pipeline 2 – Image Creation and Kubernetes Deploy

This pipeline automates the build, containerization, and deployment of all application microservices using Docker, Amazon ECR, GitHub, and Argo CD.

**Pipeline Flow:**

- Clones the latest source code from GitHub.
- Builds Docker images for all four microservices:
  ```
  Auth Service
  Converter Service
  Gateway Service
  Notification Service
  ```
- Creates Amazon ECR repositories automatically if they do not already exist. (Add ACCOUNT_ID parameter to the pipeline)
- Tags and pushes all Docker images to their respective ECR repositories.
- Cleans up local Docker images on the Jenkins server.
- Updates the Kubernetes deployment manifests with the latest image tags.
- Commits and pushes the updated manifest files to GitHub. (Put your mail id)

***Once the updated manifests are pushed, Argo CD automatically detects the changes, synchronizes the Kubernetes cluster, and deploys the latest application version to Amazon EKS.***

### Notification Configuration


For configuring email notifications and two-factor authentication (2FA), follow these steps:

1. Go to your Gmail account and click on your profile.

2. Click on "Manage Your Google Account."

3. Navigate to the "Security" tab on the left side panel.

4. Enable "2-Step Verification."

5. Search for the application-specific passwords. You will find it in the settings.

6. Click on "Other" and provide your name.

7. Click on "Generate" and copy the generated password.

8. Paste this generated password in `notification-service/manifest/secret.yaml` along with your email.

### Pipeline 3 - Final Convert

This pipeline automates the complete workflow of the Video-to-Audio Converter application by interacting with its REST APIs.

**Pipeline Flow:**

- Cleans the Jenkins workspace.
- Clones the latest source code from GitHub.
- Configures AWS CLI and connects to the Amazon EKS cluster.
- Authenticates with the application and retrieves a JWT token.
- Uploads an MP4 video using the Upload API.
- Waits for the video conversion process to complete.
- Pauses the pipeline and prompts the user to enter the generated F-ID received via email.
- Downloads the converted MP3 file using the Download API and the provided F-ID.

***This pipeline validates the complete application flow by automating authentication, video upload, asynchronous conversion, email notification, and MP3 download, ensuring that all microservices work together successfully.***

**We can Upload mp4 directly on Github and Run the pipeline again.
Or We can add from Windows. Run this on Windows CLI
```
scp -i "C:/Users/Viresh/Downloads/yourkey.pem" "D:/Files from ec2/install.sh" ubuntu@’ip-address’:/home/ubuntu/
```

## Destroying the Infrastructure

To clean up the infrastructure, follow these steps:

1. **Delete the Node Group:** Delete the node group associated with your EKS cluster.

2. **Delete the EKS Cluster:** Once the nodes are deleted, you can proceed to delete the EKS cluster itself.
