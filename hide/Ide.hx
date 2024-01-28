package hide;

class Ide extends hide.tools.IdeData {

	public var localStorage = new hltml.Storage();

	var window : hltml.Window;

	public function start() {
		var cwd = Sys.getCwd();
		cwd = "d:/projects/northgard";
		initConfig(cwd);
		setProject(cwd);
		loadDatabase();
		window = new hltml.Window();
		window.onReady = function() {
			var view = new hide.view.CdbTable();
			@:privateAccess view.element = new Element(window.getRoot());
			view.rebuild();
		}
	}

	public function confirm( msg : String ) {
		return false;
	}

	public function ask( text : String, ?defaultValue = "" ) {
		return null;
	}

	public function message( msg : String ) {
	}

	public function quickError( msg : String ) {
		throw msg;
	}

	public function createElement( kind : String ) : Element.HTMLElement {
		return window.createElement(kind);
	}

	public function setClipboard( str : String ) {
	}

	public function getClipboard() : String {
		return null;
	}

	public function runCommand(cmd, ?callb:String->Void ) {
		if( callb != null ) callb("Not implemented");
	}

	public function open( component : String, state : Dynamic, ?onCreate : hide.ui.View<Dynamic> -> Void, ?onOpen : hide.ui.View<Dynamic> -> Void ) {
	}

	public static var inst : Ide;
	static function main() {
		inst = new Ide();
		inst.start();
	}
}
