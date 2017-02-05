package zgd
{
	import com.adobe.images.PNGEncoder;
	import com.codeazur.as3swf.SWF;
	
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class MovieProxy
	{
		private var loadedSwf:MovieClip;
		private var timer:Timer;
		private var swfWidth:Number;
		private var swfHeight:Number;
		private var frameCount:uint;
		private var signature:String;
		private var version:int;
		private var frameRate:Number;
		
		private var prefix:String = "tmp";
		private const separator:String = "_";
		private var offsetMatrix:Matrix = new Matrix();
		private var scaleFactor:Number = 1;
		private var counter:int = 0;
		
		
		public function MovieProxy()
		{
		}
		
		public function load(url:String):void
		{
			var file:File = File.applicationDirectory.resolvePath(url);
			//var file:File = new File(url);
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			
			var swfBytes:ByteArray = new ByteArray();
			
			stream.readBytes(swfBytes);
			stream.close();
			
			readSwfHead(swfBytes);
			
			var conx:LoaderContext = new LoaderContext();
			conx.allowCodeImport = true;
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.OPEN, onLoadStart);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadEnd);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.loadBytes(swfBytes, conx);
		}
		
		
		private function readSwfHead(swfBytes:ByteArray):void
		{
			var swf:SWF = new SWF(swfBytes);
			swfWidth = swf.frameSize.rect.width;
			swfHeight = swf.frameSize.rect.height;
			frameCount = swf.frameCount;
			signature = swf.signature;
			version = swf.version;
			frameRate = swf.frameRate;
		}
		
		protected function onLoadEnd(event:Event):void
		{
			var loader:Loader = (event.target as LoaderInfo).loader;
			if(loader)
			{
				loadedSwf = MovieClip(loader.content);
			}
			
			if(loadedSwf)
			{
				//var outputWidth:Number = loader.width;
				//var outputHeight:Number = loader.height;
				
				var totalFrames:int = loadedSwf.totalFrames;
				
				stopClip(loadedSwf);
				gotoFrame(loadedSwf, 0);
				
				if(!timer)
				{
					timer = new Timer(30);
					timer.addEventListener(TimerEvent.TIMER, onFrameStep);
				}
				else
				{
					timer.stop();
					timer.reset();
				}
				counter = 0;
				timer.start();
			}
			else
			{
				throw(new Error("Not load a MovieClip swf"));
			}
		}
		
		protected function onFrameStep(event:TimerEvent):void
		{
			counter++;
			if(counter <= frameCount)
			{
				gotoFrame(loadedSwf, counter);
				saveFrame();
			}
			else
			{
				timer.stop();
				NativeApplication.nativeApplication.exit();
			}
		}
		
		protected function onLoadStart(event:Event):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function onLoadError(event:IOErrorEvent):void
		{
			// TODO Auto-generated method stub
			
		}
		
		private function padNumber(input:int, target:int):String
		{
			var out:String = input.toString();
			var targetCount:int = target.toString().length;
			while(out.length < targetCount)
			{
				out = "0" + out;
			}
			return out;
		}
		
		private function saveFrame():void
		{
			var bitmapData:BitmapData = new BitmapData(swfWidth, swfHeight, true, 0);
			offsetMatrix.scale(scaleFactor, scaleFactor);
			bitmapData.draw(loadedSwf, offsetMatrix);
			
			var byteArr:ByteArray = PNGEncoder.encode(bitmapData);
			var increment:String = "";
			if(frameCount > 1)
			{
				increment = separator + padNumber(counter, frameCount);
			}
			
			var outFile:File = new File(File.applicationDirectory.resolvePath(prefix + increment + ".png").nativePath);
			
			var stream:FileStream = new FileStream();
			stream.open(outFile, FileMode.WRITE);
			stream.writeBytes(byteArr);
			stream.close();
		}
		
		private function stopClip(inMc:MovieClip):void
		{
			var l:int = inMc.numChildren;
			for (var i:int=0; i<l; ++i)
			{
				var mc:MovieClip = inMc.getChildAt(i) as MovieClip;
				if(mc)
				{
					mc.stop();
					if(mc.numChildren>0)
					{
						stopClip(mc);
					}
				}
			}
			inMc.stop();
		}
		
		private function gotoFrame(inMc:MovieClip, frameAt:int):void
		{
			var l:int = inMc.numChildren;
			for(var i:int=0; i<l; ++i)
			{
				var mc:MovieClip = inMc.getChildAt(i) as MovieClip;
				if(mc)
				{
					mc.gotoAndStop(frameAt % (inMc.totalFrames + 1));
					if(mc.numChildren>0)
					{
						gotoFrame(mc, frameAt);
					}
				}
			}
			inMc.gotoAndStop(frameAt % inMc.totalFrames);
		}
		
		
	}
}