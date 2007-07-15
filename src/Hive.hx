// Copyright 2007, Russell Weir
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


typedef VarList = {
	key: String,
	value: String
}
import haxe.Stack;

class Hive {
	public static var Request	: Dynamic 	= null;
	public static var Response	: Dynamic	= null;
	public static var _ENV		: Hash<Dynamic> = null;
	public static var _GET		: Hash<Dynamic> = null;
	public static var _POST 	: Hash<Dynamic> = null;
	public static var _GETPOST	: Hash<Dynamic> = null;
	public static var _COOKIE	: Hash<Dynamic> = null;
	public static var _SERVER	: Hash<Dynamic> = null;
	public static var _REQUEST	: Hash<Dynamic> = null;
	public static var _FILES	: Hash<HttpdRequestResource>;


	public function new() {	}

	public function handleRequest(req:Dynamic, resp:Dynamic) {

		//untyped neko.Lib.print(request._POST);
		untyped {
			Hive.Request = req.getMainModuleRequest();
			Hive.Response = resp.getMainModuleResponse();
		}

		var pv : Array<{key: String,value: String}>;

		_ENV = new Hash<Dynamic>();
		/*
		pv = Request.env_vars;
		for(i in pv)
			_ENV = makeHashFromSpec(i.key,i.value,_ENV);
		*/

		_GET = new Hash<Dynamic>();
		pv = Request.get_vars;
		for(i in pv)
			_GET = makeHashFromSpec(i.key,i.value,_GET);

		_POST = new Hash<Dynamic>();
		pv = Request.post_vars;
		for(i in pv)
			_POST = Hive.makeHashFromSpec(i.key,i.value,_POST);

		_COOKIE = new Hash<Dynamic>();
		var cv : Array<HttpCookie> = Request.getCookies();
		for(i in cv)
			_COOKIE = Hive.makeHashFromSpec(i.getName(), i.getValue(),_COOKIE);

		_SERVER = new Hash<Dynamic>();
		/*
		pv = Request.server_vars;
		for(i in pv)
			_SERVER = makeHashFromSpec(i.key,i.value,_SERVER);
		*/

		_REQUEST = mergeEnv(["E","G","P","C","S"]);
		_GETPOST = mergeEnv(["G","P"]);
		_FILES = Request.file_vars;

		try {
			entryPoint();
		}
		catch(e:Dynamic) {
			err(e, null, haxe.Stack.exceptionStack());
		}
	}

	public function entryPoint() : Void {
		throw "entryPoint not overridden";
	}

	public static function err(msg, ?stack:Array<haxe.StackItem>,?exception:Array<haxe.StackItem>) {
		printbr("");
		println("<hr>");
		println("<h1>ERROR: " + Std.string(msg)+"</h1>");
		println("<hr>");
		if(stack != null) {
			println("<h2>Call stack</h2>");
			// remove ModHive
			//stack.shift();
			//remove VmModule
			//stack.shift();
			//remove Reflect
			//stack.shift();
			var foundEntry = false;
			for(i in stack) {
				switch( i ) {
                        	case CFunction:
					foundEntry = true;
                        	case Module(m):
					if(foundEntry) {
                                		print("module ");
                                		printbr(m);
					}
                        	case FilePos(name,line):
					if(foundEntry) {
                                		print(name);
                                		print(" line ");
                                		printbr(line);
					}
                        	case Method(cname,meth):
					if(foundEntry) {
        	                        	print(cname);
                	                	print(" method ");
                        	        	printbr(meth);
					}
                        	}
			}
		}
		if(exception != null) {

			println("<h2>Exception stack</h2>");

			var foundEntry = true;
			for(i in exception) {
				switch( i ) {
                        	case CFunction:
					printbr("[.dll]");
                        	case Module(m):
					if(foundEntry) {
                                		print("module ");
                                		printbr(m);
					}
                        	case FilePos(name,line):
					if(foundEntry) {
                                		print(name);
                                		print(" line ");
                                		printbr(line);
					}
                        	case Method(cname,meth):
					if(foundEntry) {
        	                        	print(cname);
                	                	print(" method ");
                        	        	printbr(meth);
					}
                        	}
			}
		}
		neko.Sys.exit(1);
	}





	///////////////////////////////////////////////////////////////////////////
	//                     STATIC METHODS                                    //
	///////////////////////////////////////////////////////////////////////////
	public static function print(s:Dynamic) {
		//neko.Lib.print(s);
		untyped __dollar__print(s);
	}

	public static function println(s:Dynamic) {
		//neko.Lib.println(s);
		untyped __dollar__print(s,"\n");
	}

	public static function printbr(s:Dynamic) {
		//neko.Lib.print(s);
		//neko.Lib.print("<br>\n");
		untyped __dollar__print(s, "<br>\n");
	}

	public static function exit() {
		neko.Sys.exit(1);
	}

	// convenience
	public static function urlEncode( s : String ) : String {
		//return untyped encodeURIComponents(s);
		return StringTools.urlEncode(s);
	}
	public static function urlDecode( s : String ) : String {
		//return untyped decodeURIComponents(s.split("+").join(" "));
		return StringTools.urlDecode(s);
	}
	public static function htmlEscape( s : String ) : String {
		return StringTools.htmlEscape(s);
	}
	public static function htmlUnescape( s : String ) : String {
		return StringTools.htmlUnescape(s);
	}
	public static function urlEncodedToHtml( s : String ) : String {
		return htmlEscape(
			Hive.urlDecode(s));
	}

	///////////////////////////////////////////////////////////////////////////
	//                  neko.Web COMPAT STATIC METHODS                       //
	///////////////////////////////////////////////////////////////////////////
	public static function setReturnCode(r:Int) : Void {
		Response.setStatus(r);
	}

	public static function setHeader(h : String, v : String) : Void {
		if(Response.headers_sent)
			err("Headers already sent", haxe.Stack.callStack());
		Response.setHeader(h, v);
	}

	public static function setCookie(cookie : HttpCookie) {
		if(Response.headers_sent) {
			err("Headers already sent", haxe.Stack.callStack());
		}
		Response.setCookie(cookie);
	}

	public static function redirect(url : String) : Void {
		setHeader("Location", url);
		setReturnCode(302);
	}
	public static function getURI(Void) : String { return Request.url; }
	public static function getPostData(Void) : String { return Request.post_data; }
	public static function getParamsString(Void) : String { return Request.args; }
	public static function getParams(Void) : Hash<Dynamic> { return _GET; }
	public static function getParamValues(param : String) : Dynamic {
		return _GET.get(param);
	}
	public static function getHostName() : String {
		return Std.string(Request.host);
	}
	public static function getCwd(Void) : String {
		var p : String = Request.path_translated;
		if(Request.path.charAt(0) != "/")
			p = p + "/";
		p = p + Request.path;
		p = p.substr(0,p.lastIndexOf("/"));
		return p;
	}
	public static function getCookies() : Hash<String> {
		var rv = new Hash<String>();
		var cv : Array<HttpCookie> = Request.getCookies();
		for(i in cv)
			rv.set(i.getName(), i.getValue());
		return rv;
	}
	public static function getClientIP() : String {
		return Request.client.remote_host.toString();
	}
	public static function getClientHeaders() : List<{ value : String, header : String }> {
		var rv = new List<{ value : String, header : String }>();
		var h : List<{key: String,value: String}> = Request.headers_in;
		for(i in h) {
			rv.add({value:i.value,header:i.key});
		}
		return rv;
	}
	public static function getClientHeader(k : String) : String {
		return Request.getHeaderIn(k);
	}
	//TODO
	public static function getAuthorization() : { user : String, pass : String } {
		var t = { user:"Me",pass:"me"};
		return t;
	}
	public static function flush() : Void {
		send_message(HiveThreadMessage.FLUSH);
	}


	///////////////////////////////////////////////////////////////////////////
	//                  FORM HANDLING STATIC METHODS                         //
	///////////////////////////////////////////////////////////////////////////

	/**
		Check if an html checkbox is set
		Either specify the source (_POST or _GET vars), or the
		default merged environment GP will be used.
	*/
	public static function formIsChecked(name:String, ?source:Hash<Dynamic>) : Bool {
		if(source == null)
			source = _GETPOST;
		return if(source.get(name) == "on") true; else false;
	}

	/**
		Return text from form field. If field does not exist,
		returns empty string. If field is a hash, it will be
		converted to a string.
	*/
	public static function formField(name:String, ?source:Hash<Dynamic>) :String {
		if(source == null)
			source = _GETPOST;
		if(!source.exists(name))
			return "";
		if(Type.getClassName(Type.getClass(source.get(name))) == "Hash")
			return(source.get(name).toString());
		return source.get(name);
	}

	/**
		Return a form Hash. If field does not exist, or is not a
		hash, will return null.
	*/
	public static function formHash(name:String, ?source:Hash<Dynamic>) : Hash<Dynamic> {
		if(source == null)
			source = _GETPOST;
		if(!source.exists(name))
			return null;
		if(Type.getClassName(Type.getClass(source.get(name))) != "Hash")
			return null;
		return source.get(name);
	}


	public static function parseVars(s:String) : Hash<Dynamic> {
		var rv = new Hash<Dynamic>();
		var args = s.split("&");

		for(i in args) {
			var v = i.split("=");
			var key = StringTools.urlDecode(v[0]);
			var value = StringTools.urlDecode(v[1]);
			rv = makeHashFromSpec(key, value, rv);
		}
		return rv;
	}


	///////////////////////////////////////////////////////////////////////////
	//                      UTILITY STATIC METHODS                           //
	///////////////////////////////////////////////////////////////////////////
	public static function makeHashFromSpec(key:String, value:String, ?h:Hash<Dynamic>, ?recursion:Int) : Hash<Dynamic>
	{
		//trace(here.methodName + " key: "+key + " value: "+value + " recurse: "+recursion);
		key = StringTools.trim(key);

		if(h == null) {
			h = new Hash<Dynamic>();
		}
		if(recursion == null)
			recursion = 0;
		/*
		if(recursion == null || recursion == 0) {
			recursion = 0;
			// match braces
			var opens = 0;
			var closes = 0;
			for(i in 0...key.length) {
				if(key.charAt(i) == "[") {
				}
				if(key.charAt(i) == "]") {
				}
			}
			if(opens != closes)
				throw("Invalid key");
		}
		*/
		var name : String = null;
		var element : String = null;
		var s:Int;
		var e:Int;
		if(key.length > 0) {
			s = key.indexOf("[");
			e = key.lastIndexOf("]");
			if(e<s || s < 0) {
				// if close brace comes before end brace, or
				// just name and no key, set name to value (myname,value)
				h.set(key, value);
				return h;
			}
			if(s>=0)
				element = StringTools.trim(key.substr(s+1,e-s-1));
			if(s > 0)
				name = key.substr(0,s);
		}
		else {
			s = 0;
			e = 0;
			element = null;
			name = null;
		}
		if(element == null || element.length == 0) { // []
			// if no name, set increment to value ([], value)
			if(name == null) {
				//trace("Setting by counter");
				var counter : Int = 0;
				for(i in h) { counter++; }
				//trace("Counter now "+counter);
				h.set(Std.string(counter), value);
				return h;
			}

		}
		// has name and element
		// if name exists, and is not a hash, make a new hash
		// as name, killing any old value.
		if(Type.getClassName(Type.getClass(h.get(name))) != "Hash") {
			h.set(name, new Hash<Dynamic>());
		}
		makeHashFromSpec(element,value,h.get(name),recursion+1);
		//trace(h);
		return h;
	}

	/**
		Return a merged set of request variables, in the
		order of precedence specified by order. the least
		important is order[0]. Default is EGPCS Just like PHP
		E environment
		G GET vars
		P POST vars
		C Cookie vars
		S Server vars.
	*/
	public static function mergeEnv(?order:Array<String>) : Hash<String>
	{
		var rv = new Hash<String>();
		if(order == null) {
			order = ["E","G","P","C","S"];
		}
		for(i in order) {
			var source : Dynamic = null;
			switch(i) {
			case "E":
				source = _ENV;
			case "G":
				source = _GET;
			case "P":
				source = _POST;
			case "C":
				source = _COOKIE;
			case "S":
				source = _SERVER;
			}
			if(source == null)
				continue;
			for(k in source.keys()) {
				rv.set(k, source.get(k));
			}
		}
		return rv;
	}


	static var send_message = neko.Lib.load("hive","send_message",1);
}


