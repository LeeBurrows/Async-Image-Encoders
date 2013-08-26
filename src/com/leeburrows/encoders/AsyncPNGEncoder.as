/**
 * AsyncPNGEncoder.as
 * Lee Burrows
 * version 1.0.4
 * 
 * Copyright (c) 2013 Lee Burrows
 * 
 * --------------------------------------------------------------------------------
 * PNG encoding algorithms adapted from as3corelib PNGEncoder by Mike Chambers.
 * https://github.com/mikechambers/as3corelib
 * --------------------------------------------------------------------------------
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
	
	import flash.utils.ByteArray;
	
	/** 
	 * Asynchronously encodes BitmapData objects into PNG file format.
	 * 
  	 * @langversion 3.0
	 * @playerversion Flash 9
	 * @playerversion AIR 1.5
	 * 
	 * @example Simple example:
	 * <listing version="3.0">
	 * package
	 * {
	 * 		import com.leeburrows.encoders.AsyncPNGEncoder;
	 * 		import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	 * 		import com.leeburrows.encoders.supportClasses.IAsyncImageEncoder;
	 * 		import flash.display.BitmapData;
	 * 		import flash.display.Sprite;
	 * 
	 * 		public class PNGEncoderExample extends Sprite
	 * 		{
	 * 			private var encoder:IAsyncImageEncoder;
	 * 
	 * 			public function PNGEncoderExample()
	 * 			{
	 * 				//generate a BitmapData object to encode
	 * 				var myBitmapData:BitmapData = new BitmapData(1000, 1000, true, 0x80FF9900);
	 * 				//create a new PNG encoder
	 * 				encoder = new AsyncPNGEncoder();
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
	public class AsyncPNGEncoder extends AsyncImageEncoderBase
	{
		private var crcTable:Array;
		private var IDAT:ByteArray;
		
		/**
		 * Create a new <code>AsyncPNGEncoder</code>
		 */
		public function AsyncPNGEncoder()
		{
			super();
		}
		
		/**
		 * Called internally when instance is instantiated.
		 * 
		 * <p>Populates CRC table.</p>
		 */
		override protected function initialise():void
		{
			crcTable = [];
			for (var n:uint = 0; n < 256; n++)
			{
				var c:uint = n;
				for (var k:uint = 0; k < 8; k++)
				{
					if (c & 1)
						c = uint(uint(0xedb88320) ^ uint(c >>> 1));
					else
						c = uint(c >>> 1);
				}
				crcTable[n] = c;
			}
		}
		
		/**
		 * Called internally before encoding loop begins.
		 * 
		 * <p>Builds PNG header bytes.</p>
		 */
		override protected function encodeHead():void
		{
			// Write PNG signature
			_encodedBytes.writeUnsignedInt(0x89504E47);
			_encodedBytes.writeUnsignedInt(0x0D0A1A0A);
			// Build IHDR chunk
			var IHDR:ByteArray = new ByteArray();
			IHDR.writeInt(sourceWidth);
			IHDR.writeInt(sourceHeight);
			IHDR.writeByte(8); // bit depth per channel
			IHDR.writeByte(6); // color type: RGBA
			IHDR.writeByte(0); // compression method
			IHDR.writeByte(0); // filter method
			IHDR.writeByte(0); // interlace method
			writeChunk(_encodedBytes, 0x49484452, IHDR);
			// Image
			IDAT = new ByteArray();
			IDAT.writeByte(0);
		}

		/**
		 * Called internally during encoding loop.
		 * 
		 * <p>Encodes a single pixel into PNG file format bytes.</p>
		 */
		override protected function encodeBlock():Boolean
		{
			//TO DO:
			//encode mulitple pixels within this block.
			//a bit wasteful to check the clock after every pixel.
			var pixel:uint;
			if (!sourceTransparent)
			{
				pixel = sourceBitmapData.getPixel(currentX, currentY);
				IDAT.writeUnsignedInt(uint(((pixel & 0xFFFFFF) << 8) | 0xFF));
			}
			else
			{
				pixel = sourceBitmapData.getPixel32(currentX, currentY);
				IDAT.writeUnsignedInt(uint(((pixel & 0xFFFFFF) << 8) | (pixel >>> 24)));
			}
			completedPixels++;
			currentX++;
			if (currentX>=sourceWidth)
			{
				currentX = 0;
				currentY++;
				if (currentY>=sourceHeight)
				{
					return true;
				}
				else
					IDAT.writeByte(0);
			}
			return false;
		}
		
		/**
		 * Called internally after encoding loop ends.
		 * 
		 * <p>Compresses encoded bytes and builds file end.</p>
		 */
		override protected function encodeTail():void
		{
			IDAT.compress();
			writeChunk(_encodedBytes, 0x49444154, IDAT);
			// Build IEND chunk
			writeChunk(_encodedBytes, 0x49454E44, null);
			//clear memory
			IDAT = null;
		}
		
		private function writeChunk(destination:ByteArray, type:uint, bytes:ByteArray):void
		{
			// Write length of data.
			var len:uint = 0;
			if (bytes)
				len = bytes.length;
			destination.writeUnsignedInt(len);
			
			// Write chunk type.
			var typePos:uint = destination.position;
			destination.writeUnsignedInt(type);
			
			// Write data.
			if (bytes)
				destination.writeBytes(bytes);
			
			// Write CRC of chunk type and data.
			var crcPos:uint = destination.position;
			destination.position = typePos;
			var crc:uint = 0xFFFFFFFF;
			for (var i:uint = typePos; i < crcPos; i++)
			{
				crc = uint(crcTable[(crc ^ destination.readUnsignedByte()) & uint(0xFF)] ^
					uint(crc >>> 8));
			}
			crc = uint(crc ^ uint(0xFFFFFFFF));
			destination.position = crcPos;
			destination.writeUnsignedInt(crc);
		}
		
	}
}
