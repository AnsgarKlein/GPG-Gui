
PACKAGES    = gtk+-3.0
PACKAGES   += glib-2.0

VALAC       = valac
CFLAGS      = -O3
CFLAGS     += -DGETTEXT_PACKAGE
VFLAGS      = $(addprefix --pkg , $(PACKAGES))
VFLAGS     += $(addprefix -X , $(CFLAGS))
SOURCES     = $(wildcard src/*.vala)

BINARYDIR   = build
BINARY      = gpg-gui

.PHONY: all clean install uninstall

all: $(BINARYDIR)/$(BINARY)
	@#

clean:
	@rm -f $(BINARYDIR)/$(BINARY)

install:
	cp $(BINARYDIR)/$(BINARY) /usr/bin/$(BINARY)

uninstall:
	rm -f /usr/bin/$(BINARY)


$(BINARYDIR)/$(BINARY): $(SOURCES)
	$(VALAC) $(VFLAGS) $(SOURCES) -o $@
