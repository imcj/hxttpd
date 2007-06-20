import HttpdPlugin.Response;

class ModNeko extends HttpdPlugin {
	static var funcs	: Hash<Dynamic> = new Hash(); 
	var loader		: neko.vmext.VmLoader;
	var cur_request		: Dynamic;
	var cur_server		: Dynamic;
	

	public static function main() {	}

	// Return the main class name
	public static function vmmMainClassName() : String {
		return "ModNeko";
	}

	public function new() {
		super();
		name = "ModNeko";
		version = "0.2";


		// set the handler functions
		_hTranslate = onTranslate;

		init_mod_neko();
	}


	private function init_mod_neko() {
		trace(here.methodName);
		neko.Sys.putEnv("MOD_NEKO", "1");
		///var funcs = new Hash<Dynamic>();
		var me = this;
		var resolve_method = function(fname:String) {
			return ModNeko.funcs.get(fname);
		}

		funcs.set("get_cookies", function() : Hash<String> {
				return me.request().getCookies();
			});
		funcs.set("set_cookie", function(k:String,v:String) : Void {
				var sb = new StringBuf();
				sb.add(k);
				sb.add("=");
				sb.add(v);
				sb.add(";");
				me.request().addResponseHeader("Cookie", sb.toString());
			});
		funcs.set("get_host_name", function() : String {
				return me.request().host;
			});
		funcs.set("get_client_ip", function() : String {
				return me.request().client.remote_host.toString();
			});
		funcs.set("get_uri", function() : String {
				// original uri, untranslated
				return me.request().url;
			});
		funcs.set("redirect", function(url:String) : Void {
				var c = me.request();
				c.return_code = 302;
				c.addResponseHeader("Location", url);
			});
		funcs.set("set_return_code", function(r:Int) : Void {
				me.request().return_code = r;
			});
		funcs.set("set_header", function(name:String,val:String) {
				me.request().addResponseHeader(name, val);
			});
		funcs.set("get_client_header", function(k : String) : String {
				return me.request().getHeaderIn(k);
			});
		funcs.set("get_client_headers", function() : List<{ value : String, header : String}>{
				return me.request().headers_in;
			});
		funcs.set("get_params_string", function() : String {
				//Returns all the GET parameters String
				return me.request().args;
			});
		funcs.set("get_post_data", function() : String {
				return "";
			});
		funcs.set("get_params", function() : Hash<String> {
				return new Hash<String>();
			});
		funcs.set("cgi_get_cwd", function() : String {
				return me.request().path_translated;
			});
		funcs.set("cgi_set_main", function(f:Void->Void) : Void {
			});
		funcs.set("cgi_flush", function() : Void {
			});
		funcs.set("parse_multipart_data", function(onPart : String -> String -> Void, onData : String -> Int -> Int -> Void) : Void {
			});

		var lp = function (spec:String, nargs:Int) {
			//trace(here.methodName + " " + spec + " "+nargs);
			var l = spec.length;
			if(l > 9 && spec.substr(0,9) == 'mod_neko@') {
				spec = spec.substr(9,l-9);
				var f = resolve_method(spec);
				//if( f == null ) throw('Unknown mod_neko primitive : ' + spec);
				if( f == null ) return neko.vm.Loader.local().loadPrimitive(spec, nargs);
				if( untyped __dollar__nargs(f) != nargs ) throw('Invalid number of arguments for ' + spec);
				return f;
			} 
			return neko.vm.Loader.local().loadPrimitive(spec, nargs);
		}
		loader = new neko.vmext.VmLoader("ModNeko", lp);
	}

	public function request() : Dynamic {
		// I highly doubt this method of doing this is thread safe
		// Perhaps better that request() is a static function var in 
		// onTranslate(), and it is accessed through Reflect?
		return cur_request;
	}

	public function checkFile(path:String) : { r : Response, d : Date } {
		// TODO: Can't recall.. do symlinks mtime change when underlying object changes?
		//	If not, is there a way currently in neko to check target.
		var stat : Dynamic;
		try {
			switch(neko.FileSystem.kind(path)) {
			case kdir:
				return { r:SKIP, d:null };
			case kother(k):
				if(k != "symlink")
					return { r:ERROR, d:null};
			case kfile:
			}
			stat = neko.FileSystem.stat(path);
		}
		catch(e : Dynamic) { // file not found
			return { r:SKIP, d:null };
		}
		return { r:COMPLETE, d:stat.mtime};
	}


	function runModule(request:Dynamic, moduleName:String, pathTranslated:String, pathInfo:String) : Response {
		var buffer = new String("");
		var pf = function(str:Dynamic) {
			buffer += Std.string(str);
			neko.io.File.stdout().write("REDIRECT BUFFER>> "+str);
		}

		// check module cache
		trace(here.methodName + " running module "+moduleName);
		var vmm = loader.getCache().get(moduleName);
		try {
			if(vmm == null) {
				vmm = loader.loadModule(moduleName, true);
			}
		} catch(e : Dynamic) {
			trace(here.methodName + " " + e);
			return ERROR;
		}

		var redirect = loader._loadPrim("std@print_redirect", 1);
		trace(redirect);
		redirect(pf);

		// don't do this, really, just testing. Don't re-execute, just call the
		// main.
		try {
			vmm.execute();
		} catch(e:Dynamic) {
			redirect(null);
			trace("EXECUTE ERROR");
			neko.Lib.rethrow(e);
		}

		redirect(null);
		if(vmm == null)
			return ERROR;
		
		setMessage(request, buffer);
		return COMPLETE;
		// check stat, if file on disk is newer, use that
	}

	public function onTranslate(server : Dynamic, request : Dynamic) : Response {
		cur_server = server;
		cur_request = request;
		var uri = getRequestField(request, "path");
		var docroot = getRequestField(request, "path_translated");
		trace(here.methodName + "docroot: "+docroot+" uri " + uri);

		var pos = uri.indexOf(".n");
		if(pos < 1)
			return SKIP;
		var parts = uri.split("/");
		// first parts[] is a null
		parts.shift();
		var idx : Int = -1;
		var x : Int = 0;
		for(i in parts) {
			if(StringTools.endsWith(i, ".n")) {
				idx = x;
				break;
			}
			x++;
		}
		if(idx < 0) return SKIP;

		trace(here.methodName + "Application is " + parts[idx]);
		uri = "/" + parts.slice(0,idx+1).join("/");
		trace(here.methodName + " New uri is " + uri);

		var path : String = docroot + uri; 
		var retval = checkFile(path);
		if(retval.r != COMPLETE)
			return retval.r;

		var moduleName : String = path.substr(0, path.length-2);

		var sbPathInfo = new StringBuf();
		for(i in idx+1...parts.length) {
			sbPathInfo.add("/");
			sbPathInfo.add(parts[i]);
		}

		if(sbPathInfo.toString().length > 0) {
			setRequestField(request, "path_info", sbPathInfo.toString());
		}

		var rv = runModule(request, moduleName, path, sbPathInfo.toString());
		trace(here.methodName + " "+rv);
		if(rv == COMPLETE) {
			//setResponseHeader(request, "Content-Type","text/html");
			setResponseHeader(request, "Last-Modified", GmtDate.timestamp());
			setResponseHeader(request, "Expires","Thu, 19 Nov 1981 08:52:00 GMT");
			setResponseHeader(request, "Cache-Control","no-store, no-cache, must-revalidate, post-check=0, pre-check=0");
			setResponseHeader(request, "Pragma","no-cache");
			setResponseHeader(request, "X-ModNeko", "0.2");
			setResponseCode(request, 200);
		}
		return rv;

		/*
		setResponseCode(request, 200);
		setMessage(request, "Heya");
		return COMPLETE;
		*/
	}

}
