#### This is a terraform script that will deploy a complete infrastructure EC2 ubuntu instance, an Elastic Load balancer and an autoscaling group
#### This deployment includes deploying a new VPC, subnets and routing tables. This instance will be used to deploy Monit app and test monitoring scripts see other scripts in the master github branch.
#### 
## Network configuration new VPC ##
resource "aws_vpc" "biotech_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "biotech VPC"
  }
}
## subnet configuration ##
resource "aws_subnet" "public_eu-west-1a" {
  vpc_id     = aws_vpc.biotech_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Public Subnet eu-west-1a"
  }
}

resource "aws_subnet" "public_eu-west-1b" {
  vpc_id     = aws_vpc.biotech_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "Public Subnet eu-west-1b"
  }
}
## Creating  internet gateway ###
resource "aws_internet_gateway" "biotech_vpc_igw" {
  vpc_id = aws_vpc.biotech_vpc.id

  tags = {
    Name = "biotech VPC - Internet Gateway"
  }
}
### Routing Table for vpc ##
resource "aws_route_table" "biotech_vpc_public" {
    vpc_id = aws_vpc.biotech_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.biotech_vpc_igw.id
    }

    tags = {
        Name = "Public Subnets Route Table for biotech VPC"
    }
}
## Associating the routing table to the subnet ##
resource "aws_route_table_association" "biotech_vpc_eu-west-1a_public" {
    subnet_id = aws_subnet.public_eu-west-1a.id
    route_table_id = aws_route_table.biotech_vpc_public.id
}

resource "aws_route_table_association" "biotech_vpc_eu-west-1b_public" {
    subnet_id = aws_subnet.public_eu-west-1b.id
    route_table_id = aws_route_table.biotech_vpc_public.id
}
## Creating Security groups ###
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.biotech_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}
### Creating autoscaling launch configuration ###
resource "aws_launch_configuration" "web" {
  name_prefix = "web-"
  image_id = "ami-0727367036f563293" 
  instance_type = "t2.micro"
  key_name = "paul"
  security_groups = [ aws_security_group.allow_http.id ]
  associate_public_ip_address = true
}
### Binding traffice to ELB ###
resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = aws_vpc.biotech_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = [
    aws_security_group.elb_http.id
  ]
  subnets = [
    aws_subnet.public_eu-west-1a.id,
    aws_subnet.public_eu-west-1b.id
  ]

  cross_zone_load_balancing   = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }

}
### Creating the autoscaling group ##
resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 4
  
  health_check_type    = "ELB"
  load_balancers = [
    aws_elb.web_elb.id
  ]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier  = [
    aws_subnet.public_eu-west-1a.id,
    aws_subnet.public_eu-west-1b.id
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}
## Routing the logs to cloudwatch 
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}

output "elb_dns_name" {
  value = aws_elb.web_elb.dns_name
}
