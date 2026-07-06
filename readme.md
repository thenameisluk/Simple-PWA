# Simple pwa (aka website as an app) for Linux Mobile (or not)

![screenshot](./screenshot.png)

this program literaly opens a website in a borderless window.

all the data is stored in `~/.local/share/pwa`

usefull for installing pwa as an app on your linux phone.

might also be used for a kiosk ig, it's simple enough that it can be extended to do whatever.

while there are alternatives like [spider](https://flathub.org/en/apps/io.github.zaedus.spider) these do have borders

and also use flatpak which are pain points for me.

I'm not really interested in writing nor reading rust code so here we are.

Simple single file pwa app without any sandboxes written in vala. ~~just like the god intended :3~~

## Usage
simply run
```
pwa https://music.youtube.pl
```
you can also setup a desktop file for it


you can pick from examples in `examples/` directory

modify them or keep them as they are and put them in `~/.local/share/applications/`

make sure to name them like `google.pl.desktop` otherwise the icon will not work

the icon should apper after openning the website in pwa and rebooting or running

```
gtk4-update-icon-cache -f -t ~/.local/share/icons/hicolor/
```

## Building

first install dependiecies

```
sudo apt install libgtk-4-dev libwebkitgtk-6.0-dev libglib2.0-dev valac pkg-config make
#or
sudo apt build-dep .
```
then build
```
make
```
alternatively if you want a .deb file
```
dpkg-buildpackge -b
```

## To-do/Things to improve

- write simple helper program to setup desktop files automatically
- dynamically load favicon as app icon?
- add zoom, rounded corners or other arguments
- figure out how to block pinch zoom (on touch screen)
	supper annoying one
	there is no webkit method i'm aware of (if someone know how to do it feel free to submit a pr)
	i triend stuff (look at ``disable_pinch_zoom` function)
