class CookieTest {
	static var testcookies : Array<String> = [
		"Set-Cookie: PHPSESSID=06a47fd11b5d7ad1e4c76f99c10f6831; path=/",
		"Cookie: Name1=Val1, name2=val2; path=/; domain=google.com",
		"Cookie: blah21=testing21; blah2=testing2; blah=testing",
		"nohead=true; path=/shopping"
		];
	public static function main() {
		trace("\n\n========= COOKIE TEST =========");
		for(i in testcookies) {
			trace("Test: " + i);
			var cookies = HttpCookie.fromString(i);
			trace("Results in "+cookies.length+" cookies parsed");
			var x = 1;
			for(c in cookies) {
				trace(">> Cookie #"+x);
				trace("   Name "+ c.getName());
				trace("   Value "+c.getValue());
				trace(c);
				x ++;
			}
			if(cookies.length > 1) {
				trace("  Single line version:" + HttpCookie.toSingleLineString(cookies));
			}
			trace("");
		}
	}
}

