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

/** 
  Representing and translating GMT dates
*/
class GmtDate {
	static public var localeOffset(default,null)	: String;
	static var nextUpdate				: Float		= 0;
	static var l2gmt_add				: Float		= 0;
	static var gmt2l_add				: Float		= 0;

	var localtime : Date;	

	public function new()
	{
		localtime = Date.now();
	}

	public function getTime() : Float {
		return localtime.getTime();
	}

	public function rfc822timestamp() : String {
		return DateTools.format(toFake(localtime), "%a, %d %b %Y %H:%M:%S GMT");
	}


	public function lt(other : GmtDate) : Bool {
		return { if(getTime() < other.getTime()) true; else false; }
	}

	public function gt(other : GmtDate) : Bool {
		return { if(getTime() > other.getTime()) true; else false; }
	}

	public function eq(other : GmtDate) : Bool {
		return { if(getTime() == other.getTime()) true; else false; }
	}

	static public function fromParts(year : Int, month : Int, day : Int, ?hour : Int, ?min : Int, ?sec : Int) : GmtDate
	{
		var gmd : GmtDate = new GmtDate();
		gmd.localtime = fromFake(new Date(year,month,day,hour,min,sec));
		return gmd;
	}

	static public function fromTime(t : Float) : GmtDate {
		var gmd : GmtDate = new GmtDate();
		gmd.localtime = Date.fromTime(t);
		return gmd;
	}

	static public function fromLocalDate(d : Date) : GmtDate {
		var gmd : GmtDate = new GmtDate();
		gmd.localtime = d;
		return gmd;
	}

	static public function now() : GmtDate {
		return new GmtDate();
	}

	static public function monthToInt(month : String) : Int {
		var s = StringTools.trim(month).substr(0,3).toLowerCase();
		//trace(here.methodName + " " + s + " from "+ month);
		if(s == "jan") return 0;
		if(s == "feb") return 1;
		if(s == "mar") return 2;
		if(s == "apr") return 3;
		if(s == "may") return 4;
		if(s == "jun") return 5;
		if(s == "jul") return 6;
		if(s == "aug") return 7;
		if(s == "sep") return 8;
		if(s == "oct") return 9;
		if(s == "nov") return 10;
		if(s == "dec") return 11;
		throw "Invalid month : " + month;
	}

	static public function timestamp(?d : Date) : String {
		if( d == null )
			d = Date.now();
		return DateTools.format(toFake(d), "%a, %d %b %Y %H:%M:%S GMT");
	}


	/** 
	  Parses dates in formats that haXe.Date does, as well as asctime, RFC 1036, and RFC 1123 dates,
	  which are all assumed to be in the GMT/UTC time.
 	  Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
	  Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format
	  Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123 (preferred http/1.1)
	  Will throw on invalid date formats 
	*/
        static public function fromString(s : String) : GmtDate {
		var d : Date;
		var gmd : GmtDate = new GmtDate();

		s = StringTools.trim(s);
		var r : EReg = ~/ +/g;
		s = r.replace(s, " ");

		// lengths 8, 10, 19 handled by Date
		if(s.length == 8 || s.length == 10 || s.length ==19) {
			d = Date.fromString(s);
			gmd.localtime = fromFake(d);
			return gmd;
		}

		var parts = s.split(" ");
		var year, month, day, hour, minute, second : Int;
		var timetoken : String;
		var tztoken : String;
		switch(parts.length) {
		case 4:
			try {
				var dp = parts[1].split("-");
				if(dp.length != 3) throw "Invalid date format : " + parts[1];
				day = Std.parseInt(dp[0]);
				month = monthToInt(dp[1]);
				if(dp[2].length == 2) dp[2] = "19"+dp[2];
				year = Std.parseInt(dp[2]);
				timetoken = parts[2];
				tztoken = parts[3];
			} catch(e :Dynamic) { throw(e); }
		case 5:
			try {
				day = Std.parseInt(parts[2]);
				month = monthToInt(parts[1]);
				year = Std.parseInt(parts[4]);
				timetoken = parts[3];
				tztoken = "GMT";
			} catch(e :Dynamic) { throw(e); }
		case 6:
			try {
				day = Std.parseInt(parts[1]);
				month = monthToInt(parts[2]);
				year = Std.parseInt(parts[3]);
				timetoken = parts[4];
				tztoken = parts[5];
			} catch(e :Dynamic) { throw(e); }
		default:
			throw "Invalid date format : " + s + " " + parts;
		}

		parts = timetoken.split(":");
		if(parts.length != 3)
			throw "Invalid time format : " + timetoken;
		hour = Std.parseInt(parts[0]);
		minute = Std.parseInt(parts[1]);
		second = Std.parseInt(parts[2]);

		d = new Date(year,month,day,hour,minute,second);
		gmd.localtime = fromFake(d);
		return gmd;
        }




/*
	private static function __init__() : Void untyped {
		__dollar__print(">> GmtDate class init\n");
		if(nextUpdate == null) nextUpdate = 0;
		initOffset();
	}
*/
	private static function initOffset() : Void {
		var d = Date.now();
		if(d.getTime() < nextUpdate)
			return;
		if(nextUpdate != 0)
			d = Date.fromTime(nextUpdate);
		var nd = Date.fromTime(d.getTime() + 3600000);
		nd = new Date(nd.getFullYear(),nd.getMonth(),nd.getDate(),nd.getHours(),0,0);
		//trace(here.methodName + " Old time: " + d.toString() + " Setting next gmt update to " + nd.toString());
		nextUpdate = nd.getTime();
		// Got to be a better way to determine GMT time than this
		var offString = DateTools.format(d, "%z");   // "0400" "-0600"

		var add : Bool = true;
		var hours : Int = 0;
		var mins : Int = 0;
		var r : EReg = ~/([\-\+]*)([0-1][0-9])([0-6][0-9])$/;
		try {
			r.match(offString);
			add = { if (r.matched(1) == "-") true; else false; } ;
			hours = Std.parseInt(r.matched(2));
			mins = Std.parseInt(r.matched(3));
		} catch (e : Dynamic) { trace(e); };

		var t : Float = ((hours * 3600) + (mins * 60)) * 1000;
		if(!add) {
			l2gmt_add = t;
			gmt2l_add = 0 - t;
		}
		else {
			l2gmt_add = 0 - t;
			gmt2l_add = t;
		}
	}

	/**
	  Returns an adjusted date from a faked date. The faked date
	  is correct except for the underlying timestamp, in that it
	  represents a date/time, but not adjusted for UTC.
	*/
	static function fromFake(fake : Date) : Date {
		initOffset();
		return DateTools.delta(fake, l2gmt_add);
	}

	static function toFake(localtime : Date) : Date {
		initOffset();
		return DateTools.delta(localtime, gmt2l_add);
	}
}



