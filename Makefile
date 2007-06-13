all: dummy
	haxe build.hxml

run:
	cd html && neko ../bin/server.n

doc: dummy
	haxe -xml doc/docs.xml build.hxml && cd doc && haxedoc docs.xml && rm docs.xml
	

dummy:

clean:
	@rm -f bin/server.n
	@rm -f tests/*.n
	@rm -Rf doc/content
	@rm -f doc/index.html
