SHELL := /bin/bash

build-inventory:
	ansible-playbook -i localhost playbooks/build-inventory/main.yml

play:
	ANSIBLE_CACHE_PLUGIN_PREFIX=$(inventory)_ \
	ansible-playbook -i .private/inventories/$(inventory) $(r)

play-vcd-kubernetes-kubespray:
	cd tools/kubespray && \
	source venv/bin/activate && \
	ANSIBLE_CACHE_PLUGIN_CONNECTION=../../local/ansible_facts \
	ANSIBLE_CACHE_PLUGIN_PREFIX=vcd-kubernetes_ \
	ansible-playbook -i ../../inventory/vcd-kubernetes --become --become-user=root $(r)
