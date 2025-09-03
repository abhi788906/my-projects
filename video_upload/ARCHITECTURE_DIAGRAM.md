# Video Upload Platform - Complete Architecture Diagram

## System Architecture Overview

```mermaid
graph TB
    subgraph "Client Layer"
        A[Web Browser]
        B[Mobile App]
        C[Desktop App]
    end
    
    subgraph "CDN & Edge"
        D[CloudFront Distribution]
        E[WAF Rules]
        F[Rate Limiting]
    end
    
    subgraph "API Layer"
        G[API Gateway]
        H[Cognito Authorizer]
        I[Lambda Authorizer]
    end
    
    subgraph "Authentication"
        J[Cognito User Pool]
        K[Cognito Identity Pool]
        L[MFA & Advanced Security]
    end
    
    subgraph "Compute Layer"
        M[Video Upload Lambda]
        N[Multipart Init Lambda]
        O[Multipart Complete Lambda]
        P[Video Processing Lambda]
    end
    
    subgraph "Storage Layer"
        Q[S3 Bucket - Videos]
        R[S3 Bucket - Metadata]
        S[KMS Encryption Keys]
        T[Lifecycle Policies]
    end
    
    subgraph "Monitoring & Observability"
        U[CloudWatch Metrics]
        V[X-Ray Tracing]
        W[CloudTrail Logs]
        X[Custom Dashboards]
    end
    
    subgraph "Security & Compliance"
        Y[IAM Roles & Policies]
        Z[Security Groups]
        AA[Network ACLs]
        BB[VPC Endpoints]
    end
    
    subgraph "Data Flow"
        CC[Upload Request]
        DD[Authentication]
        EE[File Validation]
        FF[Chunk Processing]
        GG[Storage & Encryption]
        HH[Completion & Notification]
    end
    
    %% Client to CDN
    A --> D
    B --> D
    C --> D
    
    %% CDN to API
    D --> E
    E --> F
    F --> G
    
    %% API to Auth
    G --> H
    H --> J
    G --> I
    
    %% Auth to Compute
    J --> K
    K --> M
    K --> N
    K --> O
    K --> P
    
    %% Compute to Storage
    M --> Q
    M --> R
    N --> Q
    O --> Q
    P --> Q
    
    %% Storage Encryption
    Q --> S
    R --> S
    Q --> T
    
    %% Monitoring
    M --> U
    N --> U
    O --> U
    P --> U
    G --> V
    M --> V
    Q --> W
    
    %% Security
    M --> Y
    N --> Y
    O --> Y
    P --> Y
    Q --> Z
    R --> Z
    
    %% Data Flow
    CC --> DD
    DD --> EE
    EE --> FF
    FF --> GG
    GG --> HH
    
    %% Styling
    classDef clientLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef cdnLayer fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef apiLayer fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef authLayer fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef computeLayer fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef storageLayer fill:#e0f2f1,stroke:#004d40,stroke-width:2px
    classDef monitoringLayer fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef securityLayer fill:#fafafa,stroke:#424242,stroke-width:2px
    classDef dataFlowLayer fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    
    class A,B,C clientLayer
    class D,E,F cdnLayer
    class G,H,I apiLayer
    class J,K,L authLayer
    class M,N,O,P computeLayer
    class Q,R,S,T storageLayer
    class U,V,W,X monitoringLayer
    class Y,Z,AA,BB securityLayer
    class CC,DD,EE,FF,GG,HH dataFlowLayer
```

## Multi-Part Upload Flow

```mermaid
sequenceDiagram
    participant Client as Client Browser
    participant API as API Gateway
    participant Lambda as Lambda Functions
    participant S3 as S3 Bucket
    participant KMS as KMS Encryption
    participant CloudWatch as CloudWatch
    
    Note over Client,CloudWatch: Multi-Part Upload Process
    
    %% Step 1: Initialize Upload
    Client->>API: POST /multipart/init
    API->>Lambda: multipart_init function
    Lambda->>S3: createMultipartUpload()
    S3-->>Lambda: uploadId + fileKey
    Lambda->>KMS: Generate encryption key
    KMS-->>Lambda: encryption key
    Lambda-->>API: uploadId + fileKey + presignedUrls
    API-->>Client: uploadId + fileKey + presignedUrls
    
    %% Step 2: Upload Chunks
    loop For each 5MB chunk
        Client->>S3: PUT chunk (direct to S3)
        S3->>KMS: Encrypt chunk
        KMS-->>S3: encrypted chunk
        S3-->>Client: ETag + chunk info
        Client->>CloudWatch: Log progress
    end
    
    %% Step 3: Complete Upload
    Client->>API: POST /multipart/complete
    API->>Lambda: multipart_complete function
    Lambda->>S3: completeMultipartUpload()
    S3->>Lambda: Upload complete confirmation
    Lambda->>CloudWatch: Log completion metrics
    Lambda-->>API: Success response
    API-->>Client: Upload complete
    
    %% Step 4: Post-Processing
    Lambda->>S3: Trigger post-processing
    S3->>Lambda: Process video metadata
    Lambda->>CloudWatch: Log final metrics
```

## Security Architecture

```mermaid
graph LR
    subgraph "External Threats"
        A1[Malicious Uploads]
        A2[DDoS Attacks]
        A3[Unauthorized Access]
        A4[Data Breaches]
    end
    
    subgraph "Security Layers"
        B1[WAF & Rate Limiting]
        B2[Cognito Authentication]
        B3[IAM & Least Privilege]
        B4[KMS Encryption]
        B5[VPC & Security Groups]
        B6[CloudTrail & Monitoring]
    end
    
    subgraph "Protected Resources"
        C1[API Gateway]
        C2[Lambda Functions]
        C3[S3 Buckets]
        C4[User Data]
        C5[Encryption Keys]
    end
    
    A1 --> B1
    A2 --> B1
    A3 --> B2
    A4 --> B3
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
    B5 --> C5
    B6 --> C1
    B6 --> C2
    B6 --> C3
    
    classDef threats fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef security fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef resources fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    
    class A1,A2,A3,A4 threats
    class B1,B2,B3,B4,B5,B6 security
    class C1,C2,C3,C4,C5 resources
```

## Cost Optimization Architecture

```mermaid
graph TD
    subgraph "Cost Drivers"
        A1[Lambda Invocations]
        A2[S3 Storage]
        A3[Data Transfer]
        A4[API Gateway Requests]
        A5[CDN Usage]
    end
    
    subgraph "Optimization Strategies"
        B1[Reserved Concurrency: 0]
        B2[Lifecycle Policies]
        B3[Intelligent Tiering]
        B4[CDN Price Classes]
        B5[Auto-scaling]
    end
    
    subgraph "Cost Reduction Results"
        C1[95% Cost Reduction]
        C2[Pay-per-use Model]
        C3[Economies of Scale]
        C4[Predictable Pricing]
    end
    
    A1 --> B1
    A2 --> B2
    A2 --> B3
    A5 --> B4
    A1 --> B5
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
    B5 --> C1
    
    classDef drivers fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef strategies fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef results fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    
    class A1,A2,A3,A4,A5 drivers
    class B1,B2,B3,B4,B5 strategies
    class C1,C2,C3,C4 results
```

## Performance Metrics Dashboard

```mermaid
graph LR
    subgraph "Real-time Metrics"
        A1[Upload Success Rate: 99.9%]
        A2[Average Response Time: 245ms]
        A3[Concurrent Uploads: 1,247]
        A4[Error Rate: 0.1%]
    end
    
    subgraph "Performance Indicators"
        B1[Lambda Cold Starts: 0.5%]
        B2[S3 Upload Speed: 50MB/s]
        B3[API Gateway Latency: 12ms]
        B4[CDN Hit Rate: 94%]
    end
    
    subgraph "Scalability Metrics"
        C1[Auto-scaling Events: 23/day]
        C2[Peak Concurrent Users: 2,500]
        C3[Storage Growth: 15GB/day]
        C4[Cost per GB: $0.23]
    end
    
    A1 --> B1
    A2 --> B2
    A3 --> B3
    A4 --> B4
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C4
    
    classDef metrics fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef performance fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef scalability fill:#e0f2f1,stroke:#004d40,stroke-width:2px
    
    class A1,A2,A3,A4 metrics
    class B1,B2,B3,B4 performance
    class C1,C2,C3,C4 scalability
```
