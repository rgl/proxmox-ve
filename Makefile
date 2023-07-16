VAR_FILE :=
VAR_FILE_OPTION := $(addprefix -var-file=,$(VAR_FILE))

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-virtualbox, make build-hyperv, or make build-vsphere

build-libvirt: proxmox-ve-amd64-libvirt.box
build-uefi-libvirt: proxmox-ve-uefi-amd64-libvirt.box
build-virtualbox: proxmox-ve-amd64-virtualbox.box
build-hyperv: proxmox-ve-amd64-hyperv.box
build-vsphere: proxmox-ve-amd64-vsphere.box

proxmox-ve-amd64-libvirt.box: provisioners/*.sh proxmox-ve.json Vagrantfile.template $(VAR_FILE)
	rm -f $@
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-libvirt -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 $@

proxmox-ve-uefi-amd64-libvirt.box: provisioners/*.sh proxmox-ve.json Vagrantfile-uefi.template $(VAR_FILE)
	rm -f $@
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-uefi-amd64-libvirt -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-uefi-amd64 $@

proxmox-ve-amd64-virtualbox.box: provisioners/*.sh proxmox-ve.json Vagrantfile.template $(VAR_FILE)
	rm -f $@
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-virtualbox -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 $@

proxmox-ve-amd64-hyperv.box: provisioners/*.sh proxmox-ve.json Vagrantfile.template $(VAR_FILE)
	rm -f $@
	mkdir -p tmp
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-hyperv -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.json
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 $@

proxmox-ve-amd64-vsphere.box: provisioners/*.sh proxmox-ve-vsphere.json $(VAR_FILE)
	rm -f $@
	mkdir -p tmp
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=proxmox-ve-amd64-vsphere -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve-vsphere.json
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@echo Box successfully built!
	@echo to add it to vagrant run:
	@echo vagrant box add -f proxmox-ve-amd64 $@

clean:
	rm -rf packer_cache $${PACKER_OUTPUT_BASE_DIR:-.}/output-proxmox-ve*

.PHONY: help build-libvirt build-virtualbox build-hyperv clean
