data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = "aws-learning-key"

  user_data = templatefile("${path.module}/ec2-userdata.sh.tpl", {
    region       = var.aws_region
    s3_bucket    = aws_s3_bucket.app.id
    dynamo_table = aws_dynamodb_table.images.name
  })

  user_data_replace_on_change = true

  tags = {
    Name      = "${var.project_name}-web"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
