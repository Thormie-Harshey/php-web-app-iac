
# Automated Three-Tier Web Application Deployment with Terraform and GitLab CICD
![Architecture Diagram](https://github.com/Thormie-Harshey/php-web-app-iac/blob/main/image/threetier-terraform.jpg)
---

## Project Goal
This project is a fully automated deployment of a scalable WordPress website using Infrastructure as Code (IaC). Terraform would be leveraged to provision the three-tier architecture on AWS, with GitLab CI/CD orchestrating the automation pipeline. Also, OIDC (OpenID Connect) authentication would be implemented, allowing the GitLab runner to assume AWS IAM roles with short-lived credentials.

---

##  Architecture & Technologies Used

| Category        | Tools / Services |
|----------------|------------------|
| **Cloud** | AWS |
| **Networking** | VPC, Subnets (Public & Private), Route Tables, NAT Gateway |
| **Load Balancing** | Application Load Balancer (ALB) |
| **Compute** | EC2 (Auto Scaling Group, Launch Templates) |
| **Database** | Amazon RDS for MySQL |
| **Storage** | Amazon EFS |
| **Automation** | User Data Scripts |
| **Security** | Security Groups, EC2 Instance Connect Endpoint (ICE), AWS Certificate Manager (ACM) |
| **Web Server** | Apache (httpd) |
| **App Stack** | PHP, WordPress |
| **Domain** | GoDaddy |
| **Infrastructure as Code (IaC)** | Terraform |
| **CI/CD Platform** | GitLab  CI/CD |
| **Identity Management** | AWS Identity and Access Management (IAM) (for roles, policies, instance profiles) |
| **State Management** | Amazon S3 (for Terraform remote backend), Amazon DynamoDB (for state locking) |
| **Secret Management** | AWS Secrets Manager |
| **Containerization (Implicit)** | Docker (GitLab CI/CD uses Docker out-of-the-box for runners) |
---

##  Implementation & Workflow

### 
### **1. Infrastructure Provisioning (Modular Terraform Setup)**
We will leverage custom-built modules to streamline our deployment process. By doing so, we can organize our resources into logical units, enhancing reusability and maintainability. Our infrastructure will be structured around the following modules:
VPC, ALB, RDS, EFS, EC2, ASG, Security, IAM. 
There would also be a  centralized `main.tf` for orchestration using module references as well as terraform.tfvars, variables.tf, output.tf, terraform.tf.
    

### **2. CI/CD Pipeline**
The GitLab CI/CD pipeline automates the entire infrastructure lifecycle, leveraging OpenID Connect (OIDC) for secure, token-based authentication with AWS. In it, we have:
-  **`.gitlab-ci.yml`** which includes stages like: **`create_backend_resources, terraform_format, init, validate, plan`** and **`apply`**
-  **`before_script`** installs Terraform and sets up the environment

-   **`create-backend-resources`**: Which is a Manual Stage that creates the S3 bucket and DynamoDB table for Terraform backend and state locking. This stage is crucial for initial setup and ensures the backend resources exist before Terraform operations.
-   **`init`**: Runs **`terraform init`** to initialize the working directory, download provider plugins, and configure the S3 backend with DynamoDB locking. The artifacts **(`.terraform/`, `.terraform.lock.hcl`)** are preserved for later stages.
-   **`validate`**: Executes **`terraform fmt -check -recursive`** and **`terraform validate`** to ensure configuration syntax and best practices.
-   **`plan`**: Runs **`terraform plan -out="planfile"`** to generate an execution plan. The **`planfile`** and **`.terraform.lock.hcl`** are saved as artifacts for subsequent stages.
-   **`apply`**: Also a Manual Stage which gives the luxury of first having to go through the plan file, ensuring that the right resources are provisioned before executing. Then, it executes **`terraform apply -input=false "planfile"`** to apply the planned changes to AWS. This stage depends on the **`plan`** and **`init`** stages, ensuring the correct **`planfile`** and lock file are available.
-   **`destroy`**: Manual Stage as well. It runs **`terraform destroy --auto-approve`** to tear down the entire infrastructure. This stage also relies on the **`init`** artifacts.    

### **3. OIDC Configuration**

To configure OpenID Connect, (OIDC), IAM role has to first of all be configured in AWS with a trust policy for GitLab and setting the appropriate audience and subject claim. 

-   The `before_script` section in jobs performs an `aws sts assume-role-with-web-identity` call using the OIDC token to get temporary credentials for the GitLab runner.
-   The `id_tokens` block with `GITLAB_OIDC_TOKEN` and `aud: <https://gitlab.com`> is configured to allow GitLab to obtain short-lived AWS credentials via OIDC. This eliminates the need to store static AWS access keys in GitLab variables, significantly improving security.
---

### **EC2 and ASG User Data Script Explanation**
We have two userdata scripts. The ec2 userdata script and the Auto Scaling group userdata script. Its purpose is to provision a fresh EC2 instance with WordPress, connect it to RDS and EFS, and configure Apache/PHP/MySQL.

The table below explains more about what the two userdata scripts execute.
| EC2 User Data Script (Initial Setup)        | ASG User Data Script (Scale-Out Bootstrap) |
|----------------|------------------|
| Purpose: Provision first WordPress instance with full setup. | Purpose: Prepare new Auto Scaling Group nodes to serve existing WordPress site. |
| Set Variables: AWS region, DB identifier. | Set Variable: AWS region. |
| Retrieve DB Details: Get RDS secret ARN, DB password, DB name/user/host from metadata. | No DB retrieval – DB already configured via shared setup. |
| Retrieve EFS Details: Get EFS file system ID, construct DNS name. | Same – get EFS file system ID, construct DNS name. |
| Install Software: Apache (httpd), PHP + extensions, Git, MySQL client. | Same – Apache, PHP + extensions, Git, MySQL client. |
| Mount EFS: Mount to: `/var/www/html` | Mount to: `/var/www/html` (via: /etc/fstab for persistence). |
| Download & Configure WordPress: Fetch WordPress, move files to `/var/www/html`, update `wp-config.php`with DB credentials. | Skip WordPress install – files already on EFS. |
| Permissions: Set Apache/EC2 user ownership, apply file/dir permissions. | Same – set Apache ownership and permissions. |
| Restart Services: Apache & PHP-FPM. | Same – restart Apache & PHP-FPM. |
---
The first script (EC2) was a **setup script** for a single server that was responsible for the initial configuration. It downloaded WordPress, found the database secrets, and wrote the main configuration file.
The second script (ASG) is a **bootstrap script** for an Auto Scaling Group. Its job is not to set up the website from scratch, but rather to quickly prepare a new server to become part of an existing team. It just needs to install the necessary software (Apache, PHP, MySQL client) and then connect to the shared WordPress files on EFS.

---
### Important facts to note.

1. In this project, our variables file in each child module do not contain any _values_. They only define the variables that would be used in a particular resource block. The values for the variables that we have declared in our `variables.tf` file of each child module is instead embedded in the `terraform.tfvars file`. It is the `terraform.tfvars` file that supplies these values.

 2. Each child module doesn’t have its own separate `terraform.tfvars` file. It is not necessary. Values for the modules can be supplied from the `terraform.tfvars` file in the root module. What's essential for each child module is a `variables.tf` file, which declares the variables specific to the resources created within that module.

3. Not all declared variables would get their values in the `terraform.tfvars` file. Some are sourced from the output of another module. For example, the values for the subnet are not in the `terraform.tfvars` file. You can only find the CIDR of the VPC. But then, our network module is going to generate for us subnets which would have subnet IDs, and these subnet IDs would serve as input for other resources like the load balancer, ASG, EFS, ICE, Database etc. One module’s output might most likely be the input for another module.

4. Any variables declared in the child module, which has to source its value from the `terraform.tfvars` file must also have that variable declared in the `variables.tf` file of the root module. The only variables in the child module that you do not have to declare in the `variable.tf` in the root module are the variables that are sourcing their value from the output of another module. The reason for this is that these values aren’t known. They have to be computed by the other module, generate an ID and the child module can use this value.

5. Whenever you have an output block for a child module in terraform, when it's time for it to get printed out, the output would fall within the constraints of that child module. The only way to get the output printed out on the terminal, or even, exported to a file within the GitLab CICD is that it also has to be called in the root module. That is, in the root module, there must be another `output.tf` file that would call this child module, allowing us to extract all of these values. But then, we do not neglect the starting point, which is calling out the output from the child module, because it's easier for a root module or another module to reference it.
---
### **4. GitLab CI/CD Variable Configuration** 
Now, before the pipeline can run, several CI/CD variables must be configured in the GitLab project settings (**Settings > CI/CD > Variables**). These include:

-   `AWS_ROLE_ARN`: The ARN of the IAM role for OIDC.
    
-   `TF_STATE_BUCKET`: The name of the S3 bucket for Terraform state.
    
-   `TF_STATE_TABLE`: The name of the DynamoDB table for state locking.
    
-   `AWS_DEFAULT_REGION`: The AWS region for the deployment.

These variables provide the pipeline with the necessary context to authenticate with AWS and manage the Terraform backend.

---
With a simple push to the repository, the GitLab CI/CD pipeline automates the entire process, provisioning a fully functional, highly available WordPress site on AWS while adhering to crucial IaC, security, and scalability best practices.
