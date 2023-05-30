# main.tf

module "ec2_cluster" {
  source = "./path/to/module"

  multiplas_ec2   = false
  quantidade_ec2  = 1
  role            = "indexer"
  cluster         = "teste"
}
