
class HiveApp extends Hive
{
	public function new() { super(); }
	public function __default() : Void
	{
		//neko.Web.setHeader("X-MyHeader","true");
		//neko.Web.setCookie("name", "value");
		neko.Web.setCookie("cook2","val2");


		println("WebApp Entry Point");
		//var hi : List<{ value : String, header : String}>  = neko.Web.getClientHeaders(); 
		/*
		for(i in hi) {
			print(i.value + " " + i.header+"<br>\n");
		}
		*/

		print("<hr><h1>Cookies</h1></ br>\n");
		//var c = neko.Web.getCookies();
		/*
		for(i in c.keys()) {
			print(i + ": " + c.get(i));
		}
		*/
       }

       public static function main():Void
       {
		//println("WebApp Main");
		//neko.Web.cacheModule(entryPoint);
       }
}
/*
Called from tools/WebServer.nml line 481
Called from tools/WebServer.nml line 454
Called from <null> line 1
Called from WebApp.hx line 18
Called from WebApp.hx line 10
Called from neko/Web.hx line 110
Called from tools/WebServer.nml line 407
Called from tools/WebServer.nml line 308
Exception : Neko_error(Cannot set X-MyHeader : Headers already sent)
*/
