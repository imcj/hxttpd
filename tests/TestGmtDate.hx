class TestGmtDate {
	static function strParseTest(gmtstr : String)
	{
		var d : GmtDate = GmtDate.fromString(gmtstr);
		trace("Test string: "+gmtstr+" should equal "+d.rfc822timestamp());
	}

	static function main() {
		var d : GmtDate;
		var s : GmtDate;
		trace("Declarations finished");
		d = new GmtDate();
		trace("Finished new GmtDate()");
		var ts1 = d.rfc822timestamp(); 
		trace("RFC822: " + d.rfc822timestamp());

		//d = GmtDate.fromString("Wed, 06 Jun 2007 08:19:34 GMT");
		s = GmtDate.fromString(d.rfc822timestamp());
		var ts2 = s.rfc822timestamp();
		if(ts1 != ts2) {
			trace (d.rfc822timestamp());
			trace (s.rfc822timestamp());
			throw "Not equal";
		}

		strParseTest("Sunday, 06-Nov-94 08:49:37 GMT");
		strParseTest("Sun Nov  6 08:49:37 1994");
		strParseTest("Sun, 06 Nov 1994 08:49:37 GMT");

		neko.Sys.sleep(1);
		s = new GmtDate();
		if(s.lt(d)) {
			trace("New date less than original, bad");
		} else if(s.eq(d)) {
			trace("New date equal to original.. hmm");
		} else if(s.gt(d)) {
			trace("New date bigger. good");
		} else {
			trace("wtf");
		}

	}
}
