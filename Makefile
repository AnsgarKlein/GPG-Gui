
PACKAGES	=	--pkg gtk+-3.0

CC		=	valac
CFLAGS		=	$(PACKAGES) -X -O3
SOURCES		=	src/*.vala

BINARYDIR	=	build/
BINARY		=	gpggui




all: $(BINARYDIR)$(BINARY)
	@echo "Compiling complete"

clean:
	rm $(BINARYDIR)$(BINARY)
	@echo "Cleaned everything successfully"

install:
	cp $(BINARYDIR)$(BINARY) /usr/bin/$(BINARY)
	@echo "Installed everything successfully"

uninstall:
	rm /usr/bin/$(BINARY)
	@echo "Uninstalled everything successfully"




$(BINARYDIR)$(BINARY): $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o $(BINARYDIR)$(BINARY) 
