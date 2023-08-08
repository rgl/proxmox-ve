SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VAR_FILE :=
VAR_FILE_OPTION := $(addprefix -var-file=,$(VAR_FILE))

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-proxmox, make build-uefi-proxmox, make build-virtualbox, make build-hyperv, or make build-vsphere

build-libvirt: proxmox-ve-amd64-libvirt.box
build-uefi-libvirt: proxmox-ve-uefi-amd64-libvirt.box
build-proxmox: proxmox-ve-amd64-proxmox.box
build-uefi-proxmox: proxmox-ve-uefi-amd64-proxmox.box
build-virtualbox: proxmox-ve-amd64-virtualbox.box
build-hyperv: proxmox-ve-amd64-hyperv.box
build-vsphere: proxmox-ve-amd64-vsphere.box

proxmox-ve-amd64-libvirt.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile.template $(VAR_FILE)
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.proxmox-ve-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl
	@./box-metadata.sh libvirt proxmox-ve-amd64 $@

proxmox-ve-uefi-amd64-libvirt.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile-uefi.template $(VAR_FILE)
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.proxmox-ve-uefi-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl
	@./box-metadata.sh libvirt proxmox-ve-uefi-amd64 $@

proxmox-ve-amd64-proxmox.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile.template $(VAR_FILE)
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.proxmox-ve-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl

proxmox-ve-uefi-amd64-proxmox.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile.template $(VAR_FILE)
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.proxmox-ve-uefi-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl

proxmox-ve-amd64-virtualbox.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile.template $(VAR_FILE)
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=virtualbox-iso.proxmox-ve-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl
	@./box-metadata.sh virtualbox proxmox-ve-amd64 $@

proxmox-ve-amd64-hyperv.box: provisioners/*.sh proxmox-ve.pkr.hcl Vagrantfile.template $(VAR_FILE)
	rm -f $@
	mkdir -p tmp
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=hyperv-iso.proxmox-ve-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve.pkr.hcl
	@./box-metadata.sh hyperv proxmox-ve-amd64 $@

proxmox-ve-amd64-vsphere.box: provisioners/*.sh proxmox-ve-vsphere.pkr.hcl $(VAR_FILE)
	rm -f $@
	mkdir -p tmp
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init proxmox-ve-vsphere.pkr.hcl
	PACKER_OUTPUT_BASE_DIR=$${PACKER_OUTPUT_BASE_DIR:-.} \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
		packer build -only=vsphere-iso.proxmox-ve-amd64 -on-error=abort -timestamp-ui $(VAR_FILE_OPTION) proxmox-ve-vsphere.pkr.hcl
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@./box-metadata.sh vsphere proxmox-ve-amd64 $@

clean:
	rm -rf packer_cache $${PACKER_OUTPUT_BASE_DIR:-.}/output-proxmox-ve*

.PHONY: help build-libvirt build-virtualbox build-hyperv clean
