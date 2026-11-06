# Three-Tier MERN Application on AWS --- V2

> **A production-style AWS infrastructure and DevOps portfolio
> project.**
>
> This project demonstrates the design, provisioning, deployment,
> security, monitoring, and operation of a three-tier web application on
> AWS using Terraform, Packer, and GitHub Actions.

## Project overview

The application consists of a React frontend, a Node.js/Express backend,
and MongoDB Atlas. AWS provides networking, compute, traffic management,
secrets, deployment automation, and observability.

V2 focuses on repeatable infrastructure, secure access, controlled
deployments, health verification, monitoring, and a demonstrable
incident-response exercise.

## Target architecture

``` mermaid
flowchart TB
    U[Users] --> DNS[Route 53]
    DNS --> CF[CloudFront and HTTPS]
    CF --> ALB[Public Application Load Balancer]
    ALB --> WEB[Web Auto Scaling Group<br/>Nginx and React]
    WEB --> IALB[Internal Application Load Balancer]
    IALB --> APP[Private App Auto Scaling Group<br/>Node.js and Express]
    APP --> SM[AWS Secrets Manager]
    APP --> DB[(MongoDB Atlas)]

    subgraph AWS[AWS environment]
      subgraph VPC[VPC across two Availability Zones]
        ALB
        WEB
        IALB
        APP
        MON[Private monitoring host<br/>Prometheus and Grafana]
        WEB -. metrics and logs .-> MON
        APP -. metrics and logs .-> MON
        SSM[AWS Systems Manager]
        WEB -. secure management .-> SSM
        APP -. secure management .-> SSM
        MON -. secure management .-> SSM
      end
      NAT[NAT Gateways]
      WEB --> NAT
      APP --> NAT
      STATE[(Encrypted, versioned S3<br/>Terraform state)]
    end

    GH[GitHub Actions] --> OIDC[AWS OIDC role]
    OIDC --> TF[Terraform workflows]
    OIDC --> PACKER[Packer AMI builds]
    TF --> AWS
    PACKER --> AMI[Versioned web and app AMIs]
    AMI --> WEB
    AMI --> APP
    TF --- STATE
```

*This is the intended logical architecture. Exact subnet placement,
security-group rules, routing, and service configuration will be
documented and validated during implementation.*

## Components and responsibilities

  -----------------------------------------------------------------------
  Area                    Technology              Responsibility
  ----------------------- ----------------------- -----------------------
  DNS and edge            Route 53, CloudFront    DNS, HTTPS delivery,
                                                  content distribution

  Public entry            Application Load        Receives and
                          Balancer                distributes web traffic

  Web tier                EC2 Auto Scaling,       Serves the frontend
                          Nginx, React            across Availability
                                                  Zones

  Private entry           Internal Application    Routes requests to
                          Load Balancer           backend instances

  Application tier        EC2 Auto Scaling,       Runs APIs in private
                          Node.js, Express        subnets

  Database                MongoDB Atlas           Persists application
                                                  data

  Secrets                 AWS Secrets Manager     Supplies database
                                                  credentials at runtime

  Infrastructure          Terraform               Provisions and manages
                                                  AWS resources

  Machine images          Packer                  Builds repeatable web
                                                  and app AMIs

  CI/CD                   GitHub Actions, AWS     Automates validation,
                          OIDC                    builds, and deployments

  Instance access         AWS Systems Manager     Secure administration
                                                  without public SSH

  Metrics                 Prometheus, Grafana     Collects and visualises
                                                  metrics

  Logs                    Grafana Alloy, Loki     Collects and
                                                  centralises logs

  Tracing                 OpenTelemetry, where    Adds request-level
                          useful                  visibility

  Terraform state         Encrypted, versioned S3 Protects shared
                          backend                 infrastructure state
                                                  and supports locking
  -----------------------------------------------------------------------

## Engineering principles

-   **Security by design:** private application instances,
    least-privilege IAM, managed secrets, and no public SSH.
-   **Repeatable builds:** AMIs are built from controlled inputs and
    traceable source revisions.
-   **Availability:** web and application capacity is distributed across
    two Availability Zones.
-   **Controlled delivery:** workflows validate changes, protect
    production deployment, verify health, and provide a recovery path.
-   **Observability:** metrics, logs, and useful traces support
    diagnosis---not just dashboards.
-   **Cost awareness:** paid services and redundancy are evaluated
    against their reliability and learning benefits.
-   **Evidence over claims:** screenshots and results will come from
    actual runs and tests.

## Deployment lifecycle

1.  Terraform validates and provisions the AWS foundation.
2.  Packer builds versioned web-tier and application-tier AMIs.
3.  GitHub Actions coordinates validation, image builds, and controlled
    deployment.
4.  Launch Templates and Auto Scaling Groups roll out selected AMIs.
5.  Health checks and deployment verification confirm whether new
    instances serve traffic.
6.  Prometheus, Grafana, Alloy, and Loki provide operational visibility.
7.  A controlled load test demonstrates alerting, investigation,
    remediation, and recovery.

## Planned incident-response demonstration

A controlled load test (for example, using k6) will create measurable
application or instance load.

The intended demonstration:

1.  Record normal baseline metrics and healthy targets.
2.  Generate controlled traffic.
3.  Trigger a genuine alert after a sustained threshold breach.
4.  Investigate using dashboards and centralised logs (and traces if
    implemented).
5.  Document and apply a remediation.
6.  Verify that metrics return to normal and the alert recovers.

Thresholds and test limits will be defined before the exercise.
Screenshots and conclusions will reflect actual results; simulated
success will not be presented as real evidence.

## Initial architecture decisions

  -----------------------------------------------------------------------
  Topic                   V2 direction            Rationale
  ----------------------- ----------------------- -----------------------
  Frontend                Nginx on web EC2        Preserves the existing
                          instances               three-tier design

  Backend                 Node.js on private EC2  Keeps application
                          instances               compute off the public
                                                  internet

  Database                MongoDB Atlas           Avoids an unnecessary
                                                  database migration

  Instance access         Systems Manager         Avoids public SSH

  Infrastructure          Terraform               Makes infrastructure
                                                  reviewable and
                                                  reproducible

  Image creation          Packer                  Separates image
                                                  creation from instance
                                                  launch

  Delivery                GitHub Actions with     Avoids long-lived AWS
                          OIDC                    access keys

  Scaling                 ALBs and Auto Scaling   Supports health-based
                          Groups                  replacement and
                                                  horizontal scaling

  Observability           Prometheus, Grafana,    Provides metrics, logs,
                          Alloy, Loki;            and useful tracing
                          OpenTelemetry where
                          justified

  State                   Encrypted, versioned S3 Supports safer
                          with locking            automated Terraform
                                                  operations
  -----------------------------------------------------------------------

These are design directions, not claims that every component is already
deployed. Final decisions will be recorded as implementation is
verified.

## Security and operational safeguards

-   Rotate any database credential that may have appeared in source code
    or Git history before a fresh deployment.
-   Never commit `.env` files, Terraform state, secret-bearing variable
    files, private keys, or credentials.
-   Separate IAM permissions for web, application, and monitoring
    workloads.
-   Protect Terraform state with encryption, versioning, restricted
    access, and locking.
-   Scope GitHub OIDC trust to the intended repository and deployment
    environment.
-   Protect production deployment with approval and post-deployment
    health verification.
-   Keep monitoring interfaces private unless a separately reviewed
    secure-access design is adopted.
-   Review AWS costs before provisioning and clean up resources after
    lab exercises.

## V2 and V3 scope

**V2** retains the React frontend on Nginx-backed web EC2 instances. It
improves the existing three-tier architecture, automation, security,
scaling, and observability.

**V3** is a separate future iteration that will evaluate hosting the
static React frontend in a private S3 bucket behind CloudFront with
Origin Access Control, while retaining an independently deployed backend
behind an Application Load Balancer. V3 will have its own design and
deployment documentation.

## Project status

**Architecture agreed; implementation and validation are next.**

This repository is being developed in stages. Components above describe
the target design and must not be interpreted as proof that they are
already deployed or fully operational. Implementation status, test
evidence, diagrams, and operational results will be updated as each
stage is completed.

## Skills demonstrated

-   AWS networking and multi-tier architecture
-   Terraform infrastructure design and state management
-   Packer image pipelines
-   EC2, Launch Templates, Auto Scaling Groups, and Load Balancers
-   IAM, OIDC, Secrets Manager, and Systems Manager
-   GitHub Actions CI/CD and deployment safeguards
-   Metrics, logs, alerting, and incident response
-   Cost-aware infrastructure decisions and technical documentation
