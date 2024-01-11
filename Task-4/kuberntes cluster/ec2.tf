resource "aws_instance" "Master" {
  ami           = lookup(var.Master_var,"ami")
  instance_type = lookup(var.Master_var, "itype")
  vpc_security_group_ids= [lookup(var.Master_var,"secgroupname")]
  key_name = lookup(var.Master_var,"keyname")
  user_data = <<EOF
  #!/bin/bash
  hostnamectl set-hostname master
  EOF
  tags = {
    Name = lookup(var.Master_var,"hostname")
  }
}

resource "aws_instance" "Worker" {
  ami           = lookup(var.Worker_var,"ami")
  instance_type = lookup(var.Worker_var, "itype")
  vpc_security_group_ids = [lookup(var.Worker_var,"secgroupname")]
  key_name = lookup(var.Worker_var,"keyname")
  user_data = <<EOF
  #!/bin/bash
  hostnamectl set-hostname worker1
  EOF

  tags = {
    Name = lookup(var.Worker_var,"hostname")
  }
}

resource "null_resource" "provision_cluster_member_MAster_hosts_file" {

  connection {
    type = "ssh"
    host =  aws_instance.Master.public_ip
    user = "ubuntu"
    private_key = file(var.Master_var.pemkey)
  }
  provisioner "remote-exec" {
    inline = [
      # Adds all cluster members' IP addresses to /etc/hosts (on each member)
      "sudo hostnamectl set-hostname Master",
      "echo '${join("\n", formatlist("%v", aws_instance.Master.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Master nodes:\" }; { print $0 \" ${var.Master_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null",
      "echo '${join("\n", formatlist("%v", aws_instance.Worker.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Worker nodes:\" }; { print $0 \" ${var.Worker_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null",
    ]
  }
}

resource "null_resource" "provision_cluster_member_worker_hosts_file" {

  connection {
    type = "ssh"
    host =  aws_instance.Worker.public_ip
    user = "ubuntu"
    private_key = file(var.Master_var.pemkey)
  }
  provisioner "remote-exec" {
    inline = [
      # Adds all cluster members' IP addresses to /etc/hosts (on each member)
      "sudo hostnamectl set-hostname worker1",
      "echo '${join("\n", formatlist("%v", aws_instance.Master.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Master nodes:\" }; { print $0 \" ${var.Master_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null",
      "echo '${join("\n", formatlist("%v", aws_instance.Worker.private_ip))}' | awk 'BEGIN{ print \"\\n\\n# K8 cluster Worker nodes:\" }; { print $0 \" ${var.Worker_var.hostname}\"}' | sudo tee -a /etc/hosts > /dev/null",
    ]
  }
}
#copy the pem file to ansible inventory location

resource "null_resource" "setting_private_ip_in_ansible_file" {
  provisioner "local-exec" {
    working_dir = "k8-cluster-ansible/"  #path of ansible files
    command = <<EOT
    sleep 3m
    sed -i 's/master ansible_host=master-public-ip/master ansible_host=${aws_instance.Master.public_ip}/g' inventory.ini
    sed -i 's/worker1 ansible_host=worker-public-ip/worker1 ansible_host=${aws_instance.Worker.public_ip}/g' inventory.ini
    sed -i 's/--apiserver-advertise-address master-private-ip/--apiserver-advertise-address ${aws_instance.Master.private_ip}/g' k8-master-init.yaml
    ansible-playbook -i inventory.ini k8-requirement.yaml
    ansible-playbook -i inventory.ini k8-master-init.yaml
    ansible-playbook -i inventory.ini k8-join-node.yaml
    sed -i 's/master ansible_host=${aws_instance.Master.public_ip}/master ansible_host=master-public-ip/g' inventory.ini
    sed -i 's/worker1 ansible_host=${aws_instance.Worker.public_ip}/worker1 ansible_host=worker-public-ip/g' inventory.ini
    sed -i 's/--apiserver-advertise-address ${aws_instance.Master.private_ip}/--apiserver-advertise-address master-private-ip/g' k8-master-init.yaml
    EOT
}
}
