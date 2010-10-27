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
	static var font:Xml;

	static var fileName:String;
	static var withoutExt:String;
	static var option:String;
	static var glyphs:String;
	
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
		option = a[1];
		if(option == "-s")
		{
			glyphs = a[2];
		} else if(option == "-a")
		{
			glyphs = "abcdefghijklmnopqrstuvwxyz";
		} else if(option == "-A")
		{
			glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		} else if(option == "-n")
		{
			glyphs = "0123456789";
		} else if(option == "-aA")
		{
			glyphs = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
		} else if(option == "-an")
		{
			glyphs = "abcdefghijklmnopqrstuvwxyz0123456789";
		} else if(option == "-An")
		{
			glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		} else if(option == "-aAn")
		{
			glyphs = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		} else
		{
			glyphs = null;
		}
		fileName = basePath.substr(basePath.lastIndexOf("/")+1);
		withoutExt = fileName.substr(0, fileName.lastIndexOf("."));
		basePath = basePath.substr(0, basePath.lastIndexOf("/"));
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
		
		font = Xml.createElement("font");
		font.set("id", withoutExt);
		font.set("name", withoutExt);
		font.set("import", fileName);
		if(glyphs!=null) font.set("glyphs", glyphs+" ");
		frame.addChild(font);
		
		xmlPath = Path.withExtension(basePath+"/"+withoutExt,"xml");
		swfPath = Path.withExtension(basePath+"/"+withoutExt,"swf");
		var o = File.write(xmlPath,false);
		o.writeString(xml.toString());
		o.flush();
		o.close();
		
		// make swf
		
		Sys.setCwd(basePath);
		Sys.command("swfmill", ["simple", xmlPath, swfPath]);

		
		// remove xml file

		Sys.command("rm", [xmlPath]);

		// make better swf
		
		var i = File.read(swfPath, true);
		var s:SWF = new Reader(i).read();

		var cl = context.beginClass(withoutExt);
		cl.superclass = context.type("flash.text.Font");
		context.endClass();

		s.tags.insert(s.tags.length-1, TSymbolClass([{cid:1, className:withoutExt}]));

		var abcO = new BytesOutput();
		context.finalize();
		format.abc.Writer.write(abcO, context.getData());
		s.tags.insert(s.tags.length-1, TActionScript3(abcO.getBytes()));
		
		s.tags.unshift(TSandBox(8));

		var o = File.write(swfPath,true);
		(new format.swf.Writer(o)).write(s);
		o.flush();
		o.close();
	}
}
