include ../Makefile.config

PLUGINS=mod_test.ndll
PLUGINS_HAXE=ModTest.n 

all: archtest $(PLUGINS) $(PLUGINS_HAXE)

%.ndll: %.o
	$(CC) $(LIBPATH) $(INCPATH) -Wall -shared -o $@ $< $(LIBS)
	@mv *.ndll ../ndll/$(ARCH_CAP)

%.o: %.c archtest
	$(CC) -c $(INCPATH) -Wall -o $@ $<

#%.n: %.hx
#	haxe -cp ../src -neko $@ $<

ModTest.n: archtest dummy
	haxe -cp ../src -neko ModTest.n -main ModTest ModTest.hx -D $(BUILD)
	@mv ModTest.n ../ndll/$(ARCH_CAP)

install:

clean: distclean
	@rm -f ../bin/*.n
	@rm -f ../ndll/Linux/*.ndll
	@rm -f ../ndll/Windows/*.ndll
	@rm -f ../ndll/Mac/*.ndll
	@rm -f ../ndll/BSD/*.ndll

distclean:
	@rm -f *.o

dummy:

archtest:
	@if [ "L$(ARCH_CAP)" == "L" ]; then \
		echo "You must specify the architecture to build for (make ARCH=?): "; \
		echo " ARCH: linux windows mac bsd wine"; \
		exit 1; \
	fi;

