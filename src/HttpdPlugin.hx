import neko.Lib;
enum PluginResponse {
	ERROR;
	SKIP;
	COMPLETE;
}

class HttpdPlugin {

	public var version	: String;
	public var name		: String;

	// parse configuration
	public var _hConfig		: Dynamic;
	// interval timer, 1 per second
	// Server->PluginResponse
	public var _hInterval		: Dynamic;
	// app shutdown
	public var _hCleanup		: Dynamic;

	// handle raw request
	public var _hReq		: Dynamic;
	// after the uri has been set
	public var _hUri		: Dynamic;
	// determine document root
	public var _hDocroot		: Dynamic;
	// determine physical path
	public var _hTranslated		: Dynamic;
	// request complete
	public var _hReqComplete 	: Dynamic;


	public function new() {
		version = "";
		name = "";

		_hConfig = null;
		_hReq = null;
		_hUri = null;
		_hDocroot = null;
		_hTranslated = null;
		_hCleanup = null;
		_hReqComplete = null;
	}

	public function init(name:String, version:String) {
		this.name = name;
		this.version = version;
		var lib = "name_"+version;

		_hConfig = try Lib.load(lib,"",1) catch(e : Dynamic) null;
		_hInterval = try Lib.load(lib,"on_interval",1) catch( e : Dynamic ) null;
		_hCleanup = try Lib.load(lib,"",1) catch(e : Dynamic) null;

		_hReq = try Lib.load(lib,"",2) catch(e : Dynamic) null;
		_hUri = try Lib.load(lib,"",2) catch(e : Dynamic) null;
		_hDocroot = try Lib.load(lib,"",2) catch(e : Dynamic) null;
		_hTranslated = try Lib.load(lib,"",2) catch(e : Dynamic) null;
		_hReqComplete = try Lib.load(lib,"",2) catch(e : Dynamic) null;
	}
}