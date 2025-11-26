graph TD
    %% Styles
    classDef public fill:#f9f,stroke:#333,stroke-width:2px;
    classDef private fill:#9f9,stroke:#333,stroke-width:2px;
    classDef data fill:#99f,stroke:#333,stroke-width:2px;
    classDef aws fill:#fdf,stroke:#d69,stroke-width:1px,stroke-dasharray: 5 5;

    subgraph "AWS Cloud (vpc-123abc45)"
        style "AWS Cloud (vpc-123abc45)" fill:#fafafa,stroke:#ccc,stroke-width:1px

        %% --- Public Tier ---
        subgraph "Public Subnets"
            style "Public Subnets" fill:#fff0f5,stroke:#f9f,stroke-width:2px
            ALB[Application Load Balancer]:::public
            IGW[Internet Gateway]:::public
        end

        %% --- Application Tier ---
        subgraph "Private Subnets"
            style "Private Subnets" fill:#f0fff0,stroke:#9f9,stroke-width:2px
            
            subgraph "EC2 - Graviton (ARM64)"
                WP_Container[WordPress Container]:::private
                DockerAgent[ECS Agent / Docker Daemon]:::aws
            end
            
            NAT[NAT Gateway]:::private
        end

        %% --- Data Tier ---
        subgraph "Database Subnets"
            style "Database Subnets" fill:#f0f8ff,stroke:#99f,stroke-width:2px
            RDS[(RDS MySQL Database)]:::data
        end
    end

    %% External Users
    User((Web User)) --> IGW
    
    %% Traffic Flow
    IGW -->|HTTP/HTTPS| ALB
    ALB -->|Private Traffic (Bridge Mode)| WP_Container
    
    %% App to Data Flow
    WP_Container -->|Port 3306| RDS
    
    %% Outbound Internet Flow
    WP_Container -.->|Outbound for Updates/ECR| NAT
    NAT -.-> IGW
