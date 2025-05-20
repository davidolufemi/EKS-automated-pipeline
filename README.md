For this project, I split the tasks into two:
a. Fully automated pipeline that deploys an application to EKS via Helm
b. GitOps driven development via ArgoCD, Argo and Helm.

## Part 1: Deploying to EKS via Helm (CI/CD Pipeline).
<img width="1069" alt="image" src="https://github.com/user-attachments/assets/cb1a4616-b125-45c5-b988-7b5cc6dc4378" />

This portion is a fully automated CI/CD pipeline that deploys a change to EKS via Helm once the values.yaml file has been updated with a new image. The pipeline can be seen in .github/workflows/deploy.yml. It is a fully event driven architecture in that the image has to be updated and pushed to the repo, and the pipeline handles everything else (deployment, testing, security).

---
##  Infrastructure Provisioning

- **Tool:** Terraform – Terraform was chosen because it is cloud agnostic and follows AWS best practices during environment provisioning.
- **Resources:** EKS, VPC, IAM roles.
- **Security:**
  - The control plane and data plane are deployed in private subnets for enhanced security.
  - IAM roles such as `AWSServiceRoleForAmazonEKSNodegroup` and `AWSServiceRoleForAutoScaling` are provisioned based on AWS best practices.
- **Compute:** I selected EC2-managed node groups for this implementation. While Fargate is also a great option (being serverless and cost-efficient for predictable workloads), EC2 was chosen for simplicity and speed during setup. The downside is we would have to install security patches ourselves.


##  Application Development

- **Language:** Java (Spring Boot)
- **Containerization:** Docker using a multi-stage build to keep images lightweight.
- **Tagging:** Each image is tagged with the Git commit SHA for traceability.

---

##  Security Integration

I intentionally used a vulnerable image to simulate real-world scenarios and implemented a DevSecOps pipeline to catch security issues:

- **Trivy:** Scans the container for vulnerabilities and gives the associated CVE. Results are in this repository’s security tab.
- **OWASP Dependency-Check:** Analyzes Java dependencies for known CVEs by scanning the `pom.xml`. Results can be viewed in the GitHub Actions tab under the workflow run labeled **Depcheck Report**.
- **Production Note:** In real deployments, I would use distroless images to reduce the attack surface. 

---

##  CI/CD Pipeline & GitOps

### GitHub Actions Workflow
1. Developer updates image tag and pushes code to GitHub
2. Pipeline runs and connects to AWS account, installs necessary software (kubectl, helm, etc)
3. Pipeline deploys Helm chart.

<img width="1210" alt="image" src="https://github.com/user-attachments/assets/4a140655-948f-4a10-8693-bba53ec9b7f7" />

---
##  Rollback Scenario (Testing Failure Recovery)

To test the rollback mechanism:
- I first deployed a working image.
- Then I updated the Helm chart with a fake image tag (non-existent image).
- When deployed using this command:

```bash
  helm upgrade --install $RELEASE_NAME ./eksapp \
      --namespace $NAMESPACE \
      --create-namespace \
      --set image.repository=davidayo97/us-mobile-hello \
      --set image.tag=${{ github.sha }} \
      --wait \
      --atomic \
      --timeout 10m0s
```

- Helm attempted the upgrade and failed because it couldn’t pull the image. With `--atomic` enabled, Helm automatically rolled back to the previous version. It failed after 5 minutes which is the default timer.

**Error Screenshot:**

<img width="1338" alt="image" src="https://github.com/user-attachments/assets/111b782b-3f84-4466-ad14-23a2d81f3c72" />





##  Part 2: High-Level Architectural Overview for task 2

![Architecture Diagram](https://github.com/user-attachments/assets/975bed09-efdc-4340-89ab-3525a54a88fa)

---

##  Introduction

This project shows a GitOps-driven deployment of a Spring Boot microservice to an AWS EKS cluster. It uses Terraform to provision the infrastructure, ArgoCD for GitOps automation and monitoring and Argo Rollouts for blue/green deployment. Security is integrated using Trivy and OWASP Dependency-Check. 
---

##  Infrastructure Provisioning

- **Tool:** Terraform – Terraform was chosen because it is cloud agnostic and follows AWS best practices during environment provisioning.
- **Resources:** EKS, VPC, IAM roles.
- **Security:**
  - The control plane and data plane are deployed in private subnets for enhanced security.
  - IAM roles such as `AWSServiceRoleForAmazonEKSNodegroup` and `AWSServiceRoleForAutoScaling` are provisioned based on AWS best practices.
- **Compute:** I selected EC2-managed node groups for this implementation. While Fargate is also a great option (being serverless and cost-efficient for predictable workloads), EC2 was chosen for simplicity and speed during setup. The downside is we would have to install security patches ourselves.

---

##  Application Development

- **Language:** Java (Spring Boot)
- **Containerization:** Docker using a multi-stage build to keep images lightweight.
- **Tagging:** Each image is tagged with the Git commit SHA for traceability.

---

##  Security Integration

I intentionally used a vulnerable image to simulate real-world scenarios and implemented a DevSecOps pipeline to catch security issues:

- **Trivy:** Scans the container for vulnerabilities and gives the associated CVE. Results are in this repository’s security tab.
- **OWASP Dependency-Check:** Analyzes Java dependencies for known CVEs by scanning the `pom.xml`. Results can be viewed in the GitHub Actions tab under the workflow run labeled **Depcheck Report**.
- **Production Note:** In real deployments, I would use distroless images to reduce the attack surface. 

---

##  CI/CD Pipeline & GitOps

### GitHub Actions Workflow
1. Code is pushed to GitHub.
2. Docker image is built and pushed to Docker Hub.
3. Image is tagged with the commit SHA.
4. Dev updates Helm chart (values.yaml) with the new tag.
5. Pipeline deploys Helm chart.

### ArgoCD GitOps Workflow
- Install ArgoCD using Helm.
- ArgoCD monitors the `values.yaml` for changes (e.g., image tag updates).
- Automatically syncs the changes to the EKS cluster.

**ArgoCD Sync Config:**
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```
ArgoCD syncs every 3 minutes by default. Manual syncs can also be triggered via the UI.

---





---

##  Blue/Green Deployment with Argo Rollouts (Extra Credit)

I implemented a blue/green deployment strategy using Argo Rollouts. We need to install Argo Rollouts using Helm before anything. After that is done, we proceed to our rollout strategy.

### Rollout Strategy Config:
```yaml
strategy:
  blueGreen:
    activeService: rollout-bluegreen-active
    previewService: rollout-bluegreen-preview
    autoPromotionEnabled: false
```

Two services were created:
- `rollout-bluegreen-active` (production)
- `rollout-bluegreen-preview` (staging/green)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-active
spec:
  type: LoadBalancer
  selector:
    app: rollout-bluegreen
  ports:
    - port: 80
      targetPort: 8080
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-preview
spec:
  type: LoadBalancer
  selector:
    app: rollout-bluegreen
  ports:
    - port: 80
      targetPort: 8080
```

In a real-world setup, the preview environment would not be exposed via LoadBalancer. For demo purposes, both services are publicly accessible.

I demonstrated the blue/green deployment with two app versions:
- Blue: “Welcome to EKS version 2!!”
- Green: “Hi US Mobile team!”

After updating the image tag in `rollout.yaml`, Argo Rollouts initiated the new deployment.

### Screenshots:
- **Paused before promotion**:
  ![Paused Deployment](https://github.com/user-attachments/assets/c93a89cc-4bb3-4888-880f-89ea7ef2f9bf)

- **New version (green)**:
  ![Preview Version](https://github.com/user-attachments/assets/2a7393a0-8d1a-41d8-b99e-472b3ad2ae56)

- **Old version (still live)**:
  ![Old Version](https://github.com/user-attachments/assets/4a941912-90df-47d0-8790-df09c2340224)

- **After manual promotion**:
  ![Post Promotion](https://github.com/user-attachments/assets/308b7efb-0d44-419e-ac20-f073a3afb019)

- **Production endpoint updated**:
  ![Updated Production](https://github.com/user-attachments/assets/1d15cb03-38b0-4384-a2ef-e0f95ca9f754)

---

##  Recommendations & Future Enhancements

![Improvement Diagram](https://github.com/user-attachments/assets/dbde79e9-da1c-4efc-acbf-6fa1863d6731)

1. **Monitoring & Alerting:** Install Prometheus and Grafana in the cluster to monitor for potential issues based on set metrics.
2. **Secrets Management:** Use AWS KMS to manage secrets.
3. **Web Security:** Use WAF to protect the application from web app vulnerabilities (e.g OWASP 10).
4. **Observability:** CloudWatch to observe environment. We can also save them if we need to be compliant.
5. **Policy Enforcement:** Use OPA/Gatekeeper for compliance purposes.

---

##  Summary of extra credit

- Provisioned cloud infrastructure with Teraform
- Containerized Spring app.
- Pipeline builds and pushes to Docker Hub
- Helm chart is updated and deployed via ArgoCD
- Rollback testing was performed using Helm’s `--atomic` flag
- Blue/green deployment strategy was implemented using Argo Rollouts
- Trivy and OWASP dependency check were integrated for DevSecOps and security
