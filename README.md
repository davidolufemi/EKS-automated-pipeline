##  High-Level Architectural Overview (Scope of Assignment)

![Architecture Diagram](https://github.com/user-attachments/assets/975bed09-efdc-4340-89ab-3525a54a88fa)

---

##  Introduction

This project demonstrates a GitOps-driven deployment of a Spring Boot microservice to an AWS EKS cluster. It leverages Terraform for infrastructure provisioning, ArgoCD for GitOps automation, Helm for packaging, and Argo Rollouts for blue/green deployment. Security scanning is integrated using Trivy and OWASP Dependency-Check.

---

##  Infrastructure Provisioning

- **Tool:** Terraform – used to provision the environment in a cloud-agnostic and modular way.
- **Resources:** EKS, VPC, IAM roles.
- **Security:**
  - The control plane and data plane are deployed in private subnets for enhanced security.
  - IAM roles such as `AWSServiceRoleForAmazonEKSNodegroup` and `AWSServiceRoleForAutoScaling` are provisioned based on AWS best practices.
- **Compute:** I selected EC2-managed node groups for this implementation. While Fargate is also a great option (being serverless and cost-efficient for predictable workloads), EC2 was chosen for simplicity and speed during setup.

---

##  Application Development

- **Language:** Java (Spring Boot)
- **Containerization:** Docker using a multi-stage build to keep images lightweight.
- **Tagging:** Each image is tagged with the Git commit SHA for traceability.

---

##  Security Integration

I intentionally used a vulnerable image to simulate real-world scenarios and implemented a DevSecOps pipeline to catch security issues:

- **Trivy:** Scans OS packages and application libraries on every commit. Results are available in the repository’s security tab.
- **OWASP Dependency-Check:** Analyzes Java dependencies for known CVEs by scanning the `pom.xml`. Results can be viewed in the GitHub Actions tab under the workflow run labeled **Depcheck Report**.
- **Production Note:** In real deployments, I would use distroless base images to significantly reduce the attack surface.

---

##  CI/CD Pipeline & GitOps

### GitHub Actions Workflow
1. Code is pushed to GitHub.
2. Docker image is built and pushed to Docker Hub.
3. Image is tagged with the commit SHA.
4. Helm chart is updated with the new tag.

### ArgoCD GitOps Workflow
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

##  Rollback Scenario (Testing Failure Recovery)

To test the rollback mechanism:
- I first deployed a working image.
- Then I updated the Helm chart with a fake image tag (non-existent image).
- When deployed using this command:

```bash
helm upgrade eksapp ./eksapp-0.1.0.tgz \
  --namespace ekstestatomic \
  --atomic \
  --create-namespace
```

- Helm attempted the upgrade and failed because it couldn’t pull the image. With `--atomic` enabled, Helm automatically rolled back to the previous version.

**Error Screenshot:**

![Rollback Failure](https://github.com/user-attachments/assets/f99b9cae-2a43-4d17-90e1-bc329577a638)

---

##  Blue/Green Deployment with Argo Rollouts (Extra Credit)

I implemented a blue/green deployment strategy using Argo Rollouts.

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

1. **Monitoring & Alerting:** Integrate Prometheus and Grafana to track metrics and define alert thresholds.
2. **Secrets Management:** Use AWS KMS or External Secrets Operator to manage sensitive information securely.
3. **Web Security:** Protect web apps with AWS WAF and rate limiting.
4. **Observability:** Add CloudWatch Container Insights for detailed cluster insights.
5. **Policy Enforcement:** Use OPA/Gatekeeper to enforce compliance and resource constraints.

---

##  Summary

- EKS provisioned with Terraform
- Spring Boot app containerized with Docker and Git-tagged
- CI pipeline builds and pushes to Docker Hub
- Helm chart updated and deployed via ArgoCD
- Rollback tested using Helm’s `--atomic` flag
- Blue/green deployment strategy implemented using Argo Rollouts
- Trivy and OWASP scanning integrated for DevSecOps coverage
