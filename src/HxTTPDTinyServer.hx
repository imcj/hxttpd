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
import HttpdResponse.ResponseType;
import HttpdPlugin;

class HxTTPDTinyServer extends HttpdServerLoop<HttpdClientData> {

	public static var SERVER_VERSION 	: String	= "0.3";
	public static var default_port 		: Int		= 3000;
	public static var log_format		: String 	= "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"";
	public static var debug_level		: Int		= 0;
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

	var vmPlugin				: neko.vmext.VmLoader;
	var plugins				: List<HttpdPlugin>;
	var pluginpath				: Array<String>;
	//var plugins				: List<Dynamic>;

	var request_serial			: Int;

	public function new() {
		super(onConnect);
		logTrace("\nHxTTPD init...\n",1);
		// parent
		this.listenCount = 512;

		this.document_root = neko.Sys.getCwd();
		this.index_names = new Array();
		this.index_names.push("index.html");
		this.index_names.push("index.htm");
		this.keepalive_enabled = false;
		this.keepalive_timeout = 20;
		this.connection_timeout = 100;
		this.data_timeout = 0;
		this.last_interval = Date.now().getSeconds();

		this.access_loggers = new List();
		this.error_loggers = new List();

		this.vmPlugin = new neko.vmext.VmLoader();
		//this.vmPlugin.addPath(neko.Sys.getCwd()+"plugins/");
		neko.Sys.putEnv("NEKOPATH",neko.Sys.getEnv("NEKOPATH")+":"+neko.Sys.getCwd()+"plugins");
		this.pluginpath = neko.vm.Loader.local().getPath();
		this.plugins = new List();

		for(i in parseArgs()) {
			if(!registerPlugin(i))
				neko.Sys.exit(1);
		}

		// Automatically load ModNeko if neither it, nor ModHive is
		// specifically loaded
		var found = false;
		for(i in plugins) {
			if(i.name == "ModNeko" || i.name=="ModHive") {
				found = true;
			}
		}
		if(!found)
			if(!registerPlugin("ModNeko"))
				neko.Sys.exit(1);

		document_root = neko.FileSystem.fullPath(document_root);
		var r : EReg = ~/\/$/;
		document_root = r.replace(document_root, "");

		var h = new HttpdLogger("*", "filename", log_format);
		access_loggers.add(h);
		request_serial = 0;
	}

	static function usage() {
		neko.Lib.print("\nHxTTPD Server Version " + SERVER_VERSION + " (c) 2007\n");
		neko.Lib.print("USAGE: hxttpd [options]\n");
		neko.Lib.print(" Options:\n");
		neko.Lib.print("  --docroot=/path/to/html\tPath to the server document root.\n");
		neko.Lib.print("  --pluginpath=/path/to/\tPath to the server plugin directory.\n");
		neko.Lib.print("  --port=8080\t\t\tThe port to bind to.\n");
		neko.Lib.print("  --debug=[0-5]\t\t\tLevel of trace messages dumped to console.\n");
		neko.Lib.print("  --help\t\t\tThis message.");
		neko.Lib.print("\n");
		neko.Sys.exit(0);
	}

	function parseArgs() : Array<String> {
		var p = new Array<String>();
		for(i in neko.Sys.args()) {
			var parts = i.split("=");
			switch(parts[0]) {
			case "--docroot":
				if(!neko.FileSystem.isDirectory(parts[1])) {
					neko.Lib.println("Document root "+parts[1]+" does not exist");
					usage();
				}
				this.document_root = parts[1];
			case "--pluginpath":
				if(!neko.FileSystem.isDirectory(parts[1])) {
					neko.Lib.println("Plugin path "+parts[1]+" does not exist");
					usage();
				}
				neko.Sys.putEnv("NEKOPATH",neko.Sys.getEnv("NEKOPATH")+":"+parts[1]);
				pluginpath.push(parts[1]);
			case "--load":
				if(parts[1] == null) {
					neko.Lib.println("No plugin specified for --load");
					usage();
				}
				p.push(parts[1]);
			case "--port":
				default_port = Std.parseInt(parts[1]);
				if(default_port == null || default_port < 1 || default_port > 65535) {
					neko.Lib.print("Port out of range\n");
					usage();
				}
			case "--debug":
				var lvl = Std.parseInt(parts[1]);
				if(lvl>=0 && lvl<=5) {
					debug_level = lvl;
				}
				else {
					neko.Lib.print("Invalid debug level\n");
					usage();
				}
			default:
				usage();
			}
		}
		return p;
	}

	override public function run(host : Host, port : Int ) {
		logTrace("HxTTPD Server Version " + SERVER_VERSION + " starting up on " + host.toString() + ":" + Std.string(port)+" "+ GmtDate.timestamp()+"\n",0);
		this.host = host;
		this.port = port;
		default_port = port;
		super.run(host, port);
		logTrace("HxTTPD Server Version " + SERVER_VERSION + " shutdown",0);
	}

	function registerPlugin(name:String) : Bool {
		neko.Lib.print("Initialising module "+name+"...");

		for(i in plugins) {
			if(i.name == name) {
				logTrace("Warning: plugin "+name+" already loaded.");
				return true;
			}
		}
		var inst:Dynamic;
		switch(name) {
		case "ModHive":
			inst = new ModHive();
		case "ModNeko":
			inst = new ModNeko();
		default:
			var m = neko.vm.Loader.local().getCache().get(name);
			if(m != null) return true;
			m = neko.vm.Module.readPath(name+".n",pluginpath,neko.vm.Loader.local());
			m.execute();

			var classes : Dynamic = m.exportsTable().__classes;
			var c : Class<Dynamic> = Reflect.field(classes,name);
			inst = Type.createInstance(c,[]);
		}
		var func = Reflect.field(inst, "_hConfig");
		if (Reflect.isFunction(func)) {
			var rv : Int = Reflect.callMethod(inst,func,[this]);
			if(rv == HttpdPlugin.ERROR) {
				logTrace("Error: "+inst.errStr,0);
				return false;
			}
		}
		plugins.push(inst);
		logTrace("ok",1);
		return true;
	}

	override public function onClientDisconnected( d : HttpdClientData ) {
		d.sock = null;
	}

	/*
	override public function onError( e : Dynamic ) {
		super.onError(e);
	}
	*/

	override public function onInternalError( d : HttpdClientData, e : Dynamic ) {
		logTrace(3);
		d.setResponse(500);
		d.response.setMessage(HttpdResponse.codeToHtml(500));
		d.response.keepalive = false;
		d.response.prepare();
		d.response.send();
		//STATE_CLOSING:
		closeConnection(d.sock);
	}

	override public function onClientWritable(  d : HttpdClientData ) {
		// TODO: Multipart/ranges
		if(d.response.bytes_left == null) {
			d.response.bytes_left = d.response.content_length;
		}
		var nbytes = d.response.bytes_left;
		if(nbytes > HttpdServerLoop.MAX_OUTBUFSIZE)
			nbytes = HttpdServerLoop.MAX_OUTBUFSIZE;

		var s = d.response.file.read(nbytes);
		clientWrite(d.sock, s, 0, s.length);
		d.response.bytes_left -= nbytes;

		// when finished
		if(d.response.bytes_left <= 0) {
			removeWriteSock(d.sock);
			d.endRequest();
			//if(d.state == ConnectionState.STATE_CLOSING) {
			//	trace(" closing");
			//	closeConnection(d.sock);
			//}
		}
		return 0;
	}


	public function onConnect(sock:Socket) : HttpdClientData {
		var cdata = new HttpdClientData(this, sock);
		cdata.remote_port = sock.peer().port;


		//Std.string(cnx.sock.peer().host.ip);
		//cdata.remote_host = new Host(neko.net.Host.localhost());
		//untyped { cdata.remote_host.ip = sock.peer().host.ip; }
		cdata.remote_host = sock.peer().host;

		logTrace(" New connection from "+ cdata.remote_host.toString() + " port: "+ Std.string(cdata.remote_port),2);
		return cdata;
	}

	override public function onInterval() {
		var sec = Date.now().getSeconds();
		for ( i in clients ) {
			if(i.state != HttpdClientData.STATE_READY)
				continue;
			startResponse(i);
		}
		if(sec == last_interval)
			return;
		last_interval = sec;
		for ( i in plugins ) {
			try {
				var func = Reflect.field(i, "_hInterval");
				if (Reflect.isFunction(func)) {
					Reflect.callMethod(i,func,[this]);
				}
			}
			catch (e:Dynamic) { logTrace(e,0); }
		}
		for ( i in clients ) {
			i.timer++;
			switch(i.state) {
			case HttpdClientData.STATE_WAITING:
				if(i.timer >= connection_timeout) {
					logTrace("Connection timeout",2);
					closeConnection(i.sock);
				}
			case HttpdClientData.STATE_DATA:
				if(data_timeout > 0 && i.timer >= data_timeout) {
					logTrace("Timeout waiting for post data",3);
					closeConnection(i.sock);
				}
			case HttpdClientData.STATE_READY:
			case HttpdClientData.STATE_PROCESSING:
				i.timer = 0;
			case HttpdClientData.STATE_KEEPALIVE:
				//trace(" client keepalive "+ i.timer+"/"+keepalive_timeout);
				if(i.timer >= keepalive_timeout) {
					logTrace("Keepalive timeout",3);
					closeConnection(i.sock);
				}
			case HttpdClientData.STATE_CLOSING:
				closeConnection(i.sock);
			}
		}
	}

	override public function onClientData( d : HttpdClientData, buf : String, bufpos : Int, buflen : Int ) : Int {
		//trace("\n>> "+"\n>> buf: "+buf+"\n>> bufpos: "+bufpos+"\n>> buflen: "+buflen);
		if( d.state == HttpdClientData.STATE_WAITING || d.state == HttpdClientData.STATE_KEEPALIVE) {
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
		else if (d.state == HttpdClientData.STATE_DATA) {
			//trace(buflen);
			d.req.addPostData(buf, bufpos, buflen);
			if(d.req.postComplete()) {
				logTrace(">> POST DATA");
				logTrace(d.req.post_data);
				logTrace(">> END POST DATA");
				d.req.finalizePost();
				d.markReady();
			}
			return buflen;
		}
		logTrace("Unexpected data client state: "+Std.string(d.state),0);
		if(d.req != null) {
			logTrace("Request serial number "+d.req.serial_number,0);
		}
		else {
			logTrace("Client has no active request",0);
		}
                return 0;
	}

	public function getRequestSerial() : Int {
		request_serial++;
		return request_serial;
	}

	/**
		Parse headers and see if request is complete.
		Return false if connection is closed, or more data needs to come in
		Return true if request can be handled
	**/
	function beginRequest( d : HttpdClientData, buf : String,  bufpos : Int, buflen : Int ) : Bool {
		var data : String  = buf.substr(bufpos, buflen);

		logTrace(" >> INPUT DATA FOLLOWS\n"+StringTools.trim(data)+"\nINPUT DATA END >> bufpos: "+bufpos+" buflen: "+buflen,4);

		d.startNewRequest();
		data = StringTools.replace(data, "\r\n", "\n");
		if(data.length == 0) {
			d.response.setStatus(400);
			closeConnectionError( d );
			return false;
		}
		var lines = data.split("\n");
		var rv = d.req.processRequest(lines[0]);
		if( rv != 200 ) {
			d.response.setStatus(rv);
			logTrace("Invalid request [" + d.response.getStatus() + "]",3);
			closeConnectionError( d );
			return false;
		}
		// shift off the request
		lines.shift();
		if(! d.req.processHeaders(lines)) {
			logTrace("Headers invalid",2);
			closeConnectionError( d );
			return false;
		}

		// are we waiting for multipart data?
		//Content-Type: application/x-www-form-urlencoded
		//Content-Length: 31
		// or
		//Content-Type: multipart/form-data; boundary=----------Jud
		//Content-Length: 300000
		if( d.req.in_content_type != null) {
			logTrace(" Switching to STATE_DATA for content_length "+d.req.in_content_length);
			d.awaitPost();
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
				logTrace("URL invalid",4);
			}
			closeConnectionError( d );
			return;
		}
		if(!checkPath(d)) {
			d.setResponse(403);
			closeConnectionError( d );
			return;
		}

		switch(translatePath(d)) {
		case HttpdPlugin.COMPLETE:
			//return;
		case HttpdPlugin.SKIP:
		case HttpdPlugin.ERROR:
			if(d.response.getStatus() < 300)
				d.setResponse(404);
			closeConnectionError( d );
			return;
		case HttpdPlugin.PROCESSING:
			return;
		default:
			logTrace(" unhandled response");
		}
		d.response.prepare();
		d.response.send();	// handles connection closing
	}

	function closeConnectionError( d : HttpdClientData) : Void {
		if(d.response.getStatus() == 500 && d.sock == null)
			return;
		d.response.keepalive = false;
		var url = d.req.url;
		if(d.getResponse() == 301)
			url = d.response.location;
		d.response.setMessage(HttpdResponse.codeToHtml(d.getResponse(), url));
		d.response.prepare();
		d.response.send();
	}



	/**
		Cleans up the uri and ensures it does not escape the document root (../../)
		does not set an error code
		Called after processUrl which urlDecodes the url
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
		//trace(" new path: " + d.req.path);
		return true;
	}

	/**
		Translate a path to actual file type, checks for
		index docs on directories and symlinks, 404's any
		pipe or other special files, or any file that can
		not be opened.
	**/
	function translatePath(d : HttpdClientData) : Int {
		d.req.path_translated = document_root;
		d.req.uriparts = d.req.path.split("/");
		d.req.uriparts.shift();

		// hook _hTranslate
		for ( i in plugins ) {
			try {
				var func = Reflect.field(i, "_hTranslate");
				if (Reflect.isFunction(func)) {
					var rv : Int = Reflect.callMethod(i,func,[this,d.req,d.response]);
					switch(rv) {
					case HttpdPlugin.COMPLETE:
						if(d.response.getStatus() < 100) {
							log_error(d,"Module "+i.name+" did not set response code");
							d.response.setStatus(200);
						}
						return rv;
					case HttpdPlugin.ERROR:
						onInternalError(d, null);
						return rv;
					case HttpdPlugin.PROCESSING:
						return rv;
					case HttpdPlugin.SKIP:
					}
				}
			}
			catch (e:Dynamic) {
				logTrace(e,0);
				onInternalError(d, e);
				return HttpdPlugin.ERROR;
			}
		}

		if(d.response.getStatus() == 500) {
			onInternalError(d, null);
			return HttpdPlugin.ERROR;
		}

		var p = d.req.path;
		d.req.path_translated += p;
		logTrace(" final: " + d.req.path_translated,2);

		try {
			switch(FileSystem.kind(d.req.path_translated)) {
			case kdir:
				if(!checkDirIndex( d )) {
					d.setResponse(404);
					return HttpdPlugin.ERROR;
				}
			case kother(k):
				if(k != "symlink") {
					d.setResponse(404);
					return HttpdPlugin.ERROR;
				}
				if(!checkDirIndex( d )) {
					d.setResponse(404);
					return HttpdPlugin.ERROR;
				}
			case kfile:
				if(!d.response.openFile(d, d.req.path_translated)) {
					d.setResponse(404);
					return HttpdPlugin.ERROR;
				}
			}
		}
		catch(e : Dynamic) { // file not found
			d.setResponse(404);
			return HttpdPlugin.ERROR;
		}

		if(!processFile(d)) {
			if(d.getResponse() < 300)
				d.setResponse(404);
			return HttpdPlugin.ERROR;
		}
		return HttpdPlugin.SKIP;
	}


	function checkDirIndex(d : HttpdClientData) : Bool {
		//trace(here.methodName);
		if(d.req.path_translated.charAt(d.req.path_translated.length-1) != "/") {
			d.setResponse(301);
			d.response.location = "http://" + d.req.host;
			if(d.req.port != 0) d.response.location += ":" + Std.string(d.req.port);
			d.response.location += d.req.path+"/";
			return false;
		}
		var found = false;
		for(i in index_names) {
			if(d.response.openFile(d, d.req.path_translated + i)) {
				found = true;
				break;
			}
		}
		if(! found) return false;
		return true;
	}



	/**
		Ignore POSTS to files
		Check for status of modified since requests, range
		and if-range requests.
		Called from translatePath()
	**/
	function processFile(d : HttpdClientData) : Bool {
		if(d.req.if_modified_since != null) {
			//trace("HAS MODIFIED DATE file: " + d.req.last_modified.rfc822timestamp() + " browser: "+ d.req.if_modified_since.rfc822timestamp());
			if(d.response.last_modified.lt(d.req.if_modified_since) || d.response.last_modified.eq(d.req.if_modified_since)) {
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
		// copy ranges to response
		if(d.req.in_ranges != null) {
			HttpdRange.satisfyAll(d.req.in_ranges, d.response.content_length);
		}
		//
		d.setResponse(200);
		return true;
	}



	public static function logTrace(s:String, ?level:Int) {
		if(level==null) level = 5;
		if(level <= debug_level) {
			Sys.stdout ( ).writeString(s+"\n");
			Sys.stdout ( ).flush();
		}
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

	public function isPluginRegistered(n:String) : Bool {
		for(i in plugins) {
			if(i.name == n)
				return true;
		}
		return false;
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






