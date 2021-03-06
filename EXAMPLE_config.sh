#!/bin/bash

# Build output directory. You can put your webserver root here to have the files be automatically downloadable.
BUILDDIR="build"

# Additional dirs to link the built files to from the original build directory. Typically $HOME/.nexuiz/data
# Warning: already existing RocketMinsta files will be overwritten
# Set to an empty string to disable linking
LINKDIRS=("$HOME/.nexuiz/data")

# File name for the compiled server QC module
SVPROGS="rocketminsta_sv.dat"

# File name for the compiled client QC module
CSPROGS="rocketminsta_cl.dat"

# List of QuakeC compillers the script will attempt to use
# Full and relative paths are allowed
QCC=("rmqcc" "fteqcc" "qcc" "$HOME/bin/rmqcc" "$HOME/bin/fteqcc" "$HOME/bin/qcc")

# Additional flags to pass to the QuakeC compiller
QCCFLAGS="-O3"

# Where QuakeC source is located
QCSOURCE="qcsrc"

# A list of optional client packages to build.
# These packages are a part of RocketMinsta, but aren't built automatically. They have a prefix of "o_".
# Do NOT put the prefix here (to include o_derp.pk3dir, just put 'derp'). The syntax is the same as of the QCC array
BUILDPKG_OPTIONAL=(-)

# A list of custom client packages to build.
# These packages act just like optional packages, except they are not a part of RocketMinsta and are ignored by git
# They have a prefix of "c_". 
BUILDPKG_CUSTOM=(-)

# A list of client packages that will NOT be built
# These are packages WITHOUT o_ or c_ prefixes, do not touch this option unless you really know what are you doing
IGNOREPKG=(-)

# Pack the client QC program for transfering over http together with other data packages
# Creates some redundancy, but is more reliable than the udp-based csqc transfer of DarkPlaces
PACKCSQC=1

# If this option is enabled, built packages will be stored and referenced later when you rebuild the mod,
# to save time by not rebuilding the same package over and over again. But if you made changes to the package,
# it will be, of course, rebuilt. This option is only useful if you're a developer who constantly needs to rebuild the mod
CACHEPKGS=0

# Directory to cache the packages
CACHEDIR="pkgcache"

# Like CACHEPKGS, but caches compilled QuakeC code
CACHEQC=0

# Use the DarkPlaces autocvars instead of cvar/cvar_string calls where possible
# This increases performance, however, it's not supported by the default Nexuiz engine.

# Use autocvars in the server program. Enable this if your server runs DPRM.
AUTOCVARS_SVQC=1

# Use autocvars in the client program. Not recommended, as it will make vanilla clients incompatible with your server.
# Setting this variable to 2 will compile two versions of the client program: one that supports autocvars and a fallback for old clients.
# This requires the DP_RM_ALTCSPROGS extension on the server and on the clients wishing to use autocvars (otherwise they'll just get the fallback program)
AUTOCVARS_CSQC=0

# Use autocvars in the menu program. Not recommended, as it will make vanilla clients incompatible with your server.
AUTOCVARS_MENU=0

# If enabled, some graphics in client packages will be compressed as lower quality jpgs to reduce the package size
# The list of directories to compress is specified in the "compressdirs" file of the package's directory, if present
# Requires ImageMagick, will be automatically disabled if not installed
COMPRESSGFX=1

# Will get passed to the -quality parameter of 'convert'
COMPRESSGFX_QUALITY=85

# Release branch override. Normally empty.
BUILDNAME=""
