network:
  version: 2
  ethernets:
  %{~ for v in vm.network ~}
    ${networks_config[v.name].if_name}: 
      %{~ if v.ip_allocation_mode == "MANUAL" ~}
      addresses:
        - ${v.ip}/${ can(networks_config[v.name].prefix) ? networks_config[v.name].prefix: "24"}
      %{~ else ~}
      dhcp4: yes 
      dhcp-identifier: mac
      %{~ endif ~}
      match:
        macaddress: ${v.mac}
      set-name: ${networks_config[v.name].if_name}
  %{~ endfor ~}
