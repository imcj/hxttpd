include ../Makefile.config

NDLLS=threadextra.ndll tmpfile.ndll hive.ndll
LIBPATH=-L/usr/lib
INCPATH=-I ./ -I /usr/include/neko
LIBS=-lneko

all: archtest $(NDLLS) install

%.ndll: %.o
	$(CC) -Wfatal-errors $(LIBPATH) $(INCPATH) -Wall -shared -o $@ $< $(LIBS)

%.o: %.c
	$(CC) -Wfatal-errors -c $(INCPATH) -Wall -o $@ $<

install:
	@mv *.ndll ../ndll/$(ARCH_CAP)

clean: distclean
	@rm -f ../ndll/Linux/*
	@rm -f ../ndll/Windows/*
	@rm -f ../ndll/Mac/*
	@rm -f ../ndll/BSD/*

distclean:
	@rm -f *.o

archtest:
	@if [ "L$(ARCH_CAP)" == "L" ]; then \
		echo "You must specify the architecture to build for (make ARCH=?): "; \
		echo " ARCH: linux windows mac bsd wine"; \
		exit 1; \
	fi;

