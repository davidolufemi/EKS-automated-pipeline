                                               High Level Architectural Diagram
<img width="1231" alt="image" src="https://github.com/user-attachments/assets/02e8fb12-b950-4215-a0fb-0439d9d8256f" />


                                                        Introduction.
This project follows the git-ops approach. it is an event-driven architecture in the sense that the user only has to update the image tag and it is automatically pulled from Dockerhub once Git sees the cnange has been made. It involves a microservice that is running on an EKS cluster, utilizing tools like Terraform, ArgoCD, Argo Rollouts, Trivy and OWASP dependency check (for security), and so on.

                                                        Strategy.
To build the cloud environment (EKS, VPC and other infrastructure provisioning), we will utilize Terraform. We will be using official Terraform modules because they ensure best practices are followed when building our infrastructure. The terraform code can be found in Terraform/code folder. The code is seperated into three core files - main.tf (which contains the resource that is being provisioned), variables.tf (which contains the variables) and the terraform.tfvars which contins the values to our variables. Doing it this way allows for reusability amongst teams. The control and data plane layer *where our app lives) will both be deployed in private subnets for security porposes. We will also use EC2 compute type for our nodes, and have them managed by AWS (managed node group). Fargate is also an good option since it's serverless, but we will go with EC2 just because its quicker to set up.

Once we build our environment, we can begin to focus on the code that will run - in other words, our application. We will be using a simple spring application. This application will display a line of text. The next step after writing our application is containerization. We will be using Docker as our preferred tool. 
For our Dockerfile, we will utilize a multi-stage build strategy. This will enable us to have smaller image sizes. We are intentionally using a vulnerable image for this project. This leads me to the next stage - security. We will be following a DevSecOps approach. For our container scannong, we will utilize Trivy, which will run whenever there is a new commit. The vulnerabilities found in the Docker image can be seen in the security section or tab of this repo. Ideally in production, we will usilize distroless images, which will greatly reduce our attack surface. We also utilized OWASP dependency check, which scans our pom.xml file/libraries for known CVE's. The result of this scan can be seen in the Actions tab, click on any of the workflows and the result will be at the bottom of the page (Depcheck Report). Another tool that could have been used here is Snyk, which does both and manages it better. 

<img width="1722" alt="image" src="https://github.com/user-attachments/assets/3c6edf49-cf4c-4fca-8dbe-2e1e68b3f546" />

Once the Docker build is complete, the image is pushed to the Docker Hub as defined in the workflow file. Each image tag is the hash (SHA) of the commit. We do this for traceability purposes.  

Since our EKS cluster is up, we can begin to deploy resources into it. We will utilize Helm to deploy our Spring application. We have two options here:
1. Package our helm chart and deploy it directly everytime we make a change to the image (using helm install).
_use helm atomic_
seperate the helm repo and have a runner apply the chart using kubectl --atomic







3. Use ArgoCD to monitor our repo for any image changes in the helm chart and have it pull the image.

This is a more GitOps autmated workflow.

Summary so far: 
1. Provision infrastructure using Terraform (EKS, VPC, etc.) with official modules.
2. Build a Spring Boot app that displays a line of text.
3. Containerize the app using Docker with a multi-stage build.
4. Scan the image and dependencies using Trivy and OWASP Dependency-Check.
5. Push Docker image to Docker Hub, tagged with the commit SHA.
6. Deploy the app to EKS using Helm with ArgoCD.
7. Use ArgoCD to enable GitOps and auto-sync on image/manifest changes.

A typical helm chart consists of some of the following files.
1. values.yaml: Provides default values for the variables used in template files.
2. Chart.yaml: Metadata about the chart. 
3. Deployment.yaml: Defines our deployment (container)
4. Service.yaml: Defines how we want to expose traffic to the app (Nodeport, LoadBalancer, ClusterIP)

This along with the other files in the template folder will be pushed to our Git repository. We will then have Argo CD monitor the repo folder for any changes in the manifest. We need to define an Argo application file do define which repo we want to monitoe. Below is how our Argo application looks like:

![image](https://github.com/user-attachments/assets/41fc75d4-c411-4502-a0b6-72f027ca4585)

The Source block defines our Git URL and where in the repo Argo should monitor for any changes so that it can sync our cluster to match what is present. 

So far, here is the workflow:
1. A developer makes a change and pushes it to Github
2. The pipeline runs and a docker image is built and pushed to Docker Hub.
3. The developer then updates the imaage tag in the values.yaml file of the Helm chart.
4. Argo CD will then pull the image from the repo (checks every 3 minutes) and the new code becomes live.



This is fine, but using ArgoCD alone does not have us to have a deployment model (canary or blue-green). For this, we will use Argo Rollouts to define a strategy. 




