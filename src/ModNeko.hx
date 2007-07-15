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
import HttpdRequest.VarList;

class ModNeko extends HttpdPlugin {
	static var funcs	: Hash<Dynamic> = new Hash();
	var loader		: neko.vmext.VmLoader;
	var cur_request		: Dynamic;
	var cur_response	: Dynamic;
	var cur_server		: Dynamic;
	var cur_module		: String;
	var module_cache	: Hash<Dynamic>;


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
		_hConfig = onConfig;
		_hTranslate = onTranslate;
		module_cache = new Hash();

		init_mod_neko();
	}

	public function onConfig(server : Dynamic) : Int {
		var rPlugins : List<HttpdPlugin> = server.plugins;
		for(i in rPlugins) {
			if(i.name == "ModHive") {
				errStr = "ModNeko and ModHive are incompatible";
				return HttpdPlugin.ERROR;
			}
		}
		return HttpdPlugin.COMPLETE;
	}

	private function init_mod_neko() {
		trace(here.methodName);
		neko.Sys.putEnv("MOD_NEKO", "1");
		///var funcs = new Hash<Dynamic>();
		var me = this;
		var resolve_method = function(fname:String) {
			return ModNeko.funcs.get(fname);
		}

// 		funcs.set("get_cookies", function() : Hash<String> {
		funcs.set("get_cookies", function() {
				var cArr : Array<HttpCookie> =  me.request().getCookies();
				var p = null;

				for(i in cArr) {
					var key : String = i.getName();
					var value : String = Std.string(i.getValue());
					var tmp = untyped __dollar__amake(3);
					tmp[0] = untyped key.__s;
					tmp[1] = untyped value.__s;
					tmp[2] = untyped p;
					p = tmp;
				}
				return p;
			});
// 		funcs.set("set_cookie", function(k:String,v:String) : Void {
		funcs.set("set_cookie", function(k,v) : Void {
				var c = new HttpCookie(
					Std.string(neko.Lib.nekoToHaxe(k)),
					Std.string(neko.Lib.nekoToHaxe(v))
				);
				me.response().setCookie(c);
			});
// 		funcs.set("get_host_name", function() : String {
		funcs.set("get_host_name", function() {
				return neko.Lib.haxeToNeko(me.request().host);
			});
		/*funcs.set("get_client_ip", function() : String { */
		funcs.set("get_client_ip", function() {
				return neko.Lib.haxeToNeko(me.request().client.remote_host.toString());
			});
// 		funcs.set("get_uri", function() : String {
		funcs.set("get_uri", function() {
				// original uri, untranslated
				return neko.Lib.haxeToNeko(me.request().url);
			});
// 		funcs.set("redirect", function(url:String) : Void {
		funcs.set("redirect", function(url) : Void {
				var c = me.response();
				c.setStatus(302);
				c.setHeader("Location", neko.Lib.nekoToHaxe(url));
			});
		//funcs.set("set_return_code", function(r:Int) : Void
		funcs.set("set_return_code", function(r:Int) : Void {
				me.response().setStatus(r);
			});
// 		funcs.set("set_header", function(name:String,val:String) {
		funcs.set("set_header", function(name,val) {
				me.response().setHeader(
					Std.string(neko.Lib.nekoToHaxe(name)),
					Std.string(neko.Lib.nekoToHaxe(val))
				);
			});
// 		funcs.set("get_client_header", function(k : String) : String {
		funcs.set("get_client_header", function(k) {
				var key = Std.string(neko.Lib.nekoToHaxe(k));
				return neko.Lib.haxeToNeko(me.request().getHeaderIn(key));
			});
// 		funcs.set("get_client_headers", function() : List<{value:String,header:String}>{
		funcs.set("get_client_headers", function() {
				var h : List<VarList> = me.request().headers_in;
				var p = null;
				for(i in h) {
					var key : String = i.key;
					var value : String = i.value;
					var tmp = untyped __dollar__amake(3);
					tmp[0] = untyped key.__s;
					tmp[1] = untyped value.__s;
					tmp[2] = untyped p;
					p = tmp;
				}
				return p;
			});
// 		funcs.set("get_params_string", function() : String {
		funcs.set("get_params_string", function() {
				//Returns all the GET parameters String
				return neko.Lib.haxeToNeko(me.request().args);
			});
// 		funcs.set("get_post_data", function() : String {
		funcs.set("get_post_data", function() : String {
				return neko.Lib.haxeToNeko(me.request().post_data);
			});
		// Note/TODO ?: Does not return the posted files!
		//funcs.set("get_params", function() : Hash<String> {
		funcs.set("get_params", function() {
				var get : Array<VarList> = me.request().get_vars;
				var post: Array<VarList> = me.request().post_vars;
				var p = null;
				for(i in get) {
					var key : String = i.key;
					var value : String = i.value;
					var tmp = untyped __dollar__amake(3);
					tmp[0] = untyped key.__s;
					tmp[1] = untyped value.__s;
					tmp[2] = untyped p;
					p = tmp;
				}
				for(i in post) {
					var key : String = i.key;
					var value : String = i.value;
					var tmp = untyped __dollar__amake(3);
					tmp[0] = untyped key.__s;
					tmp[1] = untyped value.__s;
					tmp[2] = untyped p;
					p = tmp;
				}
				return p;
			});
// 		funcs.set("cgi_get_cwd", function() : String {
		funcs.set("cgi_get_cwd", function() {
				var p : String = me.request().path_translated;
				if(me.request().path.charAt(0) != "/")
					p = p + "/";
				p = p + me.request().path;
				p = p.substr(0,p.lastIndexOf("/"));
				return neko.Lib.haxeToNeko(p);
			});
		funcs.set("cgi_set_main", function(f:Void->Void) : Void {
				var name = me.module();
				me.module_cache.set(name, f);
			});
		funcs.set("cgi_flush", function() : Void {
			});
// 		funcs.set("parse_multipart_data", function(onPart : String -> String -> Void, onData : String -> Int -> Int -> Void) : Void {
		funcs.set("parse_multipart_data", function(onPart, onData) : Void {
				if(!Reflect.isFunction(onPart) || !Reflect.isFunction(onData)) {
					trace("Provided callback is not a function in parse_multipart_data");
					return;
				}

				for(i in 0...me.request().file_vars.length) {
					onPart(
						neko.Lib.haxeToNeko(me.request().file_vars[i].name),
						neko.Lib.haxeToNeko(me.request().file_vars[i].filename)
						);
					me.request().file_vars[i].parse_multipart_data(onData);
				}
			});

		var lp = function (spec:String, nargs:Int) {
			//trace(here.methodName + " " + spec + " "+nargs);
			var l = spec.length;
			if(l > 9 && spec.substr(0,9) == 'mod_neko@') {
				spec = spec.substr(9,l-9);
				var f = resolve_method(spec);
				if( f == null ) throw('Unknown mod_neko primitive : ' + spec);
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

	public function response() : Dynamic {
		return cur_response;
	}

	public function module() : String {
		return cur_module;
	}


	function runModule(request:HttpdRequest, response:HttpdResponse, moduleName:String, pathTranslated:String, pathInfo:String, filedate:Date) : Int
	{
		cur_module = moduleName;
		var buffer = new String("");
		var pf = function(str:Dynamic) {
			buffer += Std.string(str);
			//neko.io.File.stdout().write("REDIRECT BUFFER>> "+str);
		}

		// setup print redirection
		var redirect = loader._loadPrim("std@print_redirect", 1);
		redirect(pf);

		// check module cache
		var oldCache = loader.getCache();
		HxTTPDTinyServer.logTrace(here.methodName + " running module "+moduleName,4);
		var vmm = loader.getCache().get(moduleName);
		var main = module_cache.get(moduleName);
		if(vmm != null &&
			(
				filedate.getTime() > vmm.timestamp.getTime() ||
				main == null
			)
		)
		{
			HxTTPDTinyServer.logTrace(here.methodName + " reloading module "+moduleName,3);
			vmm = null;
		}
		if(vmm == null) {
			// not yet in cache, or was just expired
			try {
				vmm = loader.loadModule(moduleName);
			}
			catch(e:Dynamic) {
				trace(here.methodName + " " + e);
				redirect(null);
				return HttpdPlugin.ERROR;
			}
		}

		// if main is set, call it
		if(module_cache.exists(moduleName)) {
			module_cache.get(moduleName)();
		}
		else {
			// unload module
			loader.backupCache(oldCache);
		}

		redirect(null);

		setMessage(response, buffer);
		return HttpdPlugin.COMPLETE;
	}

	public function onTranslate(server : HxTTPDTinyServer, request : HttpdRequest,response:HttpdResponse) : Int {
		cur_server = server;
		cur_request = request;
		cur_response = response;
		var uri = request.path;
		var docroot = request.path_translated;
		//trace(here.methodName + " docroot: "+docroot+" uri " + uri);

		var pos = uri.indexOf(".n");
		if(pos < 1)
			return HttpdPlugin.SKIP;
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
		if(idx < 0) return HttpdPlugin.SKIP;

		//trace(here.methodName + " Application is " + parts[idx]);
		uri = "/" + parts.slice(0,idx+1).join("/");
		//trace(here.methodName + " New uri is " + uri);

		var path : String = docroot + uri;
		var fileinfo = checkFile(path);
		if(fileinfo.r != HttpdPlugin.COMPLETE)
			return fileinfo.r;

		var moduleName : String = path.substr(0, path.length-2);

		var sbPathInfo = new StringBuf();
		for(i in idx+1...parts.length) {
			sbPathInfo.add("/");
			sbPathInfo.add(parts[i]);
		}

		if(sbPathInfo.toString().length > 0) {
			request.path_info = sbPathInfo.toString();
		}

		response.setStatus(0);
		var rv = runModule(request, response, moduleName, path, sbPathInfo.toString(), fileinfo.d);
		HxTTPDTinyServer.logTrace(here.methodName + " "+rv,5);
		if(rv == HttpdPlugin.COMPLETE) {
			//setResponseHeader(response, "Content-Type","text/html");
			setResponseHeader(response, "Last-Modified", GmtDate.timestamp());
			setResponseHeader(response, "Expires","Thu, 19 Nov 1981 08:52:00 GMT");
			setResponseHeader(response, "Cache-Control","no-store, no-cache, must-revalidate, post-check=0, pre-check=0");
			setResponseHeader(response, "Pragma","no-cache");
			setResponseHeader(response,"Content-Type","text/html",true);
			setResponseHeader(response, "X-ModNeko", version);
			if(response.getStatus() == 0)
				response.setStatus(200);
		}
		return rv;
	}


	public function checkFile(path:String) : { r : Int, d : Date } {
		// TODO: sync this function with ModHive
		var stat : Dynamic;
		try {
			switch(neko.FileSystem.kind(path)) {
			case kdir:
				return { r:HttpdPlugin.SKIP, d:null };
			case kother(k):
				if(k != "symlink")
					return { r:HttpdPlugin.ERROR, d:null};
			case kfile:
			}
			stat = neko.FileSystem.stat(path);
		}
		catch(e : Dynamic) { // file not found
			return { r:HttpdPlugin.SKIP, d:null };
		}
		return { r:HttpdPlugin.COMPLETE, d:stat.mtime};
	}

}
