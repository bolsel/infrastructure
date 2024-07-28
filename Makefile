SHELL := /bin/bash

ansible-cloudflared:
	ansible-playbook -i .private/inventory/cloudflared.ini playbooks/cloudflared.yml

tf-init:
	cd terraform/$(f) && terraform init

tf-plan:
	cd terraform/$(f) && terraform plan

tf-apply:
	cd terraform/$(f) && terraform apply --auto-approve

build-inventory:
	ansible-playbook -i localhost playbooks/build-inventory/main.yml -e single=$(f)

play:
	ANSIBLE_CACHE_PLUGIN_PREFIX=$(inventory)_ \
	ansible-playbook -i inventory/$(inventory) $(r)

plays:
	ANSIBLE_CACHE_PLUGIN_PREFIX=$(inventory)_ \
	ansible-playbook -i inventory/$(inventory) plays.yml -e task=$(t) $(r)

play-vcd-k8s-kubespray:
	cd tools/kubespray && \
	source venv/bin/activate && \
	ANSIBLE_REMOTE_USER=automation \
	ANSIBLE_PRIVATE_KEY_FILE=../../.private/ssh-keys/automation \
	ANSIBLE_CACHE_PLUGIN_CONNECTION=../../local/ansible_facts \
	ANSIBLE_CACHE_PLUGIN_PREFIX=vcd-kubernetes_ \
	ansible-playbook -i ../../inventory/vcd-kubernetes --become --become-user=root $(r)

play-vcd-k8sdev-kubespray:
	cd tools/kubespray && \
	source venv/bin/activate && \
	ANSIBLE_REMOTE_USER=automation \
	ANSIBLE_PRIVATE_KEY_FILE=../../.private/ssh-keys/automation \
	ANSIBLE_CACHE_PLUGIN_CONNECTION=../../local/ansible_facts \
	ANSIBLE_CACHE_PLUGIN_PREFIX=vcd-k8sdev_ \
	ansible-playbook -i ../../inventory/vcd-k8sdev --become --become-user=root $(r)
