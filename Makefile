
PACKAGES	=	--pkg gtk+-3.0 --pkg vte-2.90

CC			=	valac
CFLAGS		=	$(PACKAGES)
SOURCES		=	src/*.vala

#############################################################################
#																			#
#																			#
#																			#
#																			#
#																			#
#																			#
#############################################################################


all: GPG-Gui
	#sucessfully compiled everything

install:
	
	#not yet implemented

clean:
	rm GPG-Gui
	#sucessfully cleaned everything


GPG-Gui: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o GPG-Gui
