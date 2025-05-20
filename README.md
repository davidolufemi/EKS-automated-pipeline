

## Deploying to EKS via Helm (CI/CD Pipeline).
<img width="1130" alt="image" src="https://github.com/user-attachments/assets/30959e24-22c2-465a-975c-eb8cf2b82823" />

This is a fully automated CI/CD pipeline that deploys a change to EKS via Helm, ArgoCD and Argo Rollouts once the `rollout.yaml` file has been updated with a new image. The pipeline can be seen in .github/workflows/deploy.yml. It is a fully event driven architecture. The Dev just has to make a change and the pipeline handles everything else (deployment, container building and deployment, security).

---
##  Infrastructure Provisioning

- **Tool:** Terraform – Terraform was chosen because it is cloud agnostic and follows AWS best practices during environment provisioning.
- **Resources:** EKS, VPC, IAM roles.
- **Security:**
  - The control plane and data plane are deployed in private subnets for enhanced security.
  - IAM roles such as `AWSServiceRoleForAmazonEKSNodegroup` and `AWSServiceRoleForAutoScaling` are provisioned based on AWS best practices.
- **Compute:** I selected EC2-managed node groups for this implementation. While Fargate is also a great option (being serverless and cost-efficient for predictable workloads), I chose EC2 for simplicity and speed during setup. The downside of using EC2 for EKS is we would have to install security patches ourselves going forward.
- The cluster was also deployed in three AZ's for fault tolerance. 


##  Application Development

- **Language:** Java (Spring Boot)
 and assume we would have - **Containerization:** Docker using a multi-stage build to keep images lightweight.
- **Tagging:** Each image is tagged with the Git commit SHA for traceability and also for updating the docker image during pipeline runtime.

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
3. Argo syncs and sees a change in the Helm repo.
4. Blue green strategy begins and it is promoted after all the pods come up and the readiness and liveness probes pass.

<img width="1728" alt="image" src="https://github.com/user-attachments/assets/1039b36d-d959-4c7a-82f4-6f33f7983b02" />

---
##  Rollback Scenario (Testing Failure Recovery)

To test the rollback mechanism:
- I first deployed a working image.
- Then I updated the Helm chart (rollback.yaml) with a fake image tag (non-existent image).
- The image could not be pulled and as a result, liveness and readiness probes failed. Argo Rollouts marked the rollout as degraded.
 <img width="772" alt="image" src="https://github.com/user-attachments/assets/2638f51c-7085-4e5d-a217-54d30a193099" />

- Traffic still continues to go to the previous version since there was no promotion

NB: If we decide to package our Helm chart and deploy manually, we can use the `--atomic` flag.
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






---

##  Blue/Green Deployment with Argo Rollouts Explained Further (Extra Credit)

I implemented a blue/green deployment strategy using Argo Rollouts. We need to install Argo Rollouts using Helm before anything. After that is done, we proceed to our rollout strategy.
We will also set autoPromotionEnabled: true so that Argo Rllouts will promote the new version once it passes the necessary checks and the pod is up.
### Rollout Strategy Config:
```yaml
strategy:
  blueGreen:
    activeService: rollout-bluegreen-active
    previewService: rollout-bluegreen-preview
    autoPromotionEnabled: true
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

- **After automated promotion**:
  ![Post Promotion](https://github.com/user-attachments/assets/308b7efb-0d44-419e-ac20-f073a3afb019)

- **Production endpoint updated**:
  ![Updated Production](https://github.com/user-attachments/assets/1d15cb03-38b0-4384-a2ef-e0f95ca9f754)

---

##  Some Recommendations & Future Enhancements

<img width="1085" alt="image" src="https://github.com/user-attachments/assets/a831113d-0468-414e-895b-747d86ebe712" />

1. **Monitoring & Alerting:** Install Prometheus and Grafana in the cluster to monitor for potential issues based on set metrics.
2. **Secrets Management:** Use AWS KMS to manage secrets.
3. **Web Security:** Use WAF to protect the application from web app vulnerabilities (e.g OWASP 10).
4. **Observability:** CloudWatch to observe environment. We can also save them if we need to be compliant.
5. **Policy Enforcement:** Use OPA/Gatekeeper for compliance purposes.

---

