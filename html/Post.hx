/**
	Simply trace out the values of posts, gets and coookies
*/


class Post extends Hive {
	//var request : HttpdResponse;
	public function new() { super(); }


	public function cookieTest() {
		Hive.Response.setCookie(new HttpCookie("blah","testing"));
		setCookie(new HttpCookie("blah21","testing21"));
		Hive.Response.setCookie(new HttpCookie("blah2","testing2"));
	}

	public function handleRequest(req:Dynamic, resp:Dynamic) {
		super.handleRequest(req, resp);
		//cookieTest();
		if(Hive.formIsChecked("redirect")) {
			Hive.redirect("/index.html");
			Hive.exit();
		}
		Hive.print("<h1>Hive Post App</h1>\n");
		neko.Lib.print("Hello "+Std.random(1000));
		//setCookie(new HttpCookie("I should","fail"));
		Hive.print(" There!<br>\n");
		Hive.print("Request serial: " + Hive.Request.serial_number + "<br>\n");
		Hive.print("<h2>_POST</h2>\n");
		trace(Hive._POST);
		Hive.print("<h2>_REQUEST</h2>\n");
		trace(Hive._REQUEST);

		Hive.print("<h2>formField(note)</h2>\n");
		trace(Hive.formField("note"));
		Hive.print("<h2>formHash(note)</h2>\n");
		trace(Hive.formHash("note"));

		Hive.print("<h2>Flush test</h2>\n");
		Hive.flush();
		neko.Sys.sleep(5);
		Hive.print("Done sleeping");
	}

	public static function main() {
		Hive.print("<h1>Post reloaded</h1>\n");
	}
}
