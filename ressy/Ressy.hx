package ressy;

import flash.display.DisplayObject;
import flash.display.Bitmap;
import flash.utils.ByteArray;
import flash.text.Font;

class Ressy 
{
	private static var _instance : Ressy;
	public static var instance(get_instance, null) : Ressy;
	public static function get_instance() : Ressy
	{
		if (_instance == null) _instance = new Ressy();
		return _instance;
	}
	
	private var data:Hash<Dynamic>;
	
	private function new()
	{
		data = new Hash<Dynamic>();
	}
	
	public function getDirStr(s:String) : Hash<Dynamic>
	{
		if(s=="") return getDir([]);
		return getDir(s.split("."));
	}
	
	public function getDir(a:Array<String>) : Hash<Dynamic>
	{
		var c = data;
		for(n in 0...a.length)
		{
			var s = a[n];
			var h:Hash<Dynamic> = cast c.get(s);
			if(h == null)
			{
				h = new Hash<Dynamic>();
				c.set(s, h);
			}
			c = h;
		}
		return c;
	}
	
	public function setStr(s:String, d:Dynamic) : Dynamic
	{
		return set(s.split("."), d);
	}
	
	public function set(a:Array<String>, d:Dynamic) : Dynamic
	{
		var c = data;
		for(n in 0...a.length-1)
		{
			var s = a[n];
			var h:Hash<Dynamic> = cast c.get(s);
			if(h == null)
			{
				h = new Hash<Dynamic>();
				c.set(s, h);
			}
			c = h;
		}
		c.set(a[a.length-1], d);
	}
	
	public function getStr(s:String) : Dynamic
	{
		return get(s.split("."));
	}
	
	public function get(a:Array<String>) : Dynamic
	{
		var c = data;
		for(n in 0...a.length-1)
		{
			var s = a[n];
			var h:Hash<Dynamic> = cast c.get(s);
			if(h == null)
			{
				#if debug
				throw "can't search directory in "+a.join("/");
				#end
				return null;
			}
			c = h;
		}
		return c.get(a[a.length-1]);
	}
	
	public function removeStr(s:String)
	{
		remove(s.split("."));
	}
	
	public function remove(a:Array<String>)
	{
		var c = data;
		for(n in 0...a.length-1)
		{
			var s = a[n];
			var h:Hash<Dynamic> = cast c.get(s);
			if(h == null)
			{
				#if debug
				throw "can't search directory in "+a.join("/");
				#end
				return;
			}
			c = h;
		}
		c.remove(a[a.length-1]);
	}
	
	public function getTreeStr(s:String) : String
	{
		if(s=="") return getTree([]);
		return getTree(s.split("."));
	}
	
	public function getTree(a:Array<String>) : String
	{
		var h:Hash<Dynamic> = getDir(a);
		var s:String = (a.length>0)?a[a.length-1]:"root";
		s+="\n";
		s+=getTreeSub(h, 0);
		return s;
	}
	
	private function getTreeSub(h:Hash<Dynamic>, depth:Int) : String
	{
		var s = "";
		var t = "";
		for(d in 0...depth+1) t+="\t";
		for(n in h.keys())
		{
			s+=t+n+"\n";
			var hs = h.get(n);
			if(Std.is(hs, Hash))
			{
				s+=getTreeSub(cast hs,depth+1);
			}
		}
		return s;
	}

	public function registerFont(d:DisplayObject, c:String)
	{
		Font.registerFont(d.loaderInfo.applicationDomain.getDefinition(c));
	}

	public function cloneBitmap(b:Bitmap) : Bitmap
	{
		return new Bitmap(b.bitmapData, b.pixelSnapping, b.smoothing);
	}
	
	public function cloneByteArray(b:ByteArray) : ByteArray
	{
		var nb = new ByteArray();
		nb.writeBytes(b);
		return nb;
	}
	
}
