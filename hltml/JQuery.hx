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

@:forward
abstract JQueryOrString(JQuery) from JQuery to JQuery {
	@:from static function fromString(s:String) : JQueryOrString {
		var jq = new JQuery();
		var e = new Element();
		e.nodeValue = s;
		@:privateAccess jq.sel.push(e);
		return jq;
	}
	@:to function to() : String {
		return this == null ? null : @:privateAccess this.sel[0].nodeValue;
	}

}

abstract AttributeValue(Dynamic) from Int from String {
}

class JQuery {

	var sel : Array<Element>;
	public var length(get, never) : Int;

	public function new(?elt:Element,?query:String) {
		if( elt != null )
			sel = [elt];
		else if( query == null ) {
			sel = [];
		} else if( query.charCodeAt(0) == "<".code ) {
			var dom = Element.createHTML(query);
			sel = dom == null ? [] : [dom];
		} else {
			sel = [];
			var r = new Query(query);
			var window = @:privateAccess Window.inst;
			if( r.id != null ) {
				var ids = @:privateAccess window.byIdMap.get(r.id);
				if( ids != null )
					for( d in ids )
						addRec(r, d);
			} else
				addRec(r, @:privateAccess window.root);
		}
	}

	function get_length() {
		return sel.length;
	}

	public function query( ?elt : Element, ?query : String ) {
		return new JQuery(elt, query);
	}

	public inline function get( id = 0 ) {
		return sel[id];
	}

	public function hasClass( name : String ) {
		var e = get();
		return e == null ? false : e.dom.hasClass(name);
	}

	public function addClass( name : String ) {
		for( s in sel )
			s.dom.addClass(name);
		return this;
	}

	public function text( t : String ) {
		for( s in sel ) {
			s.clear();
			s.textContent = t;
		}
		return this;
	}

	public function html( html : String ) {
		var x = try Xml.parse(html) catch( e : Dynamic ) throw "Failed to parse " + html + "(" + e+")";
		for( s in sel ) {
			s.clear();
			if( html.length > 0 ) Element.createXML(x,s);
		}
		return this;
	}

	public function select() {
		trigger("select");
		return this;
	}

	public function click( ?e : Event -> Void ) {
		if( e == null ) trigger("click") else on("click", e);
		return this;
	}

	public function mousedown( ?e : Event -> Void ) {
		if( e == null ) trigger("mousedown") else on("mousedown", e);
		return this;
	}

	public function mouseup( ?e : Event -> Void ) {
		if( e == null ) trigger("mouseup") else on("mouseup", e);
		return this;
	}

	public function change( ?e : Event -> Void ) {
		if( e == null ) trigger("change") else on("change", e);
		return this;
	}

	public function keydown( ?e : Event -> Void ) {
		if( e == null ) trigger("keydown") else on("keydown", e);
		return this;
	}

	public function keypress( ?e : Event -> Void ) {
		if( e == null ) trigger("keypress") else on("keypress", e);
		return this;
	}

	public function keyup( ?e : Event -> Void ) {
		if( e == null ) trigger("keyup") else on("keyup", e);
		return this;
	}

	public function focus( ?e : Event -> Void ) {
		if( e == null ) trigger("focus") else on("focus", e);
		return this;
	}

	public function blur( ?e : Event -> Void ) {
		if( e == null ) trigger("blur") else on("blur", e);
		return this;
	}

	public function dblclick( ?e : Event -> Void ) {
		if( e == null ) trigger("dblclick") else on("dblclick", e);
		return this;
	}

	public function trigger( event : String ) {
	}

	public function val( value : Dynamic ) {
		var vstr = value == null ? null : "" + value;
		for( s in sel )
			s.setAttr("value", vstr);
		return this;
	}

	public function getValue() {
		if( sel.length == 0 )
			return null;
		return get().getAttr("value");
	}

	public function on( event : String, e : Event -> Void ) {
		for( s in sel )
			s.bindEvent(event, e);
	}

	public function off( ?event : String ) {
		for( s in sel ) {
		}
		return this;
	}

	public function find( query : String ) {
		var j = new JQuery();
		var r = new Query(query);
		for( s in sel )
			j.addRec(r, s);
		return j;
	}

	public function not( ?query : String, ?exclude : JQuery ) {
		var j = new JQuery();
		var r = query == null ? null : new Query(query);
		for( s in sel )
			if( (r != null ? !r.match(s) : exclude.sel.indexOf(s) < 0)  )
				j.sel.push(s);
		return j;
	}

	public function filter( query : String ) {
		var j = new JQuery();
		var r = new Query(query);
		for( s in sel )
			if( r.match(s) )
				j.sel.push(s);
		return j;
	}

	public function first() {
		var j = new JQuery();
		if( sel.length > 0 )
			j.sel.push(sel[0]);
		return j;
	}

	public function last() {
		var j = new JQuery();
		if( sel.length > 0 )
			j.sel.push(sel[sel.length - 1]);
		return j;
	}

	public function next( ?query : String ) {
		var j = new JQuery();
		var r = new Query(query);
		trace("TODO");
		return j;
	}


	public function is( query : String ) {
		var r = new Query(query);
		for( s in sel )
			if( r.match(s) )
				return true;
		return false;
	}

	public function children( ?query : String ) {
		var j = new JQuery();
		if( query == null ) {
			for( s in sel )
				for( c in s.children )
					j.sel.push(c);
		} else {
			var q = new Query(query);
			for( s in sel )
				for( c in s.children )
					if( q.match(c) )
						j.sel.push(c);
		}
		return j;
	}

	function addRec( q : Query, e : Element ) {
		if( q.match(e) )
			sel.push(e);
		for( e in e.children )
			addRec(q, e);
	}

	public function append( j : JQuery ) {
		j.appendTo(this);
		return this;
	}

	public function appendTo( j : JQuery ) {
		var p = j.sel[0];
		if( p != null )
			for( s in sel )
				s.parent = p;
		return this;
	}

	public function prepend( j : JQuery ) {
		j.prependTo(this);
		return this;
	}

	public function prependTo( j : JQuery ) {
		var p = j.sel[0];
		if( p != null )
			for( s in sel ) {
				s.parent = p;
				s.parent.children.remove(s);
				s.parent.children.unshift(s);
				s.parent.element.addChildAt(s.element, 0);
			}
		return this;
	}

	public function data( tag : String, ?value : Dynamic ) : Dynamic {
		trace("TODO");
		return null;
	}

	public function insertAfter( j : JQuery ) {
		var e = j.sel[0];
		if( e != null ) {
			var p = e.parent;
			if( p != null ) {
				var pos = p.children.indexOf(e) + 1;
				for( s in sel ) {
					s.parent = p;
					p.children.remove(s);
					p.children.insert(pos, s);
					p.element.addChildAt(s.element, pos);
					pos++;
				}
			}
		}
		return this;
	}

	public function attr( a : String, ?val : AttributeValue ) : JQueryOrString {
		if( val == null ) {
			var s = sel[0];
			if( s == null )
				return null;
			for( at in s.attributes )
				if( at.name == a )
					return at.value;
			return null;
		}
		var val = Std.string(val);
		for( s in sel )
			s.setAttr(a, val);
		return this;
	}

	public function prop( p : String, val : Bool ) {
		if( !val )
			removeAttr(p);
		else
			attr(p, p);
		return this;
	}

	public function removeAttr( a : String ) {
		for( s in sel ) {
			if( s.getAttr(a) == null ) continue;
			s.setAttr(a, null);
		}
		return this;
	}

	public function getAttr( a : String ) {
		if( sel.length == 0 )
			return null;
		return get().getAttr(a);
	}

	public function style( s : String, ?val : String ) {
		if( val == null ) {
			if( sel.length == 0 )
				return null;
			return sel[0].getStyle(s);
		}
		for( d in sel )
			d.setStyle(s, val);
		return val;
	}

	public function remove() {
		for( s in sel ) {
			s.unbindEvents(true);
			s.remove();
		}
		return this;
	}

	public function detach() {
		for( s in sel )
			s.remove();
		return this;
	}

	public function removeClass( name : String ) {
		for( s in sel )
			s.dom.removeClass(name);
		return this;
	}

	public function toggleClass( name : String, ?state ) {
		for( s in sel )
			s.dom.toggleClass(name,state);
		return this;
	}

	public function toggle( ?show ) {
		for( s in sel ) {
			var d = (show != null ? show : s.getStyle("display") == "none") ? "" : "none";
			s.setStyle("display", d);
		}
		return this;
	}

	public function show() {
		toggle(true);
	}

	public function hide() {
		toggle(false);
	}

	public function empty() {
		for( s in sel )
			s.clear();
	}

	public function index( jq : JQuery ) {
		trace("TODO");
		return 0;
	}

	public function eq( i : Int ) {
		var j = new JQuery();
		if( sel.length > i )
			j.sel.push(sel[i]);
		return j;
	}

	public function parent() {
		var j = new JQuery();
		j.sel = [for( s in sel ) if( s.parent != null ) s.parent];
		return j;
	}

	public function elements() {
		return [for( s in sel ) new JQuery(s)].iterator();
	}

	public function iterator() {
		return sel.iterator();
	}

	public function contextmenu( f : Event -> Void ) {
		for( s in sel )
			s.oncontextmenu = f;
	}

	public function scrollTop( offset : Float ) {
	}

	public function slideDown( time : Float ) {
	}

	public function slideUp( time : Float, ?onEnd : Void -> Void ) {
		if( onEnd != null ) onEnd();
	}

}
