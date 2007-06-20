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

enum ResponseType {
	TYPE_UNKNOWN;
	TYPE_FILE;
	TYPE_CGI;
}

class HttpdRequest {
	public var requestline				: String;
        public var method 				: HttpMethod;
        public var url 					: String;
	public var args					: String;
        public var version 				: String;
        public var version_major			: Int;
        public var version_minor			: Int;
	public var agent 				: String;
	public var referer 				: String;
	public var host 				: String;
	public var port 				: Int;
	public var path 				: String;
	public var path_translated			: String;
	public var path_info				: String;
        public var headers_in 				: List<{ value : String, header : String}>;
	public var post_data 				: String;
	public var in_content_type			: String;
	public var in_content_length			: Int;
	public var in_transfer_encoding			: String;
	public var in_content_boundary			: String;
	public var in_ranges				: Array<HttpdRange>;
	public var username				: String;
	public var cpassword				: String;
	public var if_unmodified_since			: GmtDate;
	public var if_modified_since			: GmtDate;

	// response to request
	public var return_code                		: Int;
	public var headers_out 	        		: List<String>;
	public var type					: ResponseType;
	public var message				: String;
	public var file					: FileInput;
	public var bytes_left				: Int;
	public var content_count			: Int;
	public var content_type			 	: String;
	public var content_length 			: Int;
	public var content_boundary(default,null)	: String;
	public var last_modified			: GmtDate;
	public var location				: String;
	public var ranges				: Array<HttpdRange>;
	public var multipart				: Bool;
	public var keepalive				: Bool;

	var client					: HttpdClientData;

	public function new(client:HttpdClientData) {
		this.client = client;
		init();
	}

	public function init() {
		requestline = null;
		method = METHOD_UNKNOWN;
		url = null;
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
		post_data = null;
		in_content_type = null;
		in_content_length = 0;
		in_transfer_encoding = null;
		in_content_boundary = null;
		in_ranges = null;
		username = null;
		cpassword = null;
		if_unmodified_since = null;
		if_modified_since = null;

		return_code = 0;
		headers_out = new List();
		type = TYPE_UNKNOWN;
		message = null;
		file = null;
		bytes_left = null;
		//mime_type = null;
		content_count = 0;
		content_type = null;
		content_length = 0;
		content_boundary = generateContentBoundary();
		last_modified = null;
		location = null;
		ranges = null;
		multipart = false;
		keepalive = true;	// HTTP/1.1 Default
	}

	public function getHeaderIn(key:String) : String {
		var klc = key.toLowerCase();
		for(i in headers_in) {
			if(i.header.toLowerCase() == klc)
				return i.value;
		}
		return null;
	}

	public function getCookies() : Hash<String> {
		var ch = new Hash<String>();
		var p = new Array<String>();
		for(i in headers_in) {
			if(i.header.toLowerCase() != "cookie")
				continue;
			var pp = i.value.split("; ");
			p = p.concat(pp);
		}
		for(i in p) {
			var pp = i.split("=");
			ch.set(pp[0],pp[1]);
		}
		return ch;
	}

	/**
		Create a response content boundary string.
		TODO: This should notbe called on initialization
			of the request
	**/
	public static function generateContentBoundary() : String {
		var s : String = "------------";
		for(x in 0...55) {
			var r = Std.random(62);
			if(r < 10) { // 0-9
				s += Std.chr(48 + r);
			}
			else if(r < 36) { // A-Z
				s += Std.chr(55 + r);
			}
			else { // a-z
				s += Std.chr(61 + r);
			}
		}
		return s;
	}

	public static function parseArgs(s_args:String) : Dynamic {
		var args = s_args.substr(1).split("&");
		var r = Reflect.empty();
		for (a in args) {
			var v = a.split("=");
			Reflect.setField(r,StringTools.trim(v[0]),StringTools.trim(v[1]));
		}
		return r;
	}

	public function setRequestHeader(key : String, val : String) : Bool {
		// request headers are case insensitive
		if(key == null || val == null)
			return true;
		headers_in.push({value:val, header:key});

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
				keepalive = true;
			else
				keepalive = false;
			return true;
		}
		if(key == "keep-alive") {
			//Keep-Alive: 300
			//Connection: keep-alive
			keepalive = true;
			return true;
		}
		if(key == "content-type") {
			//application/x-www-form-urlencoded
			// or
			//multipart/form-data; boundary=---------------------------262812997472408787435964820
			var p = val.indexOf(";");
			if( p == 1 || p >= val.length - 1 ) {
				trace("Request: invalid content-type " + val);
				return_code = 400;
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
		if(key == "if-range") {
		}
		if(key == "expect") {
			// expect 100-continue
			return_code = 417;
			return false;
		}
		if(key == "authorization") {
		}
		return true;
	}

	public function addResponseHeader(key : String, value : String) : Void
	{
		headers_out.add(key + ": " + value);
	}

	public function setMessage(value : String) : Void
	{
		content_type = "text/html";
		content_length = value.length;
		content_count = 1;
		last_modified = null;
		message = value;
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

	public function processRequest(line : String) : Bool {
		line = StringTools.trim(line);
		requestline = line; // for logging

		if(line.length == 0) {
			return_code = 400;
			return false;
		}

		var r : EReg = ~/HTTP\/([0-9.]+)$/g;
		if(! r.match(line)) {
			return_code = 505;
			return false;
		}
		version = r.matched(1);
		if(version == "1.0") {
			keepalive = false;
		} else if(version != "1.1") {
			return_code = 505;
			return false;
		}
		// wipe out HTTP and trim input
		line = StringTools.trim(r.replace(line, ""));

		var data = line.split(" ");
		if(data.length == 0) {
			return_code = 400;
			return false;
		}
		if(data[0] == "GET") {
			method = METHOD_GET;
		}
		else if(data[0] == "HEAD") {
			method = METHOD_HEAD;
		}
		else if(data[0] == "POST") {
			method = METHOD_POST;
		}
		if(method == METHOD_UNKNOWN) {
			return_code = 501;
			return false;
		}

		if(data.length != 2) {
			return_code = 404;
			return false;
		}
		url = data[1];
		// Request-URI Too Long
		if(url.length > 1024) {
			return_code = 414;
			return false;
		}
		return true;
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
						if(return_code == 0)
							return_code = 400;
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
					return_code = 400;
					return false;
				}
				key = StringTools.trim(i.substr(0, p));
				value = StringTools.trim(i.substr(p+1));
			}
			if(!setRequestHeader(key, value)) {
				trace("Request: invalid header "+i);
				if(return_code == 0)
					return_code = 400;
				return false;
			}
			lastkey = key;
		}
		// HTTP/1.1 with no host specified
		if(version_minor > 0 && host == null) {
			return_code = 400;
			return false;
		}
		return true;
	}

	/**
		process url -> uri path + args
		does not do translation to filesystem
	**/
	public function processUrl() : Bool {
		url = StringTools.urlDecode(url);
		if(url == null) {
			return_code = 400;
			return false;
		}
		// full url
		if(url.charAt(0) != "/") {
			var idx : Int = url.indexOf("//");
			var newUrl : String;
			if(idx < 0) {
				HxTTPDTinyServer.log_error(client, "Absolute URL incomplete "+url, 1);
				return_code = 400;
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
				return_code = 400;
				return false;
			}
			url = newUrl;
			trace(here.methodName + " FULL URL host=" + host + ":" + Std.string(port) + " url="+url);
		}
		args = null;
		var i : Int = url.indexOf("?");
		if(i < 0) {
			path = url;
		}
		else {
			path = url.substr(0,i);
			if(i < url.length - 1)
				args = url.substr(i+1);
			trace(path + " args: " + args);
		}
		return true;
	}


	public function openFile(d : HttpdClientData, filename : String) : Bool {
		if( file != null ) {
			HxTTPDTinyServer.log_error(client, "Request already has an open file");
			return false;
		}
		try {
			file = File.read(filename, true);
			trace(here.methodName + file);
		}
		catch(e : Dynamic) { file = null; return false; }
		type = ResponseType.TYPE_FILE;
		var stat = FileSystem.stat( filename );
		last_modified = GmtDate.fromLocalDate(stat.mtime);
		if(last_modified.gt(GmtDate.now())) {
			HxTTPDTinyServer.log_error(client, "File "+filename+" has a modification date in the future");
			last_modified = GmtDate.now();
		}
		content_length = stat.size;
		content_count = 1;
		setMimeType(d, filename);
		trace(here.methodName + " file: " + filename + " size: " + stat.size);
		return true;
	}

	function setMimeType(d : HttpdClientData, filename : String) : Bool {
		content_type = "unknown/unknown";
		var r : EReg = ~/\.([0-9A-Za-z]+)$/;
		r.match(filename);
		try {
			//mime_type = Mime.extensionToMime(r.matched(1));
			content_type = Mime.extensionToMime(r.matched(1));
		}
		catch(e :Dynamic) {}
		trace(here.methodName + " " + content_type);
		return true;
	}


	/**
		Add post data to the request
		Should actually open a temp file for storage
	*/
	public function addPostData(buf : String, bufpos : Int, buflen : Int ) : Bool {
		//trace(here.methodName + " in_content_type "+ in_content_type + "["+in_content_boundary+"]");
		post_data += buf.substr(bufpos, buflen);
		//trace(here.methodName + " >> DATA FOLLOWS\n" + data + "\n>> END OF POST DATA");
		return true;
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