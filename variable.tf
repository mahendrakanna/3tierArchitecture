variable "project_name" {
  description = "Name of the project, used for resource tagging."
  type        = string
  default     = "threetierapp"
}
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (web tier)."
  type        = list(string)
  default     = ["10.0.1.0/24"] # Example: one public subnet
}
variable "private_app_subnet_cidr" {
  description = "CIDR block for the private application subnet (app tier)."
  type        = list(string)
  default     = ["10.0.2.0/24"] # Example: one private app subnet
}
variable "private_db_subnet_cidr" {
  description = "CIDR block for the private database subnet (data tier)."
  type        = list(string)
  default = ["10.0.3.0/24",
  "10.0.4.0/24"] # Example: one private db subnet
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances (e.g., Amazon Linux 2)."
  type        = string
  default     = "ami-0150ccaf51ab55a51" # Example: Amazon Linux 2 AMI (us-east-1) - please update to a recent one
}
variable "instance_type_web" {
  description = "EC2 instance type for web servers."
  type        = string
  default     = "t2.micro"
}
variable "instance_type_app" {
  description = "EC2 instance type for application servers."
  type        = string
  default     = "t2.micro"
}
variable "db_instance_type" {
  description = "RDS DB instance type."
  type        = string
  default     = "db.t4g.micro"
}
variable "db_name" {
  description = "Name of the database."
  type        = string
  default     = "mydb"
}
variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "admin"
}
variable "db_password" {
  description = "Master password for the database. **WARNING: For production, use AWS Secrets Manager or similar.**"
  type        = string
  default     = "password123" # **DO NOT USE HARDCODED PASSWORDS IN PRODUCTION** 
  sensitive   = true
}
variable "db_allocated_storage" {
  description = "Allocated storage for the database in GB."
  type        = number
  default     = 20
}
