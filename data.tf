data "aws_ami" "myami"{
    owners = ["973714476881"]
    most_recent = true
    name_regex="Centos-8-DevOps-Practice"
}