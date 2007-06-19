CC=gcc
PLUGINS=mod_test.ndll
PLUGINS_HAXE=ModTest.n
#Mod_Test.n
LIBPATH=
INCPATH=-I /usr/include/neko
LIBS=-lneko

all: $(PLUGINS) $(PLUGINS_HAXE) install

%.ndll: %.o
	$(CC) -Wfatal-errors $(LIBPATH) $(INCPATH) -Wall -shared -o $@ $< $(LIBS)

%.o: %.c
	$(CC) -Wfatal-errors -c $(INCPATH) -Wall -o $@ $<

%.n: %.hx
	haxe -cp ../src -neko $@ $<

ModTest.n:
	haxe -cp ../src -neko ModTest.n ModTest.hx

install:
	@mv *.ndll ../bin
	@mv *.n ../bin

clean:
	@rm -f *.o
	@rm -f *.n
	@rm -f *.ndll

