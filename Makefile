all: proxmox-ve-amd64-virtualbox.box

proxmox-ve-amd64-virtualbox.box: *.sh proxmox-ve.json .update-iso-metadata-cookie
	rm -f proxmox-ve-amd64-virtualbox.box
	packer build proxmox-ve.json
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

.PHONY: all clean
