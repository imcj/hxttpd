package neko.vmext;
import neko.vm.Module;
import neko.vm.Loader;
import neko.vm.Loader.LoaderHandle;
/**
	VmLoader wraps the module management of neko, with a custom
	loader class and a custom VmModule class.


	SAMPLE USAGE:
		var loadA : VmLoader = new VmLoader();
		var m : VmModule;
		try {
			m = loadA.loadModule("testmodule");
		} catch(e:Dynamic) {
			trace("error loading module : "+e);
			return;
		}

		//       call cl:mth   constrarg  funcargs
		trace(m.call("TestModule:function", null, null));

		try {
			trace(m.call("TestModule:idontexist", null, null));
		} catch(e:Dynamic) { trace("Method not found"); }


		trace("Running test function 3 times");
		var inst = m.createInstance();
		m.exec(inst, "nice");
		m.exec(inst, "nice");
		m.exec(inst, "nice");
*/

class VmLoader {
	var ldr 		: neko.vm.Loader;
	var path		: Array<String>;
	var cache		: Hash<VmModule>;
	static var vmLoaders	: Hash<VmLoader> 	= new Hash();

	/**
		Create a new loader.
		Default path is taken from the system defaults
	*/
	public function new() {
		trace(here.methodName);
		ldr = neko.vm.Loader.make(_loadPrim, _loadMod);
		path = neko.vm.Loader.local().getPath();
		cache = new Hash();
	}

	//////////////////////////////////////////////////////////////////
	//		STATIC METHODS
	//////////////////////////////////////////////////////////////////
	/**
		Register global loader
	*/
	public static function registerByName(vml:VmLoader, name : String) {
		vmLoaders.set(name, vml);
	}

	/**
		Find globally registered loader
	*/
	public static function getByName(name : String) {
		var vml = vmLoaders.get(name);
		if(vml == null) 
			throw "No such loader";
		return vml;
	}

	public static function releaseByName(name : String) {
		vmLoaders.set(name, null);
	}


	//////////////////////////////////////////////////////////////////
	//		PUBLIC METHODS
	//////////////////////////////////////////////////////////////////
	/**
		Add a path to the default module path.
		The element added is inserted at the _start_ of the
		path array. This means the most recent additions 
		to the path will be searched first.
		To add to the end of the paths, set append to true.
	*/
	public function addPath( s : String, ?append : Bool ) : Void {
		if(append)
			path.push(s);
		else
			path.insert(0,s);
	}

	/**
		Load a module. Unlike neko.vm.Loader, the module
		is initialized when it is loaded.
	*/
	public function loadModule(moduleName:String) : VmModule {
		var m = _loadMod(moduleName);
		var vmm = new VmModule(m, moduleName);
		// won't runn if something above throws
		cache.set(moduleName, vmm);
		return vmm;
	}

	/**
		Cache control the same as neko.vm.Loader
	*/
	public function backupCache( c : Dynamic ) : Dynamic {
		var old = untyped cache;
		untyped cache = c;
		return old;
        }

	/**
		Cache
		var m = neko.vm.Loader.local().getCache().get(moduleName);
		would be:
		var vmm = neko.vmext.VmLoader.getByName("myloader").getCache().get(moduleName);
	*/
	public function getCache() {
		return cache;
	}

	/**
		Set the search paths for this loader. This
		erases any previous paths.
	*/
	public function setPath( p : Array<String> ) : Void {
		path = p;
	}

	/**
		Create a static instance of a class
	*/
	/*
	public function registerInstance() {
	}
	public function getInstance() {
	}
	*/
/*
	public function getClass(moduleName:String, ?className:String) {
		if(className == null) {
			className = m.getMain();
		}
	}

	public function getModule(moduleName:String) : neko.vm.Module {
	}

	call("plugins:mod_cgi:class:method",construct,
	public function call(vmm:VmModule, methodName:String, constructArgs:Array<Dynamic>, args:Array<Dynamic>) {
	}
*/



	/////////////////////////////////////////////////////////////
	// Don't call these. These are the callbacks from the real
	// neko loader.
	/////////////////////////////////////////////////////////////
	public function _loadPrim(spec:String, args:Int) : Dynamic {
		//trace(here.methodName + " "+spec+" "+args);
		return neko.vm.Loader.local().loadPrimitive(spec, args);
	}

	// don't set the cache object from here, loadModule() above does that.
	public function _loadMod(moduleName:String, ?l:neko.vm.Loader) : neko.vm.Module {
		trace(here.methodName + " " + moduleName);
		var m : neko.vm.Module;
		try {
			m =  neko.vm.Module.readPath(moduleName+".n", path, ldr);
		} catch(e:Dynamic) {
			try {
				m =  neko.vm.Module.readPath(moduleName+".ndll", path, ldr);
			}
			catch(e:Dynamic) {
				throw("Module not found : "+moduleName);
			}
		}
		return m;
	}
}



