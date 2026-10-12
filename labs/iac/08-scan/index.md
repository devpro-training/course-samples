# Scan

The code is the place where a mistake is cheapest to catch: a security group open to the world is a line of text before it is a server.
`trivy config` reads Terraform, CloudFormation, Azure ARM templates, Kubernetes, Helm and Dockerfiles, and needs no cloud account.

## An insecure file

1. Write a security group that allows SSH from anywhere, and a bucket with a public ACL:

   ```bash exec
   mkdir -p ~/lab/scan && cd ~/lab/scan && \
   cat > main.tf <<'TF'
   resource "aws_security_group" "web" {
     name        = "web"
     description = "Web server"

     ingress {
       description = "SSH from anywhere"
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }
   }

   resource "aws_s3_bucket" "assets" {
     bucket = "course-assets"
   }

   resource "aws_s3_bucket_acl" "assets" {
     bucket = aws_s3_bucket.assets.id
     acl    = "public-read"
   }
   TF
   ```

   [Open main.tf](:open:scan/main.tf)

2. Scan it, for the high and critical findings:

   <!-- verify: requires=network timeout=240 expect="AWS-0107 (HIGH)" -->

   ```bash exec
   cd ~/lab/scan && \
   trivy config --severity HIGH,CRITICAL . 2>&1 | grep -E "^AWS-"
   ```

   Each finding has an identifier, a severity, the lines of the file and a page that explains the risk.
   Nothing was created: the file was read, and the provider of the cloud was never called.

## Fix

1. Restrict SSH to an address range of the office (`203.0.113.0/24` is reserved for documentation), drop the public ACL, block public access and encrypt the bucket with a key that rotates:

   ```bash exec
   cd ~/lab/scan && \
   cat > main.tf <<'TF'
   resource "aws_security_group" "web" {
     name        = "web"
     description = "Web server"

     ingress {
       description = "SSH from the office"
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["203.0.113.0/24"]
     }
   }

   resource "aws_kms_key" "assets" {
     description         = "Encrypts the assets bucket"
     enable_key_rotation = true
   }

   resource "aws_s3_bucket" "assets" {
     bucket = "course-assets"
   }

   resource "aws_s3_bucket_public_access_block" "assets" {
     bucket                  = aws_s3_bucket.assets.id
     block_public_acls       = true
     block_public_policy     = true
     ignore_public_acls      = true
     restrict_public_buckets = true
   }

   resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
     bucket = aws_s3_bucket.assets.id
     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm     = "aws:kms"
         kms_master_key_id = aws_kms_key.assets.arn
       }
     }
   }
   TF
   ```

2. Scan again, as a gate that fails on a high or critical finding:

   <!-- verify: requires=network timeout=240 expect="status 0" -->

   ```bash exec
   cd ~/lab/scan && \
   trivy config --severity HIGH,CRITICAL --exit-code 1 . > /dev/null 2>&1; \
   echo "status $?"
   ```

   Lower severities remain, such as the versioning and the access logs of the bucket: the gate is a decision, written in the command.

## What a scan of the code does not see

- **The environment**: a rule added by hand in the console is drift, and only a plan, or a scan of the cloud account, finds it.
- **The values only known at apply time**: a variable set in a pipeline is not in the file.
- **The secrets in the state**: a state file is data to protect, as the Terraform documentation says, and is not a file of the repository.
- **A format Trivy does not list**: its page on coverage names Kubernetes, Dockerfile, Terraform, Terraform plan, CloudFormation, Azure ARM, Helm, YAML, JSON and Ansible, and not Bicep.
