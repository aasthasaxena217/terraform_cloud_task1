provider "aws" {
  region   = "ap-south-1"
  profile  = "aastha19"
}

resource "tls_private_key" "tasks_key" {
  algorithm   = "RSA"

}

resource "aws_key_pair" "tsk_key1" {
depends_on=[
              tls_private_key.tasks_key
]
  key_name     = "task1_key"
  public_key    = tls_private_key.tasks_key.public_key_openssh
}

resource "local_file" "privatekey" {
depends_on=[
       aws_key_pair.tsk_key1
]
    content     = tls_private_key.tasks_key.private_key_pem
    filename  = "C:/Users/HP/Desktop/task1_key.pem"
}

resource "aws_security_group" "Secu_grp" {
depends_on=[
	local_file.privatekey
]
  name        = "SecurityGroup1"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-47706c2f"

  ingress {
    description = "SSH protocol"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP prtocol for website users"
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


  tags = {
    Name = "Secu_grp"
  }
}
resource "aws_instance"  "myin" {
  ami           = "ami-0a780d5bac870126a"
  instance_type = "t2.micro"
  key_name      = "mycloudkey"
  
  tags = {
    Name = "Task1_os"
  }
  connection{
		type = "ssh"
		user = "ec2-user"
		private_key = file("C:/Users/HP/Desktop/task1_key.pem")
		host = aws_instance.myin.public_ip
	}
	provisioner "remote-exec"{
		inline = [
			"sudo yum install httpd -y",
			"sudo yum install git -y",
			"sudo systemctl restart httpd",
			"sudo systemctl enable httpd",
                                             "sudo yum install docker -y"
                                             
			
		]
	}
}
resource "aws_ebs_volume" "my_EBS_vol" {
 availability_zone = aws_instance.myin.availability_zone
 size                   = 1
 
 tags  =  {
    Name  = "mye_ebs"
   }
}
resource "aws_volume_attachment" "vol_attach" {
depends_on=[
   aws_ebs_volume.my_EBS_vol
]
   device_name  = "/dev/sdd"
   volume_id       = "${aws_ebs_volume.my_EBS_vol.id}"
   instance_id     = "${aws_instance.myin.id}"
   force_detach   = true
}

resource "null_resource" "mount-part"{
depends_on=[
              aws_volume_attachment.vol_attach
]
              connection{
                          type = "ssh"
                          user = "ec2-user"
                          private_key = file("C:/Users/HP/Desktop/task1_key.pem")
                          host  = aws_instance.myin.public_ip
}
               provisioner "remote-exec" {
                          inline = [
                          "sudo mkfs.ext4 /dev/xvdh",
                          "sudo mount /dev/xvdh /var/www/html",
                          "sudo rm -rf /var/www/html/*",
                          "sudo git clone https://github.com/aasthasaxena217/terraform_cloud_task1.git /var/www/html"

]
}
}
resource "aws_s3_bucket" "aaassthaa12222289" {
  bucket = "aaassthaa12222289"
  acl    = "public-read"
  force_destroy = true
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://aaassthaa12222289"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}


resource "aws_s3_bucket_object" "s3object" {
depends_on = [
	aws_s3_bucket.aaassthaa12222289
]
  bucket = aws_s3_bucket.aaassthaa12222289.bucket
  key    = "abc.jpg"
  source = "C:/Users/HP/Desktop/aws_tera.png"
  acl = "public-read"
  
}
locals {
           s3_origin_id = "s3_origin"
}

resource "aws_cloudfront_distribution" "my_cloudfr_distribution" {
depends_on = [
aws_s3_bucket_object.s3object,
]
	enabled = true
	is_ipv6_enabled = true
	
	origin {
		domain_name = aws_s3_bucket.aaassthaa12222289.bucket_regional_domain_name
		origin_id = local.s3_origin_id
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	default_cache_behavior {
		target_origin_id = local.s3_origin_id
		allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    	cached_methods  = ["HEAD", "GET", "OPTIONS"]

    	forwarded_values {
      		query_string = false
      		cookies {
        		forward = "none"
      		}
		}

		viewer_protocol_policy = "redirect-to-https"
    	min_ttl                = 0
    	default_ttl            = 120
    	max_ttl                = 86400
	}

	viewer_certificate {
    	cloudfront_default_certificate = true
  	}
}



output "myoutput1"{
value     = aws_cloudfront_distribution.my_cloudfr_distribution.domain_name
}






























