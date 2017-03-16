help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: proxmox-ve-amd64-libvirt.box

build-virtualbox: proxmox-ve-amd64-virtualbox.box

proxmox-ve-amd64-libvirt.box: *.sh proxmox-ve.json Vagrantfile.template .update-iso-metadata-cookie
	rm -f proxmox-ve-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms packer build -only=proxmox-ve-amd64-libvirt proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box

proxmox-ve-amd64-virtualbox.box: *.sh proxmox-ve.json Vagrantfile.template .update-iso-metadata-cookie
	rm -f proxmox-ve-amd64-virtualbox.box
	packer build -only=proxmox-ve-amd64-virtualbox proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-virtualbox.box

.update-iso-metadata-cookie:
	phantomjs update-iso-metadata.js
	git diff proxmox-ve.json
	touch $@

clean:
	rm -rf packer_cache output-proxmox-ve*
	rm -f .update-iso-metadata-cookie

.PHONY: help build-libvirt build-virtualbox clean
