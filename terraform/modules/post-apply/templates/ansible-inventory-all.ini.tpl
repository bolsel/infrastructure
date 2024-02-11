%{~ for groupKey,groups in data }
[${groupKey}]
%{~ for key,vm in groups }
${vm.hostname} ansible_host=${vm.primary_ip} ip=${vm.primary_ip} access_ip=${vm.primary_ip}
%{~ endfor }
%{~ endfor }
