package hltml;

#if !macro

class HtmlElement extends h2d.Flow implements h2d.domkit.Object {

	public var events : Map<String,Event -> Void>;
	var element : Element;

	override function set_enableInteractive(b) {
		super.set_enableInteractive(b);
		if( interactive != null ) {
			interactive.onOver = function(_) {
				dom.hover = true;
			}
			interactive.onOut = function(_) {
				dom.hover = false;
			}
			interactive.onPush = function(_) {
				dom.active = true;
			}
			interactive.onRelease = interactive.onReleaseOutside = function(_) {
				dom.active = false;
			}
			interactive.onClick = function(e) triggerEvent("click",e);
		}
		return b;
	}

	public function triggerEvent(name,e:hxd.Event) {
		if( events == null ) return;
		var callb = events.get(name);
		if( callb == null ) return;
		var ev = new Event();
		ev.target = element;
		callb(ev);
	}

}

class Div extends HtmlElement {
}

class Table extends HtmlElement {
}

class Td extends HtmlElement {
}

class Tr extends HtmlElement {
}

class Th extends HtmlElement {
}

class Thead extends HtmlElement {
}

class Tbody extends HtmlElement {
}

class HtmlInput extends HtmlElement {
}

class I extends HtmlElement {
}

class A extends HtmlElement {
}

class Span extends HtmlElement {
}

class Br extends HtmlElement {
}


#else

class Components {
	static function init() {
		domkit.Macros.registerComponentsPath("hltml.$");
		domkit.Macros.registerComponentsPath("hltml.Components.$");
	}
}

#end