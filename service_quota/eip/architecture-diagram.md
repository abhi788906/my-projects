# AWS Elastic IP Monitoring Solution - Architecture Diagram

## System Overview
This solution provides automated monitoring and quota management for AWS Elastic IPs using a serverless architecture with real-time event processing.

## Architecture Components

```mermaid
graph TB
    %% AWS Services
    subgraph "AWS Cloud"
        subgraph "Event Sources"
            EC2[EC2 Service<br/>Elastic IP Operations]
        end
        
        subgraph "Logging & Monitoring"
            CT[CloudTrail<br/>API Call Logging]
            CW[CloudWatch<br/>Logs & Dashboard]
        end
        
        subgraph "Event Processing"
            EB[EventBridge<br/>Event Routing]
            LAMBDA[Lambda Function<br/>Elastic IP Monitor]
            LAYER[Lambda Layer<br/>Dependencies]
        end
        
        subgraph "Storage & Data"
            S3[S3 Bucket<br/>CloudTrail Logs]
            SQS[SQS Queue<br/>Quota Requests]
        end
        
        subgraph "Security & IAM"
            IAM[IAM Role<br/>Lambda Execution]
            POLICY[IAM Policy<br/>Service Quotas Access]
        end
        
        subgraph "External Services"
            SQ[Service Quotas<br/>Quota Management]
            SNS[SNS Topic<br/>Notifications]
        end
    end
    
    %% Data Flow
    EC2 -->|1. AllocateAddress API Call| CT
    CT -->|2. Logs to S3| S3
    CT -->|3. Event to EventBridge| EB
    EB -->|4. Triggers Lambda| LAMBDA
    LAMBDA -->|5. Uses Dependencies| LAYER
    LAMBDA -->|6. Check Current Usage| SQ
    LAMBDA -->|7. Send Notifications| SNS
    LAMBDA -->|8. Logs to CloudWatch| CW
    
    %% IAM Relationships
    IAM -->|9. Assumes Role| LAMBDA
    POLICY -->|10. Grants Permissions| IAM
    
    %% Styling
    classDef awsService fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef dataFlow fill:#D86613,stroke:#232F3E,stroke-width:1px,color:#fff
    classDef security fill:#3F8624,stroke:#232F3E,stroke-width:2px,color:#fff
    
    class EC2,CT,CW,EB,LAMBDA,LAYER,S3,SQS,SQ,SNS awsService
    class IAM,POLICY security
```

## Detailed Component Architecture

```mermaid
graph LR
    subgraph "User Actions"
        USER[User/Application]
    end
    
    subgraph "AWS Infrastructure"
        subgraph "Compute Layer"
            LAMBDA[Lambda Function<br/>Python 3.9<br/>256MB Memory<br/>5min Timeout]
            LAYER[Lambda Layer<br/>boto3, requests<br/>urllib3]
        end
        
        subgraph "Event Layer"
            EB[EventBridge Rule<br/>Pattern: AllocateAddress<br/>Source: CloudTrail]
            CT[CloudTrail<br/>Write-only Events<br/>S3 Logging]
        end
        
        subgraph "Storage Layer"
            S3[S3 Bucket<br/>Versioning Enabled<br/>Encryption at Rest<br/>Lifecycle Policies]
        end
        
        subgraph "Monitoring Layer"
            CW[CloudWatch<br/>Log Groups<br/>Dashboard<br/>Metrics]
        end
        
        subgraph "Security Layer"
            IAM[IAM Role<br/>Lambda Execution<br/>Trust Policy]
            POLICY[Custom Policy<br/>EC2, Service Quotas<br/>SNS Permissions]
        end
    end
    
    subgraph "External APIs"
        SQ[Service Quotas API<br/>GetServiceQuota<br/>RequestServiceQuotaIncrease]
        SNS[SNS Service<br/>Publish Notifications]
    end
    
    %% Data Flow
    USER -->|1. Allocate EIP| EB
    EB -->|2. Event Pattern Match| LAMBDA
    LAMBDA -->|3. Load Dependencies| LAYER
    LAMBDA -->|4. Query Quotas| SQ
    LAMBDA -->|5. Send Alerts| SNS
    LAMBDA -->|6. Log Events| CW
    CT -->|7. API Logs| S3
    
    %% Styling
    classDef userAction fill:#4A90E2,stroke:#2E5BBA,stroke-width:2px,color:#fff
    classDef compute fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef storage fill:#D86613,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef monitoring fill:#3F8624,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef security fill:#8C4A02,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef api fill:#6B7280,stroke:#374151,stroke-width:2px,color:#fff
    
    class USER userAction
    class LAMBDA,LAYER,EB,CT compute
    class S3 storage
    class CW monitoring
    class IAM,POLICY security
    class SQ,SNS api
```

## Data Flow Sequence

```mermaid
sequenceDiagram
    participant User as User/Application
    participant EC2 as EC2 Service
    participant CT as CloudTrail
    participant S3 as S3 Bucket
    participant EB as EventBridge
    participant Lambda as Lambda Function
    participant SQ as Service Quotas
    participant CW as CloudWatch
    participant SNS as SNS Topic
    
    User->>EC2: 1. AllocateAddress API Call
    EC2->>CT: 2. Log API Call
    CT->>S3: 3. Store Logs
    CT->>EB: 4. Send Event
    EB->>Lambda: 5. Trigger Function
    
    Lambda->>Lambda: 6. Load Dependencies
    Lambda->>SQ: 7. GetServiceQuota
    SQ->>Lambda: 8. Return Quota Info
    Lambda->>SQ: 9. Get Current Usage
    SQ->>Lambda: 10. Return Usage Count
    
    Lambda->>Lambda: 11. Calculate Usage %
    alt Usage >= 50%
        Lambda->>SQ: 12. Request Quota Increase
        SQ->>Lambda: 13. Confirm Request
        Lambda->>SNS: 14. Send Alert
    end
    
    Lambda->>CW: 15. Log Results
    Lambda->>EB: 16. Return Response
```

## Infrastructure as Code Structure

```mermaid
graph TD
    subgraph "Terraform Root"
        MAIN[main.tf<br/>Provider & Module Calls]
        CONFIG[config.json<br/>Centralized Configuration]
        OUTPUTS[outputs.tf<br/>Resource Outputs]
    end
    
    subgraph "CloudTrail Module"
        CT_MAIN[main.tf<br/>CloudTrail & S3]
        CT_VARS[variables.tf<br/>Input Variables]
        CT_OUT[outputs.tf<br/>Module Outputs]
    end
    
    subgraph "Lambda Module"
        LAMBDA_MAIN[main.tf<br/>Lambda & IAM]
        LAMBDA_VARS[variables.tf<br/>Input Variables]
        LAMBDA_OUT[outputs.tf<br/>Module Outputs]
    end
    
    subgraph "Deployment"
        DEPLOY[deploy.sh<br/>Automated Deployment]
        BUILD[build_layer.sh<br/>Lambda Layer Build]
    end
    
    MAIN -->|Calls| CT_MAIN
    MAIN -->|Calls| LAMBDA_MAIN
    MAIN -->|Reads| CONFIG
    CT_MAIN -->|Uses| CT_VARS
    LAMBDA_MAIN -->|Uses| LAMBDA_VARS
    DEPLOY -->|Deploys| MAIN
    BUILD -->|Creates| LAMBDA_MAIN
    
    classDef terraform fill:#7C3AED,stroke:#5B21B6,stroke-width:2px,color:#fff
    classDef config fill:#059669,stroke:#047857,stroke-width:2px,color:#fff
    classDef deployment fill:#DC2626,stroke:#B91C1C,stroke-width:2px,color:#fff
    
    class MAIN,CT_MAIN,LAMBDA_MAIN,CT_VARS,LAMBDA_VARS,CT_OUT,LAMBDA_OUT terraform
    class CONFIG config
    class DEPLOY,BUILD deployment
```

## Security & Compliance Features

```mermaid
graph LR
    subgraph "Security Controls"
        ENCRYPTION[Encryption at Rest<br/>S3 SSE-S3<br/>CloudTrail Logs]
        IAM_CONTROLS[IAM Least Privilege<br/>Role-Based Access<br/>Policy Attachments]
        MONITORING[CloudWatch Logs<br/>CloudTrail Audit<br/>S3 Access Logs]
        NETWORK[VPC Endpoints<br/>Private Subnets<br/>Security Groups]
    end
    
    subgraph "Compliance Features"
        TAGS[Resource Tagging<br/>Environment Labels<br/>Cost Center Tags]
        BACKUP[S3 Versioning<br/>Lifecycle Policies<br/>Cross-Region Replication]
        AUDIT[API Call Logging<br/>User Activity Tracking<br/>Change Management]
    end
    
    subgraph "Operational Features"
        SCALING[Auto Scaling<br/>Lambda Concurrency<br/>Event-Driven Processing]
        RELIABILITY[Multi-AZ Deployment<br/>S3 Durability<br/>CloudWatch Alarms]
        MAINTAINABILITY[Infrastructure as Code<br/>Modular Design<br/>Centralized Config]
    end
    
    ENCRYPTION -->|Protects| MONITORING
    IAM_CONTROLS -->|Secures| MONITORING
    TAGS -->|Organizes| MONITORING
    BACKUP -->|Ensures| RELIABILITY
    AUDIT -->|Provides| MONITORING
    SCALING -->|Enables| RELIABILITY
    MAINTAINABILITY -->|Supports| RELIABILITY
```

## Performance & Scaling Characteristics

- **Lambda Function**: 
  - Memory: 256MB (configurable)
  - Timeout: 5 minutes (configurable)
  - Concurrent executions: Auto-scaling
  - Cold start: ~300ms typical
  
- **EventBridge**: 
  - Event processing: <100ms
  - Throughput: 10,000 events/second
  - Reliability: 99.99% SLA
  
- **CloudTrail**: 
  - Log delivery: <15 minutes
  - Storage: S3 with lifecycle policies
  - Retention: Configurable (default: 90 days)
  
- **S3**: 
  - Durability: 99.999999999%
  - Availability: 99.99%
  - Encryption: AES-256

## Cost Optimization Features

- **Lambda**: Pay-per-execution model
- **S3**: Intelligent tiering and lifecycle policies
- **CloudTrail**: Free tier available
- **EventBridge**: Pay-per-event model
- **CloudWatch**: Basic monitoring included

## High Availability Features

- **Multi-AZ**: Automatic failover
- **S3**: 99.99% availability SLA
- **Lambda**: Regional redundancy
- **CloudWatch**: Global service
- **EventBridge**: Regional service with cross-region capabilities
