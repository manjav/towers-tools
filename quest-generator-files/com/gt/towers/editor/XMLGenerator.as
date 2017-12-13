﻿package com.gt.towers.editor
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	import fl.controls.CheckBox;
	import flash.filesystem.FileMode;
	import flash.display.LoaderInfo;
	
	public class XMLGenerator extends MovieClip
	{
		
		private var timelines:XMLList;
		private var places:Vector.<PlaceComponent>;
		private var selectedPalce:PlaceComponent;
		private var linksContainer:Sprite;
		private var questClassStr:String;
		
		public var start_check:CheckBox;
		public var intro_check:CheckBox;
		public var final_check:CheckBox;
		
		public function XMLGenerator()
		{
			linksContainer = new Sprite();
			
			var dom:File = File.applicationDirectory.resolvePath(loaderInfo.url.substr(5).split(".swf")[0] + "/DOMDocument.xml");
			dom.addEventListener(Event.COMPLETE, dom_completeHandler);
			setTimeout(dom.load, 100);
		}
		private function dom_completeHandler(event:Event):void
		{
			var xml:XML = new XML(event.currentTarget.data);
			timelines = xml.children()[3].children();
			resetPlaces();
		}
		private function addButtonsListener():void
		{
			load_btn.removeEventListener(MouseEvent.CLICK, load_btn_clickHandler);
			save_btn.removeEventListener(MouseEvent.CLICK, save_btn_clickHandler);
			next_btn.removeEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			prev_btn.removeEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			scene_txt.removeEventListener(KeyboardEvent.KEY_UP, scene_txt_keyUpHandler);

			load_btn.label_txt.text = "Load";
			load_btn.addEventListener(MouseEvent.CLICK, load_btn_clickHandler);
			save_btn.label_txt.text = "Save";
			save_btn.addEventListener(MouseEvent.CLICK, save_btn_clickHandler);
			
			next_btn.addEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			prev_btn.addEventListener(MouseEvent.CLICK, scene_btn_clickHandler);
			scene_txt.addEventListener(KeyboardEvent.KEY_UP, scene_txt_keyUpHandler);
			scene_txt.text = getSceneIndex().toString();
		}
		
		private function scene_btn_clickHandler(event:MouseEvent):void
		{
			var sceneIndex:int = getSceneIndex();
			if(event.currentTarget == next_btn)
			{
				if(sceneIndex < scenes.length-1)
					nextScene();
			}
			else
			{
				if(sceneIndex > 0)
					prevScene();
			}
			resetPlaces();
		}
		private function scene_txt_keyUpHandler(event:KeyboardEvent):void
		{
			if(event.keyCode == Keyboard.ENTER)
			{
				var sceneIndex:int = Math.max(0, Math.min(int(scene_txt.text), scenes.length-1));
				gotoAndStop(1, scenes[sceneIndex].name);
				resetPlaces();
			}
		}
		private function load_btn_clickHandler(event:Event):void
		{
			var sceneJson:FileReference = new FileReference();
			sceneJson.addEventListener(Event.SELECT, sceneJson_selectHandler);
			sceneJson.browse([new FileFilter("Json Files", "*.json")]);
			function sceneJson_selectHandler(event:Event):void
			{
				sceneJson.removeEventListener(Event.SELECT, sceneJson_selectHandler);
				sceneJson.addEventListener(Event.COMPLETE, sceneJson_completeHandler);
				sceneJson.load();
			}
		}
		private function resetPlaces():void
		{
			linksContainer.removeChildren();
			addChildAt(linksContainer, 1);
			addButtonsListener();
			
			if(places != null)
				for (var i:int=0; i<places.length; i++)
					places[i].removeEventListener(MouseEvent.MOUSE_DOWN, place_mouseDownHandler);
			
			places = new Vector.<PlaceComponent>();
			var place:PlaceComponent;
			var placeIndex:int = 0;
			for (i = 0; i<numChildren; i++)
			{
				place = getChildAt(i) as PlaceComponent;
				if(place != null)
				{
					place.index = placeIndex;
					places.push(place);
					place.addEventListener(MouseEvent.MOUSE_DOWN, place_mouseDownHandler);
					place.update();
					placeIndex ++;
				}
			}
		}
		private function sceneJson_completeHandler(event:Event):void
		{
			var json:Object = JSON.parse(event.currentTarget.data);
			if(json.name != currentScene.name || places.length!=json.places.length)
			{
				trace("Incompatiple data.");
				return;
			}
			
			resetPlaces();
			
			if(start_check)
				start_check.selected = json.hasStart;
			intro_check.selected = json.hasIntro;
			final_check.selected = json.hasFinal;
			
			if(json.times)
			for (var t:int=0; t < json.times.length; t++)
				this["time_"+t+"_txt"].text = json.times[t];

			for (var p:int=0; p < places.length; p++)
			{
				places[p].type = json.places[p].type;
				if( json.places[p].improveLevel != null )
					places[p].improveLevel = json.places[p].improveLevel;
				places[p].troopType = json.places[p].troopType;
				places[p].enabled = json.places[p].enabled;
				places[p].tutorIndex = json.places[p].tutorIndex;
				places[p].tutor_input.txt.text = "" + places[p].tutorIndex;

				places[p].update();
				
				var jsonlink:int = -1;
				var a:PlaceComponent = places[p];
				var b:PlaceComponent;
				
				for (var l:int=0; l < json.places[p].links.length; l++)
				{
					jsonlink = json.places[p].links[l];
					if(a.links.indexOf(jsonlink) == -1 )
					{
						b = places[jsonlink];
						var linkMc:LinkComponent = new LinkComponent(a.index, b.index);
						linkMc.graphics.lineStyle(10, 0x999999);
						linkMc.graphics.moveTo(a.x, a.y);
						linkMc.graphics.lineTo(b.x, b.y);
						linkMc.addEventListener(MouseEvent.CLICK, linkMc_clickHandler);
						linksContainer.addChild(linkMc);
						a.links.push(b.index);
						b.links.push(a.index);
					}
				}
			}
		}

		// mouse handlers
		private function place_mouseDownHandler(event:MouseEvent):void
		{
			selectedPalce = event.currentTarget as PlaceComponent;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
		}
		private function stage_mouseMoveHandler(event:MouseEvent):void
		{
			event.updateAfterEvent();
			selectedPalce.graphics.clear();
			selectedPalce.graphics.lineStyle(10);
			selectedPalce.graphics.moveTo(0,0);
			
			selectedPalce.graphics.lineTo(selectedPalce.mouseX + (selectedPalce.mouseX>0?-10:10), selectedPalce.mouseY + (selectedPalce.mouseY>0?-10:10));
		}
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			selectedPalce.graphics.clear();
			var placeTarget:PlaceComponent = event.target.parent as PlaceComponent;//trace(event.target)
			if(placeTarget != null && placeTarget != selectedPalce)
			{
				if(selectedPalce.links.indexOf(placeTarget.index) == -1 )
				{
					var linkMc:LinkComponent = new LinkComponent(selectedPalce.index, placeTarget.index);
					linkMc.graphics.lineStyle(10, 0x999999);
					linkMc.graphics.moveTo(selectedPalce.x, selectedPalce.y);
					linkMc.graphics.lineTo(placeTarget.x, placeTarget.y);
					linkMc.addEventListener(MouseEvent.CLICK, linkMc_clickHandler);
					linksContainer.addChild(linkMc);
					
					selectedPalce.links.push(placeTarget.index);
					placeTarget.links.push(selectedPalce.index);
				}
			}
			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			selectedPalce = null;
		}
		private function linkMc_clickHandler(event:MouseEvent):void
		{
			var linkMc:LinkComponent = event.currentTarget as LinkComponent;
			linkMc.parent.removeChild(linkMc);
			
			places[linkMc.places.x].links.splice(places[linkMc.places.x].links.indexOf(linkMc.places.y), 1);
			places[linkMc.places.y].links.splice(places[linkMc.places.y].links.indexOf(linkMc.places.x), 1);
		}
		
		private function save_btn_clickHandler(event:MouseEvent):void
		{
			var times:Array = new Array();
			var intro_num:int = int(this["intro_num"].text);
			var start_num:int = int(this["start_num"].text);
			var end_num:int = int(this["end_num"].text);
			for (var t:int=0; t < 4; t++)
				times[t] = int(this["time_"+t+"_txt"].text);
			var index:int = int(currentScene.name.split('_')[1]);
			//questClassStr = '\r\r\r\t\tfield = new FieldData(' + index + ', "' + currentScene.name + '", ' + intro_check.selected + ', ' + final_check.selected + ', "' + times + '" );\r\t\t// create places\r';
			
			var className:String = currentScene.name.substr(0,1).toUpperCase()+ currentScene.name.substr(1);
			trace('\t\tquests.set( "' + currentScene.name + '" , new ' + className + '( ' + index + ', "' + currentScene.name + '", "", "", "", "' + times + '" ) );')

			var tutorSteps:String = "";
			var sceneIndex:int = getSceneIndex();
			var sceneData:Object = new Object();
			sceneData.name = currentScene.name;
			if (start_check)
				sceneData.hasStart = start_check.selected;
			sceneData.hasIntro = intro_check.selected;
			sceneData.hasFinal = final_check.selected;
			
			sceneData.times = times;
			
			questClassStr = 'package com.gt.towers.battle.fieldes;\rclass ' + className + ' extends FieldData\r{\r\tpublic function new(index:Int, name:String, introNum:String="", startNum:String="", endNum:String="", times:String="")\r\t{\r\t\tsuper(index, name, introNum, startNum, endNum, times);\r\t\t// places\r';
			var items:Array = new Array();
			for (var i:int=0; i<places.length; i++)
			{
				items.push( places[i].data );
				questClassStr += places[i].classString;
			}
			
			sceneData.places = items;
			sceneData.images = getImagesData(currentScene.name);
			
			questClassStr += '\t}\r}';
			//trace(questClassStr)
			
			var jsonFR:FileReference = new FileReference();
			jsonFR.addEventListener(Event.SELECT, jsonFR_selectHandler);
			jsonFR.save( JSON.stringify(sceneData) , currentScene.name+".json");
			
			function jsonFR_selectHandler (event:Event):void
			{
				jsonFR.removeEventListener(Event.SELECT, jsonFR_selectHandler);
				var hxFile:File = new File("C:\\_projects\\towers-projects\\Towers-core\\source\\src\\com\\gt\\towers\\battle\\fieldes\\"+className+".hx");
				var stream:FileStream = new FileStream();
				stream.open(hxFile, FileMode.WRITE);
				stream.writeUTFBytes(questClassStr);
				stream.close();
				//trace("saved to", hxFile.nativePath); 
			}

		}
		private function getSceneIndex():int
		{
			for(var s:int=0; s<scenes.length; s++)
				if(scenes[s].name == currentScene.name)
					return s;
			return 0;
		}
		
		private function getImagesData(timelineName:String):Array
		{
			var items:Array = new Array();
			var bitmaps:XMLList ;
			for (var q:int=0; q<timelines.length(); q++)
			{
				if( timelines[q].@name == timelineName )
				{
					bitmaps = timelines[q].descendants("*")
					break;
				}
			}
			if( bitmaps == null )
			{
				trace("timeline notfound.");
				return null;
			}

			questClassStr += '\r#if flash\r\t\t// images\r';
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
			questClassStr += "#end\r";
			
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