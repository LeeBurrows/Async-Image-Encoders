/**
 * AsyncBMPEncoder.as
 * Lee Burrows
 * version 1.0.4
 * 
 * Copyright (c) 2013 Lee Burrows
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
package com.leeburrows.encoders
{
	import com.leeburrows.encoders.supportClasses.AsyncImageEncoderBase;
	
	import flash.utils.Endian;
	
	/** 
	 * Asynchronously encodes BitmapData objects into JPEG file format.
	 * 
	 * @langversion 3.0
	 * @playerversion Flash 9
	 * @playerversion AIR 1.5
	 * 
	 * @example Simple example:
	 * <listing version="3.0">
	 * package
	 * {
	 * 		import com.leeburrows.encoders.AsyncBMPEncoder;
	 * 		import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	 * 		import com.leeburrows.encoders.supportClasses.IAsyncImageEncoder;
	 * 		import flash.display.BitmapData;
	 * 		import flash.display.Sprite;
	 * 
	 * 		public class BMPEncoderExample extends Sprite
	 * 		{
	 * 			private var encoder:IAsyncImageEncoder;
	 * 
	 * 			public function BMPEncoderExample()
	 * 			{
	 *				//generate a BitmapData object to encode
	 * 				var myBitmapData:BitmapData = new BitmapData(1000, 1000, true, 0x80FF9900);
	 * 				//create a new BMP encoder
	 * 				encoder = new AsyncBMPEncoder();
	 * 				//add progress and complete listeners
	 * 				encoder.addEventListener(AsyncImageEncoderEvent.PROGRESS, encodeProgressHandler);
	 * 				encoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, encodeCompleteHandler);
	 * 				//start encoding for 20 milliseconds per frame
	 * 				encoder.start(myBitmapData, 20);
	 * 			}
	 * 
	 * 			private function encodeProgressHandler(event:AsyncImageEncoderEvent):void
	 * 			{
	 * 				//trace progress
	 * 				trace("encoding progress:", Math.floor(event.percentComplete)+"% complete");
	 * 			}
	 * 
	 * 			private function encodeCompleteHandler(event:AsyncImageEncoderEvent):void
	 * 			{
	 * 				encoder.removeEventListener(AsyncImageEncoderEvent.PROGRESS, encodeProgressHandler);
	 * 				encoder.removeEventListener(AsyncImageEncoderEvent.COMPLETE, encodeCompleteHandler);
	 * 				//trace size of result
	 * 				trace("encoding completed:", encoder.encodedBytes.length+" bytes");
	 * 			}
	 * 		}
	 * }
	 * </listing>
	 */
	public class AsyncBMPEncoder extends AsyncImageEncoderBase
	{
		public function AsyncBMPEncoder()
		{
			super();
		}

		/**
		 * Called internally before encoding loop begins.
		 * 
		 * <p>Builds BMP header bytes.</p>
		 */
		override protected function encodeHead():void
		{
			var imageDataOffset:int = 0x36;
			_encodedBytes.endian = Endian.LITTLE_ENDIAN;
			//file header
			_encodedBytes.writeByte(0x42); //B
			_encodedBytes.writeByte(0x4D); //M
			_encodedBytes.writeInt(totalPixels*4 + imageDataOffset); //file size
			_encodedBytes.position = 0x0A;
			_encodedBytes.writeInt(imageDataOffset); //data position
			//info header
			_encodedBytes.writeInt(0x28); //header size
			_encodedBytes.writeInt(sourceWidth);
			_encodedBytes.writeInt(sourceHeight);
			_encodedBytes.writeShort(1); //planes
			_encodedBytes.writeShort(32); //color depth (bits)
			_encodedBytes.writeInt(0); //compression type
			_encodedBytes.writeInt(totalPixels*4); //size
			//image data
			_encodedBytes.position = imageDataOffset;
		}

		/**
		 * Called internally during encoding loop.
		 * 
		 * <p>Encodes a row of pixels into BMP file format bytes.</p>
		 */
		override protected function encodeBlock():Boolean
		{
			//BMP stores pixel data upside down (ie: top left pixel stored bottom left in bmp)
			//so we reverse the y position of getPixel.
			//we encode a whole row rather than single pixel as its a very simple algorithm
			//and a bit wasteful to check clock after every pixel.
			for (var i:uint=0;i<sourceWidth;i++)
			{
				_encodedBytes.writeUnsignedInt(sourceBitmapData.getPixel(i, sourceHeight-1-currentY));
			}
			completedPixels += sourceWidth;
			currentY++;
			if (currentY>=sourceHeight)
			{
				return true;
			}
			return false;
		}
		
	}
}