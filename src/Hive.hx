
typedef VarList = {
	key: String,
	value: String
}


class Hive {
	//public var neko : ModNeko;
	public static var Request	: Dynamic 	= null;
	public static var Response	: Dynamic	= null;
	public static var _ENV		: Hash<Dynamic> = null;
	public static var _GET		: Hash<Dynamic> = null;
	public static var _POST 	: Hash<Dynamic> = null;
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

		_SERVER = new Hash<Dynamic>();
		/*
		pv = Request.server_vars;
		for(i in pv)
			_SERVER = makeHashFromSpec(i.key,i.value,_SERVER);
		*/

		_REQUEST = mergeEnv(["E","G","P","C","S"]);
		_FILES = Request.file_vars;
	}

	public function err(msg, ?stack) {
		print(msg);
		if(stack != null) {
			//for(i in stack)
			//	print(i);
			print(stack.toString());
		}
		neko.Sys.exit(1);
	}

	public function setCookie(cookie : HttpCookie) {
		if(Response.headers_sent) {
			err("Headers already sent", haxe.Stack.callStack());
		}
		Response.setCookie(cookie);
	}

	public function println(s:String) {
		neko.Lib.println(s);
	}

	public function print(s:String) {
		neko.Lib.print(s);
	}

	///////////////////////////////////////////////////////////////////////////
	//                     STATIC METHODS                                    //
	///////////////////////////////////////////////////////////////////////////
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
/*
	public function setReturnCode(r:Int) : Void {}
	public function setHeader(h : String, v : String) : Void {}
	public function setCookie(k : String, v : String) : Void {}
	//public function redirect(url : String) : Void {}
	public function parseMultipart(onPart : (String -> String -> Void), onData : (String -> Int -> Int -> Void)) : Void {}
	public function isModNeko() : Bool { return true; }
	public function getURI(Void) : String { return ""; }
	public function getPostData(Void) : String { return ""; }
	public function getParamsString(Void) : String { return ""; }
	public function getParams(Void) : Hash<String> { return new Hash<String>(); }
	public function getParamValues(param : String) : Array<String> { return new Array<String>(); }
	public function getMultipart(maxSize : Int) : Hash<String> { return new Hash<String>(); }
	public function getHostName() : String {return "";}
	public function getCwd(Void) : String {return "";}
	public function getCookies() : Hash<String> {return new Hash<String>();}
	public function getClientIP() : String {return "";}
	public function getClientHeaders() : List<{ value : String, header : String }> { return new List<{ value : String, header : String }>();}
	public function getClientHeader(k : String) : String {return "";}
	public function getAuthorization() : { user : String, pass : String } {
		var t = { user:"Me",pass:"me"};
		return t;
	}
	public function flush() : Void {}
	public function cacheModule(f : (Void -> Void)) : Void {}
*/
}


