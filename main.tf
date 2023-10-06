resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:819908864903:parameter/roboshop.${var.env}.${var.component}.*"
        }
    ]
})
}

resource "aws_iam_role" "test_role" {
  name = "${var.component}-${var.env}-ec2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_security_group" "sg_example"{
    name="${var.component}-${var.env}-sg"
    description="${var.component}-${var.env}-sg"

    # Defining inbound rules
    ingress{
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"] # Allow SSH access from anywhere
    }
    egress{
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
    }

    tags={
        Name= "${var.component}-${var.env}-sg"
    }

}



resource "aws_instance" "my_ec2" {
  ami=data.aws_ami.myami.id
  instance_type="t2.micro"
  vpc_security_group_ids=[aws_security_group.sg_example.id]
  iam_instance_profile=aws_iam_instance_profile.instance_profile.name
  tags={
    Name="${var.component}-${var.env}"
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}"
  role = aws_iam_role.test_role.name
}

resource "aws_route53_record" "dns" {
  zone_id = "Z04770651WQZPPJRLW6XF"
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.my_ec2.public_ip]
}

resource "null_resource" "ansible" {
    depends_on = [ aws_instance.my_ec2,aws_route53_record.dns ]
    provisioner "remote-exec" {
      connection={
         type="ssh"
         user="centos"
         password="Devops321"
         host=aws_instance.my_ec2.public_ip
      }
      inline=[
        "sudo labauto ansible",
        "ansible-pull -i localhost, -U https://github.com/subbumarella/my_learn_ansible.git main.yml -e env=${var.environment} -e role_name=${var.component}"
      ]
    }
  
}