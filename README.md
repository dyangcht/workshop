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


### Reference
1. https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm#Python
2. API Entry Point: https://docs.cloud.oracle.com/en-us/iaas/api/
3. https://docs.cloud.oracle.com/en-us/iaas/api/#/en/iaas/20160918/

# 