package neko.vmext;
import neko.vm.Module;
import neko.vm.Loader;
import neko.vm.Loader.LoaderHandle;

class VmModule {
	var module(default,null)	: neko.vm.Module;
	var name			: String;
	var filename			: String;
	var main			: String;
	var eresult			: Dynamic;
	var size			: Int;

	public function new(m:neko.vm.Module, name:String) {
		module = m;
		this.name = name;
		eresult = m.execute();
		filename = m.name();
		findMain();
		size = m.codeSize();
	}

	// Checks the classes to see if there is one named the same
	// as the module name, or the return value of main() in the 
	// loaded module. This is treated as the "main" class of the
	// module, which is then used whenever a method-only call
	// is made via call() or exec()
	private function findMain() {
		main = null;
		var exp = module.exportsTable().__classes;
		for(i in Reflect.fields(exp)) {
			trace(here.methodName+ " class: " + i);
			if(i == eresult) {
				main = i;
				trace(here.methodName + " Selected " + i + " as main class");
				return;
			}
			if(i.toLowerCase() == name.toLowerCase()) {
				main = i;
				trace(here.methodName + " Selected " + i + " as main class");
				return;
			}
		}
	}

	/**
		Create an instance of a class
	*/
	public function createInstance(?className:String, ?constructArgs:Array<Dynamic>) : Dynamic {
		if(className == null)
			className = main;
		if(constructArgs == null)
			constructArgs = new Array<Dynamic>();
		var classes : Dynamic = module.exportsTable().__classes;
		var c : Class<Dynamic> = Reflect.field(classes, className);
		var inst = Type.createInstance(c,constructArgs); 
		return inst;
	}

	/**
		Call a method in a class using the syntax [class:]method
	*/
	public function call(classMethod:String, constructArgs:Array<Dynamic>, ?args:Array<Dynamic>) : Dynamic {
		var nClass,nMethod : String;
		var cmparts = classMethod.split(":");
		if(cmparts.length == 1) 
			nClass = main;
		else
			nClass = cmparts[0];
		var nMethod = cmparts[cmparts.length-1];

		// Check for function arguments. Construct args are checked in createInstance
		///
		if(args == null)
			args = new Array<Dynamic>();

		trace(here.methodName+" class: "+nClass+" method: "+nMethod);

		var classes : Dynamic = module.exportsTable().__classes;
		var c : Class<Dynamic> = Reflect.field(classes, nClass);
		var inst = createInstance(nClass, constructArgs);

		return exec(inst, nMethod, args);
	}

	/**
		Run a method on an existing Class instance. An instance
		must first be created with createInstance();
	*/
	public function exec(instance:Dynamic, nMethod:String, ?args:Array<Dynamic>) {
		// Check for constructor and function arguments.
		///
		if(args == null)
			args = new Array<Dynamic>();
		var func = Reflect.field(instance,nMethod);
		if (Reflect.isFunction(func)) {
			return Reflect.callMethod(instance,func,args);
		}			
		throw(nMethod + " is not a valid function");
		return null;
	}
}

