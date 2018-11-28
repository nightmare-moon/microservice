variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_KEYNAME" {}
variable "AWS_PUBLIC_KEY" {}


provider "aws" {
  region = "us-west-1"
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
}


resource "aws_vpc" "myapp" {
     cidr_block = "10.100.0.0/16"
  tags {
     Name = "myapp vpc"
  }
}


resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.myapp.id}"

    tags {
        Name = "myapp gw"
    }
}


resource "aws_subnet" "public_1a" {
    vpc_id = "${aws_vpc.myapp.id}"
    cidr_block = "10.100.0.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-west-1b"

    tags {
        Name = "Public 1A"
    }
}

/*resource "aws_subnet" "public_1b" {
    vpc_id = "${aws_vpc.myapp.id}"
    cidr_block = "10.100.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"

    tags {
        Name = "Public 1B"
    }
}*/



resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow inbound SSH traffic from my IP"
  vpc_id = "${aws_vpc.myapp.id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["99.149.252.56/32"]
      #cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow SSH"
  }
}



resource "aws_security_group" "web_server" {
  name = "web server"
  description = "Allow HTTP and HTTPS traffic in, browser access out."
  vpc_id = "${aws_vpc.myapp.id}"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "huskey" {
  key_name =  "${var.AWS_KEYNAME}"
  public_key = "${var.AWS_PUBLIC_KEY}"
}


resource "aws_instance" "Portal" {
  ami = "ami-2d39803a"

  instance_type = "t1.micro"
    subnet_id = "${aws_subnet.public_1a.id}"
    vpc_security_group_ids = ["${aws_security_group.web_server.id}","${aws_security_group.allow_ssh.id}"]


  key_name = "${aws_key_pair.huskey.key_name}"
  tags {
    Name = "Portal"
  }
  provisioner "local-exec" {
    command = "echo ${self.private_ip} > file.txt"
  }

}





