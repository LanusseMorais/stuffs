# modules/ec2_cluster/main.tf

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

variable "role" {
  description = "Role da EC2"
  type        = string
  default     = ""
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
  default     = {}
}

resource "aws_instance" "ec2_instance" {
  count = var.multiplas_ec2 ? var.quantidade_ec2 : 1
  ami   = "ami-12345678" # Substitua pela AMI desejada

  dynamic "config" {
    for_each = var.multiplas_ec2 ? [var.role] : []
    content {
      instance_type   = var.clusters_configurations[var.cluster][config.key].instance_type
      root_block_device {
        volume_size = var.clusters_configurations[var.cluster][config.key].root_volume_size
      }

      # Distribuir instâncias em sub-redes diferentes (se multiplas_ec2 for verdadeiro)
      subnet_id = var.multiplas_ec2 ? element(var.subnets_ids, count.index % length(var.subnets_ids)) : var.subnets_ids[0]

      # Configuração de volumes EBS
      ebs_block_device {
        for_each = var.clusters_configurations[var.cluster][config.key].ebs_volumes

        device_name = each.value.device_name
        volume_type = each.value.volume_type
        volume_size = each.value.volume_size
      }

      tags = merge(
        var.clusters_configurations[var.cluster][config.key].tags,
        {
          "Environment" = "production"
          "Role"        = config.key
          "Cluster"     = var.cluster
        }
      )
    }
  }
}
