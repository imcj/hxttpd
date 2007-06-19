/**
	A simple plugin that just illustrates both the haXe and the C portions
	of the plugin
*/
class ModTest extends HttpdPlugin {
	private static var c_on_interval = neko.Lib.load("mod_test", "on_interval", 1);

	public static function main() {	}

	// Return the main class name
	public static function vmmMainClassName() : String {
		return "ModTest";
	}

	public function new() {
		super();
		name = "ModTest";
		version = "0.1";

		// set the handler functions
		_hInterval = onInterval;
	}

	// Do not actually use the class specification for server
	// or any other class passed to the module, or all
	// of hxttpd will be compiled into the module.
	// aka. bad 
	public function onInterval(server : Dynamic) {
		c_on_interval(server);
		trace(Reflect.field(server, "document_root"));
	}

}
