package com.gt.towers.editor
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	import fl.controls.CheckBox;
	
	public class MapGenerator extends MovieClip
	{
		private var timelines:XMLList;
		private var quests:Vector.<Sprite>;
		private var selectedPalce:Sprite;
		private var questClassStr:String;
		
		public var start_check:CheckBox;
		public var intro_check:CheckBox;
		public var final_check:CheckBox;
		
		public var scene_txt:TextField;
		public var prev_btn:MovieClip;
		public var next_btn:MovieClip;
		public var save_btn:MovieClip;
		
		public function MapGenerator()
		{
			var dom:File = File.applicationDirectory.resolvePath("quests-map-generator/DOMDocument.xml");
			dom.addEventListener(Event.COMPLETE, dom_completeHandler);
			setTimeout(dom.load, 100);
			addButtonsListener();
		}
		private function dom_completeHandler(event:Event):void
		{
			var xml:XML = new XML(event.currentTarget.data);
			timelines = xml.children()[3].children();
			//resetPlaces();
		}
		private function addButtonsListener():void
		{
			save_btn.removeEventListener(MouseEvent.CLICK, save_btn_clickHandler);
			next_btn.removeEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			prev_btn.removeEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			scene_txt.removeEventListener(KeyboardEvent.KEY_UP, scene_txt_keyUpHandler);

			save_btn.addEventListener(MouseEvent.CLICK, save_btn_clickHandler);
			
			next_btn.addEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			prev_btn.addEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			scene_txt.addEventListener(KeyboardEvent.KEY_UP, scene_txt_keyUpHandler);
			scene_txt.text = getSceneIndex().toString();
			quests = new Vector.<Sprite>();
		}
		
		private function scene_btn_clickHandler(event:MouseEvent):void
		{
			var sceneIndex:int = getSceneIndex();
			if( event.currentTarget == next_btn )
			{
				if(sceneIndex < scenes.length-1)
					nextScene();
			}
			else
			{
				if( sceneIndex > 0 )
					prevScene();
			}
			addButtonsListener();
		}
		private function scene_txt_keyUpHandler(event:KeyboardEvent):void
		{
			if( event.keyCode == Keyboard.ENTER )
			{
				var sceneIndex:int = Math.max(0, Math.min(int(scene_txt.text), scenes.length-1));
				gotoAndStop(1, scenes[sceneIndex].name);
				addButtonsListener();
			}
		}
		
		private function save_btn_clickHandler(event:MouseEvent):void
		{
				var index:int = int(currentScene.name.split('_')[1]);
			//questClassStr = '\r\r\r\t\tfield = new FieldData(' + index + ', "' + currentScene.name + '", ' + intro_check.selected + ', ' + final_check.selected + ', "' + times + '" );\r\t\t// create places\r';
			
			var className:String = currentScene.name.substr(0,1).toUpperCase()+ currentScene.name.substr(1);
			trace('\r\t\tshires.set( "' + currentScene.name + '" , new ' + className + '( ' + index + ', "' + currentScene.name + '", ' + (start_check ? start_check.selected : false) + ', ' + intro_check.selected + ', ' + final_check.selected + ' ) );\r')

			var tutorSteps:String = "";
			var sceneIndex:int = getSceneIndex();
			var sceneData:Object = new Object();
			sceneData.name = currentScene.name;
			if (start_check)
				sceneData.hasStart = start_check.selected;
			sceneData.hasIntro = intro_check.selected;
			sceneData.hasFinal = final_check.selected;
			
			questClassStr = 'package com.gt.towers.battle.shires;\rimport com.gt.towers.battle.fieldes.*;\rclass ' + className + ' extends FieldData\r{\r\tpublic function new(index:Int, name:String, hasStart:Bool=false, hasIntro:Bool=false, hasFinal:Bool=false, times:String="")\r\t{\r\t\tsuper(index, name, hasStart, hasIntro, hasFinal);\r\r\t\t// quests';
			for (var i:int=0; i<numChildren; i++)
			{
				if( getChildAt(i).name.substr(0, 6) == "quest_" )
					questClassStr += '\r\t\tplaces.push( new PlaceData( ' + getChildAt(i).name.substr(6) + ',\t' + getChildAt(i).x + ',\t' + getChildAt(i).y + ',\t0,\t0,\t"") );';
			}
			
			//sceneData.places = items;
			sceneData.images = getImagesData(sceneIndex);
			
			questClassStr += '\t}\r}';
			//trace(questClassStr)

			var hxFile:File = new File("C:\\_projects\\towers-projects\\towers-core\\source\\src\\com\\gt\\towers\\battle\\shires\\"+className+".hx");
			var stream:FileStream = new FileStream();
			stream.open(hxFile, FileMode.WRITE);
			stream.writeUTFBytes(questClassStr);
			stream.close();
			//trace("saved to", hxFile.nativePath);
		}
		private function getSceneIndex():int
		{
			for(var s:int=0; s<scenes.length; s++)
				if(scenes[s].name == currentScene.name)
					return s;
			return 0;
		}
		
		private function getImagesData(t:int):Array
		{
			var items:Array = new Array();
			var bitmaps:XMLList = timelines[t].descendants("*");
			questClassStr += '\r\r\t\t// images\r';
			for (var i:int=0; i<bitmaps.length(); i++)
			{
				if(bitmaps[i].name() == "http://ns.adobe.com/xfl/2008/::DOMBitmapInstance")
				{
					//trace(t, i, bitmaps[i].name())
					var bitmap:XML = bitmaps[i];
					var item:Object = new Object();
					
					var attName:String = bitmap.attribute("libraryItemName");
					attName = attName.split(".")[0];
					var ns:Array = attName.split("/");
					item.name = ns[ns.length-1];
					questClassStr+= '\t\timages.push( new ImageData( "' + ns[ns.length-1] + '"\t';
					if(bitmap.children().length() > 0)
					{
						var bitmapChildren:XMLList = bitmap.descendants("*");
						for (var j:int=0; j<bitmapChildren.length(); j++)
						{
							if( bitmapChildren[j].name() == "http://ns.adobe.com/xfl/2008/::Matrix" )
							{
								addToItem(item, "tx", bitmapChildren[j], "tx");
								addToItem(item, "ty", bitmapChildren[j], "ty");
								addToItem(item, "a", bitmapChildren[j], "a");
								addToItem(item, "b", bitmapChildren[j], "b");
								addToItem(item, "c", bitmapChildren[j], "c");
								addToItem(item, "d", bitmapChildren[j], "d");
							}
							if( bitmapChildren[j].name() == "http://ns.adobe.com/xfl/2008/::Point" )
							{
								addToItem(item, "px", bitmapChildren[j], "x");
								addToItem(item, "py", bitmapChildren[j], "y");
							}
						}
					}
					items.push(item);
					questClassStr += ') );\r';
				}
			}
			
			function addToItem(item:Object, property:String, matrix:XML, attribute:String):void
			{
				var att:String = matrix.attribute(attribute);
				if(att != "" )
					item[property] = Number(att);
				else
					item[property] = property=="a"||property=="d" ? 1 : 0;
				
				questClassStr += ',\t' + item[property];
			}
			
			return items;
		}
	}
}