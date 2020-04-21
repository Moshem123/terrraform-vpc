# Provisioning VPC with terraform


## Prerequisites
Create an SSH key to be able to connect to the instances:
```
ssh-keygen -t rsa -f ~/.ssh/terraform -q -P ""
```

## Provisioning
```
terraform init
terraform apply