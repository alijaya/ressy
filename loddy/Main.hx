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

import hxjson2.JSON;

class Main 
{
	static function main()
	{
		var a = Sys.args();
		var p = a[0];
		var d = readDir(p);
		var o = File.write(Path.withExtension(p,"json"),false);
		o.writeString(JSON.encode(d,true));
		o.flush;
	}
	
	static function readDir(p:String) : Dynamic
	{
		var d = {};
		var a = [];
		Reflect.setField(d, "name", Path.withoutDirectory(p));
		Reflect.setField(d, "files", a);
		for(n in FileSystem.readDirectory(p))
		{
			if(n.charAt(0)=="." || n.charAt(0)=="!") continue;
			var p2 = p+"/"+n;
			if(FileSystem.isDirectory(p2))
			{
				a.push(readDir(p2));
			}else
			{
				a.push(n);
			}
		}
		return d;
	}
}