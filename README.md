* For Default Cloud Setup
---
Step 1. Clone the Repo -
```shell
git clone https://github.com/papivot/terraforming-avi.git
cd terraforming-avi
```

Step 2. Modify the variable file in the root folder of the repo. Copy the file to all the folders - 
```shell
# vi sample-variables.tf
echo ./step1/variables.tf ./step2/variables.tf ./step3/variables.tf ./step4/variables.tf |xargs -n 1 cp -v sample-variables.tf
cd ./step1
```

Step3. Execute the 4 plans -  
```shell 
cd ../step1; terraform init; terraform plan; terraform apply -auto-approve
cd ../step2; terraform init; terraform plan; terraform apply -auto-approve
# the next step may timeout successfully. 
cd ../step3; terraform init; terraform plan; terraform apply -auto-approve 
cd ../step4; terraform init; terraform plan;
# Run the 3 terraform import that the plan commond outputs example - 
# terraform import avi_ipamdnsproviderprofile.wcp_ipam https://192.168.100.58/api/ipamdnsproviderprofile/ipamdnsproviderprofile-3eefac83-488c-47fb-8adf-a1e7cb3d47fb
# terraform import avi_network.wcp_management https://192.168.100.58/api/network/dvportgroup-71-cloud-01eedfb7-9f4b-4e6b-a8b5-239da6c89c76
# terraform import avi_network.wcp_vip_pool https://192.168.100.58/api/network/dvportgroup-72-cloud-01eedfb7-9f4b-4e6b-a8b5-239da6c89c76
terraform apply -auto-approve
```
