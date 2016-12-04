proxmox-ve-amd64-virtualbox.box: *.sh proxmox-ve.json
	rm -f proxmox-ve-amd64-virtualbox.box
	packer build proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-virtualbox.box
