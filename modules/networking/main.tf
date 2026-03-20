data "aws_availability_zones" "available" { state = "available" }
data "aws_caller_identity" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, { Name = "${var.name_prefix}vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}igw" })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}public-subnet-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}private-app-subnet-${count.index + 1}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}private-data-subnet-${count.index + 1}"
    Tier = "private-data"
  })
}

resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = merge(var.common_tags, { Name = "${var.name_prefix}nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(var.common_tags, { Name = "${var.name_prefix}nat-gw-${count.index + 1}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags       = merge(var.common_tags, { Name = "${var.name_prefix}private-app-rt-${count.index + 1}" })
  depends_on = [aws_nat_gateway.main]
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_route_table" "private_data" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.name_prefix}private-data-rt-${count.index + 1}" })
}

resource "aws_route_table_association" "private_data" {
  count          = length(aws_subnet.private_data)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data[count.index].id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.name_prefix}flow-logs"
  retention_in_days = 30
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}vpc-flow-logs" })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name_prefix}vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = merge(var.common_tags, { Name = "${var.name_prefix}vpc-flow-logs-role" })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.name_prefix}vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"], Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*" }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags            = merge(var.common_tags, { Name = "${var.name_prefix}vpc-flow-log" })
}