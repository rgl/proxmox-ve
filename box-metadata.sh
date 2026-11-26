#!/bin/bash
set -euo pipefail

provider="$1"
name="$2"
path="$3"

# see https://developer.hashicorp.com/vagrant/docs/boxes/format#box-metadata
# see https://developer.hashicorp.com/vagrant/docs/boxes/format#box-file
# see https://github.com/hashicorp/packer-plugin-vagrant/blob/v1.1.7/post-processor/vagrant/libvirt.go#L105-L109
# see https://github.com/vagrant-libvirt/vagrant-libvirt/blob/0.12.2/spec/unit/action/handle_box_image_spec.rb#L97-L127
# see https://github.com/vagrant-libvirt/vagrant-libvirt/blob/0.12.2/lib/vagrant-libvirt/action/handle_box_image.rb
# see https://github.com/vagrant-libvirt/vagrant-libvirt/blob/0.12.2/docs/boxes.markdown
cat >"$path.json" <<EOF
{
  "name": "$name",
  "versions": [
    {
      "version": "0.0.0",
      "providers": [
        {
          "name": "$provider",
          "url": "$path"
        }
      ]
    }
  ]
}
EOF
cat <<EOF

Add the Vagrant Box with:

vagrant box add -f $name $path.json
EOF
