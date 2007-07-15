class Index {

	var instvar : String;
	/**
		Called on application initialization. This should print nothing.
		Setup any static vars here.
	*/
	public static function main() {}

	/**
		A must have ;) This will be the one and only instance.
	*/
	public function new() {
		instvar = "Not initialized";
		neko.Lib.println("New Index created");
	}

	/**
		This function is called when there is no function declared in the
		uri. That is, the url will be http://localhost:8080/Index
	*/
	public function handleRequest(a:Dynamic, b:Dynamic) {
		instvar = "Instance variable is initialized now";
		neko.Lib.print("This is the default method!<br>\n");
		neko.Lib.print("<a href='/Index/method1'>Method 1</a><br>\n");	

		neko.Lib.print("<a href='/Index/method2'>Method 2 with no args. It requires some, should fail</a><br>\n");
		var s = StringTools.urlEncode("Hello?&World");
		neko.Lib.print("<a href='/Index/method2/"+ s +"'>Method 2 with arg Hello World</a><br>\n");	

		neko.Lib.print("<a href='/Index/method3'>Method 3 with no args.</a><br>\n");	
		neko.Lib.print("<a href='/Index/method2/Goodbye%32Cruel%32World'>Method 3 with argument</a><br>\n");	
	}

	/**
		A method with no arguments
	*/
	public function method1() {
		neko.Lib.print("This is method1 "+instvar);	
	}

	public function method2(arg1:Dynamic) {
		neko.Lib.print(arg1);	
	}

	public function method3(?arg1:Dynamic) {
		neko.Lib.print(arg1);	
	}
}
