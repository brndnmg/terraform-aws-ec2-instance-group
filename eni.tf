locals {
  additional_ips_count = var.associate_public_ip_address && module.this.enabled && var.additional_ips_count > 0 ? var.additional_ips_count : 0
}

resource "aws_network_interface" "additional" {
  count           = local.additional_ips_count * var.instance_count
  subnet_id       = element(var.subnet_ids, count.index)
  security_groups = compact(concat(module.security_group.*.id, var.security_groups))

  tags       = module.label.tags
  depends_on = [aws_instance.default]
}

resource "aws_network_interface_attachment" "additional" {
  count                = local.additional_ips_count * var.instance_count
  instance_id          = aws_instance.default.*.id[count.index % var.instance_count]
  network_interface_id = aws_network_interface.additional.*.id[count.index]
  device_index         = 1 + count.index
  depends_on           = [aws_instance.default]
}

resource "aws_eip" "additional" {
  count             = var.enable_additional_eips ? local.additional_ips_count * var.instance_count : 0
  vpc               = true
  network_interface = aws_network_interface.additional.*.id[count.index]
  depends_on        = [aws_instance.default]
}
