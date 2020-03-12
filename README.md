# This is a sample shell script for creating OCI instance from VCN to compute

1. Get availability domain
2. Create a VCN 10.0.0.0/16
3. Create an Internet Gateway
4. Create a route table for public access
5. Create a subnet 10.0.0.0/24
6. Get shape name
7. Create a new instance

## Create Regional Subnet
Remove the parameter "availabilityDomain" in the file "subnet.json"
