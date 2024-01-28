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

class Client {

	static var inst : Client;

	var j : JQuery;
	var doms : Map<Int,Dom>;
	var root : Dom;
	var eventID : Int = 0;
	var events : Map<Int,Event -> Void>;
	var byIdMap : Map<String, Array<Dom>>;
	var serializer : hxbit.Serializer;

	function new() {
		inst = this;
		doms = new Map();
		root = new Dom();
		byIdMap = new Map();
		doms.remove(root.id);
		root.id = 0;
		doms.set(root.id, root);
		events = new Map();
		j = new JQuery(root);
		serializer = new hxbit.Serializer();
	}

	public function getRoot() {
		return root;
	}

	public inline function J( ?elt : Dom, ?query : String ) {
		return new JQuery(elt, query);
	}

	public function createDom( name : String ) {
		var d = new Dom();
		d.nodeName = name;
		send(Create(d.id, name));
		return d;
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

	function syncDom() {
		for( a in root.attributes )
			send(SetAttr(root.id, a.name, a.value));
		for( e in root.events )
			send(Event(root.id, e.name, e.id));
		for( d in doms )
			d.id = -d.id;
		for( d in doms )
			syncDomRec(d);
	}

	function syncDomRec( d : Dom ) {
		if( d.id >= 0 ) return;
		d.id = -d.id;
		if( d.parent != null ) syncDomRec(d.parent);
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
			syncDomRec(c);
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
						e.target = doms.get(props.target);
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
			var d = doms.get(id);
			if( d != null ) d.setAttr("value", v);
		case Done(eid):
			events.remove(eid);
		}
	}

}
