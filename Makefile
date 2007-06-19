all: dummy
	haxe build.hxml
	cd plugins && make
run:
#	cd html && neko ../bin/hxttpd.n
	./hxttpd

doc: dummy
	haxe -xml doc/docs.xml build.hxml && cd doc && haxedoc docs.xml && rm docs.xml
	

dummy:

clean:
	@rm -f bin/hxttpd.n
	@rm -f tests/*.n
	@rm -Rf doc/content
	@rm -f doc/index.html
