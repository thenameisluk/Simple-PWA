prefix = /usr/local

all: pwa

install:
	install pwa $(DESTDIR)$(prefix)/bin

clean:
	rm -f pwa

pwa: src/pwa.vala
	valac --pkg gtk4 --pkg webkitgtk-6.0 --pkg glib-2.0 src/pwa.vala -o pwa
