/**
 * AsyncImageEncoderEvent.as
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
 */
package com.leeburrows.encoders.supportClasses
{
	import flash.events.Event;
	
	/**
	 * Dispatched to notify progress of asynchronous encoder processing.
	 * 
   	 * @langversion 3.0
	 * @playerversion Flash 9
	 * @playerversion AIR 1.5
	 */
	public class AsyncImageEncoderEvent extends Event
	{
		/**
		 * Defines the value of the type property of a progress event object.
		 */
		public static const PROGRESS:String = "progress";

		/**
		 * Defines the value of the type property of a complete event object.
		 */
		public static const COMPLETE:String = "complete";
		
		private var _pixelsEncoded:int;
		private var _pixelsTotal:int;
		
		/**
		 * Create a new <code>AsyncImageEncoderEvent</code> object.
		 * 
		 * @param type The event type.
		 * @param pixelsEncoded Number of pixels processed by asynchronous encoder.
		 * @param pixelsTotal Total number of pixels to be processed by asynchronous encoder.
		 */
		public function AsyncImageEncoderEvent(type:String, pixelsEncoded:int=0, pixelsTotal:int=0)
		{
			super(type, false, false);
			_pixelsEncoded = pixelsEncoded;
			_pixelsTotal = pixelsTotal;
		}
		
		/**
		 * Number of pixels processed by asynchronous encoder.
		 */
		public function get pixelsEncoded():int
		{
			return _pixelsEncoded;
		}
		
		/**
		 * Total number of pixels to be processed by asynchronous encoder.
		 */
		public function get pixelsTotal():int
		{
			return _pixelsTotal;
		}
		
		/**
		 * Ratio of processing that has been completed. Between 0 and 1.
		 */
		public function get ratioComplete():Number
		{
			return _pixelsEncoded/_pixelsTotal;
		}
		
		/**
		 * Percentage of processing that has been completed. Between 0 and 100.
		 */
		public function get percentComplete():Number
		{
			return 100*ratioComplete;
		}
		
		/**
		 * Clones the current event.
		 * 
		 * @return An exact duplicate of the current event.
		 */
		override public function clone():Event
		{
			return new AsyncImageEncoderEvent(type, _pixelsEncoded, _pixelsTotal);
		}
	
	}
}