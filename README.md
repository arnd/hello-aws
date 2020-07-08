# Hello AWS!

When launched, this AMI serves this Readme via HTTP. It is based on ubuntu 20.04 and uses nginx to service user requests.

## Instructions to re-create this AMI

This AMI was created by deploying an ubuntu 20.04 instance within a VPC with terraform.
Below you find instructions to re-deploy it from the [Git Repository](https://github.com/arnd/hello-aws)

### Prerequisites

* Terraform >= v0.12.69
* AWS Credentials with EC2 permissions (e.g. AmazonEC2FullAccess)
* markdown (http://daringfireball.net/projects/markdown/)
* AWS CLI

### Deploy new Instance and create Public AMI

1. Setup credentials `aws configure` (per default terraform will use AWS Shared Credentials File)
1. Setup terraform working directory: `terraform init`
1. Deploy new Instance and AMI `terraform apply`
1. Visit the new Instances URL and check if the Content is delivered fine (check `terraform output`)
1. Tear-down infrastructure `terraform destroy`
1. Make a copy of the terraform created AMI (e.g. via `aws ec2 create-image --instance-id <REPLACE-WITH-INSTANCE-ID> --name $(date -I)-aws-hello`)
1. Make AMI public (e.g. via `aws ec2 modify-image-attribute --image-id ami-0db087fa93dde7690 --launch-permission "Add=[{Group=all}]"`)

### Terraform Dry-run

1. `terraform init -backend=false`
1. `terraform validate`

## Lessons learned

* AWS accounts which were created before 2013-12-04 may not allow a default VPC in a region. (EC2-Classic)
* Letsencrypt will not hand out SSL certificates for default AWS public DNS names (.compute.amazonaws.com), because these are ephemeral names.
* Terraform's `aws_ami_from_instance` might create the AMI before cloud-init went through, which then would require continue bootstrapping when AMI is launched
* Terraform's `file()` function requires the file referenced to be there during HCL parsing
* AWS Cli's `ec2 create-image`  does not seem to allow to specify tags (e.g. via `--tag-specifications`)
