import Type;

class Assoc implements Dynamic  {
	private var counter : Int;
	public var container : Dynamic;


	public function new() {
		counter = 0;
		container = Reflect.empty();
	}

	function __resolve(name) : Dynamic {
		if(Reflect.hasField(container, name)) {
			var f = Reflect.field(container, name);
			return f;
		}
		var t = new Assoc();
                Reflect.setField(container, name, t);
                return Reflect.field(container, name);
	}

	function __setfield(name, value:Dynamic) {
		switch(Type.typeof(value)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
			var s = c;
			while((s = Type.getSuperClass(s)) != null) {
				c = s;
			}
			switch(Type.getClassName(c)) {
			case "Hash":
				Reflect.setField(container, name, new Assoc());
				var f = Reflect.field(container, name);
				cast(value, Hash<Dynamic>);
				for(i in value.keys()) {
					f.__setfield(Std.string(i), value.get(i));
				}
				return;
			case "Array":
				Reflect.setField(container, name, new Assoc());
				var f = Reflect.field(container, name);
				cast(value, Array<Dynamic>);
				for(i in 0...value.length) {
					var v = value[i];
					f.__setfield(Std.string(i), v);
				}
				return;
			case "List":
				Reflect.setField(container, name, new Assoc());
				var f = Reflect.field(container, name);
				cast(value, List<Dynamic>);
				var x = 0;
				for(i in value) {
					Reflect.setField(f, Std.string(x++), i);
					f.__setfield(Std.string(x++), i);
				}
			}
		case TBool:
		}
		__resolve(name);
		Reflect.setField(container, name, value);
	}

	public function get(spec:Array<Dynamic>) : Dynamic {
		if(spec[0] == null)
			return null;
		var s : String = Std.string(spec[0]);
		if(spec.length == 1) {
			return Reflect.field( container, s );
		}
		var f = Reflect.field( container, s );
		if(f == null)
			return null;
		return f.get(spec.slice(1));
	}

	public function set(spec : Array<Dynamic>, value:Dynamic) : Bool{
		var l = spec.length;
		if(l == 0) {
			Reflect.setField(container, Std.string(counter++), value);
			return true;
		}
		var s : String = Std.string(spec[0]);
		if(l == 1) {
			__setfield(s, value);
			return true;
		}
		var f = Reflect.field(container, s);
		if(f == null) {
			var t = new Assoc();
			Reflect.setField(container, s, t);
			f = Reflect.field(container, s);
		}
		return f.set(spec.slice(1), value);
	}

	public function keys() : Array<String> {
		var handled : Bool = false;
		var rv = new Array<String>();
		for(i in Reflect.fields(container)) {
			handled = false;
			var f = Reflect.field(container,i);
			try {
				if(Type.getClassName(Type.getClass(f)) == "Assoc" ) {
					if( Reflect.fields(Reflect.field(f,"container")).length == 0)
						handled = true;
				}

			} catch(e:Dynamic) {}
			if(handled == false && f != null) {
				rv.push(i);
			}
		}
		return rv;
	}

	/**
		Recursive associative array string specification parser
		Usage: setByString("myarray[otherarr[1]]",myvalue);
	**/
	public function setByString(spec:String, value:Dynamic) : Bool {
		spec = StringTools.trim(spec);
		var p = spec.indexOf("[");
		if(p >= 0 && spec.charAt(spec.length-1) != "]")
			return false;
		if(p > 0) {
			var name = spec.substr(0,p);
			var newspec = spec.substr(p+1,spec.length-1-p);
			if(newspec.length == 0) { // myspec[]
				set([name,''], value);
				return true;
			}
			//name[newspec]
			var a = new Assoc();
			if(!a.setByString(newspec, value)) 
				return false;
			return set([name], a);
		}
		if(p == 0 && spec.length == 2) { // spec == "[]"
			// incrementing counter to this instance.
			return set([], value);
		}
		if(p == 0) { // spec == "[myfield]" || spec == "[myarr[myfield]]"
			var newspec = spec.substr(1,spec.length-2);
			return setByString(newspec, value);
		}
		return set([name], value);
	}
}

