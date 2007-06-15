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

import neko.net.Socket;
import neko.net.Host;
import neko.FileSystem;
import neko.io.File;

import HttpdRequest.HttpMethod;
import HttpdRequest.ResponseType;
import HttpdClientData.ConnectionState;

class HxTTPDTinyServer extends HttpdServerLoop<HttpdClientData> {

	public static var SERVER_VERSION 	: String	= "0.2";
	public static var default_port 		: Int		= 80;
	public static var log_format		: String 	= "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"";
	public static var debug_level		: Int		= 4;
	public var document_root		: String;
	public var index_names			: Array<String>;
	public var host				: Host;
	public var port				: Int;
	public var keepalive_enabled		: Bool;
	public var keepalive_timeout		: Int;
	public var connection_timeout		: Int;
	public var data_timeout			: Int;	// timout for form data etc.
	public var last_interval		: Int;

	var access_loggers			: List<HttpdLogger>;
	var error_loggers			: List<HttpdLogger>;

	public function new() {
		super(onConnect);
		this.document_root = neko.Sys.getCwd();
		var r : EReg = ~/\/$/;
		this.document_root = r.replace(this.document_root, "");
		this.index_names = new Array();
		this.index_names.push("index.html");
		this.index_names.push("index.htm");
		this.keepalive_enabled = false;
		this.keepalive_timeout = 20;
		this.connection_timeout = 100;
		this.data_timeout = 0;
		this.access_loggers = new List();
		this.last_interval = Date.now().getSeconds();
		// parent
		this.listenCount = 512;

		var h = new HttpdLogger("*", "filename", log_format);
		access_loggers.add(h);
	}

	override public function run(host : Host, port : Int ) {
		trace("HxTTPD Server Version " + SERVER_VERSION + " starting up on " + host.toString() + ":" + Std.string(port)+" "+ GmtDate.timestamp());
		this.host = host;
		this.port = port;
		default_port = port;
		super.run(host, port);
		trace("HxTTPD Server Version " + SERVER_VERSION + " shutdown");
	}

	/*
	override public function onClientDisconnected( d : HttpdClientData ) {
		trace(here.methodName);
	}

	override public function onError( e : Dynamic ) {
		super.onError(e);
	}
	*/

	override public function onInternalError( d : HttpdClientData, e : Dynamic ) {
		d.setResponse(500);
		prepareResponse(d);
		sendResponse(d);
	}

	override public function onClientWritable(  d : HttpdClientData ) {
		// TODO: Multipart/ranges
		if(d.req.bytes_left == null) {
			d.req.bytes_left = d.req.content_length;
		}
		var nbytes = d.req.bytes_left;
		if(nbytes > HttpdServerLoop.MAX_OUTBUFSIZE)
			nbytes = HttpdServerLoop.MAX_OUTBUFSIZE;

		var s = d.req.file.read(nbytes);
		clientWrite(d.sock, s, 0, s.length);
		d.req.bytes_left -= nbytes;

		// when finished
		if(d.req.bytes_left <= 0) {
			removeWriteSock(d.sock);
			d.endRequest();
			//if(d.state == ConnectionState.STATE_CLOSING) {
			//	trace(here.methodName + " closing");
			//	closeConnection(d.sock);
			//}
		}
		return 0;
	}


	public function onConnect(sock:Socket) : HttpdClientData {
		var cdata = new HttpdClientData(sock);
		cdata.remote_port = sock.peer().port;

		//var a : { host : Host, port : Int } = sock.peer();
		//cdata.remote_host = cast(a.host, Host);
		//var guh : Host = new neko.net.Host(Host.localhost());
		//guh = a.host;
		//cdata.remote_host = guh;
		//if(! Reflect.isObject(cdata.remote_host) )
		//	trace("a.host is not an object");
		//trace(Type.getClass(cdata.remote_host));

		// This is a total hack. Seems Socket.peer().host is an Int32
		// and not a Host object? Any input here would be nice
		cdata.remote_host = new Host(neko.net.Host.localhost());
		untyped { cdata.remote_host.ip = sock.peer().host; }

		trace(here.methodName + " New connection from "+ cdata.remote_host.toString() + " port: "+ Std.string(cdata.remote_port), 2);
		return cdata;
	}

	override public function onInterval() {
		var sec = Date.now().getSeconds();
		for ( i in clients ) {
			if(i.state != STATE_READY)
				continue;
			startResponse(i);
		}
		if(sec == last_interval)
			return;
		last_interval = sec;
		for ( i in clients ) {
			i.timer++;
			switch(i.state) {
			case STATE_WAITING:
				if(i.timer >= connection_timeout) {
					trace("Connection timeout");
					closeConnection(i.sock);
				}
			case STATE_DATA:
				if(data_timeout > 0 && i.timer >= data_timeout) {
					trace("Timeout waiting for post data");
					closeConnection(i.sock);
				}
			case STATE_READY:
			case STATE_PROCESSING:
				i.timer = 0;
			case STATE_KEEPALIVE:
				//trace(here.methodName + " client keepalive "+ i.timer+"/"+keepalive_timeout);
				if(i.timer >= keepalive_timeout) {
					trace("Keepalive timeout");
					closeConnection(i.sock);
				}
			case STATE_CLOSING:
				trace("Error: Interval closing socket that should have closed already");
				closeConnection(i.sock);
			}
		}
	}

        override public function onClientData( d : HttpdClientData, buf : String, bufpos : Int, buflen : Int ) : Int {
		trace("\n>> "+here.methodName + "\n>> buf: "+buf+"\n>> bufpos: "+bufpos+"\n>> buflen: "+buflen);
		if( d.state == STATE_WAITING || d.state == STATE_KEEPALIVE) {
			var s = buf.substr(bufpos, buflen);
			var i = s.indexOf("\r\n\r\n");
			if(i>=0) {
				if(beginRequest(d, buf,  bufpos, i)) {
					d.markReady();
				}
				return i + 4;
			}
			return 0;
		}
		else if (d.state == STATE_DATA) {
			//trace(buflen);
			d.req.addPostData(buf, bufpos, buflen);
			if(d.req.post_data.length >= d.req.in_content_length) {
				d.markReady();
			}
			return buflen;
		}
		trace("Unexpected data "+ buf.substr(bufpos,buflen));
		trace("Client state is " + Std.string(d.state));
                return 0;
	}

	/**
		Parse headers and see if request is complete.
		Return false if connection is closed, or more data needs to come in
		Return true if request can be handled
	**/
	function beginRequest( d : HttpdClientData, buf : String,  bufpos : Int, buflen : Int ) : Bool {
		var data : String  = buf.substr(bufpos, buflen);

		trace(here.methodName + " >> INPUT DATA FOLLOWS\n"+StringTools.trim(data)+"\nINPUT DATA END >> bufpos: "+bufpos+" buflen: "+buflen,3);

		d.startNewRequest();
		data = StringTools.replace(data, "\r\n", "\n");
		if(data.length == 0) {
			d.req.return_code = 400;
			closeConnectionError( d );
			return false;
		}
		var lines = data.split("\n");
		if(! d.req.processRequest(lines[0])) {
			trace("Invalid request [" + d.req.return_code + "]",1);
			closeConnectionError( d );
			return false;
		}
		// shift off the request
		lines.shift();
		if(! d.req.processHeaders(lines)) {
			trace("Headers invalid",1);
			closeConnectionError( d );
			return false;
		}

		// are we waiting for multipart data?
		//Content-Type: application/x-www-form-urlencoded
		//Content-Length: 31
		if( d.req.in_content_type != null) {
			d.state = ConnectionState.STATE_DATA;
			return false;
		}
		return true;
	}

	function startResponse(d: HttpdClientData)
	{
		d.startResponse();
		// process url -> path + args
		if(! d.req.processUrl()) {
			if(d.getResponse() != 304) { // not modified
				trace("URL invalid");
			}
			closeConnectionError( d );
			return;
		}
		if(!checkPath(d)) {
			d.setResponse(403);
			closeConnectionError( d );
			return;
		}
		if(!translatePath(d)) {
			if(d.req.return_code < 300)
				d.setResponse(404);
			closeConnectionError( d );
			return;
		}
		prepareResponse(d);
		sendResponse(d);	// handles connection closing
	}

	function closeConnectionError( d : HttpdClientData) : Void {
		d.req.keepalive = false;
		var url = d.req.url;
		if(d.getResponse() == 301)
			url = d.req.location;
		d.req.setMessage(HttpdResponse.codeToHtml(d.getResponse(), url));
		prepareResponse(d);
		sendResponse(d);
	}



	/**
		Cleans up the uri and ensures it does not escape the document root (../../)
		does not set an error code
		Called from processUrl
		TODO: uri must be url decoded first before this is all done.
	**/
	function checkPath(d : HttpdClientData) : Bool {
		var trail : Bool = { if(d.req.path.charAt(d.req.path.length-1) == "/") true; else false; }
		var items = d.req.path.split("/");
		var i : Int = 0;
		var newpathitems : Array<String> = new Array();
		for( x in 0 ... items.length ) {
			if(items[x] == null || items[x].length == 0)
				continue;
			if(items[x] == ".")
				continue;
			if(items[x] == "..") {
				if(newpathitems.length == 0)
					return false;
				continue;
			}
			// dot files, dot directories
			if(items[x].charAt(0) == ".")
				return false;
			// home dirs
			if(items[x].charAt(0) == "~")
				return false;
			newpathitems.push(items[x]);
		}
		d.req.path = "";
		if(newpathitems.length > 0) {
			for( p in newpathitems) {
				d.req.path += "/" + p;
			}
			if(trail) {
				d.req.path += "/";
			}
		}
		else d.req.path = "/";
		trace(here.methodName + " new path: " + d.req.path);
		return true;
	}

	/**
		Translate a path to actual file type, checks for
		index docs on directories and symlinks, 404's any
		pipe or other special files, or any file that can
		not be opened.
	**/
	function translatePath(d : HttpdClientData) : Bool {
		// TODO alias directories and such
		d.req.path_final = document_root;
		var p = d.req.path;
		d.req.path_final += p;
		trace(here.methodName + " final: " + d.req.path_final);

		try {
			switch(FileSystem.kind(d.req.path_final)) {
			case kdir:
				if(!checkDirIndex( d )) {
					d.setResponse(404);
					return false;
				}
			case kother(k):
				if(k != "symlink") {
					d.setResponse(404);
					return false;
				}
				if(!checkDirIndex( d )) {
					d.setResponse(404);
					return false;
				}
			case kfile:
				if(!openFile(d, d.req.path_final)) {
					d.setResponse(404);
				}
			}
		}
		catch(e : Dynamic) { // file not found
			d.setResponse(404);
			return false;
		}

		if(!processFile(d)) {
			if(d.getResponse() < 300)
				d.setResponse(404);
			return false;
		}
		return true;
	}


	function checkDirIndex(d : HttpdClientData) : Bool {
		trace(here.methodName);
		if(d.req.path_final.charAt(d.req.path_final.length-1) != "/") {
			d.setResponse(301);
			d.req.location = "http://" + d.req.host;
			if(d.req.port != 0) d.req.location += ":" + Std.string(d.req.port);
			d.req.location += d.req.path+"/";
			return false;
		}
		var found = false;
		trace(index_names);
		for(i in index_names) {
			//trace("Trying " + d.req.path_final + i);
			if(openFile(d, d.req.path_final + i)) {
				//trace("found");
				found = true;
				break;
			}
		}
		if(! found) return false;
		return true;
	}

	function openFile(d : HttpdClientData, filename : String) : Bool {
		if( d.req.file != null ) {
			log_error(d, "Request already has an open file");
			return false;
		}
		try {
			d.req.file = File.read(filename, true);
			trace(here.methodName + d.req.file);
		}
		catch(e : Dynamic) { d.req.file = null; return false; }
		d.req.type = ResponseType.TYPE_FILE;
		var stat = FileSystem.stat( filename );
		d.req.last_modified = GmtDate.fromLocalDate(stat.mtime);
		if(d.req.last_modified.gt(GmtDate.now())) {
			log_error(d, "File "+filename+" has a modification date in the future");
			d.req.last_modified = GmtDate.now();
		}
		d.req.content_length = stat.size;
		d.req.content_count = 1;
		setMimeType(d, filename);
		trace(here.methodName + " file: " + filename + " size: " + stat.size);
		return true;
	}

	function setMimeType(d : HttpdClientData, filename : String) : Bool {
		d.req.content_type = "unknown/unknown";
		var r : EReg = ~/\.([0-9A-Za-z]+)$/;
		r.match(filename);
		try {
			//d.req.mime_type = Mime.extensionToMime(r.matched(1));
			d.req.content_type = Mime.extensionToMime(r.matched(1));
		}
		catch(e :Dynamic) {}
		trace(here.methodName + " " + d.req.content_type);
		return true;
	}

	/**
		Ignore POSTS to files
		Check for status of modified since requests, range
		and if-range requests.
		Called from translatePath()
	**/
	function processFile(d : HttpdClientData) : Bool {
		/*
		if(d.req.method == HttpMethod.METHOD_POST) {
			trace("POST Method currently unimplemented.");
			d.closeFile();
			d.setResponse(501);
			return false;
		}
		*/
		if(d.req.if_modified_since != null) {
			//trace("HAS MODIFIED DATE file: " + d.req.last_modified.rfc822timestamp() + " browser: "+ d.req.if_modified_since.rfc822timestamp());
			if(d.req.last_modified.lt(d.req.if_modified_since) || d.req.last_modified.eq(d.req.if_modified_since)) {
				//trace("File not modified");
				d.setResponse(304);
				d.closeFile();
				return false;
			}
		}
		// TODO
		// if_unmodified_since
		// if-range
		// check ranges validity
		if(d.req.ranges != null) {
			HttpdRange.satisfyAll(d.req.ranges, d.req.content_length);
		}
		//
		d.setResponse(200);
		return true;
	}

	function prepareResponse(d : HttpdClientData) {

		if(d.req.content_count > 0 && d.getResponse() != 206) {
			d.req.addResponseHeader("Content-Type", d.req.content_type);
			if(d.req.last_modified != null)
				d.req.addResponseHeader("Last-Modified", d.req.last_modified.rfc822timestamp());
			if(d.req.message != null)
				d.req.addResponseHeader("Content-Length", Std.string(d.req.message.length));
			else
				d.req.addResponseHeader("Content-Length", Std.string(d.req.content_length));
		}

		switch(d.getResponse()) {
		case 206: // partial content
			if(! d.req.multipart) {
				d.req.addResponseHeader("Content-Type", d.req.content_type);
				d.req.addResponseHeader("Content-Range", "bytes " + d.req.ranges[0].off_start + "-" + d.req.ranges[0].off_end + "/" + d.req.content_length);
			}
			else {
				d.req.addResponseHeader("Content-type", "multipart/byteranges; boundary="+d.req.content_boundary);
			}
			// in the case of multipart, the content-type for the file is sent in the
			// multipart sections
		case 301:
			if(d.req.location != null)
				d.req.addResponseHeader("Location", d.req.location);
		case 302:
			if(d.req.location != null)
				d.req.addResponseHeader("Location", d.req.location);
		case 401:
			d.req.addResponseHeader("WWW-Authenticate", "Basic realm=myrealmchangeme");
		case 405:
			d.req.addResponseHeader("Allow","GET, POST, HEAD");
		case 416:
			// A server SHOULD return a response with this status code if a request
			// included a Range request-header field (section 14.35), and none of
			// the range-specifier values in this field overlap the current extent
			// of the selected resource, and the request did not include an If-Range
			// request-header field. (For byte-ranges, this means that the first-
			// byte-pos of all of the byte-range-spec values were greater than the
			// current length of the selected resource.)
			// When this status code is returned for a byte-range request, the
			// response SHOULD include a Content-Range entity-header field
			// specifying the current length of the selected resource (see section
			// 14.16). This response MUST NOT use the multipart/byteranges content-
			// type.

			d.req.addResponseHeader("Content-Range", "bytes */"+d.req.content_length);

			// which means... what, return only satisfiable ranges, and silently
			// ignore the rest??
		}

		if (d.req.in_content_length > 0 || d.req.in_transfer_encoding != null) {
			d.req.keepalive = false;
		}

		// 300s are redirects, not modified
		if(d.req.return_code < 300 || d.req.return_code == 301 || d.req.return_code == 302) {
			if(d.req.keepalive == true && d.req.version_minor == 0) {
				d.req.addResponseHeader("Connection", "keep-alive");
			}
			else if(d.req.version_minor > 0) {
				d.req.addResponseHeader("Connection", "close");
			}
		}
		else {
			d.req.addResponseHeader("Connection", "close");
		}
	}

	function sendResponse(d : HttpdClientData) {
		var head : String = "";
		head += "HTTP/1.1 "+HttpdResponse.codeToText(d.req.return_code)+"\r\n";
		head += "Date: "+GmtDate.timestamp()+"\r\n";
		head += "Server: HxTTPD\r\n";
		for(i in d.req.headers_out) {
			head += i + "\r\n";
		}
		head += "\r\n";
		clientWrite(d.sock, head, 0, head.length);

		if(d.req.message != null) {
			clientWrite(d.sock, d.req.message, 0, d.req.message.length);
			//closeConnection(d.sock);
			d.state = STATE_CLOSING;
		}
		else {
			// add them as a writesocket as there
			// is file data to send to client
			addWriteSock(d.sock);
		}
		log_request(d);
	}


	public static function log_error(d : HttpdClientData, msg : String, ?level : Int)
	{
		if(level == null || level == 0) level = 1;
		if(level <= debug_level) {
			trace("Error: "+msg);
			//for(i in error_loggers) {
			//	i.log(d);
			//}
		}
	}

	public function log_request(d : HttpdClientData)
	{
		for(i in access_loggers) {
			i.log(d);
		}
	}

}


/*
(when using get /index.html .. should be GET)
HTTP/1.1 501 Method Not Implemented
Date: Fri, 01 Jun 2007 01:08:57 GMT
Server: Apache
Allow: GET,HEAD,POST,OPTIONS,TRACE
Content-Length: 215
Connection: close
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>501 Method Not Implemented</title>
</head><body>
<h1>Method Not Implemented</h1>
<p>get to /index.html not supported.<br />
</p>
</body></html>



HTTP/1.1 200 OK
Date: Fri, 01 Jun 2007 01:12:20 GMT
Server: Apache
Last-Modified: Tue, 28 Aug 2001 19:09:26 GMT
ETag: "56a0d-d4-cfe76580"
Accept-Ranges: bytes
Content-Length: 212
Connection: close
Content-Type: text/html


*/






