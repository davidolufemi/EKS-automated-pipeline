                                            High Level Architectural Diagram
<img width="1500" alt="image" src="https://github.com/user-attachments/assets/578b2426-85b0-4e84-8fae-73a728ddb37b" />

                                                        Introduction.
This project follows the git-ops approach. it is a semi event-driven architecture in the sense that the user only has to update the image tag and it is automatically pulled from Dockerhub once Git sees the cnange has been made. It involves a microservice that is running on an EKS cluster, utilizing tools like Terraform, ArgoCD, Argo Rollouts, Trivy and OWASP dependency check (for security), and so on.

                                                        Strategy.
To build the cloud environment (EKS, VPC and other infrastructure provisioning), we will utilize Terraform. We will be using official Terraform modules because they ensure best practices are followed when building our infrastructure. The terraform code can be found in Terraform/code folder. The code is seperated into three core files - main.tf (which contains the resource that is being provisioned), variables.tf (which contains the variables) and the terraform.tfvars which contins the values to our variables. Doing it this way allows for reusability amongst teams.


Once we build our environment, we can begin to focus on the code that will run - in other words, our application. We will be using a simple spring application. 

