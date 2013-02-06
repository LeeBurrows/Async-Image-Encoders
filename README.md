#Asynchronous Image Encoders

##ActionScript 3 classes for asynchronously encoding BitmapData source into image file formats

Encodes BitmapData objects over multiple frames to avoid freezing the UI. Ideally suited for mobile AIR where ActionScript Workers are unavailable.

Specify milliseconds per frame to allocate to encoding. Stop processing at any time.

Current supported file formats:

* .JPG
* .PNG
* .BMP

Others can be added by sub-classing AsyncImageEncoderBase to implement asynchronous processing.
See ASDocs for further details on implementing your own encoders.


A simple usage example:

	package
	{
		import com.leeburrows.encoders.AsyncPNGEncoder;
		import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
		import com.leeburrows.encoders.supportClasses.IAsyncImageEncoder;
		import flash.display.BitmapData;
		import flash.display.Sprite;
	
		public class PNGEncoderExample extends Sprite
		{
			private var encoder:IAsyncImageEncoder;
	
			public function PNGEncoderExample()
			{
				//generate a BitmapData object to encode
				var myBitmapData:BitmapData = new BitmapData(1000, 1000, true, 0x80FF9900);
				//create a new PNG encoder
				encoder = new AsyncPNGEncoder();
				//add progress and complete listeners
				encoder.addEventListener(AsyncImageEncoderEvent.PROGRESS, encodeProgressHandler);
				encoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, encodeCompleteHandler);
				//start encoding for 20 milliseconds per frame
				encoder.start(myBitmapData, 20);
			}
	
			private function encodeProgressHandler(event:AsyncImageEncoderEvent):void
			{
				//trace progress
				trace("encoding progress:", Math.floor(event.percentComplete)+"% complete");
			}
	
			private function encodeCompleteHandler(event:AsyncImageEncoderEvent):void
			{
				encoder.removeEventListener(AsyncImageEncoderEvent.PROGRESS, encodeProgressHandler);
				encoder.removeEventListener(AsyncImageEncoderEvent.COMPLETE, encodeCompleteHandler);
				//trace size of result
				trace("encoding completed:", encoder.encodedBytes.length+" bytes");
				//do something with the bytes...
				//..save to filesystem?
				//..upload to server?
				//..set as source for flex Image component?
			}
		}
	}