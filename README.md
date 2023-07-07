```shell 
cd ../step1; terraform init; terraform plan; terraform apply -auto-approve
cd ../step2; terraform init; terraform plan; terraform apply -auto-approve
# the next step may timeout successfully. 
cd ../step3; terraform init; terraform plan; terraform apply -auto-approve 
cd ../step4; terraform init; terraform plan;
# Run the 3 terraform import that the plan commond outputs
terraform apply -auto-approve
```