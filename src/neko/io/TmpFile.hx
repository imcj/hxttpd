package neko.io;
import neko.io.File;

class TmpFile {
	private var fi : FileInput;
	private var fo : FileOutput;
	private var __f : FileHandle;

	public function new() : Void {
		__f = untyped tmpfile_open();
		fi = new FileInput(__f);
		fo = new FileOutput(__f);
	}

	public function close() : Void {
		untyped tmpfile_close(__f);
	}

	public function getInput() : FileInput {
		return fi;
	}

	public function getOutput() : FileOutput {
		return fo;
	}

#if BUILD_LINUX
	private static var tmpfile_open = neko.Lib.load("ndll/Linux/tmpfile","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("ndll/Linux/tmpfile", "tmpfile_close", 1);
#else BUILD_WINDOWS
	private static var tmpfile_open = neko.Lib.load("ndll/Windows/tmpfile","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("ndll/Windows/tmpfile", "tmpfile_close", 1);
#else BUILD_BSD
	private static var tmpfile_open = neko.Lib.load("ndll/BSD/tmpfile","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("ndll/BSD/tmpfile", "tmpfile_close", 1);
#else BUILD_MAC
	private static var tmpfile_open = neko.Lib.load("ndll/Mac/tmpfile","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("ndll/Mac/tmpfile", "tmpfile_close", 1);
#end
}