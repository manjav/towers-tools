package com.gt.towers.editor
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import com.gt.towers.constants.CardTypes;
	
	public class PlaceComponent extends Sprite
	{
		public var level_btn:MovieClip;
		public var body_mc:MovieClip;
		public var tutor_input:MovieClip;
		public var type_input:MovieClip;
		public var enabled_btn:MovieClip;
		public var radius_mc:MovieClip;
		
		public var type:int = 1;
		public var index:int = 0;
		public var improveLevel:int = 1
		public var troopType:int = -1;
		public var links:Vector.<int>;
		public var tutorIndex:int = -1;
		public var enabled:Boolean = true;
		
		public function PlaceComponent()
		{
			super();
			
			index_txt.mouseEnabled = false;
			links = new Vector.<int>();
			level_btn.addEventListener(MouseEvent.CLICK, level_btn_clickHandler);
			body_mc.addEventListener(MouseEvent.CLICK, body_mc_clickHandler);
			tutor_input.txt.addEventListener(Event.CHANGE, tutor_input_changeHandler);
			type_input.txt.addEventListener(Event.CHANGE, type_input_changeHandler);
			enabled_btn.addEventListener(MouseEvent.CLICK, enabled_btn_clickHandler);
			update();
		}

		private function level_btn_clickHandler(event:Event):void
		{
			/*if(type == 1)
				update();
			else
			{*/
				if(improveLevel >= 4)
					improveLevel = 1;
				else
					improveLevel ++;
				update();
			//}
		}
		
		private function body_mc_clickHandler(event:Event):void
		{
			if(troopType >= 1)
				troopType = -1;
			else
				troopType ++;
			update();
		}
		
		private function tutor_input_changeHandler(event:Event):void
		{
			tutorIndex = int(tutor_input.txt.text);
			update();
		}		
		private function type_input_changeHandler(event:Event):void
		{
			type = int(type_input.txt.text);
			update();
	}
		
		private function enabled_btn_clickHandler(event:Event):void
		{
			enabled = !enabled;
			update();
		}
		
		public function get classString():String
		{
			return '\t\tplaces.push( new PlaceData( '+index+',\t'+x+',\t'+y+',\t'+type+',\t'+troopType+',\t"'+links+'"'+',\t'+enabled+',\t'+tutorIndex+',\t'+improveLevel+'\t) );\r';
		}
		public function get data():Object
		{
			return { index:this.index, type:this.type, troopType:this.troopType, links:this.links, enabled:this.enabled, tutorIndex:this.tutorIndex, improveLevel:this.improveLevel};
		}
		public function update():void
		{
			//trace(type, type*10 + (troopType+1));
			index_txt.text = index.toString();
			type_input.txt.text = type;
			level_btn.txt.text = "L:" + improveLevel;
			//tutor_input.txt.text = "S:" + tutorIndex;
			enabled_btn.txt.text = enabled ? "E" : "D";
			//body_mc.gotoAndStop(type*10 + (troopType+2));
			tutor_input.alpha = tutorIndex == -3 ? 0.3 : 1;
			var isDefensive:Boolean = (CardTypes.get_category(type) == CardTypes.C500);
			radius_mc.visible = isDefensive;
			if ( isDefensive )
			{
				radius_mc.width = get_damageRadius() * 2 / (stage.stageWidth/1080) * 1.3;
				radius_mc.scaleY = radius_mc.scaleX;
				//trace(stage.stageWidth, stage.width);
				//trace(radius_mc.width, radius_mc.scaleY);
			}
		}
	
		public function get_damageRadius():Number
		{
			return 60 + Math.round( (Math.log(improveLevel)) * 20);
		}
		
		/*public function get improveLevel():int
		{
			return  type%10;
		}*/
	}
}