CC=gcc
NDLLS=threadextra.ndll tmpfile.ndll hive.ndll
LIBPATH=
INCPATH=-I ./ -I /usr/include/neko
LIBS=-lneko

all: $(NDLLS) install

%.ndll: %.o
	$(CC) -Wfatal-errors $(LIBPATH) $(INCPATH) -Wall -shared -o $@ $< $(LIBS)

%.o: %.c
	$(CC) -Wfatal-errors -c $(INCPATH) -Wall -o $@ $<

install:
	@mv *.ndll ../bin

clean:
	@rm -f *.o
	@rm -f *.ndll

