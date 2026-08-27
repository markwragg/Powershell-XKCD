# Change Log

## [1.5.0] - 2026-08-27

* Adds a new `Show-XKCD` cmdlet which displays a comic's title, image, and alt text directly in the console. The image is rendered inline if your terminal supports the Sixel, Kitty, or iTerm2 graphics protocol.
* Adds a `-Show` switch to `Get-XKCD` as a shorthand for `Get-XKCD | Show-XKCD`. Note that when `-Show` is used the comic object is not returned.
* `-HighQuality` now also applies when using `-Show` or `Show-XKCD`, displaying the higher resolution (_2x) version of the image where available.

## [1.4.82] - 2026-08-27

* Implements `-HighQuality` switch to download the high quality version of the image where available per Issue [#8](https://github.com/markwragg/Powershell-XKCD/issues/8). Thanks [@nlsdg](https://github.com/nlsdg)!
* Fixes download of image with incorrect extension per Issue [#9](https://github.com/markwragg/Powershell-XKCD/issues/9). Thanks [@nlsdg](https://github.com/nlsdg)!

## [1.4.81] - 2020-02-25

* Test deployment.
