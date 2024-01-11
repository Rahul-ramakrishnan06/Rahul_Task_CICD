**Kubernetes Cluster-1.24 - Terraform-Ansible** 


**Authored by:** R.Rahul **Date:** 10-Oct-2023

<a name="_page1_x51.00_y116.00"></a>**Summary:**

Creating Kubernetes clusters with Terraform streamlines infrastructure provisioning. Leveraging provider plugins, Terraform orchestrates resources like VMs, networks, and storage, ensuring consistent setups. Modules encapsulate best practices, promoting reusability. Terraform abstracts complexities, enabling declarative definitions. Infrastructure as Code practices enhance scalability, version control, and collaboration. Combining Terraform's power with Kubernetes manifests accelerates cloud-native deployments, fostering efficient, reproducible, and automated cluster management. 

<a name="_page1_x51.00_y271.00"></a>**Prerequisites:** 

- Ec2 Instance - 1 
- Ansible 
- Terraform 

<a name="_page1_x51.00_y386.00"></a> **What will we do:** 

- Install terraform and ansible in Ec2 server 
- Create terraform files for setting up K8 cluster 
- Deploy kubernetes cluster using terraform and ansible 

<a name="_page1_x51.00_y472.00"></a>**Terraform**  

- Install unzip 
- **sudo apt-get install unzip** 
- Confirm the latest version number on the terraform website: 
- [**https://www.terraform.io/downloads.html** ](https://www.terraform.io/downloads.html)
- Download latest version of the terraform (substituting newer version number if needed) 
- **wget[ https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip** ](https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip)**
- Extract the downloaded file archive 
- **unzip terraform\_1.0.7\_linux\_amd64.zip** 
- Move the executable into a directory searched for executables 
- **sudo mv terraform /usr/local/bin/** 
- Run it 
- **terraform --version**  

<a name="_page2_x51.00_y97.00"></a>**Ansible** 

- Connect to Your EC2 Instance 
- **ssh -i /path/to/your/key.pem ec2-user@your-instance-ip** 
- Update the Package Manager 
- **sudo apt-get update -y  # For Ubuntu/Debian** 
- Install Ansible 
- **sudo apt-get install ansible -y** 
- Check Ansible Version 
- **ansible --version** 

<a name="_page2_x51.00_y303.00"></a>**Provider.tf** 

The provider.tf file in Terraform defines cloud providers and configurations. It specifies authentication details, regions, and resources for the infrastructure. By declaring providers, Terraform understands where to create resources. It supports various providers like AWS, Azure, and GCP. This file centralizes provider settings, ensuring consistent deployments and simplifying multi-cloud management. Properly configured provider.tf files are essential for Terraform to provision resources accurately and securely across cloud environments. 

provider "aws" { region = "us-east-1" } 

Please use aws configure to setup secret access key and access id. 

<a name="_page2_x51.00_y541.00"></a>**Variable.tf** 

In Terraform, variable.tf defines input parameters for modules. It sets values like IP addresses, instance sizes, or strings. These dynamic inputs enable reusable and flexible configurations. Using variables promotes modularity and standardization across Terraform projects. variable.tf enhances code readability and allows users to customize deployments without modifying the core infrastructure code, fostering adaptability and collaborative development. 

variable "Master\_var" { type = "map" 

default = { 

hostname="Master" 

region = "us-east-1" 

vpc = "vpc-00c8ac1c65622bea1" 

ami = "ami-053b0d53c279acc90" 

itype = "t2.medium" 

subnet = "subnet-0c9724fe421d89f38" publicip = true 

keyname = "rahul1" 

secgroupname = "sg-0a00726f1325bc02e" } 

} 

variable "Worker\_var" { 

type = "map" 

default = { 

hostname="Worker" 

region = "us-east-1" 

vpc = "vpc-00c8ac1c65622bea1" 

ami = "ami-053b0d53c279acc90" 

itype = "t2.medium" 

subnet = "subnet-019fc7c8313c5b154" publicip = true 

keyname = "rahul1" 

secgroupname = "sg-0a00726f1325bc02e" } 

} 

<a name="_page3_x51.00_y523.00"></a>**Ec2.tf** 

resource "aws\_instance" "Master" { 

ami = lookup(var.Master\_var,"ami") 

instance\_type = lookup(var.Master\_var, "itype") vpc\_security\_group\_ids= [lookup(var.Master\_var,"secgroupname")] key\_name = lookup(var.Master\_var,"keyname") 

user\_data = <<EOF 

#!/bin/bash 

hostnamectl set-hostname master 

EOF 

tags = { 

Name = lookup(var.Master\_var,"hostname") } 

} 

resource "aws\_instance" "Worker" { 

ami = lookup(var.Worker\_var,"ami") 

instance\_type = lookup(var.Worker\_var, "itype") vpc\_security\_group\_ids = [lookup(var.Worker\_var,"secgroupname")] key\_name = lookup(var.Worker\_var,"keyname") 

user\_data = <<EOF 

#!/bin/bash 

hostnamectl set-hostname worker1 

EOF 

tags = { 

Name = lookup(var.Worker\_var,"hostname") } 

} 

resource "null\_resource" "provision\_cluster\_member\_MAster\_hosts\_file" { 

connection { 

type = "ssh" 

host = aws\_instance.Master.public\_ip 

user = "ubuntu" 

private\_key = file("rahul1.pem") 

} 

provisioner "remote-exec" { 

inline = [ 

- Adds all cluster members' IP addresses to /etc/hosts (on each member) "sudo hostnamectl set-hostname Master", 

  "echo '${join("\n", formatlist("%v", aws\_instance.Master.private\_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Master nodes:\" }; { print $0 \" ${var.Master\_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null", 

"echo '${join("\n", formatlist("%v", aws\_instance.Worker.private\_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Worker nodes:\" }; { print $0 \" ${var.Worker\_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null", 

} } 

resource "null\_resource" "provision\_cluster\_member\_worker\_hosts\_file" { 

connection { 

type = "ssh" 

host = aws\_instance.Worker.public\_ip 

user = "ubuntu" 

private\_key = file("rahul1.pem") 

} 

provisioner "remote-exec" { 

inline = [ 

- Adds all cluster members' IP addresses to /etc/hosts (on each member) "sudo hostnamectl set-hostname worker1", 

  "echo '${join("\n", formatlist("%v", aws\_instance.Master.private\_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Master nodes:\" }; { print $0 \" ${var.Master\_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null", 

"echo '${join("\n", formatlist("%v", aws\_instance.Worker.private\_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Worker nodes:\" }; { print $0 \" ${var.Worker\_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null", 

] 

} 

} 

resource "null\_resource" "setting\_private\_ip\_in\_ansible\_file" { provisioner "local-exec" { 

working\_dir = "/home/ubuntu/ansible/Ansible/k8-cluster-ansible" 

command = <<EOT 

sleep 3m 

sed -i 's/master ansible\_host=18.212.187.125/master ansible\_host=${aws\_instance.Master.public\_ip}/g' inventory.ini 

sed -i 's/worker1 ansible\_host=44.211.162.58/worker1 ansible\_host=${aws\_instance.Worker.public\_ip}/g' inventory.ini 

sed -i 's/--apiserver-advertise-address 172.31.90.250/--apiserver-advertise- address ${aws\_instance.Master.private\_ip}/g' k8-master-init.yaml ansible-playbook -i inventory.ini k8-requirement.yaml 

ansible-playbook -i inventory.ini k8-master-init.yaml 

ansible-playbook -i inventory.ini k8-join-node.yaml 

EOT 
} 

} 

<a name="_page6_x51.00_y137.00"></a>**Conclusion:** 

Creating Kubernetes clusters via Terraform offers streamlined, scalable, and reproducible infrastructure. Leveraging provider modules simplifies cloud resource management. Infrastructure as Code principles ensure versioned, collaborative cluster setups. The modular approach enables flexibility, supporting diverse cloud environments. Terraform's declarative syntax accelerates deployments, promoting consistent, manageable, and automated Kubernetes clusters, aligning with modern DevOps practices. 

