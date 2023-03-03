output "instance" {
  value = module.vms.instances["registry"]["registry-0"].public_ip
}
