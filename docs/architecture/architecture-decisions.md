# Architecture Decision Records (ADRs) — V2

## Purpose

This document records the major technical decisions behind the V2 Three-Tier MERN Application on AWS.

Each decision explains the context, selected approach, alternatives considered, and the consequences. These records help developers, reviewers, and technical interviewers understand not just what technologies are used, but why they were selected.

**Status:** Architecture agreed; implementation and validation are ongoing. A decision marked Accepted describes the agreed direction, not necessarily a completed deployment.

---

## ADR-001: Retain a Three-Tier Application Architecture

**Status:** Accepted

**Decision:** Retain React as the frontend, Node.js/Express as the application backend, and MongoDB Atlas as the database.

**Context:** The existing application already follows a three-tier design. V2 focuses on improving infrastructure, automation, security, and observability rather than unnecessarily redesigning the application.

**Alternatives considered:**

- Deploy all components on one EC2 instance.
- Introduce a completely new application architecture.

**Consequences:**

- Each tier can be managed and scaled independently.
- Network boundaries can be established between tiers.
- More infrastructure components require monitoring, maintenance, and cost management.

## ADR-002: Retain MongoDB Atlas

**Status:** Accepted

**Decision:** Continue using MongoDB Atlas as the application's database.

**Context:** The existing application uses Atlas. Migrating databases would introduce additional complexity without directly supporting the primary V2 objectives.

**Alternatives considered:**

- Self-managed MongoDB on EC2.
- Migrating to another managed database platform.

**Consequences:**

- Database administration remains managed by Atlas.
- Credentials, network access, backups, and connection security must be properly configured.

## ADR-003: Use EC2 Auto Scaling Groups for Compute

**Status:** Accepted

**Decision:** Use separate EC2 Auto Scaling Groups for the web and application tiers, distributed across two Availability Zones.

**Context:** This extends the existing infrastructure and demonstrates horizontal scaling, instance replacement, launch templates, and health checks.

**Alternatives considered:**

- Single EC2 instances.
- Amazon ECS or EKS.

**Consequences:**

- Instances can be replaced when unhealthy.
- Capacity can scale according to demand.
- AMI management, health checks, and scaling policies require careful configuration.
- EC2 and associated networking resources introduce ongoing costs.

## ADR-004: Separate Public and Internal Load Balancing

**Status:** Accepted

**Decision:** Use a public Application Load Balancer for incoming web traffic and an internal Application Load Balancer for communication with the backend.

**Context:** The frontend-facing web tier needs to receive public traffic, while backend instances should remain private.

**Alternatives considered:**

- Expose backend instances publicly.
- Route directly from Nginx to individual backend instances.

**Consequences:**

- Backend instances are isolated from direct public access.
- Traffic distribution and health checks are centralised.
- The internal ALB introduces additional cost and must have restricted security-group rules.

## ADR-005: Use Packer for Immutable Machine Images

**Status:** Accepted

**Decision:** Use Packer to build separate web-tier and application-tier AMIs.

**Context:** Installing all dependencies every time an EC2 instance launches can create inconsistent startup times and unpredictable deployments.

**Alternatives considered:**

- Install all software through instance user data.
- Manually create and maintain AMIs.

**Consequences:**

- Machine images become repeatable and traceable.
- Image builds can be automated through GitHub Actions.
- Build dependencies, software versions, and application source revisions must be controlled.

## ADR-006: Use Terraform for Infrastructure as Code

**Status:** Accepted

**Decision:** Continue using Terraform to provision and manage AWS infrastructure.

**Context:** Infrastructure changes should be version-controlled, reviewable, and repeatable.

**Alternatives considered:**

- Manual AWS Console provisioning.
- Other infrastructure-as-code tools.

**Consequences:**

- Infrastructure configuration becomes easier to review and reproduce.
- Terraform state becomes a critical asset that must be protected.
- Provider versions, state migration, and resource lifecycle require careful management.

## ADR-007: Use S3 for Remote Terraform State

**Status:** Proposed

**Decision:** Move Terraform state to an encrypted, versioned S3 backend with state locking.

**Context:** Local state is unsuitable for reliable automated infrastructure workflows and creates risks around collaboration, loss, and exposure.

**Alternatives considered:**

- Continue using local state.
- Use a managed Terraform platform.

**Consequences:**

- State is centrally stored and protected.
- Access can be restricted through IAM.
- Migration must preserve existing state and backups.
- No migration should occur until the current state has been safely inventoried and reconciled.

## ADR-008: Use AWS Systems Manager Instead of Public SSH

**Status:** Accepted

**Decision:** Use Systems Manager Session Manager for instance administration.

**Context:** Public SSH access increases the attack surface and creates additional key-management responsibilities.

**Alternatives considered:**

- Public SSH access.
- A bastion host.

**Consequences:**

- Instances do not need publicly accessible SSH.
- Access can be managed through IAM.
- SSM Agent, instance permissions, and network connectivity must be configured correctly.

## ADR-009: Separate IAM Roles by Workload

**Status:** Accepted design direction

**Decision:** Use separate IAM roles for web, application, and monitoring instances.

**Context:** Sharing one IAM role across all workloads can give a compromised instance unnecessary access to other services.

**Alternatives considered:**

- One shared IAM role for all EC2 instances.

**Consequences:**

- Permissions can be limited to the requirements of each workload.
- The application role can access only the required database secret.
- Additional IAM configuration and policy management are required.

## ADR-010: Use AWS Secrets Manager for Application Credentials

**Status:** Accepted design direction

**Decision:** Store the MongoDB connection credential in AWS Secrets Manager and retrieve it at runtime.

**Context:** Credentials should not be embedded in source code, machine images, or committed environment files.

**Alternatives considered:**

- Hardcoded credentials.
- Credentials embedded in AMIs.
- Plaintext environment files committed to Git.

**Consequences:**

- Credentials are managed separately from application code.
- Application instances need narrowly scoped permission to retrieve the secret.
- Terraform state and deployment logs must also be protected.
- Any credential potentially exposed in source code or Git history must be rotated.

## ADR-011: Use GitHub Actions with AWS OIDC

**Status:** Accepted

**Decision:** Authenticate GitHub Actions to AWS using OpenID Connect rather than long-lived AWS access keys.

**Context:** CI/CD needs AWS permissions for AMI builds and infrastructure deployment.

**Alternatives considered:**

- Store long-lived AWS IAM access keys in GitHub Secrets.

**Consequences:**

- No permanent AWS access keys are required for the workflow.
- IAM trust must be restricted to the intended repository and deployment environment.
- Production deployment should require approval and verify deployment health.

## ADR-012: Use Prometheus and Grafana for Monitoring

**Status:** Accepted design direction

**Decision:** Use Prometheus to collect metrics and Grafana to visualise metrics and alerts.

**Context:** The project should demonstrate operational visibility and an actual monitoring and incident-response workflow.

**Alternatives considered:**

- Depend only on basic AWS CloudWatch metrics.
- Use a fully managed observability platform.

**Consequences:**

- Infrastructure metrics can be collected and visualised centrally.
- Metric discovery, retention, storage, alert rules, and access control must be configured.
- A single monitoring instance is a potential single point of failure and should be documented as a portfolio-lab limitation unless improved.

## ADR-013: Use Grafana Alloy and Loki for Centralised Logging

**Status:** Planned

**Decision:** Evaluate Grafana Alloy for log collection and Loki for centralised log storage.

**Context:** Metrics identify abnormal behaviour, while logs help investigate the underlying cause.

**Alternatives considered:**

- Inspect logs manually on individual EC2 instances.
- Use a managed AWS logging service.

**Consequences:**

- Logs can be investigated centrally.
- Storage, retention, labels, access control, and sensitive-data filtering must be planned.
- Credentials must never be written into logs.

## ADR-014: Introduce OpenTelemetry Where Useful

**Status:** Planned

**Decision:** Add OpenTelemetry instrumentation where it provides useful application request tracing.

**Context:** Traces can help explain how requests move through application components and where delays or failures occur.

**Alternatives considered:**

- Rely exclusively on metrics and logs.

**Consequences:**

- Request-level visibility can improve troubleshooting.
- Instrumentation introduces additional complexity.
- A suitable trace backend must be selected before claiming end-to-end tracing capability.

## ADR-015: Keep V2 and V3 Architectures Separate

**Status:** Accepted

**Decision:** Retain the Nginx-backed EC2 frontend for V2. Evaluate S3 and CloudFront Origin Access Control for the frontend in a separate V3 iteration.

**Context:** Combining a frontend hosting redesign with the V2 infrastructure and observability improvements would make implementation and validation harder.

**Alternatives considered:**

- Move the frontend to S3 and CloudFront immediately.

**Consequences:**

- V2 remains focused on improving the existing architecture.
- V3 can independently evaluate static frontend hosting, caching, and separate frontend deployment workflows.

---

## Implementation Review Checklist

Before describing V2 as production-ready, verify the following:

- [ ] Existing Terraform state and backups have been inventoried.
- [ ] Remote state migration has been planned and safely tested.
- [ ] Potentially exposed MongoDB credentials have been rotated.
- [ ] IAM roles are separated and permissions restricted.
- [ ] Packer builds are repeatable and version-controlled.
- [ ] GitHub OIDC trust is restricted to the intended repository.
- [ ] Production deployment includes approval and health verification.
- [ ] Load balancer and Auto Scaling health checks have been tested.
- [ ] Monitoring interfaces are protected.
- [ ] Metrics, logs, and alerts have been tested.
- [ ] A controlled incident has been demonstrated and documented.
- [ ] Documentation reflects actual implementation and test evidence.

## Final Note

These records are living engineering documentation. Decisions should be updated when implementation reveals new constraints, and completed capabilities should only be claimed after they have been tested and verified.
