# UI Tweaks Reloaded - A mod for Invisible Inc. by KLEI Entertainment

On Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2660875942

Forked from osheroff's UI Tweaks ([github](https:/github.com/osheroff/ui_tweaks)
[steam](https://steamcommunity.com/sharedfiles/filedetails/?id=581951281))


## Build From Source

Requires:

* `make`
* `zip`
* [KWAD Builder](http://forums.kleientertainment.com/index.php?app=core&module=attach&section=attach&attach_id=60753)
  (from the official
  [modding guide](https://steamcommunity.com/sharedfiles/filedetails/?id=551325449))

Copy `makeconfig.example.mk` to `makeconfig.mk`. This file provides local-specific variables to the Makefile.
* `KWAD_BUILDER`: Path to the KWAD builder binary (`bin/{OS}/builder` inside the zip file)
* `INSTALL_PATH`: Path to this mod's folder within your Invisible Inc. install path. (The example value is usually
  correct for a Steam install, filling in the steam directory.
* `INSTALL_PATH2` (optional): Path to an alternate mod folder. Useful if maintaining separate "all mods" and "active
  mods" paths.

```
make
```

Builds mod files. The generated `out/` directory contains everything, and can be passed to the official mod uploader.

```
make install
```

Builds mod files and installs them to the specified installation directory.

