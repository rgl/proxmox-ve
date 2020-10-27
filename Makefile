help:
	@echo type make build-libvirt, make build-virtualbox or make build-hyperv

build-libvirt: proxmox-ve-amd64-libvirt.box
build-virtualbox: proxmox-ve-amd64-virtualbox.box
build-hyperv: proxmox-ve-amd64-hyperv.box

proxmox-ve-amd64-libvirt.box: *.sh proxmox-ve.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-libvirt -on-error=abort -timestamp-ui proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box

proxmox-ve-amd64-virtualbox.box: *.sh proxmox-ve.json Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-virtualbox -on-error=abort -timestamp-ui proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-virtualbox.box

proxmox-ve-amd64-hyperv.box: *.sh proxmox-ve.json Vagrantfile.template
	rm -f $@
	mkdir -p tmp
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-hyperv -on-error=abort -timestamp-ui proxmox-ve.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-hyperv.box

clean:
	rm -rf packer_cache output-proxmox-ve*

.PHONY: help build-libvirt build-virtualbox build-hyperv clean
