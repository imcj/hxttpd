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

import ThreadExtra;

private class ThreadInfo implements Dynamic {
	public var buffer : StringBuf;
	public var bufcount : Int;
	public var id : Int;
	public var t : ThreadExtra;
	public var sock : neko.net.Socket;
	public var request : HttpdRequest;
	public var response : HttpdResponse;
	public var context : ModHive;
	public var moduleName : String;
	public var filedate : Date;
	public var print_redirect : Dynamic;
	public var exit : Dynamic;

	/**
		Each client has an output buffer, for buffering output.
		This is 4K by default.
	**/
	public static var MAX_OUTBUFSIZE = (1 << 12);


	public function new(context:Dynamic, tid:Int) {
		buffer = new StringBuf();
		bufcount = 0;
		id = tid;
		this.context = context;

		t = null;
		sock = null;
		request = null;
		response = null;
		moduleName = null;
		filedate = null;
	}

	public function init() {
		var l = new neko.vm.Lock();
		buffer = new StringBuf();
		bufcount = 0;
		t = null;
		sock = null;
		request = null;
		response = null;
		//context = null;
		moduleName = null;
		filedate = null;
		l.release();
	}

	public function flush() {
		if(!response.headers_sent) {
			response.startChunkedResponse();
		}
		flushbuffer();
	}

	public function flushbuffer() {
		var s = buffer.toString();
		if(s.length > 0) {
			response.sendChunk(s);
			bufcount = 0;
			buffer = new StringBuf();
		}
	}

	public function printfunction(str:Dynamic) {
		var s : String = Std.string(str);
		var inLength = s.length;
		if(!response.headers_sent) {
			response.startChunkedResponse();
		}

		buffer.add(str);
		bufcount += inLength;
		if(bufcount >= MAX_OUTBUFSIZE) {
			flushbuffer();
		}
		//neko.io.File.stdout().write("REDIRECT BUFFER>> "+str);
	}

	public function sendMessage(msg:Dynamic) : Void {
		neko.Lib.print(msg);
		flushbuffer();
		response.endChunkedResponse();
		request.setClientState(HttpdClientData.STATE_CLOSING);
	}

	public function internalError(msg:Dynamic, ?e:Dynamic) {
		try {
			//setResponseCode(ti.request, 500);
			neko.Lib.print(HttpdResponse.codeToHtml(500));
			if(e != null)
				neko.Lib.print(Std.string(e));
			response.keepalive = false;
			//ti.request.prepareResponse();
			//ti.request.sendResponse();

		} catch ( e:Dynamic ) {}
		print_redirect(null);
		flushbuffer();
		trace(msg);
		response.endChunkedResponse();
		request.setClientState(HttpdClientData.STATE_CLOSING);
	}
}


/*
enum WorkerMsgType {
SHUTDOWN;
FLUSH;
}
*/

typedef ClientThreadMsg = {
	id : Int,
	msg : Int
}




class ModHive extends HttpdPlugin {


	static var threads 	: Array<ThreadInfo> = new Array<ThreadInfo>();
	static var worker	: ThreadExtra;
	var nthreads 	: Int;			// same as server.listenCount
	var ithread	: Int;			// thread index position

	public static function main() { }

	// Return the main class name
	public static function vmmMainClassName() : String {
                return "ModHive";
	}

	public static function findThread(th:ThreadExtra) : Int {
		//var l = new neko.vm.Lock();
		for(i in threads) {
			if(i.t == null) continue;
// 			if(i.id < 10) {
// 				trace(here.methodName + " checking thread #"+i.id);
// 			}
			if(ThreadExtra.equals(i.t, th) == true)
				return i.id;
		}
		neko.io.File.stdout().write("Could not locate thread.");
		//l.release();
		return -1;
	}

	public function new() {
		super();
		name = "ModHive";
		version = "0.3";

		//threads = new Array();
		nthreads = 0;
		ithread = 0;

		// set the handler functions
		_hConfig = onConfig;
		_hTranslate = onTranslate;
        }

	public function onConfig(server : HxTTPDTinyServer) : Int {
		if(server.isPluginRegistered("ModNeko")) {
			errStr = "ModNeko and ModHive are currently incompatible";
			return HttpdPlugin.ERROR;
		}

		nthreads = server.listenCount;
		for( i in 0...nthreads ) {
			var t = {
				id : i,
				t : null,
				sock : null,
				request : null,
				response : null,
				context : this,
				moduleName : null,
				filedate : null
			};
			var t = new ThreadInfo(this, i);
			threads.push(t);
		}
		worker = ThreadExtra.create(runWorker);
		//timer = neko.vm.Thread.create(runTimer);

		return HttpdPlugin.COMPLETE;
	}

	public function isHiveDir(path:String) : Bool {
		return true;
	}

	public function checkFile(path:String) : { r : Int, d : Date } {
		// TODO: sync this function with ModNeko
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


	public function onTranslate(server : HxTTPDTinyServer, request : HttpdRequest,response:HttpdResponse) : Int {
		var uri = request.path;
		var docroot = request.path_translated;

		var uriparts : Array<String> = request.uriparts;
		var idx : Int = -1;
		var rPath = new StringBuf();
		rPath.add(docroot);
		for(x in 0...request.uriparts.length) {
			if(isHiveDir(rPath.toString())) {
				idx = x;
				break;
			}
			rPath.add("/");
			rPath.add(uriparts[x]);
		}
		if(idx < 0)
			return HttpdPlugin.SKIP;
		uriparts = uriparts.slice(idx);
		//trace(rPath);
		//trace(uriparts);
		if(uriparts.length == 0 || (uriparts.length==1 && uriparts[0].length == 0)) {
			trace("No elements in parts");
			uriparts = ["Index"];
		}

		// getting module name
		var nameOnly = uriparts.shift();
		var moduleName = rPath.toString() + "/" + nameOnly;
		var fullpath = moduleName + ".n";

		// check file
		var fileinfo = checkFile(fullpath);
		if(fileinfo.r != HttpdPlugin.COMPLETE)
			return fileinfo.r;

		request.path_info = "/" + uriparts.join("/");
		if(request.path_info == "/") request.path_info = null;
		request.path_translated = fullpath;
		uriparts.insert(0,nameOnly);
		request.uriparts = uriparts;
// 		trace("path_translated: "+request.path_translated);
// 		trace("path_info: " +request.path_info);
// 		trace("uriparts: "+request.uriparts);

		// find empty thread
		// 503 Service Unavailable on error
		idx = -1;
		for(i in ithread...nthreads) {
			//trace("thread "+i);
			if(threads[i].request == null) {
				idx = i;
				break;
			}
		}
		//trace("first try idx:"+idx);
		if(idx < 0) {
			for(i in 0...ithread) {
				//trace("try 2" + i);
				if(threads[i].request == null) {
					idx = i;
					break;
				}
			}
		}
		if(idx < 0) {
			response.setStatusMessage(503);
			return HttpdPlugin.COMPLETE;
		}
		//trace("Thread number " + idx);

		// Assume we're ok
		response.setStatus(200);
		request.path = docroot;

		request.client.setState(HttpdClientData.STATE_PROCESSING);
		threads[idx].request = request;
		threads[idx].response = response;
		threads[idx].sock = request.client.sock;
		threads[idx].moduleName = moduleName;
		threads[idx].filedate = fileinfo.d;
		threads[idx].t = ThreadExtra.create(callback(runThread,threads[idx]));

		//set client to processing state
		return HttpdPlugin.PROCESSING;
	}

	function runWorker() {
		while( true ) {
 			var m : ClientThreadMsg = ThreadExtra.readMessage(true);
 			switch(m.msg) {
 			case HiveThreadMessage.SHUTDOWN:
 				threads[m.id].init();
 			case HiveThreadMessage.FLUSH:
 				threads[m.id].flush();
 			}
		}
	}


	function runThread(ti : ThreadInfo) : Void {
		var lock : neko.vm.Lock;
		var funcs : Hash<Dynamic> = new Hash();

		// wait for parent thread assignment
		while(ti.t == null) {}

/*
trace(here.methodName);
trace(1);
trace("moduleName " + ti.moduleName);
trace("args " + ti.request.args);
trace("uriparts in ti " +ti.request.uriparts);
trace("path "+ti.request.path);
trace("path_translated: "+ti.request.path_translated);
trace("path_info "+ti.request.path_info);
trace(2);
//trace(ti.request);
*/
		// set the default headers out
		ti.response.setHeader("Content-Type", "text/html");
		ti.response.setHeader("Last-Modified", GmtDate.timestamp());
		ti.response.setHeader("Expires","Thu, 19 Nov 1981 08:52:00 GMT");
		ti.response.setHeader("Cache-Control","no-store, no-cache, must-revalidate, post-check=0, pre-check=0");
		ti.response.setHeader("Pragma","no-cache");
		ti.response.setHeader("X-ModHive", version);


		var nekoSysExit = function(code:Int) {
			//trace("Thread "+ThreadExtra.current()+ " called exit");
			var idx = ModHive.findThread(ThreadExtra.current());
			//var ti : ThreadInfo = ModHive.findThread(ThreadExtra.current());
			if(idx >= 0) {
				if(!threads[idx].response.headers_sent) {
					threads[idx].response.startChunkedResponse();
				}
				try {
					threads[idx].flushbuffer();
					threads[idx].response.endChunkedResponse();
				} catch(e:Dynamic) {}
				threads[idx].print_redirect(null);
				threads[idx].request.setClientState(HttpdClientData.STATE_CLOSING);
				worker.sendMessage({ id : idx, msg : HiveThreadMessage.SHUTDOWN });
			}
			ThreadExtra.exit();
		}

		var hiveSendMessage = function(mesg:Dynamic) : Void {
			//trace("Thread "+ThreadExtra.current()+ " called sendMessage");
			var idx = ModHive.findThread(ThreadExtra.current());
			if(idx >= 0) {
				worker.sendMessage({ id: idx, msg: mesg});
			}
		}

		// retrieve the loader for this module
		var vml : neko.vmext.VmLoader;
		try {
			vml = neko.vmext.VmLoader.get("ModHive:"+ti.moduleName);
		} catch(e:Dynamic) {
			vml = null;
		}

		var resolve_method = function(fname:String) : Dynamic {
			return funcs.get(fname);
		}
		var lp = function (spec:String, nargs:Int) {
			//trace(here.methodName + " " + spec + " "+nargs);
			var l = spec.length;
			// std@sys_exit
			if(l == 12) {
				if(spec == "std@sys_exit") {
					var f = nekoSysExit;
					return f;
				}

			}
			if(l == 17) {
				if(spec == "hive@send_message") {
					var f = hiveSendMessage;
					return f;
				}
			}
			if(spec.indexOf("encodeURIComponent")>=0) {
				trace(spec);
			}
			if(l > 9 && spec.substr(0,9) == 'mod_neko@') {
				neko.Lib.println("*********   Module tried to load mod_neko");
				return null;
			}
			return neko.vm.Loader.local().loadPrimitive(spec, nargs);
		}
		if(vml == null) {
			//vml = HaxeModNeko.getModNekoVmLoader("ModHive:"+ti.moduleName,request_method, resolve_method, funcs);

			vml = new neko.vmext.VmLoader("ModHive:"+ti.moduleName, lp);

		}

		// setup print redirection
		ti.print_redirect = neko.vm.Loader.local().loadPrimitive("std@print_redirect", 1);
		ti.print_redirect(ti.printfunction);

		// retrieve the module
		var vmm : neko.vmext.VmModule;
		lock = new neko.vm.Lock();
		vmm = vml.getCache().get(ti.moduleName);
		if(vmm != null && ti.filedate.getTime() > vmm.timestamp.getTime())
			vmm = null;
		if(vmm == null) {
			// not yet in cache, or was just expired
			try {
				vmm = vml.loadModule(ti.moduleName);
			}
			catch(e:Dynamic) {
				//print_redirect(null);
				lock.release();
				ti.internalError("Module not found",e);
				worker.sendMessage({ id : ti.id, msg : HiveThreadMessage.SHUTDOWN });
				return;
			}
		}


		// retrieve the instance
		var inst : Dynamic;
		try {
			inst = vmm.getInstance("ModHiveInst");
			if(inst == null) {
				inst = vmm.createInstance();
				vmm.registerInstance(inst, "ModHiveInst");
			}
		}
		catch(e:Dynamic) {
			// if this is reached, it means that an instance of the
			// class could not be created. That would be because it
			// has no function new()
			lock.release();
			trace(e);
			ti.internalError(e);
			worker.sendMessage({ id : ti.id, msg : HiveThreadMessage.SHUTDOWN });
			return;
		}
		lock.release();


		// determine method and args
		var uriparts = ti.request.uriparts;
		// remove moduleName
		uriparts.shift();
		var method = "handleRequest";
		if(uriparts.length > 0) {
			if(uriparts[0].length > 0)
				method = uriparts.shift();
			else
				uriparts.shift();
		}


		var finalize = function() {
			ti.print_redirect(null);
			if(!ti.response.headers_sent) {
				ti.response.startChunkedResponse();
			}
			try {
				ti.flushbuffer();
				ti.response.endChunkedResponse();
			} catch(e:Dynamic) { trace("Error flushing ModHive thread buffer.");}
		}

		// execute it
		var rv : Dynamic;
		try {
			var args = new Array<Dynamic>();
			/*
			for(i in uriparts) {
				args.push(i);
			}
			*/
//trace("Calling method: " +method);
//trace("args: "+uriparts);
//trace(ti.response.status);
			//vmm.exec(inst,method,args);
			rv = vmm.exec(inst,method,[ti.request,ti.response]);
		}
		catch(e:Dynamic) {
			if(!ti.response.headers_sent) {
				ti.response.setStatus(400);
				ti.sendMessage(HttpdResponse.codeToHtml(400));
			}
			finalize();
			ti.request.setClientState(HttpdClientData.STATE_CLOSING);
			trace(here.methodName + " rv: "+rv + " e: "+e);
			worker.sendMessage({ id : ti.id, msg : HiveThreadMessage.SHUTDOWN });
			return;
		}


		finalize();
		ti.request.setClientState(HttpdClientData.STATE_CLOSING);
		worker.sendMessage({ id : ti.id, msg : HiveThreadMessage.SHUTDOWN });
		return;
	}
}
