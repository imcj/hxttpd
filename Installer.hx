
class Installer {
	static var si : neko.io.FileInput;
	static var so : neko.io.FileOutput;

	static function print(s:Dynamic) : Void {
		so.write(Std.string(s));
		so.flush();
	}

	static function read() : String {
		return StringTools.trim(si.readLine());
	}

	static function promptInteger(m:String, defaultVal:Null<Int>, min:Null<Int>, max:Null<Int>) {
		var retval : Int = 0;
		while(true) {
			print(m);
			if(defaultVal != null)
				print(" ["+Std.string(defaultVal)+"] ");
			var s = read();
			if(s.length == 0 && defaultVal != null)
				return defaultVal;

			var input = Std.parseInt(s);
			if(input == null)
				continue;
			if(min != null && input < min) {
				print("ERROR: "+input+" is too low.\n");
				continue;
			}
			if(max != null && input > max) {
				print("ERROR: "+input+" is too high.\n");
				continue;
			}

			return input;
		}
		return 0;
	}

	static function promptYesNo(m:String, defaultVal:Bool) : Bool {
		var retval : Bool = false;
		while(true) {
			print(m);
			if(defaultVal) {
				print(" [Y/n] ");
			}
			else {
				print(" [y/N] ");
			}
			var input = read().toLowerCase();
			if(input.charAt(0) == "y")
				return true;
			if(input.charAt(0) == "n")
				return false;
			if(input.length == 0)
				return defaultVal;
		}
		return retval;
	}

	static function promptDir(m:String, defaultVal:String, ?allowEmpty:Bool) : String {
		var retval : String = "";
		while(true) {
			print(m);
			if(defaultVal.length > 0) {
				print(" ["+defaultVal+"] >");
			}
			else {
				print(" >");
			}
			var input = read();
			if(input.length == 0 && (defaultVal.length > 0 || allowEmpty))
				return defaultVal;
			if(input.length == 0)
				continue;
			if(input.length > 1 && input.charAt(input.length) == "/")
				input = input.substr(0, input.length-1);
			return input;
		}
		return retval;
	}

	static function promptDirMake(m:String, defaultVal:String, ?allowEmpty:Bool) : String {
		while(true) {
			var dir = promptDir(m, defaultVal, allowEmpty);
			if(allowEmpty == true && dir.length == 0)
				return defaultVal; 
			if(neko.FileSystem.exists(dir) && neko.FileSystem.isDirectory(dir))
				return dir;
			if(neko.FileSystem.exists(dir)) {
				print(dir + " exists, but is not a directory. Try again.");
				continue;
			}
			if(promptYesNo("The directory "+dir+" does not exist. Create?", false)) {
				try {
					neko.FileSystem.createDirectory(dir);
				}
				catch(e:Dynamic) {
					print("ERROR: Unable to create directory "+dir+"\n");
					continue;
				}
			}
			else 
				continue;
			return dir;
		}
		return "";
	}

	static function nekoDir() : String {
		var s = neko.Sys.getEnv("NEKOPATH");
		if(s.indexOf(":") >= 0) {
			var parts = s.split(":");
			s = parts[0];
		}
		if(s.length == 0) {
			s = "/usr/neko/lib";
			if(neko.Sys.systemName() == "Windows")
				s = "c:\\neko";
		}
		return s;
	}

	static function binDir() : String {
		var parts = neko.Sys.executablePath().split("/");
		var s = new StringBuf();
		for(i in 0...parts.length-1) {
			if(parts[i].length == 0)
				continue;
			s.add("/");
			s.add(parts[i]);
		}
		return s.toString();
	}

	public static function main() {
		si = neko.io.File.stdin();
		so = neko.io.File.stdout();
		var paths = new Hash<String>();

		switch(neko.Sys.systemName()) {
		case "Linux":
			paths.set("bindir", binDir());
			paths.set("neko", nekoDir());
			paths.set("plugins", "/usr/share/hxttpd");
			paths.set("app", "hxttpd-linux-bin");
		case "Windows":
			paths.set("bindir", "c:\\neko");
			paths.set("neko", nekoDir());
			paths.set("plugins", "c:\\neko");
			paths.set("app", "hxttpd-windows-bin");
		case "Mac":
			paths.set("bindir", binDir());
			paths.set("neko", nekoDir());
			paths.set("plugins", "/usr/share/hxttpd");
			paths.set("app", "hxttpd-mac-bin");
		case "BSD":
			paths.set("bindir", binDir());
			paths.set("neko", nekoDir());
			paths.set("plugins", "/usr/share/hxttpd");
			paths.set("app", "hxttpd-bsd-bin");
		default:
			print("This installer is not configured to work on " + neko.Sys.systemName() + "\n");
			print("Please report this error, including the line above, to the developers");
			neko.Sys.exit(0);
		}

		var dlltmp = neko.FileSystem.readDirectory("ndll/" + neko.Sys.systemName());
		var dlls = new Array<String>();
		var modules = new Array<String>();
		for(i in dlltmp) {
			if(StringTools.endsWith(i, ".n"))
				modules.push(i);
			if(StringTools.endsWith(i, ".ndll"))
				dlls.push(i);
		}

		if(promptYesNo("This program will install hxttpd to your system. Continue?", false) == false) {
			neko.Sys.exit(0);
		}

		var bindir = promptDirMake("What directory should hold the executable files?", paths.get("bindir"));
		var nekodir = promptDirMake("Where are your neko .ndll files kept?", paths.get("neko"));
		var plugindir = promptDirMake("Where should hxttpd plugins and other static data go?", paths.get("plugins"));

		print("\nThe following settings can be changed by editing the wrapper script after installation.\n");
		print("The document root directory is the base directory all web requests will be served from.\n");
		print("If you specify an empty string, hxttpd will serve from the directory it is started in.\n");
		print("This can be changed later by adding a --docroot=/path argument when starting hxttpd.\n");
		var docroot = promptDirMake("Document root directory","",true);

		print("\nThe port that hxttpd will listen for requests on. In order to use any value below 1024,\n");
		print("you must have root/administrator priveledges on your system. The default web port is 80.\n");
		var port = promptInteger("What port should hxttpd bind to by default? (1-65534)", 80, 1, 65534);

		var source:String = "";
		try {
			// the application
			source = "bin/" + paths.get("app");
			neko.io.File.copy(source, bindir + "/hxttpd-bin");

			// the .n and .ndlls
			for(i in dlls) {
				source = "ndll/" + neko.Sys.systemName() + "/" + i;
				neko.io.File.copy(source, nekodir + "/" + i);
			}
			for(i in modules) {
				source = "ndll/" + neko.Sys.systemName() + "/" + i;
				neko.io.File.copy(source, plugindir + "/" + i);
			}

			// create the wrapper
			source = "hxttpd wrapper";
			if(neko.Sys.systemName() == "Windows") {
				var fo = neko.io.File.write(bindir + "/hxttpd.bat", true);
				fo.write("hxttpd-bin --pluginpath=" + paths.get("plugins") + " --port=" + Std.string(port) + "\n");
				fo.close();
			}
			else {
				var fo = neko.io.File.write(bindir + "/hxttpd", true);
				fo.write("#!/bin/sh\n");
				fo.write("NEKOPATH=" + nekodir + ":"+neko.Sys.getEnv("NEKOPATH")+" "+bindir+"/hxttpd-bin --pluginpath=" + plugindir + " --port=" + Std.string(port));
				if(docroot.length > 0)
					fo.write(" --docroot="+docroot);
				fo.write("\n");
				fo.close();
				var rv = neko.Sys.command("chmod 0755 " + bindir + "/hxttpd");
				if(rv > 0)
					throw "Unable to change permissions on " + bindir + "/hxttpd";
				rv = neko.Sys.command("chmod 0755 " + bindir + "/hxttpd-bin");
				if(rv > 0)
					throw "Unable to change permissions on " + bindir + "/hxttpd-bin";
			}

		} catch(e:Dynamic) {
			print("Install failed while copying " + source + "\n");
			trace(e);
			print("Make sure you have correct permissions to install files to the directories specified.\n");
			neko.Sys.exit(1);
		}

		print("\nInstallation successful.\nYou should now be able to run hxttpd from the command line\n");
		print("You may want to modify the wrapper script (hxttpd or hxttpd.bat) located in "+bindir+"\n");
	}	
}

