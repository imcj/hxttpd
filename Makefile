all: dummy
	haxe build.hxml
	cd plugins && make
	cd neko && make
	cd html && make

run:
#	cd html && neko ../bin/hxttpd.n
	./hxttpd

doc: dummy
	haxe -xml doc/docs.xml build.hxml && cd doc && haxedoc docs.xml && rm docs.xml
	

dummy:

clean:
	cd plugins && make clean
	cd html && make clean
	@rm -f bin/hxttpd.n
	@rm -Rf doc/content
	@rm -f doc/index.html
	@rm -f src/*.hx~
	@rm -f src/neko/vmext/*.hx~
	@rm -f src/neko/io/*.hx~
	@rm -f core
	@rm -f *~
	@rm -f tests/*.n
	@rm -f tests/*.neko
	@rm -f tests/*~

distclean:
	@rm -f bin/*
