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

// TODO: Finish Cookie V1
class HttpCookie {

	public var name(getName,setName)		: String;
	public var value(getValue,setValue)		: Dynamic;
	public var comment(getComment,setComment)	: String;
	public var domain(getDomain,setDomain)		: String;
	public var expires(getExpires,setExpires)	: Date;
	public var max_age(getMaxAge,setMaxAge)		: Int;
	public var path(getPath,setPath)		: String;

	public var secure(getSecure,setSecure)		: Bool;
	public var version(getVersion,setVersion)	: Int;

	/**
		Create a new cookie. Will throw if the name is invalid.
	*/
	public function new(name:String, value:String) {
		this.name = name;
		this.value = value;
		expires = null;
		max_age = -1;
		path = null;
		domain = null;
		secure = false;
		version = 0;
	}

	public function getName() : String { return name; }
	public function setName(str:String) : String { name = str; return name; }

	public function getValue() : Dynamic { return value; }
	public function setValue(str:Dynamic) : Dynamic { value = str; return value; }

	public function getComment() { return comment; }
	public function setComment(str:String) : String {
		setVersion(1);
		comment = str;
		return comment;
	}

	public function getDomain() : String { return domain; }
	public function setDomain(str:String) : String { domain = str; return domain; }

	public function getExpires() : Date { return expires; }
	public function setExpires(d:Date) : Date { expires = d; return expires; }

	/**
		Get maximum age in seconds. If no max was specified, returns
		-1
	*/
	public function getMaxAge() : Int { return max_age; }
	/**
		Set the max age in seconds for this cookie. To
		set no max age, specify -1
	*/
	public function setMaxAge(v:Int): Int {
		if(v < 0) v = -1;
		max_age = v;
		return max_age;
	}

	public function getPath() : String  { return path; }
	public function setPath(str:String) : String { path = str; return path; }

	public function getSecure() : Bool { return secure; }
	public function setSecure(v:Bool) : Bool { secure = v; return secure;}

	public function getVersion() : Int { return version; }
	public function setVersion(v:Int) : Int {
		if(v != 0 && v != 1)
			throw "Invalid cookie version";
		version = v;
		return version;
	}

	public static function fromString(cs:String) : Array<HttpCookie> {
		var cookielist = new Array<HttpCookie>();
		var eReg = ~/^[Set-]*Cookie: /gi;
		cs = eReg.replace(cs,"");

		var tags = StringTools.trim(cs).split(";");
		var cookie : HttpCookie = null;
		for(t in tags) {
			t = StringTools.trim(t);
			var nameValue = t.split("=");
			nameValue[0] = StringTools.trim(nameValue[0]);
			var attr = StringTools.urlDecode(nameValue[0]).toLowerCase();
			var value = StringTools.urlDecode(nameValue[1]);
			switch(attr) {
			case "comment": // V1
				if(cookie != null) {
					cookie.setVersion(1);
					cookie.setComment(value);
				}
			case "domain":  // both
				if(cookie != null)
					cookie.setDomain(value);
			case "expires": // V0
				if(cookie != null) {
					try {
						cookie.expires = GmtDate.fromString(value).getLocalDate();
					}
					catch(e:Dynamic) {
						cookie.expires = null;
					}
				}
			case "max-age": // V1
				if(cookie != null) {
					cookie.setVersion(1);
					cookie.setMaxAge(Std.parseInt(value));
				}
			case "path": // BOTH
				if(cookie != null)
					cookie.setPath(value);
			case "secure": // BOTH
				if(cookie != null)
					cookie.setSecure(true);
			case "version": // V1 only
				if(cookie != null)
					cookie.setVersion(Std.parseInt(value));
			default:
				if(cookie != null)
					cookielist.push(cookie);
				cookie = new HttpCookie(nameValue[0], nameValue[1]);
			}
		}
		if(cookie != null)
			cookielist.push(cookie);

		return cookielist;
	}

// 	public static function fromString(cs:String) : Array<HttpCookie> {
// 		var cookielist = new Array<HttpCookie>();
// 		var eReg = ~/^[Set-]*Cookie: /gi;
// 		cs = eReg.replace(cs,"");
// 		var parts = cs.split(",");
// 		for(i in parts) {
// 			var tags = StringTools.trim(i).split(";");
// 			var nameValue = StringTools.trim(tags.shift()).split("=");
// 			//trace(here.methodName + " "+ nameValue[0] +" "+ nameValue[1]);
// 			var cookie = new HttpCookie(nameValue[0], nameValue[1]);
// 			for(t in tags) {
// 				t = StringTools.trim(t);
// 				nameValue = t.split("=");
// 				nameValue[0] = StringTools.trim(nameValue[0]);
// 				var attr = StringTools.urlDecode(nameValue[0]).toLowerCase();
// 				var value = StringTools.urlDecode(nameValue[1]);
// 				switch(attr) {
// 				case "comment": // V1
// 					cookie.setVersion(1);
// 					cookie.setComment(value);
// 				case "domain":  // both
// 					cookie.setDomain(value);
// 				case "expires": // V0
// 				case "max-age": // V1
// 					cookie.setVersion(1);
// 					cookie.setMaxAge(Std.parseInt(value));
// 				case "path": // BOTH
// 					cookie.setPath(value);
// 				case "secure": // BOTH
// 					cookie.setSecure(true);
// 				case "version": // V1 only
// 					cookie.setVersion(Std.parseInt(value));
// 				default:
// 					trace("UNKNOWN cookie attribute: "+attr);
// 				}
// 			}
// 			cookielist.push(cookie);
// 		}
// 		return cookielist;
// 	}

	/**
		Return a cookie header line for sending to web browser
		From a web script/webserver, syntax is "Set-Cookie: name=val[; ...]"
	*/
	public function toString() {
		var cs = new StringBuf();
		cs.add("Set-Cookie: ");
		cs.add(HttpCookie.bodyString(this));
		return cs.toString();
	}

	/**
		Return cookie header for sending to a http server.
		From a web browser, syntax is "Cookie: name=val[; ...]"
	*/
	public function toClientString() {
		var cs = new StringBuf();
		cs.add("Cookie: ");
		cs.add(HttpCookie.bodyString(this));
		return cs.toString();
	}

	/**
		Generate only the body of the cookie, that is the
		part not including the Cookie: or Set-Cookie: part.
	*/
	public static function bodyString(c:HttpCookie) : StringBuf {
		var buf = new StringBuf();
		buf.add(StringTools.urlEncode(c.getName()));
		buf.addChar(61);
		buf.add(StringTools.urlEncode(c.getValue()));
		if(c.getExpires() != null) {
			buf.add("; expires=");
			buf.add(GmtDate.timestamp(c.getExpires()));
			//buf.add(c.getExpires().rfc822timestamp());
		}
		if(c.getPath() != null) {
			buf.add("; path=");
			buf.add(StringTools.urlEncode(c.getPath()));
		}
		if(c.getDomain() != null) {
			buf.add("; domain=");
			buf.add(StringTools.urlEncode(c.getDomain()));
		}
		if(c.getSecure()) {
			buf.add("; secure");
		}
		return buf;
	}

	/**
		This creates a single Cookie line from a set of cookies.
		By default, the cookie line is assumed to be coming from
		the server, sent to the web browser. If you wish to send
		a Cookie: line from a web browser client, set fromClient
		to true.
	*/
	public static function toSingleLineString(cookies:Array<HttpCookie>, ?fromClient:Bool) : String {
		var buf = new StringBuf();
		if(!fromClient)
			buf.add("Set-Cookie: ");
		else
			buf.add("Cookie: ");
		var initial : Bool = true;
		for(i in cookies) {
			if(initial)
				initial = false;
			else
				buf.add(", ");
			buf.add(bodyString(i));
		}
		return buf.toString();
	}
}