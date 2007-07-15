import neko.Web;

class WebApp 
{
	public static function onPart(name:String, filename:String) {
		neko.Lib.print("Received file name:"+name+" filename:"+filename+"<br>");
	}

	public static function onData(buf:String, pos:Int, len:Int) {
		neko.Lib.print("...Received data part "+len+" bytes<br>\n");
		//neko.Lib.print(buf.substr(pos,len));
	}

	public static function entryPoint():Void
	{
		neko.Lib.println("WebApp entryPoint()<br>\n");

		// IMPLEMENTS:
		//neko.Web.cacheModule(this.entryPoint);
		//neko.Web.flush();
		// done //neko.Web.getAuthorization();
		// done //neko.Web.getClientHeader("Content-Type");
		// done //neko.Web.getClientHeaders();
		// done //neko.Web.getClientIP();
		// done //neko.Web.getCookies();
		// done but test vs. nekotools //neko.Web.getCwd();
		// done //neko.Web.getHostName();
		//neko.Web.getMultipart();
		//neko.Web.getParamValues();
		// done //neko.Web.getParams()
		// done //neko.Web.getParamsString()
		// done //neko.Web.getPostData()
		// done //neko.Web.getURI()
		//neko.Web.parseMultipart()
		//neko.Web.redirect()
		// done //neko.Web.setCookie()
		// done //neko.Web.setHeader()
		// done //neko.Web.setReturnCode()


		//	CLIENTIP
		///
		neko.Lib.print("<hr><h1>getClientIP</h1>\n");
		try {
			neko.Lib.print("Client IP Address: " + neko.Web.getClientIP());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getClientIP");
		}
		neko.Lib.print("</ br>\n");


		//	HOSTNAME
		///
		neko.Lib.print("<hr><h1>Hostname</h1>\n");
		try {
			neko.Lib.print(neko.Web.getHostName());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getHostName");
		}
		neko.Lib.print("</ br>\n");


		//	URI
		///
		neko.Lib.print("<hr><h1>getURI</h1>\n");
		try {
			neko.Lib.print(neko.Web.getURI());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getURI");
		}
		neko.Lib.print("</ br>\n");



		//	CWD
		///
		neko.Lib.print("<hr><h1>getCwd</h1>\n");
		try {
			neko.Lib.print(neko.Web.getCwd());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getCwd");
		}
		neko.Lib.print("</ br>\n");


		//	PARAMS
		///
		neko.Lib.print("<hr><h1>getParams</h1>\n<form method='post' action='WebApp.n'><table border='1'><tr><th>Name</th><th>Value</th></tr>");
		try {
			var h = neko.Web.getParams();
			for(i in h.keys()) {
				neko.Lib.print("<tr><td>"+i+"</td><td>"+h.get(i)+"</td></tr>\n");
			}
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getParams");
		}
		neko.Lib.print("<tr><td>Text 1<td><input type='text' name='text1'></td></tr>\n");
		neko.Lib.print("<tr><td colspan='2' align='center'><input type='submit' name='submit' value='submit'></td></tr>\n");
		neko.Lib.print("</table></form></ br>\n");


		//	PARAMS STRING
		///
		neko.Lib.print("<hr><h1>getParamsString</h1>\n");
		try {
			neko.Lib.print(neko.Web.getParamsString());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getParamsString");
		}
		neko.Lib.print("</ br>\n");


		//	POST DATA
		///
		neko.Lib.print("<hr><h1>getPostData</h1>\n");
		try {
			neko.Lib.print(neko.Web.getPostData());
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getPostData");
		}
		neko.Lib.print("</ br>\n");


		//	PARSE MULTIPART
		///
		neko.Lib.print("<hr><h1>parseMultipart</h1>\n");
		neko.Lib.print("<form method='post' action='WebApp.n' enctype='multipart/form-data'>\n");
		neko.Lib.print("<table><tr><td colspan='2'>\n");
		try {
			neko.Web.parseMultipart(WebApp.onPart, WebApp.onData);
		} catch(e:Dynamic) {
			neko.Lib.print("Error with parseMultipart " + e);
		}
		neko.Lib.print("</td></tr>\n");
		neko.Lib.print("<tr><td>File 1<td><input type='file' name='file_one' size='50'></td></tr>\n");
		neko.Lib.print("<tr><td colspan='2' align='center'><input type='submit' name='submit' value='submit'></td></tr>\n");
		neko.Lib.print("</table></form>\n");
		neko.Lib.print("</ br>\n");


		//	SET HEADER
		///
		neko.Lib.print("<hr><h1>setHeader</h1>\n");
		neko.Web.setHeader("X-MyHeader","true");


		//	RETURN CODE
		///
		neko.Lib.print("<hr><h1>setReturnCode</h1>\n");
		neko.Web.setReturnCode(404);


		//	COOKIES
		///
		neko.Lib.print("<hr><h1>Cookies</h1>\n");
		try {
			var c = neko.Web.getCookies();
			for(i in c.keys()) {
				neko.Lib.print(i + ": " + c.get(i) + " ");
			}
			neko.Lib.print("</ br>\n");

			// Setting a cookie
			neko.Web.setCookie("cook2","val2");
		}
		catch(e:Dynamic) {
			neko.Lib.print("Error with cookies</ br>\n");
		}



		//	getClientHeader
		///
		neko.Lib.print("<hr><h1>getClientHeader</h1>\n");
		try {
			neko.Lib.print("Client user agent: " + neko.Web.getClientHeader("User-Agent"));
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getClientHeader");
		}

		//	getClientHeaders
		///
		neko.Lib.print("<hr><h1>getClientHeaders</h1>\n<table><tr><th>Name</th><th>Value</th></tr>");
		try {
			//List<{ value : String, header : String}>
			var h = neko.Web.getClientHeaders();
			for(i in h) {
				neko.Lib.print("<tr><td>" + i.header + "</td><td>"+i.value+"</td></tr>\n");
			}
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getClientHeader");
		}
		neko.Lib.print("</table></ br>\n");



		//	Authorization
		///
		neko.Lib.print("<hr><h1>Authorization</h1>\n");
		try {
			var auth = neko.Web.getAuthorization();
			if(auth != null) {
				neko.Lib.print("User: " + auth.user + "</ br>\n");
				neko.Lib.print("Pass: " + auth.pass + "</ br>\n");
			} else {
				neko.Lib.print("No auth sent</ br>\n");
			}
		} catch(e:Dynamic) {
			neko.Lib.print("Error with getAuthorization");
		}
		neko.Lib.print("</ br>\n");



	}

       
	public static function main():Void {
		neko.Lib.println("WebApp main() initialized. Caching entry function<br>\n");
		neko.Web.cacheModule(entryPoint);
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
