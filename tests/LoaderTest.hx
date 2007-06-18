import neko.vmext.VmLoader;
import neko.vmext.VmModule;
class LoaderTest {


	static public function main() {
		trace("\n\n**** LoaderTest");
		var loadA = new neko.vmext.VmLoader();

		// Example of keeping your own handle to a module
		var mb : VmModule;
		try {
			mb = loadA.loadModule("Test");
		} catch(e:Dynamic) {
			trace("error loading module : "+e);
			return;
		}
		trace("\nLoaderTest calling method fromString()");
                try {
			//       call cl:mth   constrarg  funcargs
			trace(mb.call("Test:fromString2", null, ["bytes=1-2,4-45"]));
                } 
		catch(e:Dynamic) { 
			trace("Method not found: " + e); 
		}

		// get module from loader
		trace("\n\nLoader test 2");
		mb = loadA.getCache().get("Test");
		trace(mb.call("Test:fromString2", null, ["bytes=1-2,4-45"]));

		// register loader globally
		trace("\n\nLoader test 3");
		VmLoader.registerByName(loadA, "myloader");
		mb = VmLoader.getByName("myloader").getCache().get("Test");
		trace(mb.call("Test:fromString2", null, ["bytes=1-2,4-45"]));
		

	}
}
