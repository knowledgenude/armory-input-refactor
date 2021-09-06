
package libs;

import kha.input.KeyCode;

import iron.App;

/*
	Refactored Input Class. Now it is more extendable and maintainable.
	Previously i guess it was impossible to decide whether to use or not mouse or surface in mobile. Now this can change.
	Fixed mouse movement influence after changing the cursor lock state.
	Improved way to set mouse hide / lock states. Now is just changing a variable.
	Improved performance. Now the started, down and released keys lists just stores its indexes and the keys are filtered by its string representation just when needed.
	Created a properly Surface class.
	Created Gyroscope class.
	Added blockMovement field to Mouse, Surface, Pen and Gamepad sticks
	Added enums for all inputs
*/

/*
	Add repeat keys
	Add combo keys
	Kha: Fix mouse movement influence after the cursor leave / enter the window.
	Make mouse "compatible" with surface depending on target and add pinch for wheel delta
	Add way to refer to keys trought string to keep compatibility (probably using virtual buttons for that)
	Handle left / right modifier keys
*/

/*
	Example usage of virtual button
		keyboard.setVirtual("my_key", "e");
		mouse.setVirtual("my_key", "left");
		// ...
		if (Input.getVirtualButton("my_key").started) {}
*/
class Input {
	static var keyboard: Null<Keyboard>;
	static var mouse: Null<Mouse>;
	static var pen: Null<Pen>;
	static var surface: Null<Surface>;
	static var accelerometer: Null<Accelerometer>;
	static var gyroscope: Null<Gyroscope>;

	static var gamepads: Null<haxe.ds.Vector<Null<Gamepad>>>;

	final startedKeys = new Array<Int>();
	final downKeys = new Array<Int>();
	final releasedKeys = new Array<Int>();

	function new() {
		App.notifyOnEndFrame(endFrame);
		App.notifyOnReset(reset);
	}

	public static function getKeyboard(): Keyboard {
		if (keyboard == null) keyboard = new Keyboard();
		return keyboard;
	}

	public static function getMouse(): Mouse {
		if (mouse == null) mouse = new Mouse();
		return mouse;
	}

	public static function getPen(): Pen {
		if (pen == null) pen = new Pen();
		return pen;
	}

	public static function getGamepad(index: Int): Null<Gamepad> {
		if (gamepads == null) gamepads = new haxe.ds.Vector<Null<Gamepad>>(4);

		var g = gamepads[index];
		if (g == null && index <= 4) gamepads[index] = new Gamepad(index);

		return g;
	}

	public static function getSurface(maxTouches: Int): Surface {
		if (surface == null) surface = new Surface(maxTouches);
		return surface;
	}

	public static function getAccelerometer(): Accelerometer {
		if (accelerometer == null) accelerometer = new Accelerometer();
		return accelerometer;
	}

	public static function getGyroscope(): Gyroscope {
		if (gyroscope == null) gyroscope = new Gyroscope();
		return gyroscope;
	}

	// Will use string parameters on this functions and move enums to another
	public inline function started(key = 0): Bool {
		return startedKeys.contains(key);
	}

	public inline function down(key = 0): Bool {
		return downKeys.contains(key);
	}

	public inline function released(key = 0): Bool {
		return releasedKeys.contains(key);
	}

	function keyDown(key: Int) {
		startedKeys.push(key);
		downKeys.push(key);
	}

	function keyUp(key: Int) {
		downKeys.remove(key);
		releasedKeys.push(key);
	}

	function endFrame() {
		startedKeys.resize(0);
		releasedKeys.resize(0);
	}

	function reset() {
		downKeys.resize(0);
		endFrame();
	}
}

class Keyboard extends Input {
	public function new() {
		super();

		var k = kha.input.Keyboard.get();
		if (k != null) k.notify(keyDown, keyUp);
	}
}

class Coords2D {
	public var x(default, null) = 0;
	public var y(default, null) = 0;
	var lastX = 0;
	var lastY = 0;
	public var movementX(default, null) = 0;
	public var movementY(default, null) = 0;
	public var moved(default, null) = false;
	public var viewX(get, null) = 0;
	public var viewY(get, null) = 0;
	public var blockMovement = false;

	public function new() {}

	public function setPos(x: Int, y: Int) {
		this.x = x;
		this.y = y;
	}

	public function setMovement(x: Int, y: Int) {
		movementX = x;
		movementY = y;
		moved = true;
	}

	public function displaceTo(x: Int, y: Int) {
		if (blockMovement) {
			setPos(x, y);
			return;
		}

		lastX = this.x;
		lastY = this.y;
		this.x = x;
		this.y = y;
		setMovement(this.x - lastX, this.y - lastY);
	}

	public inline function get_viewX() {
		return x - App.x();
	}

	public inline function get_viewY() {
		return y - App.y();
	}

	public function endFrame() {
		movementX = 0;
		movementY = 0;
		moved = false;
	}
}

class CoordsInput extends Input {
	final coords = new Coords2D();
	public var x(get, null): Int;
	public var y(get, null): Int;
	public var movementX(get, null): Int;
	public var movementY(get, null): Int;
	public var moved(get, null): Bool;
	public var viewX(get, null): Int;
	public var viewY(get, null): Int;
	public var blockMovement(get, set): Bool;

	public inline function get_x() { return coords.x; }
	public inline function get_y() { return coords.y; }
	public inline function get_movementX() { return coords.movementX; }
	public inline function get_movementY() { return coords.movementY; }
	public inline function get_moved() { return coords.moved; }
	public inline function get_viewX() { return coords.viewX; }
	public inline function get_viewY() { return coords.viewY; }
	public inline function get_blockMovement() { return coords.blockMovement; }
	public inline function set_blockMovement(value: Bool) { return coords.blockMovement = value; }

	override function endFrame() {
		super.endFrame();
		coords.endFrame();
	}
}

class Mouse extends CoordsInput {
	public var wheelDelta(default, null) = 0;
	public var locked(default, set) = false;
	public var hidden(default, set) = false;
	var ignoreMovement = false; // Prevent movement catching after change lock state

	public function new() {
		super();

		var m = kha.input.Mouse.get();
		if (m != null) m.notify(downListener, upListener, moveListener, wheelListener);

		// Reset on foreground state
		kha.System.notifyOnApplicationState(reset, null, null, null, null);
	}

	public function set_locked(locked: Bool) {
		var khaMouse = kha.input.Mouse.get();

		if (khaMouse.canLock()) {
			if (locked) {
				khaMouse.lock();
				ignoreMovement = this.locked = true;

			} else {
				khaMouse.unlock();
				this.locked = false;
			}
		}

		return this.locked;
	}

	public function set_hidden(hidden: Bool) {
		var khaMouse = kha.input.Mouse.get();

		if (hidden) {
			khaMouse.hideSystemCursor();
			this.hidden = true;
		
		} else {
			khaMouse.showSystemCursor();
			this.hidden = false;
		}

		return this.hidden;
	}

	function downListener(button: Int, x: Int, y: Int) {
		keyDown(button);
		coords.setPos(x, y);
	}

	function upListener(button: Int, x: Int, y: Int) {
		keyUp(button);
		coords.setPos(x, y);
	}

	function moveListener(x: Int, y: Int, movementX: Int, movementY: Int) {
		if (ignoreMovement) ignoreMovement = false;
		else if (!locked) coords.displaceTo(movementX, movementY);
		else coords.setMovement(movementX, movementY);
	}

	function wheelListener(wheelDelta: Int) {
		this.wheelDelta = wheelDelta;
	}

	override function endFrame() {
		super.endFrame();
		wheelDelta = 0;
	}
}

class Pen extends CoordsInput {
	public var pressure(default, null) = 0.0;

	public function new() {
		super();

		var p = kha.input.Pen.get();
		if (p != null) p.notify(downListener, upListener, moveListener);
	}

	function downListener(x: Int, y: Int, pressure: Float) {
		keyDown(0);
		coords.setPos(x, y);
		this.pressure = pressure;
	}

	function upListener(x: Int, y: Int, pressure: Float) {
		keyUp(0);
		coords.setPos(x, y);
		this.pressure = pressure;
	}

	function moveListener(x: Int, y: Int, pressure: Float) {
		this.pressure = pressure;
		coords.displaceTo(x, y);
	}
}

class Surface extends Input {
	public final touches: Array<Coords2D>;
	public var maxTouches(default, null): Int;

	public function new(maxTouches = 3) {
		super();

		var s = kha.input.Surface.get();
		if (s != null) kha.input.Surface.get().notify(touchStartListener, touchEndListener, moveListener);

		touches = new Array<Coords2D>();
		setMaxTouches(maxTouches);
	}

	public function getTouchCoords(touchIndex: Int): Null<Coords2D> {
		return touches[touchIndex];
	}

	public function setMaxTouches(maxTouches: Int): Int {
		if (maxTouches > touches.length) {
			for (i in touches.length...maxTouches) {
				touches.push(new Coords2D());
			}
		
		} else if (maxTouches < touches.length) {
			touches.resize(maxTouches);
		}

		return this.maxTouches = maxTouches;
	}

	function touchStartListener(touchIndex: Int, x: Int, y: Int) {
		if (touchIndex > maxTouches) return;

		keyDown(touchIndex);
		touches[touchIndex].setPos(x, y);
	}

	function touchEndListener(touchIndex: Int, x: Int, y: Int) {
		if (touchIndex > maxTouches) return;

		keyUp(touchIndex);
		touches[touchIndex].setPos(x, y);
	}

	function moveListener(touchIndex: Int, x: Int, y: Int) {
		if (touchIndex > maxTouches) return;

		touches[touchIndex].displaceTo(x, y);
	}

	override function endFrame() {
		super.endFrame();
		for (t in touches) {
			t.endFrame();
		}
	}
}

class Gamepad extends Input {
	public final index: Int;
	public final leftStick = new GamepadStick();
	public final rightStick = new GamepadStick();
	final pressures = new Array<Float>();

	public function new(index = 0) {
		super();

		var g = kha.input.Gamepad.get(index);
		if (g != null) g.notify(axisListener, buttonListener);

		this.index = index;
	}

	public inline function getPressure(button: Int): Float {
		var p = pressures[button];
		return p != null ? p : 0.0;
	}

	function axisListener(axis: Int, value: Float) {
		switch (axis) {
			case 0: leftStick.x = value;
			case 1: leftStick.y = value;
			case 2: rightStick.x = value;
			case 3: rightStick.y = value;
		}
	}

	function buttonListener(button: Int, pressure: Float) {
		if (pressure > 0.0) keyDown(button);
		else keyUp(button);

		pressures[button] = pressure;
	}

	override function endFrame() {
		super.endFrame();
		leftStick.endFrame();
		rightStick.endFrame();
	}
}

class GamepadStick {
	public var x(default, set) = 0.0;
	public var y(default, set) = 0.0;
	var lastX = 0.0;
	var lastY = 0.0;
	public var movementX(default, null) = 0.0;
	public var movementY(default, null) = 0.0;
	public var moved(default, null) = false;
	public var blockMovement = false;

	public function new() {}

	public function set_x(value: Float) {
		lastX = x;
		x = value;

		if (!blockMovement) {
			movementX = x - lastX;
			moved = true;
		}

		return x;
	}

	public function set_y(value: Float) {
		lastY = y;
		y = value;

		if (!blockMovement) {
			movementX = y - lastY;
			moved = true;
		}

		return y;
	}

	public function endFrame() {
		movementX = 0.0;
		movementY = 0.0;
		moved = false;
	}
}

class Sensor {
	public var x(default, null) = 0.0;
	public var y(default, null) = 0.0;
	public var z(default, null) = 0.0;

	function listener(x: Float, y: Float, z: Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Accelerometer extends Sensor {
	public function new() {
		var a = kha.input.Sensor.get(kha.input.SensorType.Accelerometer);
		if (a != null) a.notify(listener);
	}
}

class Gyroscope extends Sensor {
	public function new() {
		var g = kha.input.Sensor.get(kha.input.SensorType.Gyroscope);
		if (g != null) g.notify(listener);
	}
}

@:enum
abstract PenButton(Int) from Int to Int {
	var TIP;
}

@:enum
abstract MouseButton(Int) from Int to Int {
	var LEFT;
	var MIDDLE;
	var RIGHT;
}

@:enum
abstract XboxButton(Int) from Int to Int {
	var BUTTON_A;
	var BUTTON_B;
	var BUTTON_X;
	var BUTTON_Y;
	var LB;
	var RB;
	var LT;
	var RT;
	var VIEW;
	var MENU;
	var LS;
	var RS;
	var UP;
	var DOWN;
	var LEFT;
	var RIGHT;
	var HOME;
}

@:enum
abstract PSButton (Int) from Int to Int {
	var CROSS;
	var CIRCLE;
	var SQUARE;
	var TRIANGLE;
	var L1;
	var R1;
	var L2;
	var R2;
	var SHARE;
	var MENU;
	var L3;
	var R3;
	var UP;
	var DOWN;
	var LEFT;
	var RIGHT;
	var HOME;
	var TOUCHPAD;
}

@:enum
abstract KeyboardKey(Int) from Int to Int {
	var BACK = KeyCode.Back; // Android

	var KEY_A = KeyCode.A;
	var KEY_B = KeyCode.B;
	var KEY_C = KeyCode.C;
	var KEY_D = KeyCode.D;
	var KEY_E = KeyCode.E;
	var KEY_F = KeyCode.F;
	var KEY_G = KeyCode.G;
	var KEY_H = KeyCode.H;
	var KEY_I = KeyCode.I;
	var KEY_J = KeyCode.J;
	var KEY_K = KeyCode.K;
	var KEY_L = KeyCode.L;
	var KEY_M = KeyCode.M;
	var KEY_N = KeyCode.N;
	var KEY_O = KeyCode.O;
	var KEY_P = KeyCode.P;
	var KEY_Q = KeyCode.Q;
	var KEY_R = KeyCode.R;
	var KEY_S = KeyCode.S;
	var KEY_T = KeyCode.T;
	var KEY_U = KeyCode.U;
	var KEY_V = KeyCode.V;
	var KEY_W = KeyCode.W;
	var KEY_X = KeyCode.X;
	var KEY_Y = KeyCode.Y;
	var KEY_Z = KeyCode.Z;

	var LEFT = KeyCode.Left;
	var RIGHT = KeyCode.Right;
	var UP = KeyCode.Up;
	var DOWN = KeyCode.Down;

	var KEY_0 = KeyCode.Zero;
	var KEY_1 = KeyCode.One;
	var KEY_2 = KeyCode.Two;
	var KEY_3 = KeyCode.Three;
	var KEY_4 = KeyCode.Four;
	var KEY_5 = KeyCode.Five;
	var KEY_6 = KeyCode.Six;
	var KEY_7 = KeyCode.Seven;
	var KEY_8 = KeyCode.Eight;
	var KEY_9 = KeyCode.Nine;

	var NUM_0 = KeyCode.Numpad0;
	var NUM_1 = KeyCode.Numpad1;
	var NUM_2 = KeyCode.Numpad2;
	var NUM_3 = KeyCode.Numpad3;
	var NUM_4 = KeyCode.Numpad4;
	var NUM_5 = KeyCode.Numpad5;
	var NUM_6 = KeyCode.Numpad6;
	var NUM_7 = KeyCode.Numpad7;
	var NUM_8 = KeyCode.Numpad8;
	var NUM_9 = KeyCode.Numpad9;

	var F1 = KeyCode.F1;
	var F2 = KeyCode.F2;
	var F3 = KeyCode.F3;
	var F4 = KeyCode.F4;
	var F5 = KeyCode.F5;
	var F6 = KeyCode.F6;
	var F7 = KeyCode.F7;
	var F8 = KeyCode.F8;
	var F9 = KeyCode.F9;
	var F10 = KeyCode.F10;
	var F11 = KeyCode.F11;
	var F12 = KeyCode.F12;
	var F13 = KeyCode.F13;
	var F14 = KeyCode.F14;
	var F15 = KeyCode.F15;
	var F16 = KeyCode.F16;
	var F17 = KeyCode.F17;
	var F18 = KeyCode.F18;
	var F19 = KeyCode.F19;
	var F20 = KeyCode.F20;
	var F21 = KeyCode.F21;
	var F22 = KeyCode.F22;
	var F23 = KeyCode.F23;
	var F24 = KeyCode.F24;

	var DOUBLE_QUOTE = KeyCode.DoubleQuote;
	var BACK_QUOTE = KeyCode.BackQuote;
	var QUOTE = KeyCode.Quote;
	var EXCLAMATION = KeyCode.Exclamation;
	var AT = KeyCode.At;
	var HASH = KeyCode.Hash;
	var DOLLAR = KeyCode.Dollar;
	var PERCENT = KeyCode.Percent;
	var AMPERSAND = KeyCode.Ampersand;
	var ASTERISK = KeyCode.Asterisk;
	var OPEN_PARENTESIS = KeyCode.OpenParen;
	var CLOSE_PARENTESIS = KeyCode.CloseParen;
	var UNDERSCORE = KeyCode.Underscore;
	var HYPHEN = KeyCode.HyphenMinus;
	var PLUS = KeyCode.Plus;
	var MINUS = KeyCode.HyphenMinus;
	var EQUALS = KeyCode.Equals;
	var OPEN_CURLY_BRACKET = KeyCode.OpenCurlyBracket;
	var OPEN_BRACKET = KeyCode.OpenBracket;
	var CLOSE_CURLY_BRACKET = KeyCode.CloseCurlyBracket;
	var CLOSE_BRACKET = KeyCode.CloseBracket;
	var CIRCUMFLEX = KeyCode.Circumflex;
	var TILDE = KeyCode.Tilde;
	var BACK_SLASH = KeyCode.BackSlash;
	var SLASH = KeyCode.Slash;
	var LESS_THAN = KeyCode.LessThan;
	var GREATER_THAN = KeyCode.GreaterThan;
	var PERIOD = KeyCode.Period;
	var SEPARATOR = KeyCode.Separator;
	var COMMA = KeyCode.Comma;
	var DECIMAL = KeyCode.Decimal;
	var COLON = KeyCode.Colon;
	var SEMICOLON = KeyCode.Semicolon;
	var QUESTION = KeyCode.QuestionMark;
	var PIPE = KeyCode.Pipe;

	var PRINT_SCREEN = KeyCode.PrintScreen;
	var SCROLL_LOCK = KeyCode.ScrollLock;
	var PAUSE = KeyCode.Pause;
	var PRINT = KeyCode.Print;

	var ESC = KeyCode.Escape;
	var TAB = KeyCode.Tab;
	var CAPSLOCK = KeyCode.CapsLock;
	var SHIFT = KeyCode.Shift;
	var CTRL = KeyCode.Control;
	var WIN = KeyCode.Win;
	var ALT = KeyCode.Alt;
	var META = KeyCode.Meta;
	var SPACE = KeyCode.Space;
	var ALT_GR = KeyCode.AltGr;
	var CONTEXT = KeyCode.ContextMenu;
	var BACKSPACE = KeyCode.Backspace;
	var RETURN = KeyCode.Return;

	var HOME = KeyCode.Home;
	var END = KeyCode.End;
	var INSERT = KeyCode.Insert;
	var DELETE = KeyCode.Delete;
	var PAGE_UP = KeyCode.PageUp;
	var PAGE_DOWN = KeyCode.PageDown;

	var MUTE = KeyCode.VolumeMute;
	var VOLUME_DOWN = KeyCode.VolumeDown;
	var VOLUME_UP = KeyCode.VolumeUp;

	var NUM_LOCK = KeyCode.NumLock;
	var CLEAR = KeyCode.Clear;
	var DIVIDE = KeyCode.Divide;
	var MULT = KeyCode.Multiply;
	var SUB = KeyCode.Subtract;
	var ADD = KeyCode.Add;

	var SLEEP = KeyCode.Sleep;
	var SELECT = KeyCode.Select;
	var EXECUTE = KeyCode.Execute;
	var HELP = KeyCode.Help;
	var UNKNOWN = KeyCode.Unknown;
	var CANCEL = KeyCode.Cancel;
	var CONVERT = KeyCode.Convert;
	var NON_CONVERT = KeyCode.NonConvert;
	var ACCEPT = KeyCode.Accept;
	var MODE_CHANGE = KeyCode.ModeChange;
	var PLAY = KeyCode.Play;
	var ZOOM = KeyCode.Zoom;

	var ATTN = KeyCode.ATTN;
	var CRSEL = KeyCode.CRSEL;
	var EXSEL = KeyCode.EXSEL;
	var EREOF = KeyCode.EREOF;
	var PA1 = KeyCode.PA1;

	var KANA = KeyCode.Kana;
	var HANGUL = KeyCode.Hangul;
	var EISU = KeyCode.Eisu;
	var JANJA = KeyCode.Junja;
	var FINAL = KeyCode.Final;
	var HANJA = KeyCode.Hanja;
	var KANJI = KeyCode.Kanji;

	var WIN_ICO_HELP = KeyCode.WinIcoHelp;
	var WIN_ICO_00 = KeyCode.WinIco00;
	var WIN_ICO_CLEAR = KeyCode.WinIcoClear;

	var WIN_OEM_RESET = KeyCode.WinOemReset;
	var WIN_OEM_JUMP = KeyCode.WinOemJump;
	var WIN_OEM_PA1 = KeyCode.WinOemPA1;
	var WIN_OEM_PA2 = KeyCode.WinOemPA2;
	var WIN_OEM_PA3 = KeyCode.WinOemPA3;
	var WIN_OEM_WSCTRL = KeyCode.WinOemWSCTRL;
	var WIN_OEM_CUSEL = KeyCode.WinOemCUSEL;
	var WIN_OEM_ATTN = KeyCode.WinOemATTN;
	var WIN_OEM_FINISH = KeyCode.WinOemFinish;
	var WIN_OEM_COPY = KeyCode.WinOemCopy;
	var WIN_OEM_AUTO = KeyCode.WinOemAuto;
	var WIN_OEM_ENLW = KeyCode.WinOemENLW;
	var WIN_OEM_BACKTAB = KeyCode.WinOemBackTab;
	var WIN_OEM_CLEAR = KeyCode.WinOemClear;

	var WIN_OEM_FJ_JISHO = KeyCode.WinOemFjJisho;
	var WIN_OEM_FJ_MASSHOU = KeyCode.WinOemFjMasshou;
	var WIN_OEM_FJ_TOUROKU = KeyCode.WinOemFjTouroku;
	var WIN_OEM_FJ_LOYA = KeyCode.WinOemFjLoya;
	var WIN_OEM_FJ_ROYA = KeyCode.WinOemFjRoya;
}