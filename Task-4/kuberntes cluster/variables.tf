variable "Master_var" {
    type = map
    default = {
    hostname="Master"
    region = "us-east-1"
    vpc = "vpc-049cbab08257b010d"
    ami = "ami-0c7217cdde317cfec"
    itype = "t2.medium"
    subnet = "subnet-07f3aed903e7c2793"
    publicip = true
    keyname = "basic"
    secgroupname = "sg-0645a10965e1d2e65"
    pemkey = "basic.pem"
  }
}

variable "Worker_var" {
    type = map
    default = {
    hostname="Worker"
    region = "us-east-1"
    vpc = "vpc-00c8ac1c65622bea1"
    ami = "ami-0c7217cdde317cfec"
    itype = "t2.medium"
    subnet = "subnet-07f3aed903e7c2793"
    publicip = true
    keyname = "basic"
    secgroupname = "sg-0645a10965e1d2e65"
    pemkey = "basic.pem"
  }
}
