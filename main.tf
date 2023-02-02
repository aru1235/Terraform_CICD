# To store the "tf state" file remotely (to be specific in S3 bucket) to access it anyone, perform following
# By performing below, tfstate file will be moved to the s3 bucket, so that organisation can access to it.
# So, whenever we update this main.tf file here, tf state file will be updated in s3 bucket.
terraform {             
    required_version = ">= 0.12"      # Version of terraform
    backend "s3" {
        bucket = "myapp-bucket-9"   # To be created manually in console
        key = "myapp/state.tfstate"
        region = "us-east-1"
    }
}


# Declaring an AWS provider named aws
provider "aws" {
  # Declaring the provider region
  region = "us-east-1"
  # Declaring the access_key and secret_key
  shared_credentials_file = "~/.aws/credentials"
  profile = "default"
}

# assign  these below values in seperate "terraform.tfvars" folder
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable instance_type {}
variable public_key_location {}

resource "aws_vpc" "my-VPC" {                  
    cidr_block = var.vpc_cidr_block               
    tags = {
        Name = "Terra_VPC_new"
    }
}

resource "aws_subnet" "my-subnet-1" {
    vpc_id = aws_vpc.my-VPC.id         # This VPC Id shall be taken from above "resource" line for vpc
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "Terra_Subnet_ new"
    }
}


# create new route table

resource "aws_route_table" "my-route-table" {
    vpc_id = aws_vpc.my-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-gateway.id           # this IGW is created in next step
    }     
    tags = {
        Name = "MY_RT"
    }                 
}

# creating internet gateway ans we need to use this gateway in route table "gateway_id"
# irresepective of sequency here, terraform will first create IGW and create route table

resource "aws_internet_gateway" "my-gateway" {
    vpc_id = aws_vpc.my-VPC.id
    tags = {
        Name = "MY_IGW"
    }
}

# Associating subnet with route table

resource "aws_route_table_association" "Asso-RT-subnet" {
    subnet_id = aws_subnet.my-subnet-1.id                       # this is name of subnet created above
    route_table_id = aws_route_table.my-route-table.id             # this is name of route table created abpve
}

# Creating AWS instance

data "aws_ami" "latest-amazon-linux-image" {           # This will take latest image from aws
    most_recent = true
    owners = ["amazon"]                                # Owner name is available under AMI in AWS console
    # filter to make differentiate between two identical aws image
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]     # This name is available under community AMI (While choosing ami during launch)
        # Like this we can add many filter based on ami name
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id    # This is name of data above
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id        # This is name of data above
    instance_type = var.instance_type
# To launch instance in the created subnet
    subnet_id = aws_subnet.my-subnet-1.id
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name        # This is name of key pair created in next step
  # we will install some pre-defined commands using shell script as below
  # these will be executed during instance launching
  #-aG means, adding ec2-user to the docker group, because, by doing this, we can run docker command without sudo
    user_data = <<-EOF
                  #! /bin/bash
                  sudo yum update -y
                  sudo amazon-linux-extras install docker -y
                  sudo service docker start
                  sudo usermod -a -G docker ec2-user
                  sudo docker pull nginx:latest
                  sudo docker pull jenkins/jenkins
                  sudo docker run --name mynginx1 -p 8080:80 -d nginx
                  sudo docker run --name jenkins -p 9090:80 -d jenkins
           
                EOF

    tags = {
        Name = "My_instance"
    }
 
}

# Creating SSH key pair
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    # This public key will be availble in id_rsa.pub (we can generate this by "ssh-keygen", two files is_rsa and id_rsa.pub will be generated)
    # go to that ssh folder and "cat is_rsa.pub" to see public key and its location
    # we can keep this key path/location as variable
    public_key = "${file(var.public_key_location)}"

}

# by this we can login to our instance using ssh key (as we do not have .pem key)
# to login, use "ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>fromm_instance" 
# type this in terminal, you will be logged in to instance
# In addition, allow SSH, port 22 in security group in console to allow ssh
# we can also manage security in configuration file of terraform
# Jenkins is not working here due to some issues
# afte running "docker ps". if it shows daemon error, then perform "sudo systemctl start docker"
# To restart stopped container (docker ps -a), perform "docker start <container_name>"


