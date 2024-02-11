[all]
%{~ for vm in data}
${vm.hostname} ansible_host=${vm.primary_ip} ip=${vm.primary_ip} access_ip=${vm.primary_ip}
%{~ endfor }
