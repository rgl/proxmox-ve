// developed by Rui Lopes (ruilopes.com). licensed under GPLv3.

// TODO set a global timeout and abort the process if it expires.

phantom.onError = function(msg, trace) {
  var msgStack = ["PHANTOM ERROR: " + msg];
  if (trace && trace.length) {
    msgStack.push("TRACE:");
    trace.forEach(function(t) {
      msgStack.push(" -> " + (t.file || t.sourceURL) + ": " + t.line + (t.function ? " (in function " + t.function + ")" : ""));
    });
  }
  console.error(msgStack.join("\n"));
  phantom.exit(2);
};

function printArgs() {
  var i, ilen;
  for (i = 0, ilen = arguments.length; i < ilen; ++i) {
    console.log("    arguments[" + i + "] = " + JSON.stringify(arguments[i]));
  }
  console.log("");
}

function open(url, cb) {
  var page = require("webpage").create();

  // window.console.log(msg);
  //page.onConsoleMessage = function() {
  //  console.log("page console:");
  //  printArgs.apply(this, arguments);
  //};

  // NB even thou the global phantom.onError should have run when there is a
  //    page error... in practice, it does not happen on phantom 1.9.7... so
  //    set the handler on the page too.
  // See https://github.com/ariya/phantomjs/wiki/API-Reference-phantom#onerror
  page.onError = phantom.onError;

  page.open(url, function(status) { cb(page, status); });
}

// as-of phantomjs 1.9.7, things returned from page.evaluate are read-only,
// this function makes them read-write by JSON serializing.
function rw(o) {
  return JSON.parse(JSON.stringify(o));
};

function getIndexFromPage(page) {
  return page.evaluate(function() {
    var $$ = function(selector) {
      return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
    };

    // look for html alike:
    //  <div class="teaser-item">
    //    <div class="pos-media media-right">
    //      <a
    //        class="yoo-zoo element-download-type element-download-type-iso"
    //        href="/en/downloads?task=callelement&amp;format=raw&amp;item_id=229&amp;element=f85c494b-2b32-4109-b8c1-083cca2b7db6&amp;method=download&amp;args[0]=6254c27c1d16d0ebc386fb86e29eefff"
    //        title="Download proxmox-ve_4.4-eb2d6f1e-2.iso"></a>
    //    </div>
    //	  <h2 class="pos-title">
    //      <a
    //        title="Proxmox VE 4.4 ISO Installer"
    //        href="/en/downloads/item/proxmox-ve-4-4-iso-installer">
    //          Proxmox VE 4.4 ISO Installer</a>
    //    </h2>
    //    <p class="pos-meta">Updated on 15 December 2016</p>
    //    <ul class="pos-specification">
    //      <li class="element element-text first last">
    //        <strong>Version: </strong>4.4-eb2d6f1e-2
    //      </li>
    //    </ul>
    //    <div class="pos-button">
    //      <a
    //        class="yoo-zoo element-download-button"
    //        href="/en/downloads?task=callelement&amp;format=raw&amp;item_id=229&amp;element=f85c494b-2b32-4109-b8c1-083cca2b7db6&amp;method=download&amp;args[0]=6254c27c1d16d0ebc386fb86e29eefff"
    //        title="Download proxmox-ve_4.4-eb2d6f1e-2.iso">
    //          <span><span>Download</span></span>
    //      </a>
    //    </div>
    //  </div>
    //
    // and return something like:
    //    [
    //      {
    //        name: "Proxmox VE 4.4 ISO Installer",
    //        version: "4.4-eb2d6f1e-2",
    //        date: "15 December 2016",
    //        url: "https://www.proxmox.com/en/downloads/item/proxmox-ve-4-4-iso-installer",
    //        iso_url: "https://www.proxmox.com/en/downloads?task=callelement&amp;format=raw&amp;item_id=229&amp;element=f85c494b-2b32-4109-b8c1-083cca2b7db6&amp;method=download&amp;args[0]=6254c27c1d16d0ebc386fb86e29eefff",
    //      }
    //    ]

    var index = $$("div.teaser-item").map(function(el) {
      var titleEl = el.querySelector("h2 a");
      var metaEl = el.querySelector(".pos-meta");
      var specificationEl = el.querySelector(".pos-specification");
      var downloadEl = el.querySelector(".element-download-button");
      return {
        name: titleEl.title,
        version: specificationEl.innerText.replace("Version: ", "").trim(),
        date: metaEl.innerText.replace("Updated on ", "").trim(),
        url: titleEl.href,
        iso_url: downloadEl.href,
        iso_checksum: ""
      };
    });

    return index;
  }).filter(function(v) {
    return v &&
            !v.name.match("BitTorrent");
  });
}

function getLatestVersion(cb) {
  open("https://www.proxmox.com/en/downloads/category/iso-images-pve", function(page, status) {
    if (status !== "success") {
      console.log("ERROR: Unable to access network:", status);
      phantom.exit(1);
      return;
    }

    var index = rw(getIndexFromPage(page));

    page.close();

    var version = index[0];

    open(version.url, function(page, status) {
      if (status !== "success") {
        console.log("ERROR: Unable to access network:", status);
        phantom.exit(1);
        return;
      }

      version.iso_checksum = page.evaluate(function() {
        var m = document.querySelector(".download-default .element-textarea").innerText.match(/MD5SUM for the ISO is ([a-f0-9]+)/)
        return m[1];
      });

      page.close();

      cb(version);
    });
  });
}

function main() {
  console.log('Fetching latest proxmox iso metadata...');
  getLatestVersion(function(version) {
    var fs = require('fs');
    var originalTemplate = fs.read('proxmox-ve.json');
    var template = originalTemplate;
    var t = JSON.parse(originalTemplate);

    if (t.variables.iso_url != version.iso_url) {
      template = template.replace(/("iso_url": )"[^{"]+"/, '$1"'+version.iso_url+'"');
    }

    if (t.variables.iso_checksum != version.iso_checksum) {
      template = template.replace(/("iso_checksum": )"[^{"]+"/, '$1"'+version.iso_checksum+'"');
    }

    if (template != originalTemplate) {
      console.log('iso metadata updated to match:');
      console.log(JSON.stringify(version, null, 2));
      fs.write('proxmox-ve.json', template, 'w');
    } else {
      console.log('iso metadata is already up to date');
    }

    phantom.exit(0);
  });
}

main();
