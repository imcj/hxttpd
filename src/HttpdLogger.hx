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

class HttpdLogger {
	public var host(default, null)		: String;	// hostname this logs for, or *
	public var format(default,null)		: String;
	public var filename(default,null)	: String;

	var replace_header			: List<String>;

	public function new(host: String, filename : String, format : String) {
		this.host = host.toLowerCase();
		this.filename = filename;
		this.format = format;
		replace_header = new List();

		//trace(format);
		var r : EReg = new EReg("%{([A-Z-]+)}i","i");
		var x : Int = 0;
		var h : Hash<Bool> = new Hash();
		var s : String = format;
		while(s.length > 0 && r.match(s) == true ) {
			var lcase = r.matched(1).toLowerCase();
			h.set(lcase, true);
			s = s.substr(r.matchedPos().pos + r.matchedPos().len);
			// replace all instances with a lowercase version in out format copy
			var er : EReg = new EReg("%{"+lcase+"}i","ig");
			this.format = er.replace(this.format,"%{"+lcase+"}i");
		}
		for(i in h.keys()) {
			replace_header.add(i);
		}
		//trace(this.format);
	}

	public function log(d : HttpdClientData) : Void {
		if(host != "*" && d.req.host != host)
			return;
		trace("ACCESSLOG: "+parse(d));
	}

	function parse(d : HttpdClientData) : String {
	        // http://httpd.apache.org/docs/2.0/mod/mod_log_config.html#formats
                // LogFormat "%h %l %u %t \"%r\" %>s %b" common
                // LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
                // CustomLog logs/access_log common
                // %h - remote host
                // %u - username (auth)
                // %t - timestamp
                // %r - request GET /apache_pb.gif HTTP/1.0
                // %>s - status code
                // %b - size of reply (or "-" for nothing returned besides headers)
                // %{Headername}i - Log specific header by name
                // %...{Foobar}C  - Cookie value of foobar
                var msg : String = format;
                msg = StringTools.replace(msg, "%h", d.remote_host.toString());
                //msg = StringTools.replace(msg, "%", Std.string(d.remote_port));
                msg = StringTools.replace(msg, "%l", "-");
                msg = StringTools.replace(msg, "%u", { if(d.req.username==null) "-"; else d.req.username; });
                msg = StringTools.replace(msg, "%t", GmtDate.timestamp());
                msg = StringTools.replace(msg, "%r", d.req.requestline);
                msg = StringTools.replace(msg, "%>s", Std.string(d.req.return_code));
                msg = StringTools.replace(msg, "%b", { if(d.req.content_length > 0) Std.string(d.req.content_length); else "-";});
                //msg = StringTools.replace(msg, "%
                //msg = StringTools.replace(msg, "%

		for(s in replace_header) {
			var r : EReg = new EReg("%{" + s + "}i", "g");
			var headval = d.req.headers_in.get(s);
			if(headval == null) headval = "-";
			msg = r.replace(msg, headval);
		}

		return msg;
	}
}
