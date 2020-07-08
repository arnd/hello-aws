variable "ssh_key_name" {
  description = "Existing SSH Keypair to use (specify this, if you want to login into the instance)"
  type        = string
  default     = null
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks for which SSH will be allowed to login into the instance)"
  type        = list(string)
  default     = []
}

variable "availability_zone" {
  description = "AWS availability zone to deploy in."
  type        = string
  default     = "us-west-1b"
}
