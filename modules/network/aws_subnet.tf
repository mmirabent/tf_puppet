resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone       = "us-east-1a" # TODO: Make variable
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  availability_zone = "us-east-1a"
  tags = {
    Name = "private"
  }
}