import neko.vmext.VmLoader;
import neko.vmext.VmModule;
class LoaderTest {

	static public function registerTest() {
		VmLoader.get("webdoc").loadModule("Test");
		var inst = VmLoader.get("webdoc").getCache().get("Test").createInstance();
		VmLoader.get("webdoc").getCache().get("Test").registerInstance(inst,"global");
		VmLoader.get("webdoc").getCache().get("Test").exec(inst, "setMessage", ["Hello world!"]);

	}

	static public function useTest() {
		var vmm = VmLoader.get("webdoc").getCache().get("Test");
		var inst = vmm.getInstance("global");
		trace("useTest says "+vmm.exec(inst,"getMessage"));
	}

	static public function staticTest() {
		var vmm = VmLoader.get("myloader").getCache().get("Test");
		//fromString(str : String) : Array<String>
		var res = vmm.call(["fromString"], ["bytes=1000-2000"]);
		trace(here.methodName + " This should say [1000-2000] >> " + Std.string(res));

		// here, is an example where one loader sets a static
		// class value, and the other loader does not have the
		// same value set.
		res = vmm.call(["setStaticMessage"],["Hello again, world."]);
		trace("myloader " + vmm.call(["getStaticMessage"]));
		var vmm2 = VmLoader.get("webdoc").getCache().get("Test");
		trace("webdoc " + vmm2.call(["getStaticMessage"]));
	}

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
			trace(mb.call(["Test","fromString2"], ["bytes=1-2,4-45"]));
                }
		catch(e:Dynamic) {
			trace("Method not found: " + e);
		}

		// get module from loader
		trace("\n\nLoader test 2");
		mb = loadA.getCache().get("Test");
		trace(mb.call(["Test","fromString2"], ["bytes=1-2,4-45"]));

		// register loader globally
		trace("\n\nLoader test 3");
		VmLoader.register(loadA, "myloader");
		mb = VmLoader.get("myloader").getCache().get("Test");
		trace(mb.call(["Test","fromString2"], ["bytes=1-2,4-45"]));

		// create a pre-named loader
		neko.vmext.VmLoader.create("webdoc");
		// use it in this function:
		registerTest();
		useTest();
		staticTest();


	}
}
