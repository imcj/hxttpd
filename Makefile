include Makefile.config

all: archtest dummy
	haxe build.hxml -D $(BUILD)
	cd plugins && $(MAKE)
	cd neko && $(MAKE)
	cd html && $(MAKE)
	$(NEKOTOOLS) boot bin/hxttpd.n
	@mv bin/hxttpd$(EXE) bin/hxttpd-$(ARCH)-bin$(EXE)

run:
#	cd html && neko ../bin/hxttpd.n
	./hxttpd

doc: dummy
	haxe -xml doc/docs.xml build.hxml && cd doc && haxedoc docs.xml && rm docs.xml

archtest:
	@if [ -z $(ARCH_CAP) ]; then \
		echo "You must specify the architecture to build for (make ARCH=?): "; \
		echo " ARCH: linux windows mac bsd wine"; \
		exit 1; \
	fi;

install:
	$(NEKO) run.n

clean:
	cd plugins && $(MAKE) clean
	cd neko && $(MAKE) clean
	cd html && $(MAKE) clean
	@rm -f bin/hxttpd.n
	@rm -Rf doc/content
	@rm -f doc/index.html
	@rm -f core
	@rm -f tests/*.n
	@rm -f tests/*.neko

distclean:
	cd plugins && $(MAKE) distclean
	cd neko && $(MAKE) distclean
	cd html && $(MAKE) distclean
	@rm -f src/*.hx~
	@rm -f src/neko/vmext/*.hx~
	@rm -f src/neko/io/*.hx~
	@rm -f *~
	@rm -f tests/*~

dummy:
