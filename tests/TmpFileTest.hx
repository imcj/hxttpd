import neko.io.File;
//FileSeek;
class TmpFileTest {
	static public function main() {
		neko.vm.Loader.local().addPath("./../bin/");
		trace(neko.vm.Loader.local().getPath());
		var tmpfile = new neko.io.TmpFile();
		trace("opened");
		var fo = tmpfile.getOutput();
		var s = "Just a test of the tmpfile";

		trace("Writing");
		try {
			fo.writeChar(25);
			fo.write(s);
		}
		catch (e:Dynamic) {
			trace(e);
		}
		neko.Sys.sleep(500);
		

		trace("Getting input handle");
		var fi = tmpfile.getInput();

		trace("Seeking");
		fi.seek(0, SeekBegin);

		trace("Reading");
		trace(fi.readAll());

		fi.close();
	}
}
