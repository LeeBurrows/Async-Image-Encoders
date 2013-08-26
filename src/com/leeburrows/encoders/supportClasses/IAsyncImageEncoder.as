/**
 * IAsyncImageEncoder.as
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
	import flash.display.BitmapData;
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;
	
	/** 
	 * The public interface for asynchronous image encoders.
 	 * @langversion 3.0
	 * @playerversion Flash 9
	 * @playerversion AIR 1.5
	 */
	public interface IAsyncImageEncoder extends IEventDispatcher
	{
		/**
		 * Starts encoding.
		 * 
		 * @param source The BitmapData object to encode. Encoder clones BitmapData, so original does not need to be retained while encoding occurs.
		 * @param frameTime Number of milliseconds to spend processing on each frame. 
		 */
		function start(source:BitmapData, frameTime:int=20):void
		
		/**
		 * Halts the encoding.
		 */
		function stop():void
		
		/**
		 * Clears any encoded bytes, freeing memory.
		 */
		function dispose():void
		
		/**
		 * If <code>true</code>, the encoder is active. If <code>false</code>, the encoder has finished or has been stopped.
		 */
		function get isRunning():Boolean
		
		/**
		 * If encoder has finished, returns the encoded bytes.
		 * 
		 * <p>If encoder has been stopped, returns any bytes that have been encoded.</p>
		 * <p>If encoder is currently running or has never been run, returns <code>null</code>.</p>
		 */		
		function get encodedBytes():ByteArray
	}
}