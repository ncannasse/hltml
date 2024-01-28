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

class Element extends h2d.Flow implements h2d.domkit.Object {
}

private class DomkitApp extends hxd.App {

	var client : DomkitClient;

	public function new(client) {
		this.client = client;
		super();
	}

	override function init() {
		@:privateAccess client.ready();
	}

	override function update(dt:Float) {
		super.update(dt);
	}

}

class DomkitClient extends Client {

	var app : DomkitApp;
	var nodes : Map<Int,h2d.Object> = [];
	var unknownAttrs : Map<String,Bool> = [];

	public function new() {
		super();
		app = new DomkitApp(this);
	}

	function ready() {
		var fl = createElement("div");
		app.s2d.addChild(fl);
		nodes.set(0, fl);
		onReady();
	}

	function setAttr( o : h2d.Object, name : String, value : String ) {
		switch( name ) {
		case "name":
			o.name = name;
		case "class":
			o.dom.setClasses(value);
		case "href" if( value == "#" ):
			// ignore
		default:
			if( !unknownAttrs.exists(name) ) {
				unknownAttrs.set(name, true);
				trace("Unknown attribute "+name+"="+value);
			}
		}
	}

	function createElement( name : String ) : h2d.Object {
		return new Element();
	}

	function setStyle( o : h2d.Object, st : String, v : String ) {
		switch( st ) {
		case "display":
			o.visible = v != "none";
		default:
			trace(o, st, v);
		}
	}

	override function send(msg:Message) {
		switch( msg ) {
		case Create(id,name,attr):
			var o = createElement(name);
			nodes.set(id, o);
			if( attr != null ) {
				for( a in attr )
					setAttr(o, a.name, a.value);
			}
		case AddClass(id, name):
			nodes.get(id).dom.addClass(name);
		case RemoveClass(id, name):
			nodes.get(id).dom.removeClass(name);
		case Append(id, to):
			nodes.get(to).addChild(nodes.get(id));
		case InsertAt(id, to, pos):
			nodes.get(to).addChildAt(nodes.get(id),pos);
		case CreateText(id, text, parent):
			var f = new h2d.HtmlText(hxd.res.DefaultFont.get());
			f.text = text;
			nodes.set(id, f);
			if( parent != null )
				nodes.get(parent).addChild(f);
		case SetStyle(id, st, val):
			var n = nodes.get(id);
			setStyle(n, st, val);
		case SetAttr(id, a, val):
			var n = nodes.get(id);
			setAttr(n, a, val);
		case Remove(id):
			var n = nodes.get(id);
			n.remove();
		default:
			var n = msg.getName();
			if( !unknownAttrs.exists(n) ) {
				unknownAttrs.set(n,true);
				trace("Unknown message "+msg);
			}
		}
	}

	public dynamic function onReady() {
	}

}