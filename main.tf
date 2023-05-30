# main.tf

variable "multiplas_ec2" {
  description = "Indica se devem ser lançadas várias instâncias EC2"
  type        = bool
  default     = false
}

variable "quantidade_ec2" {
  description = "Quantidade de instâncias EC2 a serem lançadas"
  type        = number
  default     = 1
}

variable "subnets_ids" {
  description = "IDs das sub-redes onde as instâncias serão lançadas"
  type        = list(string)
  default     = []
}

variable "cluster" {
  description = "Nome do cluster"
  type        = string
  default     = ""
}

variable "clusters_configurations" {
  description = "Configurações de instâncias EC2 por tipo de cluster e role"
  type        = map(map(object({
    instance_type   = string
    ebs_volumes     = list(object({
      device_name = string
      volume_type = string
      volume_size = number
    }))
    root_volume_size = number
    tags             = map(string)
  })))
  default     = {
    teste = {
      indexer = {
        instance_type   = "c5.large"
        ebs_volumes     = [
          {
            device_name = "/dev/sdb"
            volume_type = "gp2"
            volume_size = 100
          }
        ]
        root_volume_size = 50
        tags = {
          "Environment" = "production"
          "Role"        = "indexer"
        }
      }
      worker = {
        instance_type   = "t3.medium"
        ebs_volumes     = [
          {
            device_name = "/dev/sdb"
            volume_type = "gp2"
            volume_size = 50
          },
          {
            device_name = "/dev/sdc"
            volume_type = "st1"
            volume_size = 200
          }
        ]
        root_volume_size = 50
        tags = {
          "Environment" = "production"
          "Role"        = "worker"
        }
      }
    }
    validacao = {
      indexer = {
        instance_type   = "c5.24xlarge"
        ebs_volumes     = [
          {
            device_name = "/dev/sdb"
            volume_type = "gp2"
            volume_size = 100
          }
        ]
        root_volume_size = 50
        tags = {
          "Environment" = "production"
          "Role"        = "indexer"
        }
      }
      worker = {
        instance_type   = "t3.medium"
        ebs_volumes     = [
          {
            device_name = "/dev/sdb"
            volume_type = "gp2"
            volume_size = 50
          },
          {
            device_name = "/dev/sdc"
            volume_type = "st1"
            volume_size = 200
          }
        ]
        root_volume_size = 50
        tags = {
          "Environment" = "production"
          "Role"        = "worker"
        }
      }
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "ec2_instance" {
  count         = var.multiplas_ec2 ? var.quantidade_ec2 : 1
  ami           = "ami-12345678" # Substitua pela AMI desejada

  # Verificar se o tipo de cluster e a role têm uma configuração definida
  dynamic "config" {
    for_each = var.clusters_configurations[var.cluster][var.role] != null ? [var.clusters_configurations[var.cluster][var.role]] : []
    content {
      instance_type   = config.value.instance_type
      root_block_device {
        volume_size = config.value.root_volume_size
      }
      
      # Distribuir instâncias em sub-redes diferentes (se multiplas_ec2 for verdadeiro)
      subnet_id = var.multiplas_ec2 ? element(var.subnets_ids, count.index % length(var.subnets_ids)) : var.subnet_id

      # Configuração de volumes EBS
      ebs_block_device {
        for_each = config.value.ebs_volumes

        device_name = each.value.device_name
        volume_type = each.value.volume_type
        volume_size = each.value.volume_size
      }

      tags = merge(
        var.clusters_configurations[var.cluster][var.role].tags,
        {
          "Environment" = var.clusters_configurations[var.cluster][var.role].tags["Environment"],
          "Role"        = var.role,
          "Cluster"     = var.cluster,
        }
      )
    }
  }
}
