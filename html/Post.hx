/**
	Simply trace out the values of posts, gets and coookies
*/


class Post extends Hive {
	//var request : HttpdResponse;
	public function new() { super(); }


	public function cookieTest() {
		Hive.Response.setCookie(new HttpCookie("blah","testing"));
	}

	public function handleRequest(req:Dynamic, resp:Dynamic) {
		super.handleRequest(req, resp);
		print("<h1>Hive Post App</h1>\n");
/*
		cookieTest();
		Hive.Response.setCookie(new HttpCookie("blah2","testing2"));
		setCookie(new HttpCookie("blah21","testing21"));
		neko.Lib.print("Hello "+Std.random(1000));
		setCookie(new HttpCookie("I should","fail"));
		print("There!");
		print("Request serial: " + Hive.Request.serial_number);
		trace(Hive._POST);
*/
		trace(Hive._REQUEST);
	}

	public static function main() {}
}
