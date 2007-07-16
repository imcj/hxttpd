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

import haxe.Stack;
import Type;

typedef VarList = {
	key: String,
	value: String
}

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

	/**
		Do not override or call this function. It is called
		automatically at the beginning of each client request,
		and will call handleRequest() when it is ready for
		your handler to continue.
	*/
	public function _main(req:Dynamic, resp:Dynamic) {

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
			handleRequest();
		}
		catch(e:Dynamic) {
			err(e, null, haxe.Stack.exceptionStack());
		}
	}

	/**
		When creating an instance of Hive, this method must
		be overridden, and is the main entry point of that
		handles each client request.
	*/
	public function handleRequest() : Void {
		throw "entryPoint not overridden";
	}



	///////////////////////////////////////////////////////////////////////////
	//                     STATIC METHODS                                    //
	///////////////////////////////////////////////////////////////////////////
	public static function exit() {
		neko.Sys.exit(1);
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
	//                     PRINTING METHODS                                  //
	///////////////////////////////////////////////////////////////////////////
	/**
		Print, shortcut for neko.Lib.print
	*/
	public static function print(s:Dynamic) {
		untyped __dollar__print(s);
	}

	/**
		Print, adding newline character. Shortcut for
		neko.Lib.println. To add breaks to the line,
		see printbr()
	*/
	public static function println(s:Dynamic) {
		untyped __dollar__print(s,"\n");
	}
	/**
		Print, adding an html break and a newline
	*/
	public static function printbr(s:Dynamic) {
		untyped __dollar__print(s, "<br>\n");
	}

	/**
		Print out an indented text representation
		of any value, like PHP's print_r. Will format
		in HTML by default, by placing breaks at the end
		of each line. Set htmlize to false to disable.
	*/
	public static function print_r(v:Dynamic, ?htmlize:Bool, ?depth:Null<Int>,?hasNext:Bool) {
		/*
		Name => {
			note => {
				0 => null,
				2 => Note 2,
				1 => Note 1
			},
			city => Los Angeles,
			submit => button,
			address => 123 Anywhere street
		}
		*/
		if(htmlize == null)
			htmlize = true;
		if(depth == null || depth<0)
			depth = 0;

		var space : String = " ";
		var newline : String = "\n";
		if(htmlize) {
			space = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
			newline = "<br>\n";
		}
		if(hasNext == true)
			newline = ","+newline;

		var sb = new StringBuf();

		switch(Type.typeof(v)) {
		case TUnknown:
			sb.add("[Unknown]");
			sb.add(newline);
		case TObject:
			sb.add("[Object]");
			sb.add(newline);
		case TNull:
			sb.add("Null");
			sb.add(newline);
		case TInt:
			sb.add(v);
			sb.add(newline);
		case TFunction:
			sb.add("[Function]");
			sb.add(newline);
		case TFloat:
			sb.add(v);
			sb.add(newline);
		case TEnum(e):
			sb.add("[Enum]");
			sb.add(newline);
		case TClass(c):
			var s = c;
			while((s = Type.getSuperClass(s)) != null) {
				c = s;
			}
			var cn : String = Type.getClassName(c);
			if(cn == "Hash" || cn == "List" || cn == "Array") {
				sb.add("{");
				if(htmlize)
					sb.add("<br>\n");
				else
					sb.add("\n");

				var it = v.keys();
				for(i in it) {
					for(i in 0...depth+1)
						sb.add(space);
					sb.add(i);
					sb.add(" => ");
					sb.add(print_r(v.get(i), htmlize, depth+1,it.hasNext()));
				}
				for(i in 0...depth)
					sb.add(space);
				sb.add("}");
				sb.add(newline);
			}
			else if(cn == "String") {
				sb.add(v);
				sb.add(newline);
			}
			else {
				sb.add("[Class]");
				sb.add(newline);
			}
		case TBool:
			sb.add(v);
			sb.add(newline);
		}
		if(depth == 0)
			untyped __dollar__print(sb.toString());
		return sb.toString();
	}


	// convenience
	/**
		Encode a string for URL use.
	*/
	public static function urlEncode( s : String ) : String {
		//return untyped encodeURIComponents(s);
		return StringTools.urlEncode(s);
	}
	/**
		Decode a URL encoded string.
	*/
	public static function urlDecode( s : String ) : String {
		//return untyped decodeURIComponents(s.split("+").join(" "));
		return StringTools.urlDecode(s);
	}
	/**
		Convert HTML elements in a string.
	*/
	public static function htmlEscape( s : String ) : String {
		return StringTools.htmlEscape(s);
	}
	/**
		Strip html tags from string.
	*/
	public static function htmlUnescape( s : String ) : String {
		return StringTools.htmlUnescape(s);
	}
	/**
		Html encode string.
	*/
	public static function urlEncodedToHtml( s : String ) : String {
		return htmlEscape(
			Hive.urlDecode(s));
	}
	/**
		Return a string representation of the base class of
		any value. Also returns string representations of the
		primary types, like Int, Bool etc.
	*/
	public static function getBaseClass( v : Dynamic) : String {
		switch(Type.typeof(v)) {
		case TUnknown:
			return "Unknown";
		case TObject:
			return "Object";
		case TNull:
			return "Null";
		case TInt:
			return "Int";
		case TFunction:
			return "Function";
		case TFloat:
			return "Float";
		case TEnum(e):
			return "Enum";
		case TClass(c):
			var s = c;
			while((s = Type.getSuperClass(s)) != null) {
				c = s;
			}
			return(Type.getClassName(c));
		case TBool:
			return "Bool";
		}
		return null;
	}
	/**
		Check if any value is a string.
	*/
	public static function isString( v : Dynamic) : Bool {
		var c = getBaseClass(v);
		if(c != "String")
			return false;
		return true;
	}
	/**
		Check if any value is a Hash.
	*/
	public static function isHash( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "Hash")
			return false;
		return true;
	}
	/**
		Check if any value is a List.
	*/
	public static function isList( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "List")
			return false;
		return true;
	}
	/**
		Check if any value is an Array.
	*/
	public static function isArray( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "Array")
			return false;
		return true;
	}
	/**
		Check if any value is an Integer.
	*/
	public static function isInt( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
			return true;
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is an object.
	*/
	public static function isObject( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
			return true;
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Function.
	*/
	public static function isFunction( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
			return true;
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Float.
	*/
	public static function isFloat( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
			return true;
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Class.
	*/
	public static function isClass( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
			return true;
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Bool.
	*/
	public static function isBool( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
			return true;
		}
		return false;
	}
	///////////////////////////////////////////////////////////////////////////
	//                  neko.Web COMPAT STATIC METHODS                       //
	///////////////////////////////////////////////////////////////////////////
	/**
		Set the HTTP response code.
	*/
	public static function setReturnCode(r:Int) : Void {
		Response.setStatus(r);
	}
	/**
		Set a HTTP response header.
	*/
	public static function setHeader(h : String, v : String) : Void {
		if(Response.headers_sent)
			err("Headers already sent", haxe.Stack.callStack());
		Response.setHeader(h, v);
	}
	/**
		Set an HTTP cookie.
	*/
	public static function setCookie(cookie : HttpCookie) {
		if(Response.headers_sent) {
			err("Headers already sent", haxe.Stack.callStack());
		}
		Response.setCookie(cookie);
	}
	/**
		Redirect to url.
	*/
	public static function redirect(url : String) : Void {
		setHeader("Location", url);
		setReturnCode(302);
	}
	/**
		Return the request uri.
	*/
	public static function getURI(Void) : String { return Request.url; }
	/**
		Return the raw POST variable string. In the case of multipart
		this value will be empty.
	*/
	public static function getPostData(Void) : String { return Request.post_data; }
	/**
		Return the raw GET variable string (everything after ? in the URI).
	*/
	public static function getParamsString(Void) : String { return Request.args; }
	/**
		Return the server hostname.
	*/
	public static function getHostName() : String {
		return Std.string(Request.host);
	}
	/**
		Current script working directory.
	*/
	public static function getCwd(Void) : String {
		var p : String = Request.path_translated;
		if(Request.path.charAt(0) != "/")
			p = p + "/";
		p = p + Request.path;
		p = p.substr(0,p.lastIndexOf("/"));
		return p;
	}
	/**
		Return array of HttpCookies.
	*/
	public static function getCookies() : Array<HttpCookie> {
		return Request.getCookies();

	}
	/**
		Return a hash of the cookie name value pairs.
		Unlike the Hive._COOKIE variable, no array like
		hashing is done on the cookie values.
	*/
	public static function getCookieAsString() : Hash<String> {
		var rv = new Hash<String>();
		var cv : Array<HttpCookie> = Request.getCookies();
		for(i in cv)
			rv.set(i.getName(), i.getValue());
		return rv;
	}
	/**
		Return string IP address of remote client.
	*/
	public static function getClientIP() : String {
		return Request.client.remote_host.toString();
	}
	/**
		Return all webbrowser headers sent to server.
	*/
	public static function getClientHeaders() : List<{ key : String, value : String }> {
		return Request.headers_in;
	}
	/**
		Return value of a specific client header.
	*/
	public static function getClientHeader(k : String) : String {
		return Request.getHeaderIn(k);
	}
	//TODO
	public static function getAuthorization() : { user : String, pass : String } {
		var t = { user:"Me",pass:"me"};
		return t;
	}
	/**
		Flush the output buffer. If headers have not been sent
		yet, they will be output by using this function. This
		comes in handy for any long running process, or for
		displaying content before the script is finished executing.
	*/
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

	/**
		Parses a GET style string into an associative hash.
		The associative hash creates a 'hash of hashes' or
		key-string pairs from GET, POST and COOKIE vars, much
		like PHP's implementation of _POST. By creating form fields
		with empty brackets [], all similar variable names are added
		to the Hash as integer values. Any specific name contained
		in the brackets will set that key to the value of the form
		field or GET variable.
		For example:
		<input type='text' name='foo[]' value='zero'>
		<input type='text' name='foo[]' value='one'>
		Will create a hash with one key 'foo' that is a hash
		with two keys '0' and '1' that contain the values 'zero'
		and 'one' respectively.
		This method is the same one used to create _GET,
		_POST and _COOKIE out of the client request.
	*/
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
		// taking any old value and making it the first entry
		// in the new hash.
		if(Type.getClassName(Type.getClass(h.get(name))) != "Hash") {
			var oldval = h.get(name);
			h.set(name, new Hash<Dynamic>());
			if(oldval != null)
				h.get(name).set("0", oldval);
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


	///////////////////////////////////////////////////////////////////////////
	//                  PRIVATE STATIC UTILITY METHODS                       //
	///////////////////////////////////////////////////////////////////////////
	// this function does not actually 'exist' in the ndll. It is
	// overridden by the loader to a haXe function that handles sending
	// messages to the worker thread. This increases security by not
	// exposing the ModNeko instance, or the thread instance to the
	// module.
	static var send_message = neko.Lib.load("hive","send_message",1);
}


