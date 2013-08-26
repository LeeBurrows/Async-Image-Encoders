/**
 * AsyncJPGEncoder.as
 * Lee Burrows
 * version 1.0.4
 * 
 * Copyright (c) 2013 Lee Burrows
 * 
 * --------------------------------------------------------------------------------
 * JPEG encoding algorithms adapted from as3corelib JPGEncoder by Mike Chambers.
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
	
	import flash.display.BitmapData;
	
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
	 * 		import com.leeburrows.encoders.AsyncJPGEncoder;
	 * 		import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	 * 		import com.leeburrows.encoders.supportClasses.IAsyncImageEncoder;
	 * 		import flash.display.BitmapData;
	 * 		import flash.display.Sprite;
	 * 
	 * 		public class JPGEncoderExample extends Sprite
	 * 		{
	 * 			private var encoder:IAsyncImageEncoder;
	 * 
	 * 			public function JPGEncoderExample()
	 * 			{
	 *				//generate a BitmapData object to encode
	 * 				var myBitmapData:BitmapData = new BitmapData(1000, 1000, true, 0x80FF9900);
	 * 				//create a new JPG encoder with 75% quality
	 * 				encoder = new AsyncJPGEncoder(75);
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
	public class AsyncJPGEncoder extends AsyncImageEncoderBase
	{
		private var _quality:Number = 80;
		private var _qualityChanged:Boolean = false;
		
		/**
		 * Quality of JPEG image. Values less than 1 or greater than 100 are clipped.
		 * 
		 * <p>Higher values cause less compression and so result in larger file sizes.</p>
		 * <p>Changing value does not affect any .</p>
		 */
		public function get quality():Number
		{
			return _quality;
		}
		
		public function set quality(value:Number):void
		{
			if (_quality!=value)
			{
				_quality = value;
				if (isRunning)
				{
					//if encoder is running we dont want to update tables yet.
					//instead we set a flag and update tables when encoding is stopped or completes.
					_qualityChanged = true;
				}
				else
				{
					initQuantTables();
				}
			}
		}

		private function validateQuality():void
		{
			//if encoder is running we dont want to update tables yet.
			//instead we set a flag and update tables when encoding is stopped or completes.
			if (_qualityChanged)
			{
				_qualityChanged = false;
				initQuantTables();
			}
		}
		
		/**
		 * Create a new <code>AsyncJPGEncoder</code>
		 * 
		 * @param quality Quality of JPEG image. Values less than 1 or greater than 100 are clipped.
		 */
		public function AsyncJPGEncoder(quality:Number=80.0)
		{
			_quality = quality;
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function stop():void
		{
			super.stop();
			//see if quality changed during processing
			validateQuality();
		}

		/**
		 * Called internally when instance is instantiated.
		 * 
		 * <p>Validates quality value and populates tables.</p>
		 */
		override protected function initialise():void
		{
			initHuffmanTbl();
			initCategoryNumber();
			initQuantTables();
		}
		
		/**
		 * Called internally before encoding loop begins.
		 * 
		 * <p>Builds JPEG header bytes.</p>
		 */
		override protected function encodeHead():void
		{
			//adjust blocksTotal as we are encoding 8x8 pixels each time
			totalPixels = Math.ceil(sourceWidth/8)*Math.ceil(sourceHeight/8)*64;
			// Add JPEG headers
			bytenew = 0;
			bytepos = 7;
			writeWord(0xFFD8); // SOI
			writeAPP0();
			writeDQT();
			writeSOF0(sourceWidth, sourceHeight);
			writeDHT();
			writeSOS();
			// Encode 8x8 macroblocks
			bytenew = 0;
			bytepos = 7;
			DCY = 0;
			DCU = 0;
			DCV = 0;
		}
		
		/**
		 * Called internally during encoding loop.
		 * 
		 * <p>Encodes an 8x8 block of pixels into JPEG file format bytes.</p>
		 */
		override protected function encodeBlock():Boolean
		{
			RGB2YUV(sourceBitmapData, currentX, currentY, sourceWidth, sourceHeight);
			
			DCY = processDU(YDU, fdtbl_Y, DCY, YDC_HT, YAC_HT);
			DCU = processDU(UDU, fdtbl_UV, DCU, UVDC_HT, UVAC_HT);
			DCV = processDU(VDU, fdtbl_UV, DCV, UVDC_HT, UVAC_HT);
			
			completedPixels += 64;
			currentX += 8;
			if (currentX>=sourceWidth)
			{
				currentX = 0;
				currentY += 8;
				if (currentY>=sourceHeight)
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Called internally after encoding loop ends.
		 * 
		 * <p>Builds EOI marker.</p>
		 */
		override protected function encodeTail():void
		{
			// Do the bit alignment of the EOI marker
			if (bytepos >= 0)
			{
				var fillbits:BitString = new BitString();
				fillbits.len = bytepos + 1;
				fillbits.val = (1 << (bytepos + 1)) - 1;
				writeBits(fillbits);
			}
			// Add EOI
			writeWord(0xFFD9);
			//see if quality changed during processing
			validateQuality();
		}
		
		private const std_dc_luminance_nrcodes:Array = [ 0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 ];
		private const std_dc_luminance_values:Array = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ];
		private const std_dc_chrominance_nrcodes:Array = [ 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 ];
		private const std_dc_chrominance_values:Array = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ];
		private const std_ac_luminance_nrcodes:Array = [ 0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7D ];
		private const std_ac_luminance_values:Array = [
			0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
			0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
			0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
			0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0,
			0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0A, 0x16,
			0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
			0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
			0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
			0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
			0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
			0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
			0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
			0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
			0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
			0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
			0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5,
			0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2, 0xD3, 0xD4,
			0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
			0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA,
			0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
			0xF9, 0xFA ];
		private const std_ac_chrominance_nrcodes:Array = [ 0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77 ];
		private const std_ac_chrominance_values:Array = [
			0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
			0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
			0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
			0xA1, 0xB1, 0xC1, 0x09, 0x23, 0x33, 0x52, 0xF0,
			0x15, 0x62, 0x72, 0xD1, 0x0A, 0x16, 0x24, 0x34,
			0xE1, 0x25, 0xF1, 0x17, 0x18, 0x19, 0x1A, 0x26,
			0x27, 0x28, 0x29, 0x2A, 0x35, 0x36, 0x37, 0x38,
			0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
			0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
			0x59, 0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
			0x69, 0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
			0x79, 0x7A, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
			0x88, 0x89, 0x8A, 0x92, 0x93, 0x94, 0x95, 0x96,
			0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5,
			0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4,
			0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3,
			0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2,
			0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA,
			0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9,
			0xEA, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
			0xF9, 0xFA ];
		private const ZigZag:Array = [
			0,  1,  5,  6, 14, 15, 27, 28,
			2,  4,  7, 13, 16, 26, 29, 42,
			3,  8, 12, 17, 25, 30, 41, 43,
			9, 11, 18, 24, 31, 40, 44, 53,
			10, 19, 23, 32, 39, 45, 52, 54,
			20, 22, 33, 38, 46, 51, 55, 60,
			21, 34, 37, 47, 50, 56, 59, 61,
			35, 36, 48, 49, 57, 58, 62, 63 ];
		
		private var YDC_HT:Array;
		private var UVDC_HT:Array;
		private var YAC_HT:Array;
		private var UVAC_HT:Array;
		private var category:Array = new Array(65535);
		private var bitcode:Array = new Array(65535);
		private var YTable:Array = new Array(64);
		private var UVTable:Array = new Array(64);
		private var fdtbl_Y:Array = new Array(64);
		private var fdtbl_UV:Array = new Array(64);
		
		private var bytenew:int = 0;
		private var bytepos:int = 7;
		private var DU:Array = new Array(64);
		private var YDU:Array = new Array(64);
		private var UDU:Array = new Array(64);
		private var VDU:Array = new Array(64);
		private var DCY:Number = 0;
		private var DCU:Number = 0;
		private var DCV:Number = 0;
		
		private function initHuffmanTbl():void
		{
			YDC_HT = computeHuffmanTbl(std_dc_luminance_nrcodes, std_dc_luminance_values);
			UVDC_HT = computeHuffmanTbl(std_dc_chrominance_nrcodes, std_dc_chrominance_values);
			YAC_HT = computeHuffmanTbl(std_ac_luminance_nrcodes, std_ac_luminance_values);
			UVAC_HT = computeHuffmanTbl(std_ac_chrominance_nrcodes, std_ac_chrominance_values);
		}
		
		private function computeHuffmanTbl(nrcodes:Array, std_table:Array):Array
		{
			var codevalue:int = 0;
			var pos_in_table:int = 0;
			var HT:Array = [];
			for (var k:int = 1; k <= 16; k++)
			{
				for (var j:int = 1; j <= nrcodes[k]; j++)
				{
					HT[std_table[pos_in_table]] = new BitString();
					HT[std_table[pos_in_table]].val = codevalue;
					HT[std_table[pos_in_table]].len = k;
					pos_in_table++;
					codevalue++;
				}
				codevalue *= 2;
			}
			return HT;
		}
		
		private function initCategoryNumber():void
		{
			var nr:int;
			var nrlower:int = 1;
			var nrupper:int = 2;
			for (var cat:int = 1; cat <= 15; cat++)
			{
				// Positive numbers
				for (nr = nrlower; nr < nrupper; nr++)
				{
					category[32767 + nr] = cat;
					bitcode[32767 + nr] = new BitString();
					bitcode[32767 + nr].len = cat;
					bitcode[32767 + nr].val = nr;
				}
				// Negative numbers
				for (nr = -(nrupper - 1); nr <= -nrlower; nr++)
				{
					category[32767 + nr] = cat;
					bitcode[32767 + nr] = new BitString();
					bitcode[32767 + nr].len = cat;
					bitcode[32767 + nr].val = nrupper - 1 + nr;
				}
				nrlower <<= 1;
				nrupper <<= 1;
			}
		}
		
		private function initQuantTables():void
		{
			var clippedQuality:Number = Math.max(1, Math.min(100, _quality));
			var sf:int = (clippedQuality<50) ? int(5000/clippedQuality) : int(200-clippedQuality*2);
			var i:int = 0;
			var t:Number;
			var YQT:Array = [
				16, 11, 10, 16,  24,  40,  51,  61,
				12, 12, 14, 19,  26,  58,  60,  55,
				14, 13, 16, 24,  40,  57,  69,  56,
				14, 17, 22, 29,  51,  87,  80,  62,
				18, 22, 37, 56,  68, 109, 103,  77,
				24, 35, 55, 64,  81, 104, 113,  92,
				49, 64, 78, 87, 103, 121, 120, 101,
				72, 92, 95, 98, 112, 100, 103,  99 ];
			for (i = 0; i < 64; i++)
			{
				t = Math.floor((YQT[i] * sf + 50)/100);
				if (t < 1)
					t = 1;
				else if (t > 255)
					t = 255;
				YTable[ZigZag[i]] = t;
			}
			var UVQT:Array = [
				17, 18, 24, 47, 99, 99, 99, 99,
				18, 21, 26, 66, 99, 99, 99, 99,
				24, 26, 56, 99, 99, 99, 99, 99,
				47, 66, 99, 99, 99, 99, 99, 99,
				99, 99, 99, 99, 99, 99, 99, 99,
				99, 99, 99, 99, 99, 99, 99, 99,
				99, 99, 99, 99, 99, 99, 99, 99,
				99, 99, 99, 99, 99, 99, 99, 99 ];
			for (i = 0; i < 64; i++)
			{
				t = Math.floor((UVQT[i] * sf + 50) / 100);
				if (t < 1)
					t = 1;
				else if (t > 255)
					t = 255;
				UVTable[ZigZag[i]] = t;
			}
			var aasf:Array = [
				1.0, 1.387039845, 1.306562965, 1.175875602,
				1.0, 0.785694958, 0.541196100, 0.275899379 ];
			
			i = 0;
			for (var row:int = 0; row < 8; row++)
			{
				for (var col:int = 0; col < 8; col++)
				{
					fdtbl_Y[i] = (1.0 / (YTable [ZigZag[i]] * aasf[row] * aasf[col] * 8.0));
					fdtbl_UV[i] = (1.0 / (UVTable[ZigZag[i]] * aasf[row] * aasf[col] * 8.0));
					i++;
				}
			}
		}
		
		private function RGB2YUV(bitmapData:BitmapData, xpos:int, ypos:int, width:int, height:int):void
		{
			var k:int = 0;
			
			for (var j:int = 0; j < 8; j++)
			{
				var y:int = ypos + j;
				if (y >= height)
					y = height - 1;
				
				for (var i:int = 0; i < 8; i++)
				{
					var x:int = xpos + i;
					if (x >= width)
						x = width - 1;
					
					var pixel:uint = bitmapData.getPixel32(x, y);
					
					var r:Number = Number((pixel >> 16) & 0xFF);
					var g:Number = Number((pixel >> 8) & 0xFF);
					var b:Number = Number(pixel & 0xFF);
					
					YDU[k] =  0.29900 * r + 0.58700 * g + 0.11400 * b - 128.0;
					UDU[k] = -0.16874 * r - 0.33126 * g + 0.50000 * b;
					VDU[k] =  0.50000 * r - 0.41869 * g - 0.08131 * b;
					
					k++;
				}
			}
		}
		
		private function processDU(CDU:Array, fdtbl:Array, DC:Number, HTDC:Array, HTAC:Array):Number
		{
			var EOB:BitString = HTAC[0x00];
			var M16zeroes:BitString = HTAC[0xF0];
			var i:int;
			
			var DU_DCT:Array = fDCTQuant(CDU, fdtbl);
			
			// ZigZag reorder
			for (i = 0; i < 64; i++)
			{
				DU[ZigZag[i]] = DU_DCT[i];
			}
			
			var Diff:int = DU[0] - DC;
			DC = DU[0];
			
			// Encode DC
			if (Diff == 0)
			{
				writeBits(HTDC[0]); // Diff might be 0
			}
			else
			{
				writeBits(HTDC[category[32767 + Diff]]);
				writeBits(bitcode[32767 + Diff]);
			}
			
			// Encode ACs
			var end0pos:int = 63;
			for (; (end0pos > 0) && (DU[end0pos] == 0); end0pos--)
			{
			};
			
			// end0pos = first element in reverse order != 0
			if (end0pos == 0)
			{
				writeBits(EOB);
				return DC;
			}
			
			i = 1;
			while (i <= end0pos)
			{
				var startpos:int = i;
				for (; (DU[i] == 0) && (i <= end0pos); i++)
				{
				}
				var nrzeroes:int = i - startpos;
				
				if (nrzeroes >= 16)
				{
					for (var nrmarker:int = 1; nrmarker <= nrzeroes / 16; nrmarker++)
					{
						writeBits(M16zeroes);
					}
					nrzeroes = int(nrzeroes & 0xF);
				}
				
				writeBits(HTAC[nrzeroes * 16 + category[32767 + DU[i]]]);
				writeBits(bitcode[32767 + DU[i]]);
				
				i++;
			}
			
			if (end0pos != 63)
				writeBits(EOB);
			
			return DC;
		}
		
		private function fDCTQuant(data:Array, fdtbl:Array):Array
		{
			// Pass 1: process rows.
			var dataOff:int = 0;
			var i:int;
			for (i = 0; i < 8; i++)
			{
				var tmp0:Number = data[dataOff + 0] + data[dataOff + 7];
				var tmp7:Number = data[dataOff + 0] - data[dataOff + 7];
				var tmp1:Number = data[dataOff + 1] + data[dataOff + 6];
				var tmp6:Number = data[dataOff + 1] - data[dataOff + 6];
				var tmp2:Number = data[dataOff + 2] + data[dataOff + 5];
				var tmp5:Number = data[dataOff + 2] - data[dataOff + 5];
				var tmp3:Number = data[dataOff + 3] + data[dataOff + 4];
				var tmp4:Number = data[dataOff + 3] - data[dataOff + 4];
				
				// Even part
				var tmp10:Number = tmp0 + tmp3;	// phase 2
				var tmp13:Number = tmp0 - tmp3;
				var tmp11:Number = tmp1 + tmp2;
				var tmp12:Number = tmp1 - tmp2;
				
				data[dataOff + 0] = tmp10 + tmp11; // phase 3
				data[dataOff + 4] = tmp10 - tmp11;
				
				var z1:Number = (tmp12 + tmp13) * 0.707106781; // c4
				data[dataOff + 2] = tmp13 + z1; // phase 5
				data[dataOff + 6] = tmp13 - z1;
				
				// Odd part
				tmp10 = tmp4 + tmp5; // phase 2
				tmp11 = tmp5 + tmp6;
				tmp12 = tmp6 + tmp7;
				
				// The rotator is modified from fig 4-8 to avoid extra negations.
				var z5:Number = (tmp10 - tmp12) * 0.382683433; // c6
				var z2:Number = 0.541196100 * tmp10 + z5; // c2 - c6
				var z4:Number = 1.306562965 * tmp12 + z5; // c2 + c6
				var z3:Number = tmp11 * 0.707106781; // c4
				
				var z11:Number = tmp7 + z3; // phase 5
				var z13:Number = tmp7 - z3;
				
				data[dataOff + 5] = z13 + z2; // phase 6
				data[dataOff + 3] = z13 - z2;
				data[dataOff + 1] = z11 + z4;
				data[dataOff + 7] = z11 - z4;
				
				dataOff += 8; // advance pointer to next row
			}
			
			// Pass 2: process columns.
			dataOff = 0;
			for (i = 0; i < 8; i++)
			{
				tmp0 = data[dataOff +  0] + data[dataOff + 56];
				tmp7 = data[dataOff +  0] - data[dataOff + 56];
				tmp1 = data[dataOff +  8] + data[dataOff + 48];
				tmp6 = data[dataOff +  8] - data[dataOff + 48];
				tmp2 = data[dataOff + 16] + data[dataOff + 40];
				tmp5 = data[dataOff + 16] - data[dataOff + 40];
				tmp3 = data[dataOff + 24] + data[dataOff + 32];
				tmp4 = data[dataOff + 24] - data[dataOff + 32];
				
				// Even par
				tmp10 = tmp0 + tmp3; // phase 2
				tmp13 = tmp0 - tmp3;
				tmp11 = tmp1 + tmp2;
				tmp12 = tmp1 - tmp2;
				
				data[dataOff +  0] = tmp10 + tmp11; // phase 3
				data[dataOff + 32] = tmp10 - tmp11;
				
				z1 = (tmp12 + tmp13) * 0.707106781; // c4
				data[dataOff + 16] = tmp13 + z1; // phase 5
				data[dataOff + 48] = tmp13 - z1;
				
				// Odd part
				tmp10 = tmp4 + tmp5; // phase 2
				tmp11 = tmp5 + tmp6;
				tmp12 = tmp6 + tmp7;
				
				// The rotator is modified from fig 4-8 to avoid extra negations.
				z5 = (tmp10 - tmp12) * 0.382683433; // c6
				z2 = 0.541196100 * tmp10 + z5; // c2 - c6
				z4 = 1.306562965 * tmp12 + z5; // c2 + c6
				z3 = tmp11 * 0.707106781; // c4
				
				z11 = tmp7 + z3; // phase 5 */
				z13 = tmp7 - z3;
				
				data[dataOff + 40] = z13 + z2; // phase 6
				data[dataOff + 24] = z13 - z2;
				data[dataOff +  8] = z11 + z4;
				data[dataOff + 56] = z11 - z4;
				
				dataOff++; // advance pointer to next column
			}
			
			// Quantize/descale the coefficients
			for (i = 0; i < 64; i++)
			{
				// Apply the quantization and scaling factor
				// and round to nearest integer
				data[i] = Math.round((data[i] * fdtbl[i]));
			}
			
			return data;
		}
		
		private function writeBits(bs:BitString):void
		{
			var value:int = bs.val;
			var posval:int = bs.len - 1;
			while (posval >= 0)
			{
				if (value & uint(1 << posval) )
				{
					bytenew |= uint(1 << bytepos);
				}
				posval--;
				bytepos--;
				if (bytepos < 0)
				{
					if (bytenew == 0xFF)
					{
						writeByte(0xFF);
						writeByte(0);
					}
					else
					{
						writeByte(bytenew);
					}
					bytepos = 7;
					bytenew = 0;
				}
			}
		}
		
		private function writeByte(value:int):void
		{
			_encodedBytes.writeByte(value);
		}
		
		private function writeWord(value:int):void
		{
			writeByte((value >> 8) & 0xFF);
			writeByte(value & 0xFF);
		}
		
		private function writeAPP0():void
		{
			writeWord(0xFFE0);	// marker
			writeWord(16);		// length
			writeByte(0x4A);	// J
			writeByte(0x46);	// F
			writeByte(0x49);	// I
			writeByte(0x46);	// F
			writeByte(0);		// = "JFIF",'\0'
			writeByte(1);		// versionhi
			writeByte(1);		// versionlo
			writeByte(0);		// xyunits
			writeWord(1);		// xdensity
			writeWord(1);		// ydensity
			writeByte(0);		// thumbnwidth
			writeByte(0);		// thumbnheight
		}
		
		private function writeDQT():void
		{
			writeWord(0xFFDB);	// marker
			writeWord(132);     // length
			writeByte(0);
			var i:int;
			
			for (i = 0; i < 64; i++)
			{
				writeByte(YTable[i]);
			}
			
			writeByte(1);
			
			for (i = 0; i < 64; i++)
			{
				writeByte(UVTable[i]);
			}
		}
		
		private function writeSOF0(width:int, height:int):void
		{
			writeWord(0xFFC0);	// marker
			writeWord(17);		// length, truecolor YUV JPG
			writeByte(8);		// precision
			writeWord(height);
			writeWord(width);
			writeByte(3);		// nrofcomponents
			writeByte(1);		// IdY
			writeByte(0x11);	// HVY
			writeByte(0);		// QTY
			writeByte(2);		// IdU
			writeByte(0x11);	// HVU
			writeByte(1);		// QTU
			writeByte(3);		// IdV
			writeByte(0x11);	// HVV
			writeByte(1);		// QTV
		}
		
		private function writeDHT():void
		{
			var i:int;
			
			writeWord(0xFFC4); // marker
			writeWord(0x01A2); // length
			
			writeByte(0); // HTYDCinfo
			for (i = 0; i < 16; i++)
			{
				writeByte(std_dc_luminance_nrcodes[i + 1]);
			}
			for (i = 0; i <= 11; i++)
			{
				writeByte(std_dc_luminance_values[i]);
			}
			
			writeByte(0x10); // HTYACinfo
			for (i = 0; i < 16; i++)
			{
				writeByte(std_ac_luminance_nrcodes[i + 1]);
			}
			for (i = 0; i <= 161; i++)
			{
				writeByte(std_ac_luminance_values[i]);
			}
			
			writeByte(1); // HTUDCinfo
			for (i = 0; i < 16; i++)
			{
				writeByte(std_dc_chrominance_nrcodes[i + 1]);
			}
			for (i = 0; i <= 11; i++)
			{
				writeByte(std_dc_chrominance_values[i]);
			}
			
			writeByte(0x11); // HTUACinfo
			for (i = 0; i < 16; i++)
			{
				writeByte(std_ac_chrominance_nrcodes[i + 1]);
			}
			for (i = 0; i <= 161; i++)
			{
				writeByte(std_ac_chrominance_values[i]);
			}
		}
		
		private function writeSOS():void
		{
			writeWord(0xFFDA);	// marker
			writeWord(12);		// length
			writeByte(3);		// nrofcomponents
			writeByte(1);		// IdY
			writeByte(0);		// HTY
			writeByte(2);		// IdU
			writeByte(0x11);	// HTU
			writeByte(3);		// IdV
			writeByte(0x11);	// HTV
			writeByte(0);		// Ss
			writeByte(0x3f);	// Se
			writeByte(0);		// Bf
		}
	}
	
}
/**
 *  @private
 */
class BitString
{
	public var len:int = 0;
	public var val:int = 0;
}