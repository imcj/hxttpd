import Type;

class AssocTest {
	public static function main() {
		var t = new Assoc();
		trace("Main: setting t.action"); 
		t.action = "jump";
		trace("Main: t = " + t);
		trace("Main: t.action = " + t.action);
		trace("Main: t.action.jackson = " + t.action.jackson);
		trace("Main: t.other = " + t.other);
		trace("Main: t.other.jackson = " + t.other.jackson);
		trace("Main: t.other = " + t.other);
		//trace(t.other.jackson.blah);

		t.array = [1,2,3,4,5,6];
		trace(t.get(['array','5']));
		trace(t.array.get(['5']));
		trace(t.array.get(['6']));
/*
		t.bool = true;
		trace(t);
*/
		trace("Main: t.get(['action']): "+ t.get(["action"]));
		trace("Main: t.get(['array']): "+ t.get(["array"]));
		trace("Main: t.get(['array','0']): "+ t.get(["array",'0']));
		trace(t.bool);
		trace(t.bool.jsa);

		trace("\n-- non existing keys");
		trace(t.get(['apples']));
		trace(t.get(['apples', 'bananas']));
/*

		trace("\nAssignment");
		t.newfield = "Hey";
		var f = t.newfield;
		trace(f);
*/

		trace("\nSet method");
		t.set(['one','two','three'], "Nested three");
//		t.set(['one','two','four'], "Nested four");
		trace(t.get(['one','two','three']));
//		trace(t.get(['one','two','four']));

		trace("1 level");
		trace(t.get(['one']));
		trace(t.one);
		trace("2 level");
		trace(t.get(['one','two']));
		trace(t.one.get(['two']).get(['three']));

		trace("Showing keys");
		for(i in t.keys()) {
			trace(" >> key "+i);
		}
		trace (t.container);
		//trace("vvvvv this is what I want vvvvvvv");
		//trace(t.one.two.three);

		t.one.two = 34;
		trace(t.one.two);
		//trace(t.one.two.three);
		//trace(t.one.two.four);
		var x = t.get(['one','two']);
		trace(x.get(['three']));

		t.set([0,1],[45,67,23]);
		trace(t.get(["0"]));
		trace(t.get(["0",1]));
		trace(t.get(["0",1,0]));

		t.set([],"Mystring");
		t.set([],"Mystring");
		t.set([],"Mystring");
		t.set([],"Mystring");
		t.set([],"Mystring");
		t.set([],"Mystring");
		t.set([9], ["my","array",'values']);

		var b = new Assoc();
		trace(b);
		b = t;
		trace(b);

/*
		trace(t.testme());
 		trace(t.foo(1,2,4));
		trace(t.bla("hello",1.45));
		trace(t.get("a","b","c"));
		//trace(t.foo.milk(1,2,4));
*/

	}
}
