all: dummy
	haxe -cp ../src -cp . -neko HiveApp.n -main HiveApp HiveApp.hx
	haxe -cp . -neko WebApp.n -main WebApp WebApp.hx
	haxe -cp ../src -cp . -neko Post.n -main Post Post.hx
	haxe -cp . -neko Index.n -main Index Index.hx
dummy:

clean: distclean
	@rm -f *.n

distclean:
	@rm -f *.hx~
	@rm -f *.neko

