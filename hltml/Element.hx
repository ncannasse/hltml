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

import hltml.Components;

class ElementClassList {
	var elt : Element;
	public function new(elt) {
		this.elt = elt;
	}
	public function add( cl : String ) {
	}
	public function toggle( cl : String, set : Bool ) {
	}
	public function remove( cl : String ) {
	}
}

@:allow(hltml.JQuery)
@:allow(hltml.Query)
@:allow(hltml.Window)
class Element {

	static var window(get,never) : Window;
	public var nodeName(default, null) : String;
	public var nodeValue(default, null) : String;
	public var numChildren(get, never) : Int;
	var element : HtmlElement;
	var parent(default,set) : Null<Element>;
	var children : Array<Element> = [];
	var attributes : Array<{ name : String, value : String }> = [];
	var data : Array<{ name : String, value : Dynamic }>;
	var clientID(default, set) : String;
	var dom(get,never) : domkit.Properties<h2d.Object>;
	public var parentElement(get,never) : Element;

	function new() {
	}

	static inline function get_window() return @:privateAccess Window.inst;

	inline function get_numChildren() return children.length;
	inline function get_parentElement() return parent;
	inline function get_dom() return element.dom;

	@:access(hltml.Window)
	function set_clientID(id) {
		if( clientID != null ) {
			var ids = window.byIdMap.get(clientID);
			ids.remove(this);
			if( ids.length == 0 ) window.byIdMap.remove(clientID);
		}
		clientID = id;
		if( id != null ) {
			var ids = window.byIdMap.get(id);
			if( ids == null ) {
				ids = [];
				window.byIdMap.set(id, ids);
			}
			ids.push(this);
		}
		return id;
	}

	function set_parent(p:Element) {

		var pchck = p;
		while( pchck != null ) {
			if( pchck == this ) throw "Recursive parent";
			pchck = pchck.parent;
		}

		if( parent != null ) parent.children.remove(this);
		if( p != null ) {
			p.children.push(this);
			p.element.addChild(element);
		} else
			element.remove();

		parent = p;

		var id = getAttr("id");
		if( id != null )
			clientID = @:privateAccess element.allocated ? id : null;

		return p;
	}

	public function clear() {
		while( numChildren > 0 )
			children[0].remove();
	}

	public function remove() {
		if( parent != null ) {
			parent.children.remove(this);
			parent = null;
		}
		element.remove();
	}

	public function unbindEvents( rec = false ) {
		if( rec ) {
			for( e in children )
				e.unbindEvents(true);
		}
	}

	function mkEvent( e : hxd.Event ) : hltml.Event {
		var ev = new Event();
		ev.target = this;
		return ev;
	}

	function bindEvent( event : String, callb : Event -> Void ) {
		element.enableInteractive = true;
		if( element.events == null ) element.events = new Map();
		element.events.set(event, callb);
	}

	function unbindEvent( event : String ) {
		element.events.remove(event);
	}

	public function getAttr( name : String ) {
		for( a in attributes )
			if( a.name == name )
				return a.value;
		return null;
	}

	static var unknowns : Map<String,Bool> = [];
	static function unknown( type, name, ?value ) {
		if( !unknowns.exists(type+"."+name) ) {
			unknowns.set(type+"."+name, true);
			trace("Unknown "+type+" "+name+(value == null ? "" : "="+value));
		}
	}
	static function unsupported( ?pos : haxe.PosInfos ) {
		unknown("implementation", pos.methodName);
	}

	function setAttr( name : String, value : String ) {
		var found = false;
		for( a in attributes )
			if( a.name == name ) {
				if( value == null )
					attributes.remove(a);
				else
					a.value = value;
				found = true;
				break;
			}
		if( !found && value != null )
			attributes.push({ name : name, value : value });

		switch( name ) {
		case "name":
			element.name = name;
		case "class":
			dom.setClasses(value);
		case "href" if( value == "#" ):
			// ignore
		case "index", "tabindex":
			// ignore
		default:
			unknown("Attribute", name, value);
		}
	}

	function getStyle( st : String ) : String {
		return switch( st ) {
		case "display":
			element.visible ? "" : "none";
		default:
			trace(nodeName, st);
			null;
		}
	}

	function setStyle( st : String, v : String ) {
		switch( st ) {
		case "display":
			element.visible = v != "none";
		default:
			trace(nodeName, st, v);
		}
	}

	// ---- HTML API ---

	public var classList(get,null) : ElementClassList;
	public var className(get,set) : String;
	public var innerHTML(never,set) : String;
	public var innerText(get,set) : String;
	public var textContent(get,set) : String;
	public var title(never,set) : String;
	public var offsetHeight(get,never) : Int;

	public var oncontextmenu(default,set) : Event -> Void;

	function get_offsetHeight() {
		return 0;
	}

	function get_classList() {
		if( classList == null )
			classList = new ElementClassList(this);
		return classList;
	}

	function get_className() {
		return [for( c in element.dom.getClasses() ) c.toString()].join(" ");
	}

	function set_className(v:String) {
		setAttr("class", v);
		return v;
	}

	function set_oncontextmenu(f) {
		if( f == null ) {
			if( oncontextmenu != null )
				unbindEvent("menu");
		} else if( oncontextmenu == null )
			bindEvent("menu", function(e) this.oncontextmenu(e));
		oncontextmenu = f;
		return f;
	}

	public function addEventListener( event : String, callb : Event -> Void ) {
		bindEvent(event, callb);
	}

	public function removeAttribute( attr : String ) {
		setAttr(attr, null);
	}

	public function appendChild( e : Element ) {
		if( e != null ) e.parent = this;
	}

	function set_innerHTML(v:String) {
		clear();
		new JQuery(v).appendTo(new JQuery(this));
		return v;
	}

	function get_textContent() {
		return nodeValue ?? "";
	}

	function set_textContent(v:String) {
		clear();
		nodeValue = v;
		createText(v, this);
		return v;
	}

	function get_innerText() {
		return textContent;
	}

	function set_innerText(v:String) {
		return textContent = v;
	}

	function set_title(v:String) {
		setAttr("title", v);
		return v;
	}

	public function scrollIntoViewIfNeeded() {
		unsupported();
	}

	public function click() {
		element.triggerEvent("click", new hxd.Event(ERelease,0,0));
	}

	public static function createHTML( str : String ) {
		if( ~/^<[A-Za-z]+>$/.match(str) )
			return create(str.substr(1,str.length-2));
		if( str.charCodeAt(str.length-1) == ">".code && str.charCodeAt(str.length-2) == '"'.code )
			str = str.substr(0,str.length-1)+"/>";
		var x = try Xml.parse(str) catch( e : Dynamic ) throw "Invalid XML "+str;
		return createXML(x, null);
	}

	static function createXML( x : Xml, parent : Element ) {
		switch( x.nodeType ) {
		case Document:
			var d = null;
			for( x in x )
				d = createXML(x, parent);
			return d;
		case Element:
			var e = create(x.nodeName);
			e.nodeName = x.nodeName;
			for( a in x.attributes() )
				e.setAttr(a, x.get(a));
			if( parent != null )
				e.parent = parent;
			for( x in x )
				createXML(x, e);
			return e;
		case PCData, CData:
			createText(x.nodeValue, parent);
			return null;
		case ProcessingInstruction, DocType, Comment:
			// nothing
			return null;
		}
	}

	public static function createText( text : String, parent : Element ) {
		var t = new h2d.HtmlText(hxd.res.DefaultFont.get(), parent.element);
		t.dom = domkit.Properties.create("html-text", t);
		t.text = text;
		return t;
	}

	public static function create( name : String ) {
		var e = new Element();
		e.nodeName = name;
		if( name == "input" )
			name = "html-input";
		var comp = domkit.Component.get(name, true);
		if( comp != null )
			e.element = comp.make([], null);
		else {
			unknown("Component", name);
			e.element = new HtmlElement();
		}
		@:privateAccess e.element.element = e;
		return e;
	}

}