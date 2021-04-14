resource "aws_eip" "ngw" {
  vpc = true
  tags = {
    Name = "NAT Gateway IP"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Internet Gateway"
  }
}
