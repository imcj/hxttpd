import neko.Lib;


class HttpdPlugin {
	// responses
	public static var ERROR		: Int = 0;
	public static var SKIP		: Int = 1;
	public static var COMPLETE	: Int = 2;
	public static var PROCESSING	: Int = 3; // when socket needs to be left alone

	public var name		: String;
	public var version	: String;
	public var errStr	: String;

	// Each of the following fields can be set to a function
	// to handle that event.

	// parse configuration
	public var _hConfig			: Dynamic;
	// interval timer, 1 per second
	// Server->PluginResponse
	public var _hInterval			: Dynamic;
	// app shutdown
	public var _hCleanup			: Dynamic;

	// handle raw request
	public var _hReq			: Dynamic;
	// after the uri has been set
	public var _hUri			: Dynamic;
	// determine document root
	public var _hDocroot			: Dynamic;
	// determine physical path. When called, req.path_translated is set
	// to the document root, and req.path is the uri
	public var _hTranslate			: HxTTPDTinyServer->HttpdRequest->HttpdResponse->Int;
	// request complete
	public var _hReqComplete 		: Dynamic;

	public function new() {
		version = "";
		name = "";

		_hConfig = null;
		_hReq = null;
		_hUri = null;
		_hDocroot = null;
		_hTranslate = null;
		_hCleanup = null;
		_hReqComplete = null;
	}

	/**
		Return a string with the name of the main
		class in the module. This class will be instanced
		when loading the plugin.
		Must be overridden.
	*/
	public static function vmmMainClassName() : String {
		throw("Plugin has not implemented vmmMainClassName");
		return "";
	}

	public function setRequestField(request:Dynamic, field:String, value:Dynamic) : Void {
		Reflect.setField(request, field, value);
	}

	public function getRequestField(request:Dynamic, field:String) {
		return Reflect.field(request,field);
	}
/*
	public function setResponseCode(response:Dynamic, code:Int) : Void {
		Reflect.setField(response, "status", code);
	}
*/
	public function setMessage(response:Dynamic, msg: String) : Void {
		Reflect.setField(response, "message", msg);
	}

	public function setResponseHeader(response:Dynamic, key:String, value:String, ?noreplace:Bool) {
		try {
			var func : Dynamic;
			if(noreplace)
				func = Reflect.field(response,"setHeaderIfNotSet");
			else
				func = Reflect.field(response,"setHeader");
			Reflect.callMethod(response, func,[key,value]);
		} catch(e:Dynamic) {
			trace(e);
			throw e;
		}
	}
}
