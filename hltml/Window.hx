/*
 * Copyright (c) 2015-2024, Nicolas Cannasse
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
 * IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
package hltml;

class Window extends hxd.App {

	static var inst : Window;

	var nodes : Map<Int,h2d.Object> = [];
	var byIdMap : Map<String, Array<Element>> = [];
	var root : hltml.Element;
	var style : h2d.domkit.Style;
	var debug : Bool;
	var css : Map<String,hxd.res.Resource> = [];

	public function new(debug) {
		inst = this;
		this.debug = debug;
		super();
		style = new h2d.domkit.Style();
		style.allowInspect = debug;
	}

	public function getRoot() {
		return root;
	}

	public function loadCSS( path : String ) {
		var res = css.get(path);
		var prev = res != null;
		if( res != null )
			style.unload(res);
		var res = hxd.res.Any.fromBytes(path,sys.io.File.getBytes(path));
		css.set(path, res);
		style.load(res);
		if( prev )
			@:privateAccess style.onChange(); // trigger warnings
	}

	override function init() {
		root = hltml.Element.create("div");
		s2d.addChild(root.element);
		style.addObject(root.element);
		onReady();
	}


	override function update(dt:Float) {
		style.sync(dt);
	}

	public dynamic function onReady() {
	}

}
