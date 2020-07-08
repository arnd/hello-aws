# TAM Assignment EMEA Pre Loop
# main.tf - Main terraform code

provider "aws" {
  region  = "us-west-1"
  version = "~> 2.69"
}

provider "template" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

# VPC dedicated for the webservers
resource "aws_vpc" "webserver-vpc" {
  cidr_block = "10.23.0.0/16"
  # we want our webservers to be reachable with https and public amazon hostnames
  # https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "webserver", provisioned-by = "terraform" }
}

# Subnet for webservers in eu-west-1
resource "aws_subnet" "webserver-eu-west-1" {
  vpc_id     = aws_vpc.webserver-vpc.id
  cidr_block = "10.23.0.0/24"

  availability_zone = var.availability_zone

  tags = { Name = "webserver", provisioned-by = "terraform" }
}

# Internet gateway for our webservers
resource "aws_internet_gateway" "webserver-gw" {
  vpc_id = aws_vpc.webserver-vpc.id
  tags = { Name = "webserver", provisioned-by = "terraform" }
}

# find out generated route table id
data "aws_route_table" "webserver-rt" {
  #subnet_id = aws_subnet.webserver-eu-west-1.id
  vpc_id = aws_vpc.webserver-vpc.id
}

# Point default route to the internet gateway
resource "aws_route" "default-route" {
  route_table_id         = data.aws_route_table.webserver-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             =  aws_internet_gateway.webserver-gw.id
}

# to find latest ubuntu 20.04 images for amd64
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# for debugging, creata an SSH security group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic from jumphosts"
  vpc_id      = aws_vpc.webserver-vpc.id

  ingress {
    description = "SSH from Jumpthosts"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "webserver", provisioned-by = "terraform" }
}

# for user-traffic on http/https
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.webserver-vpc.id

  ingress {
    description = "HTTP from everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "webserver", provisioned-by = "terraform" }
}

# Convert the README.md within this repository to an index.html
resource "null_resource" "mdtohtml" {
  triggers = {
    sha1sum = sha1(file("${path.module}/README.md"))
  }
  provisioner "local-exec" {
    command = "markdown ${path.module}/README.md > ${path.module}/index.html"
  }
}

# we include our index.html we want to service within the cloud-init config
data "template_file" "cloud-config" {
  template = "${file("${path.module}/webserver.yaml.tpl")}"
  vars = {
    # to keep content in one line, encode it in base64
    index_html_content = base64encode(file("${path.module}/index.html"))
  }
  depends_on = [ null_resource.mdtohtml ]
}

# compress cloud-init for good measure (limited to 16kb on AWS)
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init2.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-config.rendered
  }

}

# AWS instance where cloud-init will be run
resource "aws_instance" "webserver" {
  ami               = data.aws_ami.ubuntu.id
  # We use a small instance type
  instance_type     = "t2.small"
  availability_zone = var.availability_zone

  associate_public_ip_address = "true"
  subnet_id              = aws_subnet.webserver-eu-west-1.id
  vpc_security_group_ids = [ aws_security_group.allow_http.id,
                             aws_security_group.allow_ssh.id ]

  user_data_base64 = data.template_cloudinit_config.config.rendered

  key_name = var.ssh_key_name

  tags = { Name = "webserver", provisioned-by = "terraform" }
  depends_on = [ null_resource.mdtohtml ]
}

# For reference: switched to CLI to create AMI
# To apply changes the instance needs to be tainted
# this will shutdown the AWS instance and create an AMI
#resource "aws_ami_from_instance" "hello-aws" {
#  name               = "terraform-hello-aws"
#  source_instance_id = aws_instance.webserver.id
#  tags = { Name = "webserver", provisioned-by = "terraform" }
#}

