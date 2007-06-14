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

class HttpdResponse {
	static var codemap : IntHash<String>;
	static var htmlmap : IntHash<String>;
	static var initialized : Bool		= false;

	static public function init() {
		// must be done first, html init below relies on
		// codemap being setup already
		initialized = true;

		codemap = new IntHash<String>();
		// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
		codemap.set(100, "Continue");
		codemap.set(101, "Switching Protocols");
		codemap.set(200, "OK");
		codemap.set(201, "Created");
		codemap.set(204, "No Content");
		codemap.set(206, "Partial Content");
		codemap.set(301, "Moved Permanently");
		codemap.set(302, "Moved");
		codemap.set(304, "Not Modified");
		codemap.set(307, "Temporary Redirect");
		codemap.set(400, "Bad Request");
		codemap.set(401, "Not Authorized");
		codemap.set(403, "Forbidden");
		codemap.set(404, "Not Found");
		codemap.set(405, "Method Not Allowed");
		codemap.set(411, "Length Required");
		codemap.set(412, "Precondition Failed");
		codemap.set(414, "Request-URI Too Long");
		codemap.set(416, "Requested Range Not Satisfiable");
		codemap.set(417, "Expectation Failed");
		codemap.set(500, "Internal Server Error");
		codemap.set(501, "Method Not Implemented");
		codemap.set(503, "Service Unavailable");
		codemap.set(505, "HTTP Version Not Supported");

		// TITLE MSG SERVERNAME for initialization
		// ~URL~
		// for 0 only ~CODESTR~
		var html : String = "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html>\n<head><title>~TITLE~</title>\n</head><body>\n<h1>~TITLE~</h1>\n<p>~MSG~</p>\n<HR>\n<ADDRESS>~SERVERNAME~</ADDRESS>\n</body>\n</html>\n";
		htmlmap = new IntHash<String>();
		htmlmap.set(0, initHtml(html,"~CODESTR~", ""));
		htmlmap.set(301, initHtml(html,codeToText(301), "The document has moved <a href=\"~URL~\">here</a>."));
		htmlmap.set(400, initHtml(html,codeToText(400), "Your browser sent a request that this server could not understand."));
		htmlmap.set(403, initHtml(html,codeToText(403), "You don't have permission to access ~URL~ on this server."));
		htmlmap.set(404, initHtml(html,codeToText(404), "The requested URL ~URL~ was not found on this server."));
		htmlmap.set(414, initHtml(html,codeToText(414), "The URI ~URL~ supplied by your browser is too long."));
		htmlmap.set(417, initHtml(html,codeToText(417), "Expectation can not be met by this server."));
		htmlmap.set(500, initHtml(html,codeToText(500), "The server encountered an internal error."));
		htmlmap.set(501, initHtml(html,codeToText(501), "The server does not handle this type of request."));
		htmlmap.set(505, initHtml(html,codeToText(505), "The server does not speak this version of the HTTP protocol."));
	}

	static function initHtml(html:String,title:String,msg:String) : String {
		var r : EReg = ~/~TITLE~/g;
		html = r.replace(html, title);
		r = ~/~MSG~/g;
		html = r.replace(html, msg);
		return html;
	}


	static public function codeToText(val : Int) : String {
		if(!initialized) init();
		if(codemap.exists(val))
			return ("" + val + " " + codemap.get(val));
		return "" + val;
	}

	static public function codeToHtml(val : Int, ?requrl : String) : String {
		if(!initialized) init();
		if(requrl == null) requrl = "";
		var s : String;
		var r : EReg;
		if(htmlmap.exists(val))
			s = htmlmap.get(val);
		else {
			s = htmlmap.get(0);
			r = ~/~CODESTR~/g;
			s = r.replace(s, codeToText(val));
		}
		r = ~/~URL~/g;
		s = r.replace(s, requrl);
		r = ~/~SERVERNAME~/g;
		s = r.replace(s, "HxTTPD");
		return s;
	}

}
