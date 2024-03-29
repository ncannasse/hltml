package hide;

class Ide extends hide.tools.IdeData {

	static var DEBUG_PATH = "d:/projects/northgard";

	public var localStorage = new hltml.Storage();

	var window : hltml.Window;

	public function start() {
		var cwd = Sys.getCwd();
		var prj = cwd;
		if( DEBUG_PATH != null )
			prj = DEBUG_PATH;
		initConfig(prj);
		setProject(prj);
		loadDatabase();
		window = new hltml.Window(DEBUG_PATH != null);
		var css = cwd+"style.css";
		window.loadCSS(css);
		fileWatcher.register(css, function() {
			window.loadCSS(css);
		});
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

	public function createElement( kind : String ) {
		return hltml.Element.create(kind);
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
