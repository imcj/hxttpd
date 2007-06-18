// file Server.hx
class Test {
	public function new() {}
        public static function fromString(str : String) : Array<String> {
                var hranges = new Array<String>();
                str = StringTools.trim(str);
                str = StringTools.replace(str," ","");
                if(str.substr(0,6) != "bytes=")
                        return hranges;
                str = str.substr(6);
                var parts = str.split(",");
                for(i in parts) {
                        var r = new String(i);
                        hranges.push(r);
                }
                return hranges;
        }

        public function fromString2(str : String) : Array<String> {
                var hranges = new Array<String>();
                str = StringTools.trim(str);
                str = StringTools.replace(str," ","");
                if(str.substr(0,6) != "bytes=")
                        return hranges;
                str = str.substr(6);
                var parts = str.split(",");
                for(i in parts) {
                        var r = new String(i);
                        hranges.push(r);
                }
                return hranges;
        }

    static function main() {
	var r : EReg;
	r = ~/([0-9]*)-([0-9]*)$/;

	r.match("120-240");
	trace(r.matched(1));
	trace(r.matched(2));

	r.match("120-");
	trace(r.matched(1));
	trace(r.matched(2));
	if(r.matched(2) == null) 
		trace("2 is null");
	if(r.matched(2).length == 0) 
		trace("2 is 0 length");

	r.match("-240");
	trace(r.matched(1));
	trace(r.matched(2));

	try {
		r.match("mary had a little lamb");
		trace(r.matched(1));
		trace(r.matched(2));
	} catch(e:Dynamic) { trace(e); }

	var str = "bytes=0 -   12,14 -34,  -500,  500-";
	//Test.fromString(str);
	fromString(str);
	trace(str);
	trace(Test.fromString(str));
	/* 
        var s = new neko.net.Socket();
        s.bind(new neko.net.Host("localhost"),5000);
        s.listen(1);
        trace("Starting server...");
        while( true ) {
            var c : neko.net.Socket = s.accept();
            trace("Client connected...");
            c.write("hello\n");
            c.write("your IP is "+c.peer().host.toString()+"\n");
            c.write("exit\n");
            c.close();
        }
	*/
   }
}
