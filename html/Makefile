all: dummy
	haxe -cp ../src -neko HiveApp.n -main HiveApp HiveApp.hx
	haxe -neko WebApp.n -main WebApp WebApp.hx
	haxe -cp ../src -neko Post.n -main Post Post.hx
	haxe -neko Index.n -main Index Index.hx
dummy:

clean:
	@rm -f *.neko
	@rm -f *.n
	@rm -f *.hx~

