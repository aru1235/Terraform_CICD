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

