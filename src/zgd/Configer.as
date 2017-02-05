package zgd
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class Configer
	{
		private static var _instance:Configer;
		private static var _binit:Boolean;
		private var data:XML;
		private var _cmdPath:String;
		private var _ffmpegXml:String;
		
		
		public function Configer()
		{
			if(_binit == false)
			{
				throw(new Error("Please Use getInstance() instand!"));
			}
			loadData();
		}
		
		private function loadData():void
		{
			var file:File = new File( File.applicationDirectory.resolvePath("config.xml").nativePath );
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			
			var bytes:ByteArray = new ByteArray();
			stream.readBytes(bytes);
			stream.close();
			
			parseData(bytes);
		}
		
		private function parseData(bytes:ByteArray):void
		{
			var str:String = bytes.readUTFBytes(bytes.bytesAvailable);
			
			data = new XML(str);
			_cmdPath = XML(data.cmd[0]).toString();
			_ffmpegXml = XML(data.ffmpeg[0]).toString();
		}
		
		public function cmdPath():String
		{
			return _cmdPath;
		}
		
		public function ffmpegPath():String
		{
			return _ffmpegXml;
		}
		
		public static function getInstance():Configer
		{
			if(_instance)
				return _instance;
			
			_binit = true;
			_instance = new Configer();
			_binit = false;
			return _instance;
		}
		
	}
}