help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: proxmox-ve-amd64-libvirt.box

build-virtualbox: proxmox-ve-amd64-virtualbox.box

proxmox-ve-amd64-libvirt.box: *.sh proxmox-ve.json Vagrantfile.template
	rm -f proxmox-ve-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms packer build -only=proxmox-ve-amd64-libvirt -on-error=abort proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box

proxmox-ve-amd64-virtualbox.box: *.sh proxmox-ve.json Vagrantfile.template
	rm -f proxmox-ve-amd64-virtualbox.box
	packer build -only=proxmox-ve-amd64-virtualbox -on-error=abort proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-virtualbox.box

clean:
	rm -rf packer_cache output-proxmox-ve*

.PHONY: help build-libvirt build-virtualbox clean
