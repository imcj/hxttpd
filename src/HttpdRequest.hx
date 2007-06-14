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

import neko.io.File;
import neko.io.FileInput;

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
	public var path_final				: String;
        public var headers_in 				: Hash<String>;
	public var post_data 				: String;
	public var in_content_type			: String;
	public var in_content_length			: Int;
	public var in_transfer_encoding			: String;
	public var in_content_boundary			: String;
	public var username				: String;
	public var cpassword				: String;
	public var if_unmodified_since			: GmtDate;
	public var if_modified_since			: GmtDate;

	// response to request
	public var return_code                		: Int;
	public var headers_out 	        		: List<String>;
	public var type					: ResponseType;
	public var message				: String;
	public var file					: FileInput; // file handle
	public var bytes_left				: Int;
	public var content_count			: Int;
	public var content_type			 	: String;
	public var content_length 			: Int;
	public var last_modified			: GmtDate;
	public var location				: String;
	public var ranges				: Array<HttpdRange>;
	public var multipart				: Bool;
	public var keepalive				: Bool;

	public function new() {
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
		path_final = null;
		headers_in = new Hash<String>();
		post_data = null;
		in_content_type = null;
		in_content_length = 0;
		in_transfer_encoding = null;
		in_content_boundary = null;
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
		last_modified = null;
		location = null;
		ranges = null;
		multipart = false;
		keepalive = true;	// HTTP/1.1 Default
	}

	public function setRequestHeader(key : String, val : String) : Bool {
		// request headers are case insensitive
		key = key.toLowerCase();
		//trace(here.methodName + " Key: " + key + " value: " + val, 5);
		if(key == null || val == null)
			return true;
		headers_in.set(key, val);

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
			ranges = HttpdRange.fromString(val);
			content_count = ranges.length;
			if(ranges.length == 0) {
				content_count = 1;
				ranges = null;
				return true;
			}
			if(ranges.length > 1) {
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


	function parseRange(val : String) {
		// either
		// a) Encompass a range to include the min and max, then do a single range response
		// b) Do 206 Partial Content
		//	HTTP/1.1 206 Partial Content
		//	Date: Wed, 15 Nov 1995 06:25:24 GMT
		//	Last-Modified: Wed, 15 Nov 1995 04:58:08 GMT
		//	Content-type: multipart/byteranges; boundary=THIS_STRING_SEPARATES
		//
		//	--THIS_STRING_SEPARATES
		//	Content-type: application/pdf
		//	Content-range: bytes 500-999/8000
		//
		//	...the first range...
		//	--THIS_STRING_SEPARATES
		//	Content-type: application/pdf
		//	Content-range: bytes 7000-7999/8000
		//
		//	...the second range
		//	--THIS_STRING_SEPARATES--
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

	public function addContentIn(buf : String, bufpos : Int, buflen : Int ) {
		trace(here.methodName + " in_content_type "+ in_content_type + "["+in_content_boundary+"]");
		var data : String  = buf.substr(bufpos, buflen);
		trace(here.methodName + " >> DATA FOLLOWS\n" + data + "\n>> END OF POST DATA");
		return 0;
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