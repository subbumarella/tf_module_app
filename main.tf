resource "null_resource" "ex" {
  provisioner "local-exec" {
    command = "echo this is ${var.environment} environment"
  }
}