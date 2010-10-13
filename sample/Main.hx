package ;

import ressy.Loddy;
import ressy.Eddy;
import ressy.Ressy;


class Main 
{
	
	
	static function main()
	{
		new Main();
	}

	public function new()
	{
		#if embed
		Eddy.instance.load("swf", "json", complete);
		#else
		Loddy.instance.load("assets.json", complete);
		#end
	}

	public function complete()
	{
		flash.Lib.current.addChild(Ressy.instance.getStr("Forest")); // Bitmap
		//Ressy.instance.getStr("flixel").play(); // Sound
		Ressy.instance.getStr("PowerUp").play();
		trace(Ressy.instance.getStr("another.Texty")); // String
		trace(Ressy.instance.getStr("another.Data")); // Dynamic
	}
}
