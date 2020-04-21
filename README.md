# Provisioning VPC with terraform


## Prerequisites
- Create an SSH key to be able to connect to the instances:
```
ssh-keygen -t rsa -f ~/.ssh/terraform -q -P ""
```
- Have a working set of credentials to a working AWS account
- Install jq
```
brew install jq
```

## Provisioning
```
terraform init
terraform apply
```

### Test the script's output
- Get the server's public IP from the output
```
public_ip_address=$(terraform output -json instances_data | jq -r 'to_entries | .[0].value')
```
- Run
```
ssh -i ~/.ssh/terraform ubuntu@${public_ip_address} "cat /var/log/ping-output.log"
```
