# Swift X11 in Xcode

An example Xcode project showing how to write an X11 app on OS X

## Prerequisites

Install Quartz using [Homebrew Cask](https://github.com/caskroom/homebrew-cask) or directly from [Sourceforge](http://www.xquartz.org)

```
$ brew cask install xquartz
```

After installing XQuartz, **you will need to logout**. Log back in and ensure the `DISPLAY` environment variable is set up:

```
$ echo $DISPLAY
/private/tmp/com.apple.launchd.uk0lyyi1Ny/org.macosforge.xquartz:0
```

If this is empty, your XQuartz installation may have failed.

## Getting Started

Link the header files into `/usr/local/include/X11` and libraries into `/usr/local/lib/X11`:

```
$ ln -s /usr/X11/include/X11 /usr/local/include
$ ln -s /usr/X11/lib /usr/local/lib/X11
```

## Building using Xcode

In the Xcode project, under build settings, import the following paths to the search path:

1. `$(SRCROOT)/CX11` for the CX11 module
2. `/usr/local/include/X11` for the X11 headers

![Import paths](http://puu.sh/o1r7Z/6983640e2d.png)

Also under build settings, import the following library search path `/usr/local/lib/X11`:

![Import library search path](http://puu.sh/o1t8k/5903ca00ac.png)

Under build phases, link the binary with `libX11.6.dylib`. Under the "Choose frameworks and libraries to add" drop sheet, select "Add Other" and locate `/usr/local/lib/X11/libX11.6.dylib`.

![Import libx11](http://puu.sh/o1r9v/445a91739d.png)

## Building using `xcrun` and `swiftc`

Navigate to `main.swift`

Run:

```$bash
$ cd /path/to/main.swift
$ xcrun \
    -sdk macosx \                # Include OS X SDK    
    swiftc main.swift \          # Compile main.swift
    -lX11 -L/usr/local/lib/X11 \ # Include X11 dylib
    -I/usr/local/include/X11 \   # Include X11 headers
    -I$(pwd)/../CX11             # Include CX11 module
```

## Screenshot

![Running via Xcode](http://puu.sh/o1GIp/201eaa29f0.png)

## Attribution

Thanks to [@terhechte](https://github.com/terhechte) for his [Linux example](https://github.com/terhechte/swift-x11-example) and [CX11 package](https://github.com/terhechte/CX11.swift) (slightly modified to support El Capitan's [rootless system](http://apple.stackexchange.com/questions/193368/what-is-the-rootless-feature-in-el-capitan-really))

