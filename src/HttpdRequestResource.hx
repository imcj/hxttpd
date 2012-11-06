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
	Class to contain POSTed files
	Errors thrown by file io are not caught.
*/
import neko.io.File;

class HttpdRequestResource {
	public var name		: String;
	public var mime_type	: String; 	// as set by browser
	public var size		: Int;		// bytes
	public var length	: Int;		// data so far
	public var filename	: String;	// full path to file
	public var error	: Int;
	public var isFile	: Bool;

	public static var ERR_OK	: Int	= 0;
	public static var ERR_FORM_SIZE : Int	= 1; // bigger than MAX_FILE_SIZE in html form
	public static var ERR_PARTIAL	: Int	= 2; // partial upload
	public static var ERR_NO_FILE	: Int 	= 3; // received no file

	private var tmpfile		: neko.io.TmpFile;
	private var sval		: StringBuf;

	public function new(name : String, ?contentsize:Null<Int>) {
		this.name = name;
		this.filename = null;
		size = contentsize;
		length = 0;
		isFile = false;
		if(size == 0 || size == null || size > (16*1024)) {
			tmpfile = new neko.io.TmpFile();
		}
		else {
			tmpfile = null;
		}
		mime_type = "unknown/unknown";
		error = ERR_OK;

		sval = new StringBuf();
	}

	public function setFilename(filename:String) {
		this.filename = filename;
		if(filename.length <= 0) {
			error = ERR_NO_FILE;
		}
		if(tmpfile == null && length == 0)
			tmpfile = new neko.io.TmpFile();
		isFile = true;
	}


	public function addData(s:String, p:Int, len: Int) : Void {
		if(len <= 0)
			return;
		//trace(s.substr(p,len));
		//var data = s.substr(p,len);
		//trace(data);
		if(tmpfile != null)
			tmpfile.getOutput().writeBytes(s, p, len);
		else
			sval.addSub(s, p, len);
			//sval.add(data);
		length += len;
	}


	public function getValue() : String {
		try {
			if(tmpfile != null) {
				var fi = tmpfile.getInput();
				fi.seek(0, SeekBegin);
				var data = fi.readAll();
				fi.seek(0,SeekEnd);
				return data;
			}
		}
		catch(e:Dynamic) {
			return null;
		}
		trace(sval.toString());
		return sval.toString();
	}

	public function copyTo(o : haxe.io.Output) : Bool {
		if(tmpfile == null)
			return false;
		var fi : neko.io.FileInput;
		try {
			fi = tmpfile.getInput();
			fi.seek(0, SeekBegin);
			while(true) {
				o.writeChar(fi.readChar());
			}
		}
		catch(e:neko.io.Eof) {}
		catch(e:Dynamic) {
			return false;
		}
		try {
			fi.seek(0,SeekEnd);
		}
		catch(e:Dynamic) {}
		return true;
	}

	public function parse_multipart_data(onData : String -> Int -> Int -> Void) : Void
	{
		var fi : neko.io.FileInput;
		try {
			fi = tmpfile.getInput();
			fi.seek(0, SeekBegin);
		}
		catch(e:Dynamic) {
			return;
		}

		while(true) {
			var retval = read(fi, 64*1024);
			if(retval.bytes > 0) {
				onData(
					//neko.Lib.haxeToNeko(retval.buffer),
					retval.buffer.substr(0,retval.bytes),
					0,
					retval.bytes
				);
			}
			if(retval.status != 0)
				break;
		}
	}

	// stat: -1 on error, 0 read all, 1 = eof
	static function read( i : neko.io.FileInput, len : Int ) : {buffer:String,bytes:Int,status:Int}
	{
		var c : Int;
		var s = neko.Lib.makeString(len);
		var p = 0;
		var stat = 0;
		while( p < len ) {
			try {
				c = i.readChar();
			}
			catch(e:haxe.io.Eof) {
				stat = 1;
			}
			catch(e:Dynamic) {
				stat = -1;
			}
			if(stat != 0)
				break;
			untyped __dollar__sset(s.__s,p,c);
			p += 1;
		}
		return {buffer: s.__s, bytes: p, status: stat};
	}
}
