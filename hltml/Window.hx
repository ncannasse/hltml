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

class HTMLElement extends h2d.Flow implements h2d.domkit.Object {
}

private class App extends hxd.App {

	var window : Window;

	public function new(window) {
		this.window = window;
		super();
	}

	override function init() {
		@:privateAccess window.ready();
	}

	override function update(dt:Float) {
		super.update(dt);
	}

}

private class BaseClient {

	var j : JQuery;
	var elements : Map<Int,Element>;
	var root : Element;
	var eventID : Int = 0;
	var events : Map<Int,Event -> Void>;
	var byIdMap : Map<String, Array<Element>>;
	var serializer : hxbit.Serializer;

	function new() {
		elements = new Map();
		root = new Element();
		byIdMap = new Map();
		elements.remove(root.id);
		root.id = 0;
		elements.set(root.id, root);
		events = new Map();
		j = new JQuery(root);
		serializer = new hxbit.Serializer();
	}

	public function getRoot() {
		return root;
	}

	public inline function J( ?elt : Element, ?query : String ) {
		return new JQuery(elt, query);
	}

	public function createElement( name : String ) {
		var e = new Element();
		e.nodeName = name;
		send(Create(e.id, name));
		return e;
	}

	public function send( msg : Message ) {
		sendBytes(encodeMessage(msg));
	}

	function encodeMessage(msg:Message) {
		serializer.begin();
		(null : hxbit.Serializable.SerializableEnum<Message>).serialize(serializer, msg);
		return serializer.end();
	}

	function decodeAnswer( bytes : haxe.io.Bytes ) {
		serializer.setInput(bytes, 0);
		var a = (null : hxbit.Serializable.SerializableEnum<Answer>).unserialize(serializer);
		serializer.setInput(null, 0);
		return a;
	}

	function sendBytes( b : haxe.io.Bytes ) {
	}

	public function allocEvent( e : Event -> Void ) {
		var id = eventID++;
		events.set(id, e);
		return id;
	}

	public function onKey( e : Event ) {
	}

	function syncElement() {
		for( a in root.attributes )
			send(SetAttr(root.id, a.name, a.value));
		for( e in root.events )
			send(Event(root.id, e.name, e.id));
		for( d in elements )
			d.id = -d.id;
		for( d in elements )
			syncElementRec(d);
	}

	function syncElementRec( d : Element ) {
		if( d.id >= 0 ) return;
		d.id = -d.id;
		if( d.parent != null ) syncElementRec(d.parent);
		if( d.nodeName == null ) {
			send(CreateText(d.id, d.nodeValue, d.parent == null ? null : d.parent.id));
			return;
		}
		send(Create(d.id, d.nodeName, d.attributes.length == 0 ? null : d.attributes));
		if( d.parent != null )
			send(Append(d.id, d.parent.id));
		if( d.getAttr("dock") != null )
			send(Special(d.id,"dock",[]));
		for( c in d.childs )
			syncElementRec(c);
		for( e in d.events )
			send(Event(d.id, e.name, e.id));
	}

	function handle( msg : Answer ) {
		switch( msg ) {
		case Event(id, props):
			var e = new Event();
			if( props != null )
				for( f in Reflect.fields(props) )
					switch( f ) {
					case "target":
						e.target = elements.get(props.target);
					default:
						Reflect.setField(e, f, Reflect.field(props, f));
					}
			if( id < 0 )
				onKey(e);
			else {
				var f = events.get(id);
				if( f != null )
					f(e);
			}
		case SetValue(id, v):
			var d = elements.get(id);
			if( d != null ) d.setAttr("value", v);
		case Done(eid):
			events.remove(eid);
		}
	}

}

class Window extends BaseClient {

	static var inst : Window;

	var app : App;
	var nodes : Map<Int,h2d.Object> = [];
	var unknownAttrs : Map<String,Bool> = [];

	public function new() {
		inst = this;
		super();
		app = new App(this);
	}

	function ready() {
		var fl = createObject("div");
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

	function createObject( name : String ) : h2d.Object {
		return new HTMLElement();
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
			var o = createObject(name);
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
