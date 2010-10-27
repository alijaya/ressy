package ressy;
import flash.events.Event;
import flash.system.ApplicationDomain;
import flash.display.Loader;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import haxe.Resource;

import hxjson2.JSON;

class Eddy 
{
	private static var _instance : Eddy;
	public static var instance(get_instance, null) : Eddy;
	public static function get_instance() : Eddy
	{
		if (_instance == null) _instance = new Eddy();
		return _instance;
	}
	
	
	var jsons:Array<{path:String, json:Dynamic, finished:Bool}>;
	
	var temporaryPath:Array<String>;
	
	var complete:Dynamic;
	
	var appDom:ApplicationDomain;
	var fileList:Dynamic;
	
	var count:Int;
	var waiting:Bool;
	
	public function new()
	{
		
	}
	
	public function load(swfFileName:String, fileListName:String, complete:Dynamic)
	{
		waiting = false;
		count = 0;
		jsons = [];
		temporaryPath = [];
		this.complete = complete;
		fileList = JSON.decode(Resource.getString(fileListName));
		var loader = new Loader();
		loader.loadBytes(Resource.getBytes(swfFileName).getData(), new LoaderContext(new ApplicationDomain()));
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete, false, 0 , true);
	}
	
	function onComplete(e:Event)
	{
		appDom = e.target.applicationDomain;
		loadDir(fileList.files, fileList.name, false);
		waiting = true;
		if(count == 0) callComplete();
	}
	
	function callComplete()
	{
		//trace(Manager.data.getTree([]));
		// json extension
		for(json in jsons)
		{
			if(json.finished) continue;
			checkJSON(json);
		}
		
		// remove temporary
		for(n in temporaryPath)
		{
			Ressy.instance.removeStr(n);
		}
		temporaryPath = null;
		
		if(complete!=null) complete();
		complete==null;
	}
	
	function loadDir(a:Array<Dynamic>, p:String, temporary:Bool)
	{
		var pa = (p.indexOf(".")>=0)? p.substr(p.indexOf(".")+1) : "";
		if(pa != "") pa += ".";
		for(n in a)
		{
			if(Std.is(n, String))
			{
				var m = n.substr(0, n.lastIndexOf("."));
				var e:String = n.substr(n.lastIndexOf(".")+1);
				e = e.toLowerCase();
				loadFile(p+"."+m, e, pa+m, (!temporary&&n.charAt(0)=="#"));
			} else
			{
				loadDir(n.files, p+"."+n.name, (!temporary&&n.name.charAt(0)=="#"));
			}
		}
	}
	
	function loadFile(p:String, ext:String, pa:String, temporary:Bool)
	{
		if(temporary) temporaryPath.push(pa);
		switch(ext)
		{
			case "json":
				var ba:ByteArray = Type.createInstance(appDom.getDefinition(p),[]);
				jsons.push({path:pa, json:JSON.decode(ba.readUTFBytes(ba.length)), finished:false});
			case "txt":
				var ba:ByteArray = Type.createInstance(appDom.getDefinition(p),[]);
				Ressy.instance.setStr(pa, ba.readUTFBytes(ba.length));
			case "swf":
				startLoad();
				var ba:ByteArray = Type.createInstance(appDom.getDefinition(p),[]);
				loadSwf(ba, pa);
			case "png","jpg","jpeg":
				Ressy.instance.setStr(pa, Type.createInstance(appDom.getDefinition(p),[]));
			default:
				Ressy.instance.setStr(pa, Type.createInstance(appDom.getDefinition(p),[]));
		}
	}

	private function startLoad()
	{
		count++;
	}
	
	private function endLoad()
	{
		count--;
		if(waiting && count==0) callComplete();
	}
	
	private function loadSwf(ba:ByteArray, pa:String) : Void
	{
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, callback(onSwfCom, pa), false, 0, true);
		loader.loadBytes(ba, new LoaderContext(new ApplicationDomain()));
	}

	private function onSwfCom(dataPath:String, e:Event)
	{
		//trace("swf");
		Ressy.instance.setStr(dataPath, e.target.content);
		endLoad();
		//trace("end "+dataPath+" "+count);
	}
	
	private function checkJSON(json:{path:String, json:Dynamic, finished:Bool})
	{
		Ressy.instance.setStr(json.path, checkJSONVal(json.json, json.path.substr(0, json.path.lastIndexOf("."))));
		json.finished = true;
	}
	
	private function checkJSONVal(v:Dynamic, curPath:String) : Dynamic
	{
		return if(Std.is(v, String))
		{
			checkJSONStr(v, curPath);
		} else if(Std.is(v, Array))
		{
			checkJSONArr(v, curPath);
		} else if(Reflect.isObject(v))
		{
			checkJSONObj(v, curPath);
		} else
		{
			v;
		}
	}
	
	private function checkJSONStr(s:String, curPath:String) : Dynamic
	{
		var f = s.charAt(0);
		return if(f=="@")
		{
			var path = s.substr(1, s.lastIndexOf(".")-1);
			path = path.split("/").join(".");
			if(path.charAt(0)=="$")
			{
				path = path.substr(2);
			} else
			{
				path = curPath+"."+path;
			}
			for(j in jsons)
			{
				if(j.path==path)
				{
					checkJSON(j);
					break;
				}
			}
			return Ressy.instance.getStr(path);
		}else if(f=="\\")
		{
			return s.substr(1);
		}else
		{
			return s;
		}
	}
	
	private function checkJSONArr(a:Array<Dynamic>, curPath:String) : Array<Dynamic>
	{
		for(n in 0...a.length)
		{
			a[n] = checkJSONVal(a[n], curPath);
		}
		return a;
	}
	
	private function checkJSONObj(o:Dynamic, curPath:String) : Dynamic
	{
		for(n in Reflect.fields(o))
		{
			Reflect.setField(o, n, checkJSONVal(Reflect.field(o, n), curPath));
		}
		return o;
	}
	
}
