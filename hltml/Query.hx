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

class Query {

	var query : String;
	var pos = 0;
	public var id(default,null) : Null<String>;
	var classes : Array<String>;
	var name : Null<String>;
	var attrib : { name : String, value : String };
	var mode : String; // :focus, :visible etc.

	public function new( q : String ) {
		this.query = q;

		function unexpected() {
			throw "Unexpected '" + query.charAt(pos - 1) + "' in '" + query + "'";
		}

		while( true ) {
			var c = nextChar();
			if( StringTools.isEof(c) ) break;
			switch( c ) {
			case '#'.code:
				id = readIdent();
			//case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				// skip
			case '.'.code:
				if( classes == null ) classes = [];
				classes.push(readIdent());
			case '['.code:
				var attr = readIdent();
				if( nextChar() != '='.code )
					unexpected();
				var value = readIdent();
				if( nextChar() != ']'.code )
					unexpected();
				this.attrib = { name : attr, value : value };
			case ':'.code:
				mode = readIdent();
			default:
				if( (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) ) {
					pos--;
					name = readIdent();
				} else
					unexpected();
			}
		}
	}

	function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function readIdent() {
		var s = new StringBuf();
		while( true ) {
			var c = nextChar();
			if( (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code || c == '-'.code )
				s.addChar(c);
			else {
				pos--;
				break;
			}
		}
		return s.toString();
	}

	public function match( e : Element ) {

		if( name != null && e.nodeName != name )
			return false;

		if( id != null ) {
			var ok = false;
			for( a in e.attributes )
				if( a.name == "id" && a.value == id ) {
					ok = true;
					break;
				}
			if( !ok ) return false;
		}
		if( classes != null ) {
			for( c in classes ) {
				if( e.classes.indexOf(c) < 0 )
					return false;
			}
		}
		if( attrib != null ) {
			var found = false;
			for( a in e.attributes )
				if( a.name == attrib.name ) {
					found = a.value == attrib.value;
					break;
				}
			if( !found )
				return false;
		}

		if( mode != null )
			return false; // TODO : implement

		return true;
	}

}