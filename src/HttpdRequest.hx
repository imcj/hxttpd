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

// http://www.cs.columbia.edu/sip/syntax/rfc2068.html

import neko.io.File;
import neko.io.FileInput;
import neko.FileSystem;

enum HttpMethod {
	METHOD_UNKNOWN;
        METHOD_GET;
        METHOD_POST;
	METHOD_HEAD;
}

// application/x-www-form-urlencoded (FORM)
//
enum PostType {
	POST_NONE;
	POST_FORM;
	POST_MULTIPART;
}

typedef VarList = {
	key: String,
	value: String
}

class HttpdRequest {
	public var requestline			: String;
        public var method 			: HttpMethod;
        public var url 				: String;
	public var uriparts			: Array<String>;
	public var args				: String;
        public var version 			: String;
        public var version_major		: Int;
        public var version_minor		: Int;
	public var agent 			: String;
	public var referer 			: String;
	public var host 			: String;
	public var port 			: Int;
	public var path 			: String;
	public var path_translated		: String;
	public var path_info			: String;
	public var headers_in			: List<VarList>;
	public var post_data 			: String;
	public var post_type			: PostType;
	public var in_content_type		: String;
	public var in_content_length		: Int;
	public var in_transfer_encoding		: String;
	public var in_content_boundary		: String;
	public var in_ranges			: Array<HttpdRange>;
	public var username			: String;
	public var cpassword			: String;
	public var if_unmodified_since		: GmtDate;
	public var if_modified_since		: GmtDate;


	public var cookies(getCookies,null)	: Array<HttpCookie>;
	public var get_vars			: Array<VarList>;
	public var post_vars			: Array<VarList>;
	public var file_vars			: Array<HttpdRequestResource>;


	public var client(default,null)			: HttpdClientData;
	public var serial_number			: Int;
	private var tmpfile				: neko.io.TmpFile;

	public function new(client:HttpdClientData, serial:Int) {
		this.client = client;
		this.serial_number = serial;
		init();
	}

	public function init() {
		requestline = null;
		method = METHOD_UNKNOWN;
		url = null;
		uriparts = new Array();
		args = null;
		version = null;
		agent = null;
		referer = null;
		host = null;
		port = 0;
		path = null;
		path_translated = null;
		path_info = null;
		headers_in = new List();
		post_data = "";
		post_type = POST_NONE;
		in_content_type = null;
		in_content_length = 0;
		in_transfer_encoding = null;
		in_content_boundary = null;
		in_ranges = null;
		username = null;
		cpassword = null;
		if_unmodified_since = null;
		if_modified_since = null;

		cookies = new Array<HttpCookie>();
		get_vars = new Array<VarList>();
		post_vars = new Array<VarList>();
		file_vars = new Array<HttpdRequestResource>();
	}

	public function getMainModuleRequest() {
		return this;
	}

	public function getHeaderIn(key:String) : String {
		var klc = key.toLowerCase();
		for(i in headers_in) {
			if(i.key.toLowerCase() == klc)
				return i.value;
		}
		return null;
	}

	public function getCookies() : Array<HttpCookie> {
		return cookies;
	}

	public function setRequestHeader(key : String, val : String) : Bool {
		// request headers are case insensitive
		if(key == null || val == null)
			return true;
		headers_in.push({key:key, value:val});

		key = key.toLowerCase();
		if(key == "host") {
			return setHost(val);
			return true;
		}
		if(key == "user-agent") {
			agent = val;
			return true;
		}
		if(key == "connection") {
			if(val.toLowerCase() == "keep-alive")
				client.response.keepalive = true;
			else
				client.response.keepalive = false;
			return true;
		}
		if(key == "keep-alive") {
			//Keep-Alive: 300
			//Connection: keep-alive
			client.response.keepalive = true;
			return true;
		}
		if(key == "content-type") {
			//application/x-www-form-urlencoded
			// or
			//multipart/form-data; boundary=---------------------------262812997472408787435964820
			var p = val.indexOf(";");
			if( p == 1 || p >= val.length - 1 ) {
				trace("Request: invalid content-type " + val);
				client.response.setStatus(400);
				return false;
			}
			if(p > 0) {
				in_content_type = StringTools.trim(val.substr(0, p));
				val = StringTools.trim(val.substr(p+1));
				if(val.substr(0,9) == "boundary=") {
					in_content_boundary = val.substr(10);
				}
			}
			else {
				in_content_type = val;
			}
			if(in_content_type.toLowerCase() == "application/x-www-form-urlencoded")
				post_type = POST_FORM;
			else
				post_type = POST_MULTIPART;
			return true;
		}
		if(key == "content-length") {
			in_content_length = Std.parseInt(val);
			return true;
		}
		if(key == "transfer-encoding") {
			in_transfer_encoding = val;
			return true;
		}
		if(key == "referer") {
			referer = val;
			return true;
		}
		if(key == "if-modified-since") {
			try {
				var gdate : GmtDate = GmtDate.fromString(val);
				if(gdate.gt(GmtDate.now())) {
					// xxx
					HxTTPDTinyServer.log_error(null, "If-Modified-Since date \""+val+"\" is in the future. Ignoring.");
					if_modified_since = null;
				}
				else { if_modified_since = gdate; }
			}
			catch(e : Dynamic) {
				if_modified_since = null;
				// xxx
				HxTTPDTinyServer.log_error(null, "Date parse error for If-Modified-Since date \""+val+"\" " + e);
			}
			return true;
		}
		if(key == "if-unmodified-since") {
			return true;
		}
		if(key == "range") {
			/* TODO: test and activate
			// Invalid ranges are simply ignored. Return the file
			// Apache just serves the whole file in one multipart/byteranges; boundary
			//parseRange(val);
			in_ranges = HttpdRange.fromString(val);
			content_count = ranges.length;
			if(in_ranges.length == 0) {
				content_count = 1;
				ranges = null;
				return true;
			}
			if(in_ranges.length > 1) {
				multipart = true;
			}
			*/
			return true;
		}
		if(key == "cookie") {
			try {
				var cArray = HttpCookie.fromString(val);
				cookies = cookies.concat(cArray);
			} catch(e:Dynamic) {
				//client.server.log_error("Invalid cookie header "+val);
			}
			return true;
		}
		if(key == "if-range") {
		}
		if(key == "expect") {
			// expect 100-continue
			client.response.setStatus(417);
			return false;
		}
		if(key == "authorization") {
		}
		return true;
	}

	public function setHost(value : String) : Bool
	{
		var parts : Array<String>;
		parts = value.split(":");
		host = parts[0].toLowerCase();
		if(host == null || host.length == 0)
			return false;
		if(host.charAt(host.length -1) == ".")
			host = host.substr(0, host.length-1);
		port = Std.parseInt(parts[1]);
		if(port == null || port == 0)
			port = HxTTPDTinyServer.default_port;
		return true;
	}

	public function processRequest(line : String) : Int {
		line = StringTools.trim(line);
		requestline = line; // for logging

		if(line.length == 0)
			return 400;

		var r : EReg = ~/HTTP\/([0-9.]+)$/g;
		if(! r.match(line))
			return 505;

		version = r.matched(1);
		if(version == "1.0")
			client.response.keepalive = false;
		else if(version != "1.1")
			return 505;

		// wipe out HTTP and trim input
		line = StringTools.trim(r.replace(line, ""));

		// parse method
		var data = line.split(" ");
		if(data.length == 0)
			return 400;
		if(data[0] == "GET")
			method = METHOD_GET;
		else if(data[0] == "HEAD")
			method = METHOD_HEAD;
		else if(data[0] == "POST")
			method = METHOD_POST;
		if(method == METHOD_UNKNOWN)
			return 501;

		// no url
		if(data.length != 2)
			return 404;

		url = data[1];
		// Request-URI Too Long
		if(url.length > 1024)
			return 414;
		return 200;
	}

	public function processHeaders(lines : Array<String>) : Bool {
		var key : String = null;
		var lastkey : String = null;
		var value : String = null;
		for(i in lines) {
			if(lastkey != null) {
				// single space or tab is value continuation
				if(i.charAt(0) == " " || i.charAt(0) == "\t") {
					// rfc 2616 sec 2.2 (may replace continuation with SP)
					value = value + " " + StringTools.trim(i);
					if(!setRequestHeader(lastkey, value)) {
						trace("Request: invalid header "+i);
						if(client.response.getStatus() == 0)
							client.response.setStatus(400);
						return false;
					}
					continue;
				}
				lastkey = null;
			}
			if(lastkey == null) {
				i = StringTools.trim(i);
				if(i.length == 0) continue;
				var p = i.indexOf(":");
				if( p < 2 || p >= i.length - 1 ) {
					trace("Request: invalid short header "+i);
					client.response.setStatus(400);
					return false;
				}
				key = StringTools.trim(i.substr(0, p));
				value = StringTools.trim(i.substr(p+1));
			}
			if(!setRequestHeader(key, value)) {
				trace("Request: invalid header "+i);
				if(client.response.getStatus() == 0)
					client.response.setStatus(400);
				return false;
			}
			lastkey = key;
		}
		// HTTP/1.1 with no host specified
		if(version_minor > 0 && host == null) {
			client.response.setStatus(400);
			return false;
		}
		return true;
	}

	/**
		process url -> uri path + args
		does not do translation to filesystem
	**/
	public function processUrl() : Bool {
		// strip off args
		args = null;
		var i : Int = url.indexOf("?");
		if(i >= 0) {
			var urlcpy = url;
			url = url.substr(0,i);
			if(i < urlcpy.length - 1)
				args = urlcpy.substr(i+1);
			trace(url + " args: " + args);
			get_vars = parseGetStyleVars(args);
		}

		url = StringTools.urlDecode(url);
		if(url == null) {
			client.response.setStatus(400);
			return false;
		}
		// full url
		if(url.charAt(0) != "/") {
			var idx : Int = url.indexOf("//");
			var newUrl : String;
			if(idx < 0) {
				HxTTPDTinyServer.log_error(client, "Absolute URL incomplete "+url, 1);
				client.response.setStatus(400);
				return false;
			}
			idx += 2;
			var idx2 : Int = url.indexOf("/", idx);
			if(idx2 < 0) {
				newUrl = "/";
				idx2 = url.length;
			}
			else {
				newUrl = url.substr(idx2);
			}
			if(! setHost(url.substr(idx, idx2-idx))) {
				HxTTPDTinyServer.log_error(client, "Absolute URL incomplete "+url, 1);
				client.response.setStatus(400);
				return false;
			}
			url = newUrl;
			trace(here.methodName + " FULL URL host=" + host + ":" + Std.string(port) + " url="+url);
		}
		path = url;
		return true;
	}




	public function startPost() : Bool {
		switch(post_type) {
		case POST_NONE:
			return false;
		case POST_FORM:
		case POST_MULTIPART:
			HxTTPDTinyServer.logTrace(here.methodName + " POST_MULTIPART");
			tmpfile = new neko.io.TmpFile();
		}
		return true;
	}

	/**
		Add post data to the request
	*/
	public function addPostData(buf : String, bufpos : Int, buflen : Int ) : Bool {
		switch(post_type) {
		case POST_NONE:
			return false;
		case POST_FORM:
			// must consume all of it.
			post_data += buf.substr(bufpos, buflen);
			if(post_data.length > (256*1024))
				throw "Post data overflow";
			return true;
		case POST_MULTIPART:
			HxTTPDTinyServer.logTrace(here.methodName + " POST_MULTIPART "+buflen+" bytes from "+bufpos);
			try {
				tmpfile.getOutput().writeBytes(buf, bufpos, buflen);
				//tmpfile.getOutput().write(buf.substr(bufpos,buflen));
			} catch(e:Dynamic) {
				trace(here.methodName + " file write error");
				return true;
			}
			return true;
		}
		return false;
	}

	public function postComplete() : Bool {
		switch(post_type) {
		case POST_NONE:
			return true;
		case POST_FORM:
			return post_data.length >= in_content_length;
		case POST_MULTIPART:
			return tmpfile.getOutput().tell() >= in_content_length;
		}
		return true;
	}

	public function finalizePost() {
		//trace(here.methodName);
		switch(post_type) {
		case POST_NONE:
			throw(here.methodName + " post_type in invalid state POST_NONE");
		case POST_FORM:
			post_vars = post_vars.concat(parseGetStyleVars(post_data));
			//HxTTPDTinyServer.logTrace(post_vars.toString(),4);
		case POST_MULTIPART:
			HxTTPDTinyServer.logTrace(here.methodName + " POST_MULTIPART");
			try {
				var fi = tmpfile.getInput();
				fi.seek(0, SeekBegin);
				trace(fi.readAll());
				//tmpfile.close();

				parseMultipartFile(tmpfile, this);
			}
			catch(e:Dynamic) { trace(e); }
			//trace(post_vars);
		}
	}

	public function setClientState(s:Int) {
		client.setState(s);
	}


	///////////////////////////////////////////////////////////////////////////
	//                     STATIC METHODS                                    //
	///////////////////////////////////////////////////////////////////////////

	public static function parseGetStyleVars(s:String) : Array<VarList> {
		var rv = new Array<VarList>();
		var args = s.split("&");
		for(i in args) {
			var v = i.split("=");
			rv.push(
				{ 	key: StringTools.urlDecode(v[0]),
					value:StringTools.urlDecode(v[1])
				}
			);
		}
		return rv;
	}


	public static function parseCookies(cookies:Array<HttpCookie>) {
		var rv = new Hash<String>();
		for(i in cookies) {
			// TODO date checking
			rv.set(i.getName(), i.getValue());
		}
		return rv;
	}

	public static function parseMultipartFile(f:neko.io.TmpFile, r:HttpdRequest) : Void {
		//HxTTPDTinyServer.logTrace(here.methodName,5);
		var DEFAULT_BUFSIZE = 16*1024;
		var fi = f.getInput();
		//var fo = f.getOutput();
		//------------oikgW9sSmaGyRqbcpTZLpZSn1VaGBhyxPjcusUMc4cYVR85GbeZRE0C
		//Content-Disposition: form-data; name="file_two"; filename=""

		var findValue = function(s:String, p:Int) : String {
			var value : String;
			if(p < 0)
				return null;
			if(s.charAt(p) != '"') {
				if(s.charAt(p) == "")
					return null;
				value = s.substr(p);
			}
			else {
				var e = s.indexOf('"',p+1);
				value = s.substr(p+1,e-p-1);
			}
			return value;
		}

		var s : String;
		var headLines = new List<String>();
		try { fi.seek(0, SeekBegin); } catch(e:Dynamic) { return; }

		var boundary = StringTools.trim("---"+r.in_content_boundary);
		while(true) {
			var name : String = null;
			var mime : String = null;
			var resource : HttpdRequestResource = null;

			//HxTTPDTinyServer.logTrace(">> readLine()");
			try { s = fi.readLine(); } catch(e:Dynamic) { return; }
			//HxTTPDTinyServer.logTrace("   "+s);
			if(s != boundary) {
				return;
			}
			headLines.clear();

			try {
				while("" != (s = fi.readLine()) ) {
					//HxTTPDTinyServer.logTrace("   "+s);
					if(headLines.length > 20)
						return;
					if(s.length > (20 *1024))
						return;
					headLines.add(s);
				}
			}
			catch (e : Dynamic) { return; }

			// processHeaders
			var headers = new Hash<String>();
			for(i in headLines) {
				i = StringTools.trim(i);
				if(i.length == 0)
					return;
     				var p = i.indexOf(":");
				if( p < 2 || p >= i.length - 1 ) {
					HxTTPDTinyServer.logTrace(here.methodName + ": invalid short header while parsing multipart data "+i,0);
					return;
				}
				headers.set(StringTools.trim(i.substr(0, p)).toLowerCase(), StringTools.trim(i.substr(p+1)));
			}

			//trace(headers);
			if(!headers.exists("content-disposition"))
				return;
			s = headers.get("content-disposition");

			var p = s.indexOf("name=");
			if(p < 0)
				return;
			p += 5;
			name = findValue(s, p);
			if(name.length == 0)
				return;

			resource = new HttpdRequestResource(name);
			p = s.indexOf("filename=");
			if(p >= 0) {
				p += 9;
				resource.setFilename(findValue(s, p));
				if(headers.exists("content-type"))
					resource.mime_type = StringTools.trim(headers.get("content-type"));
			}

			while(true) {
				var buf : String = neko.Lib.makeString(DEFAULT_BUFSIZE);
				var buflen : Int = 0;
				var bytesRead : Int = 0;
				var eof:Bool = false;
				try{
					bytesRead = fi.readBytes(buf, 0, DEFAULT_BUFSIZE);
				}
				catch(e:neko.io.Eof) {}
				catch(e:Dynamic) {
					trace("POST data io error");
					return;
				}
				eof = fi.eof();

				p = buf.indexOf(boundary);

				try {
					if(p < 0) {
						// boundary not found, assume may be partly
						// at end of buffer.
						buflen = bytesRead - boundary.length - 1;
						resource.addData(buf, 0, buflen);
					}
					else {
					// boundary found.
						buflen = p;
						// do not add the \r\n
						resource.addData(buf, 0, buflen-2);
					}
				}
				catch(e:Dynamic) {
					try {fi.seek(0-(bytesRead - buflen), SeekCur);}
					catch(e:Dynamic) { return; }
					break;
				}

				try {
					// reset for next read
					fi.seek(0-(bytesRead - buflen), SeekCur);
				} catch(e:Dynamic) {
					resource = null;
					return;
				}
				if(p>=0 || eof) break;
			} // while true read data

			if(resource.isFile) {
				r.file_vars.push(resource);
			}
			else {
				// add post var
				// TODO: length checking etc.
				trace(resource.getValue());
				r.post_vars.push({key:resource.name, value:resource.getValue()});
			}
		} // while true read header
	}
}

/*
	// Multipart when using "form upload.html" and sending one file
	// NOTE the trailing two - signs on the final boundary

------------cKRzOp35uw7dhIsNbEEs5FOtOSwpRWr4qI1C83G2zLdfdV0FiE5lTRc
Content-Disposition: form-data; name="somename"; filename="code"
Content-Type: text/x-objcsrc

... File DATA HERE ...

------------cKRzOp35uw7dhIsNbEEs5FOtOSwpRWr4qI1C83G2zLdfdV0FiE5lTRc
Content-Disposition: form-data; name="submit"

button
------------cKRzOp35uw7dhIsNbEEs5FOtOSwpRWr4qI1C83G2zLdfdV0FiE5lTRc--
*/

/*
	// Normal form elements
HttpdRequest.hx:393: addContentIn in_content_type application/x-www-form-urlencoded[null]
HttpdRequest.hx:395: addContentIn >> DATA FOLLOWS
textfield=my+text&submit=button
>> END OF POST DATA
*/