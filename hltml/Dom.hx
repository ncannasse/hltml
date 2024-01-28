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

class DomClassList {
	var dom : Dom;
	public function new(dom) {
		this.dom = dom;
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
@:allow(hltml.Client)
class Dom {

	static var UID = 0;
	static var client(get,never) : Client;

	public var nodeName(default, null) : String;
	public var nodeValue(default, null) : String;
	public var numChildren(get, never) : Int;
	var id : Int;
	var attributes : Array<{ name : String, value : String }>;
	var classes : Array<String>;
	var parent(default,set) : Null<Dom>;
	var childs : Array<Dom>;
	var events : Array<{ id : Int, name : String, callb : Event -> Void }>;
	var style : Array<{ name : String, value : String }>;
	var clientID(default, set) : String;
	public var parentElement(get,never) : Dom;

	public function new() {
		id = UID++;
		@:privateAccess client.doms.set(id, this);
		events = [];
		attributes = [];
		classes = [];
		childs = [];
		style = [];
	}

	static inline function get_client() return @:privateAccess Client.inst;

	inline function get_numChildren() return childs.length;
	inline function get_parentElement() return parent;

	inline function send(msg) {
		if( id >= 0 ) client.send(msg);
	}

	@:access(hltml.Client)
	function set_clientID(id) {
		if( clientID != null ) {
			var ids = client.byIdMap.get(clientID);
			ids.remove(this);
			if( ids.length == 0 ) client.byIdMap.remove(clientID);
		}
		clientID = id;
		if( id != null ) {
			var ids = client.byIdMap.get(id);
			if( ids == null ) {
				ids = [];
				client.byIdMap.set(id, ids);
			}
			ids.push(this);
		}
		return id;
	}

	function set_parent(p:Dom) {

		var pchck = p;
		while( pchck != null ) {
			if( pchck == this ) throw "Recursive parent";
			pchck = pchck.parent;
		}

		if( parent != null ) parent.childs.remove(this);
		if( p != null ) {
			if( id < 0 ) throw "Can't add disposed node";
			if( p.id < 0 ) throw "Can't add to a disposed node";
			p.childs.push(this);
		}

		parent = p;

		var id = getAttr("id");
		if( id != null )
			clientID = onStage() ? id : null;

		return p;
	}

	public function reset() {
		if( (nodeName != null || nodeValue == "") && childs.length == 0 )
			return;
		send(Reset(id));
		if( nodeName == null )
			nodeValue = "";
		var cold = childs;
		childs = [];
		for( c in cold )
			c.dispose();
	}

	public function dispose() {
		if( id < 0 ) return;
		parent = null;
		if( nodeName != null ) nodeValue = "";
		@:privateAccess client.doms.remove(id);
		send(Dispose(id, events.length == 0 ? null : [for( e in events ) e.id]));
		id = -12345678;
		if( events.length > 0 ) events = [];
		var cold = childs;
		childs = [];
		for( c in cold )
			c.dispose();
	}

	public function remove() {
		if( id < 0 ) return;
		send(Remove(id));
		if( parent != null ) {
			parent.childs.remove(this);
			parent = null;
		}
	}

	public function countRec() {
		var n = 1;
		for( c in childs )
			n += c.countRec();
		return n;
	}

	public function unbindEvents( rec = false ) {
		if( events.length > 0 ) {
			send(Unbind([for( e in events ) e.id]));
			events = [];
		}
		if( rec )
			for( e in childs )
				e.unbindEvents(true);
	}

	function bindEvent( event : String, callb : Event -> Void ) {
		var eid = client.allocEvent(callb);
		events.push( { id : eid, name : event, callb : callb } );
		send(Event(id, event, eid));
	}

	function unbindEvent( name : String ) {
		for( s in events )
			if( s.name == name ) {
				events.remove(s);
				send(Unbind([s.id]));
				return;
			}
	}

	public function getStyle( name : String ) {
		for( s in style )
			if( s.name == name )
				return s.value;
		return null;
	}

	function updatedClasses() {
		var classAttr = classes.length == 0 ? null : classes.join(" ");
		for( a in attributes )
			if( a.name == "class" ) {
				if( classAttr == null )
					attributes.remove(a);
				else
					a.value = classAttr;
				return;
			}
		if( classAttr != null )
			attributes.push( { name : "class", value : classAttr } );
	}

	function setStyle( name : String, value : String ) {
		for( s in style )
			if( s.name == name ) {
				if( value == null )
					style.remove(s);
				else
					s.value = value;
				value = null;
				break;
			}
		if( value != null )
			style.push( { name : name, value : value } );

		// sync attribute
		var styleAttr = [for( s in style ) s.name+" : " + s.value].join(";");
		for( a in attributes )
			if( a.name == "style" ) {
				a.value = styleAttr;
				return;
			}
		attributes.push( { name : "style", value : styleAttr } );
	}


	public function getAttr( name : String ) {
		for( a in attributes )
			if( a.name == name )
				return a.value;
		return null;
	}

	function onStage() {
		var p = this;
		var root = client.getRoot();
		while( p != null ) {
			if( p == root ) return true;
			p = p.parent;
		}
		return false;
	}

	// should only be called by JQuery ! (don't send messsage)
	function setAttr( name : String, value : String)  {

		switch( name ) {
		case "class":
			classes = value == null ? [] : value.split(" ");
		case "style":
			style = [];
			if( value != null )
				for( pair in value.split(";") ) {
					var parts = pair.split(":");
					if( parts.length != 2 ) continue;
					style.push({ name : StringTools.trim(parts[0]), value : StringTools.trim(parts[1]) });
				}
		case "id":
			if( onStage() )
				clientID = value;
		case "dock":
			send(Special(id, "dock", []));
		default:
		}

		for( a in attributes )
			if( a.name == name ) {
				if( value == null )
					attributes.remove(a);
				else
					a.value = value;
				return;
			}
		if( value != null )
			attributes.push( { name: name, value:value } );
	}

	// ---- HTML API ---

	public var classList(get,null) : DomClassList;
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
			classList = new DomClassList(this);
		return classList;
	}

	function get_className() {
		return "";
	}

	function set_className(v:String) {
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

	public function removeAttribute( str : String ) {
	}

	public function appendChild( e : Dom ) {
	}

	function set_innerHTML(v:String) {
		reset();
		new JQuery(v).appendTo(new JQuery(this));
		return v;
	}

	function get_textContent() {
		return nodeValue ?? "";
	}

	function set_textContent(v:String) {
		reset();
		nodeValue = v;
		return v;
	}

	function get_innerText() {
		return textContent;
	}

	function set_innerText(v:String) {
		return textContent = v;
	}

	function set_title(v:String) {
		// TODO
		return v;
	}

	public function click() {
		throw "TODO";
	}

	public static function createHTML( str : String ) {
		if( ~/^<[A-Za-z]+>$/.match(str) )
			return client.createDom(str.substr(1,str.length-2));
		if( str.charCodeAt(str.length-1) == ">".code && str.charCodeAt(str.length-2) == '"'.code )
			str = str.substr(0,str.length-1)+"/>";
		var x = try Xml.parse(str) catch( e : Dynamic ) throw "Invalid XML "+str;
		return createXML(x, null);
	}

	static function createXML( x : Xml, parent : Dom ) {
		switch( x.nodeType ) {
		case Document:
			var d = null;
			for( x in x )
				d = createXML(x, parent);
			return d;
		case Element:
			var d = new Dom();
			d.nodeName = x.nodeName;
			for( a in x.attributes() )
				d.setAttr(a, x.get(a));
			client.send(Create(d.id, d.nodeName, d.attributes));
			if( parent != null ) {
				d.parent = parent;
				client.send(Append(d.id, parent.id));
			}
			for( x in x )
				createXML(x, d);
			return d;
		case PCData, CData:
			var d = new Dom();
			d.nodeValue = x.nodeValue;
			d.parent = parent;
			client.send(CreateText(d.id, d.nodeValue, parent == null ? -1 : parent.id));
			return d;
		case ProcessingInstruction, DocType, Comment:
			// nothing
			return null;
		}
	}

}