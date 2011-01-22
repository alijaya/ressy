//
//  Main.hx
//  
//
//  Created by Ali Jaya Meilio Lie on 1/24/10.
//  Copyright 2010 alijaya. All rights reserved.
//

package ;
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import neko.io.Path;

import haxe.io.BytesOutput;

import format.abc.Context;
import format.swf.Data;
import format.swf.Reader;
import format.swf.Tools;

class Main 
{
	static var basePath:String;
	
	static var xml:Xml;
	static var lib:Xml;
	
	static var ids:Array<Int>;
	static var scs:Array<String>;
	static var names:Array<String>;
	
	static var xmlPath:String;
	static var swfPath:String;
	
	static var context:Context;
	static var symbols:Array<{ cid : Int, className : String }>;
	
	static function main()
	{
		var a = Sys.args();
		basePath = FileSystem.fullPath(a[0]);
		ids = [];
		scs = [];
		names = [];
		context = new Context();
		symbols = [];
		
		// make xml
		
		xml = Xml.createElement("movie");
		xml.set("width","100");
		xml.set("height","100");
		xml.set("framerate","12");
		xml.set("version","9");
		
		var frame = Xml.createElement("frame");
		xml.addChild(frame);
		lib = Xml.createElement("library");
		frame.addChild(lib);
		
		var lastIndex : Int = basePath.lastIndexOf("/");
		if ( lastIndex == -1 ) {
			lastIndex = basePath.lastIndexOf("\\");
		}
		
		var root = basePath.substr(lastIndex);
		basePath = basePath.substr(0, lastIndex);
		readDir(root);
		
		xmlPath = Path.withExtension(basePath+root,"xml");
		swfPath = Path.withExtension(basePath+root,"swf");
		var o = File.write(xmlPath,false);
		o.writeString(xml.toString());
		o.flush();
		o.close();
		//trace(names);
		
		// make swf
		
		Sys.setCwd(basePath);
		Sys.command("swfmill", ["simple", xmlPath, swfPath]);

		// remove xml file

		Sys.command("rm", [xmlPath]);
		
		// make better swf
		
		var i = File.read(swfPath, true);
		var s:SWF = new Reader(i).read();
		
		for(n in s.tags)
		{
			switch(n)
			{
				case TBitsLossless(data), TBitsLossless2(data): ids.push(data.cid); scs.push("flash.display.Bitmap");
				case TBitsJPEG2(id,_), TBitsJPEG3(id,_,_): ids.push(id); scs.push("flash.display.Bitmap");
				case TSound(data): ids.push(data.sid); scs.push("flash.media.Sound");
				case TBinaryData(id,_): ids.push(id); scs.push("flash.utils.ByteArray");
				default:
			}
		}
		
		var id:Int;
		var cn:String;
		var sc:String;
		for(n in 0...ids.length)
		{
			id = ids[n];
			cn = names[n];
			sc = scs[n];
			symbols.push({cid:id, className:cn});
			var cl = context.beginClass(cn);
			cl.superclass = context.type(sc);
			context.endClass();
		}
		
		s.tags.insert(s.tags.length-1, TSymbolClass(symbols));
		
		var abcO = new BytesOutput();
		context.finalize();
		format.abc.Writer.write(abcO, context.getData());
		s.tags.insert(s.tags.length-1, TActionScript3(abcO.getBytes()));
		
		s.tags.unshift(TSandBox(8));
		
		var o = File.write(swfPath,true);
		(new format.swf.Writer(o)).write(s);
		o.flush();
		o.close();
		
		/*for(n in s.tags)
		{
			trace(Tools.dumpTag(n,0));
		}*/
	}
	
	static function readDir(p:String) : Dynamic
	{
		for(n in FileSystem.readDirectory(basePath+p))
		{
			var p2 = p+"/"+n;
			if(FileSystem.isDirectory(basePath+p2))
			{
				readDir(p2);
			}else
			{
				if(n.charAt(0)=="." || n.charAt(0)=="!")continue;
				var ext = p2.substr(p2.lastIndexOf(".")+1);
				ext = ext.toLowerCase();
				var type:String = switch(ext)
				{
					case "jpg","jpeg","png": "bitmap";
					case "mp3","wav": "sound";
					default: "binary";
				}
				var x = Xml.createElement(type);
				x.set("import", p2.substr(1));
				lib.addChild(x);
				names.push(p2.substr(1, p2.lastIndexOf(".")-1).split("/").join("."));
			}
		}
	}
}
