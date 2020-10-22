
PACKAGES    = gtk+-3.0

VALAC       = valac
CFLAGS      = -O3
VFLAGS      = $(addprefix --pkg , $(PACKAGES))
VFLAGS     += $(addprefix -X , $(CFLAGS))
SOURCES     = $(wildcard src/*.vala)

BINARYDIR   = build
BINARY      = gpggui

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
