/**
	Simply trace out the values of posts, gets and coookies
*/


class Post extends Hive {
	//var request : HttpdResponse;
	public function new() { super(); }


	public function cookieTest() {
		Hive.setCookie(new HttpCookie("foo","bar"));
		var c = new HttpCookie("fooexpire","expiredval");
		c.setExpires(Date.fromTime(Date.now().getTime()-3600));
		Hive.setCookie(c);
		Hive.setCookie(new HttpCookie("space embedded","Testing url encoding"));
	}

	//public function handleRequest(req:Dynamic, resp:Dynamic) {
	public function entryPoint() : Void {
		//super.handleRequest(req, resp);
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
		neko.Sys.sleep(3);
		Hive.print("Done sleeping");

		Hive.print("<h2>Cookies</h2>");
		for(i in Hive._COOKIE.keys()) {
			Hive.printbr("Client cookie name: " + Hive.urlEncodedToHtml(i) + " value: " + Hive.urlEncodedToHtml(Hive._COOKIE.get(i)));
		}
		Hive.printbr("The cookie named fooexpire should not appear in the list above");
	}

	public static function main() {
		Hive.print("<h1>Post reloaded</h1>\n");
	}
}
