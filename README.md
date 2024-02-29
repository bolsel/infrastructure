# Infrastructure Bolsel

## :link: Links
  - [Ansible](https://docs.ansible.com/)
  - [Docker](https://docs.docker.io/)
  - [Kubernetes](https://kubernetes.io/)
  - [Kubespray](https://kubespray.io/)
  - [Microk8s](https://microk8s.io/)
  - [Smallstep](https://smallstep.com/docs/)
  - [Terraform](https://www.terraform.io/)
  - [VSCode](https://code.visualstudio.com/)

## Terraform

jalankan terraform pada directory [**terraform**](./terraform/)

ganti *dir* dengan nama folder. ex: `make tf-plan f=cloudlare` atau `make tf-plan f=vcd/k8s`
### plan

```shell
make tf-plan f=dir
```  

### apply

```shell
make tf-apply f=dir
```  

## Build inventory

setelah *terraform apply*, build ansible inventory dari data state terraform.

```shell
# build semua data state
make build-inventory

# build single data state. 
# ganti statefilename dengan nama file data state
make build-inventory f=statefilename
```

## Plays

ganti *inventory_dirname* dengan nama folder di *.private/inventories/* atau *inventory/*

### playbooks 

jalankan ansible playbook pada file-file di folder [playbooks/](./playbooks).

 ganti *namafile.yml* dengan nama file playbooks.

```shell
make play inventory=inventory_dirname r="namafile.yml"

# menambahkan ansible-playbook argument
make play inventory=inventory_dirname r="namafile.yml --limit master --tags install,configure"
```

contoh, deploy *cloudflared* tunnel playbook pada semua host di *vcd-cloudflared* inventory

```shell
make play inventory=vcd-cloudflared r="cloudflared.yml"
```

### plays role

jalankan task-task pada [roles/plays/](./roles/plays/)

ganti *namatask* dengan file task pada [roles/plays/tasks/](./roles/plays/tasks/) (tanpa extensi).

```shell
make play inventory=inventory_dirname t="namatask"

# menambahkan ansible-playbook argument
make play inventory=inventory_dirname t="namatask" r="--limit master --tags install,configure"
```

contoh, melakukan *ping* task ke *master* host pada *vcd-k8s* inventory

```shell
make play inventory=vcd-k8s t=ping r="--limit master"
```