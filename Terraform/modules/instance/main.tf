# Retrieve the current AWS region.
data "aws_region" "current" {
}

# Using Amazon Linux 2 so I can install cloudagent from the repository
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-ebs"]
  }
  owners = ["amazon"]
}

# Create load balancer target group, enable communication on port 8080 and enable health check
resource "aws_lb_target_group" "target-group" {
  name     = "${var.namespace}-${var.project_name}-tg"
  protocol = "HTTP"
  vpc_id   = var.vpc.id
  port     = 8080
  health_check {
    enabled           = true
    path              = "/"
    healthy_threshold = 2
  }
}

# Create listener on port 80 
resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.alb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

# Create sg for the instances permitting port 8080 only from load balancer, port 22 from everywhere
resource "aws_security_group" "instance" {
  name        = "${var.namespace}-${var.project_name}-app"
  description = "Allow traffic to application"
  vpc_id      = var.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [var.alb.sg.id]
    self            = false
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

# Set cloudinit from template file
data "cloudinit_config" "httpserver" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content        = templatefile("${path.module}/cloud_config.yaml", {
      db_config    = var.db_config,
      region       = data.aws_region.current.name,
      app_url      = var.app_url
      namespace    = var.namespace
      project_name = var.project_name
      }
    )
  }
}

# set ssh key
resource "aws_key_pair" "ssh" {
  public_key = var.ssh_key
  key_name   = "ssh"
}

# set template for the instances that load balancer create
resource "aws_launch_template" "server" {
  name_prefix            = "${var.namespace}-${var.project_name}"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh.key_name
  user_data              = data.cloudinit_config.httpserver.rendered
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.cloudwatch_logs.name
  }
  lifecycle {
    create_before_destroy = true
  }

}

# iam instance profile needed for the cloudwatch agent to send log from inside instance
resource "aws_iam_instance_profile" "cloudwatch_logs" {
  name = "${var.namespace}-${var.project_name}-cloudwatch-logs"
  role = aws_iam_role.cloudwatch_logs.name
}

resource "aws_iam_role" "cloudwatch_logs" {
  name = "${var.namespace}-${var.project_name}-cloudwatch-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.cloudwatch_logs.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" 
}

# create autoscaling group 
resource "aws_autoscaling_group" "server" {
  name                = "${var.namespace}-${var.project_name}-asg"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.subnet.public_a.id, var.subnet.public_b.id]
  target_group_arns   = [aws_lb_target_group.target-group.arn]
  launch_template {
    id      = aws_launch_template.server.id
    version = aws_launch_template.server.latest_version
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}


# example of autoscaling up 
resource "aws_autoscaling_policy" "scaling_up" {
  name                   = "${var.namespace}-${var.project_name}-scale_up"
  autoscaling_group_name = aws_autoscaling_group.server.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
  scaling_adjustment     = 1
}

# example of autoscaling down
resource "aws_autoscaling_policy" "scaling_down" {
  name                   = "${var.namespace}-${var.project_name}-scale_down"
  autoscaling_group_name = aws_autoscaling_group.server.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 5
  scaling_adjustment     = -1
}

# ToDo: change condition to scale up when the number of request are greater than 100 req /min
resource "aws_cloudwatch_metric_alarm" "scale" {
  alarm_name          = "${var.namespace}-${var.project_name}-scale"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "RequestCount"
  threshold           = 100
  statistic           = "Sum"
  namespace           = "AWS/ApplicationELB"
  alarm_actions       = [aws_autoscaling_policy.scaling_up.arn]
  ok_actions          = [aws_autoscaling_policy.scaling_down.arn]
  dimensions          = {
    LoadBalancer     = var.alb.lb.arn_suffix
  }
}

# Setting alarm for CPU peak
# Note: This metric cannot be collected at a frequency lower than one per minute. 
resource "aws_cloudwatch_metric_alarm" "cpu_usage_alarm" {
  alarm_name          = "${var.namespace}-${var.project_name}-cpu-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  threshold           = 80
  alarm_description   = "High CPU usage alarm"
  statistic = "Maximum"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.server.name
  }

}

