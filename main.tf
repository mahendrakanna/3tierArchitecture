# main.tf

# --- Networking Layer (VPC, Subnets, Internet Gateway, Route Tables) ---

# 1. Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "three_tier_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.project_name}-VPC"
    Project = var.project_name
  }
}

# 2. Create Public Subnet (for Web Tier)
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = "us-east-1${element(["a", "b", "c"], count.index)}" # Distribute across AZs
  map_public_ip_on_launch = true                                                # Instances in this subnet get a public IP
  tags = {
    Name    = "${var.project_name}-Public-Subnet-${count.index + 1}"
    Tier    = "Web"
    Project = var.project_name
  }
}

# 3. Create Private Application Subnet (for App Tier)
resource "aws_subnet" "private_app_subnet" {
  count             = length(var.private_app_subnet_cidr)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_app_subnet_cidr[count.index]
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}" # Distribute across AZs
  tags = {
    Name    = "${var.project_name}-Private-App-Subnet-${count.index + 1}"
    Tier    = "Application"
    Project = var.project_name
  }
}

# 4. Create Private Database Subnet (for Data Tier)
resource "aws_subnet" "private_db_subnet" {
  count             = length(var.private_db_subnet_cidr)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_db_subnet_cidr[count.index]
  availability_zone = "us-east-1${element(["a", "b", "c"], count.index)}" # Distribute across AZs
  tags = {
    Name    = "${var.project_name}-Private-DB-Subnet-${count.index + 1}"
    Tier    = "Database"
    Project = var.project_name
  }
}

# 5. Create Internet Gateway (for public subnet access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name    = "${var.project_name}-IGW"
    Project = var.project_name
  }
}

# 6. Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name    = "${var.project_name}-Public-RT"
    Project = var.project_name
  }
}

# 7. Add route to Internet Gateway in Public Route Table
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0" # All traffic
  gateway_id             = aws_internet_gateway.igw.id
}

# 8. Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# 9. Create Private Route Table (for App and DB tiers - no direct internet access)
#    For outbound internet access from private subnets, a NAT Gateway would be needed.
#    This example simplifies by not including NAT Gateway for brevity, meaning private
#    instances won't have outbound internet access unless configured.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name    = "${var.project_name}-Private-RT"
    Project = var.project_name
  }
}

# 10. Associate Private App Subnet with Private Route Table
resource "aws_route_table_association" "private_app_subnet_association" {
  count          = length(var.private_app_subnet_cidr)
  subnet_id      = aws_subnet.private_app_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# 11. Associate Private DB Subnet with Private Route Table
resource "aws_route_table_association" "private_db_subnet_association" {
  count          = length(var.private_db_subnet_cidr)
  subnet_id      = aws_subnet.private_db_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# --- Security Groups ---

# 1. Security Group for Web Tier (Allow HTTP/HTTPS from anywhere)
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.three_tier_vpc.id
  name        = "${var.project_name}-Web-SG"
  description = "Allow HTTP/HTTPS access to web servers"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name    = "${var.project_name}-Web-SG"
    Project = var.project_name
  }
}

# 2. Security Group for Application Tier (Allow traffic from Web SG, SSH from anywhere)
resource "aws_security_group" "app_sg" {
  vpc_id      = aws_vpc.three_tier_vpc.id
  name        = "${var.project_name}-App-SG"
  description = "Allow traffic from web tier and SSH"

  ingress {
    from_port       = 8080 # Example application port
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Allow traffic from web tier SG
    description     = "Allow app traffic from web tier"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for management, restrict in production)
    description = "Allow SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name    = "${var.project_name}-App-SG"
    Project = var.project_name
  }
}

# 3. Security Group for Database Tier (Allow traffic from App SG)
resource "aws_security_group" "db_sg" {
  vpc_id      = aws_vpc.three_tier_vpc.id
  name        = "${var.project_name}-DB-SG"
  description = "Allow traffic from application tier"

  ingress {
    from_port       = 3306 # MySQL/Aurora default port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Allow traffic from app tier SG
    description     = "Allow DB traffic from app tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-DB-SG"
    Project = var.project_name
  }
}

# --- Compute Layer (EC2 Instances) ---

# 1. Web Servers (in Public Subnet)
resource "aws_instance" "web_server" {
  count                       = length(var.public_subnet_cidr) # One web server per public subnet
  ami                         = var.ami_id
  instance_type               = var.instance_type_web
  subnet_id                   = aws_subnet.public_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  user_data                   = file("user_data_web.sh") # Execute script on launch
  key_name                    = "my_pem"                 # Replace with your SSH key pair name
  associate_public_ip_address = true                     # Ensure public IP for direct access (or use ALB)

  tags = {
    Name    = "${var.project_name}-Web-Server-${count.index + 1}"
    Tier    = "Web"
    Project = var.project_name
  }
}

# 2. Application Servers (in Private App Subnet)
resource "aws_instance" "app_server" {
  count                  = length(var.private_app_subnet_cidr) # One app server per private app subnet
  ami                    = var.ami_id
  instance_type          = var.instance_type_app
  subnet_id              = aws_subnet.private_app_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = file("user_data_app.sh") # Execute script on launch
  key_name               = "my_pem"                 # Replace with your SSH key pair name

  tags = {
    Name    = "${var.project_name}-App-Server-${count.index + 1}"
    Tier    = "Application"
    Project = var.project_name
  }
}

# --- Database Layer (RDS) ---

# 1. DB Subnet Group (required for RDS in a VPC)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private_db_subnet : s.id] # Use all private DB subnets
  tags = {
    Name    = "${var.project_name}-DB-Subnet-Group"
    Project = var.project_name
  }
}

# 2. RDS Instance (MySQL example)
resource "aws_db_instance" "main_db" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = "8.0.35" # Specify a compatible MySQL version
  instance_class         = var.db_instance_type
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] # Associate with DB security group
  skip_final_snapshot    = true                          # Set to false in production for data backup
  publicly_accessible    = false                         # Database should NOT be publicly accessible

  tags = {
    Name    = "${var.project_name}-Database"
    Tier    = "Database"
    Project = var.project_name
  }
}
