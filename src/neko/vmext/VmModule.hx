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
	var instances			: Hash<Dynamic>;

	/**
		Create a new VmModule from an existing neko.vm.Module
		and the module name. Module name does not include
		the .n or .ndll
	*/
	public function new(m:neko.vm.Module, name:String) {
		module = m;
		this.name = name;
		filename = m.name();
		main = null;
		eresult = m.execute();
		size = m.codeSize();
		instances = new Hash();
		findMain();
	}

	/**
		Checks the classes to see if there is one named the same
		as the module name, or the return value of main() in the
		loaded module. This is treated as the "main" class of the
		module, which is then used whenever a method-only call
		is made via call() or exec()
	*/
	private function findMain() {
		main = null;
		var exp = module.exportsTable().__classes;
		var nlc = name.toLowerCase();
		for(i in Reflect.fields(exp)) {
			//trace(here.methodName+ " class: " + i);
			if(i == eresult) {
				main = i;
				//trace(here.methodName + " Selected " + i + " as main class");
				return;
			}
			if(i.toLowerCase() == nlc) {
				main = i;
				//trace(here.methodName + " Selected " + i + " as main class");
				return;
			}
		}
	}

	/**
		Checks if passed class name is null, if so
		check if main is set and return it instead
	*/
	private function checkClassName(defaultName:String) {
		if(defaultName == null) {
			if(main == null)
				throw "Main class not determined for module " + name;
			return main;
		}
		return defaultName;
	}

	/**
		Create an instance of a class
	*/
	public function createInstance(?className:String, ?constructArgs:Array<Dynamic>) : Dynamic {
		className = checkClassName(className);
		if(constructArgs == null)
			constructArgs = new Array<Dynamic>();
		var classes : Dynamic = module.exportsTable().__classes;
		var c : Class<Dynamic> = Reflect.field(classes, className);
		var inst = Type.createInstance(c,constructArgs);
		return inst;
	}

	/**
		Register a static instance of a class in this module.
		The instanceName must be unique per class. If an instance
		for the specified class already exists, an error will be
		thrown. If the className is not specified, an attempt
		to use the automatically discovered main class will occur,
		which can also throw an error if there is no main.
		This returns the exact key for the registered instance,
		which is in the form "ClassName:InstanceName"
		To release instances, use freeInstance()
	*/
	public function registerInstance(inst:Dynamic, instanceName:String, ?className:String) : String {
		className = checkClassName(className);
		var spec = className+ ":" + instanceName;
		if(instances.get(spec) != null)
			throw "Instance "+spec+" already exists";
		instances.set(spec, inst);
		return spec;
	}

	/**
		Return a registered instance of a class. If no class
		has been registered, will throw an error
	*/
	public function getInstance(instanceName:String,?className:String) : Dynamic {
		var inst = instances.get(checkClassName(className) + ":" + instanceName);
		if( inst == null)
			throw "Instance "+checkClassName(className) + ":" + instanceName+ " does not exist";
		return inst;
	}

	/**
		Release a registered instance. Ignores instances that
		do not exist.
	*/
	public function freeInstance(instanceName:String,?className:String) {
		var spec = checkClassName(className) + ":" + instanceName;
		if(instances.get(spec) != null)
			instances.set(spec, null);
	}


	/**
		Call a method in a class using the syntax [class:]method
	*/
	public function call(classMethod:Array<String>, ?args:Array<Dynamic>, ?constructArgs:Array<Dynamic> ) : Dynamic {
		var nClass,nMethod : String;
		if(classMethod.length == 1) {
			if(main == null)
				throw "Main class not determined for module " + name;
			nClass = main;
		}
		else
			nClass = classMethod[0];
		var nMethod = classMethod[classMethod.length-1];

		// Check for function arguments. Construct args are checked in createInstance
		///
		if(args == null)
			args = new Array<Dynamic>();

		//trace(here.methodName+" class: "+nClass+" method: "+nMethod);

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
		// check for static method
		func = Reflect.field(Type.getClass(instance),nMethod);
		if (Reflect.isFunction(func)) {
			return Reflect.callMethod(instance,func,args);
		}
		throw(nMethod + " is not a valid function");
		return null;
	}
}

