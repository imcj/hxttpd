import neko.Lib;
enum PluginResponse {
	ERROR;
	SKIP;
	COMPLETE;
}

class HttpdPlugin {
	public var name		: String;
	public var version	: String;

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
	// determine physical path
	public var _hTranslated			: Dynamic;
	// request complete
	public var _hReqComplete 		: Dynamic;

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
}