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

		//       call class:method          funcargs  constrarg
		trace(m.call(["TestModule","function"], null, null));

		try {
			trace(m.call("TestModule:idontexist", null, null));
		} catch(e:Dynamic) { trace("Method not found"); }


		trace("Running test function 3 times");
		var inst = m.createInstance();
		m.exec(inst, "testfunc");
		m.exec(inst, "testfunc");
		m.exec(inst, "testfunc");
*/

class VmLoader {
	static var vmLoaders	: Hash<VmLoader> 	= new Hash();

	var ldr 		: neko.vm.Loader;
	var path		: Array<String>;
	var cache		: Hash<VmModule>;

	/**
		Create a new loader.
		Default path is taken from the system defaults
	*/
	public function new(?ldrName : String) {
		ldr = neko.vm.Loader.make(_loadPrim, _loadMod);
		path = neko.vm.Loader.local().getPath();
		cache = new Hash();
		if(ldrName != null) {
			VmLoader.register(this,ldrName);
		}
	}

	//////////////////////////////////////////////////////////////////
	//		STATIC METHODS
	//////////////////////////////////////////////////////////////////
	/**
		Register global loader
	*/
	public static function register(vml:VmLoader, name : String) {
		vmLoaders.set(name, vml);
	}

	/**
		Find globally registered loader
	*/
	public static function get(name : String) {
		var vml = vmLoaders.get(name);
		if(vml == null)
			throw "No such loader";
		return vml;
	}

	public static function release(name : String) {
		vmLoaders.set(name, null);
	}

	/**
		Create a named, registered loader.
	*/
	public static function create(ldrName:String) {
		return new neko.vmext.VmLoader(ldrName);
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
		// won't run if something above throws
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

	public function getPath() {
		return path;
	}

	/**
		Set the search paths for this loader. This
		erases any previous paths.
	*/
	public function setPath( p : Array<String> ) : Void {
		path = p;
	}


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
		//trace(here.methodName + " " + moduleName);
		var m : neko.vm.Module;
		try {
			m =  neko.vm.Module.readPath(moduleName+".n", path, ldr);
		} catch(e:Dynamic) {
			throw("Module not found : "+moduleName);
		}
		return m;
	}
}



