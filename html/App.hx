class App
{
       public static function entryPoint():Void
       {
		neko.Lib.println("App Entry Point");
       }

       public static function main():Void
       {
		neko.Lib.println("App Main");
		entryPoint();
       }
}
