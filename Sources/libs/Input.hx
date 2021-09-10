
package libs;

import iron.App;
import kha.input.KeyCode;

/*
	Refactored Input Class. Now it is more extendable and maintainable.
	Previously i guess it was impossible to decide whether to use or not mouse or surface in mobile. Now this can change.
	Fixed mouse movement influence after changing the cursor lock state.
	Improved way to set mouse hide / lock states. Now is just changing a variable.
	Performance may be increased in some situations. Now the started, down and released keys lists just stores its indexes and the keys are filtered by its string representation just when needed.
	Created a properly Surface class.
	Created Gyroscope class.
	Added blockMovement field to Mouse, Surface, Pen and Gamepad sticks.
	Added enums for all inputs.
	Fixed mouse movement delta when leave / enter the window. The fix only works for hmtl5, HL/C and hxcpp.
	Repeat method is avaiable for all inputs.
	Added anyStarted, anyDown and anyReleased methods.
	Added docs
*/

/*
	Add pinch *
	Mouse right button in android *
	Make mouse "compatible" with surface depending on target *
	Use assert (?)
	Add deprecate notice where needed (?)
*/
class Input {
	static var keyboard: Null<Keyboard>;
	static var mouse: Null<Mouse>;
	static var pen: Null<Pen>;
	static var surface: Null<Surface>;
	static var accelerometer: Null<Accelerometer>;
	static var gyroscope: Null<Gyroscope>;

	static var gamepads: Null<haxe.ds.Vector<Null<Gamepad>>>;

	final startedKeyCodes = new Array<Int>();
	final downKeyCodes = new Array<Int>();
	final releasedKeyCodes = new Array<Int>();

	var notifyDown: Null<Array<Int -> Void>>;
	var notifyUp: Null<Array<Int -> Void>>;

	var virtualKeys: Null<Map<Int, String>>;
	var startedVirtualKeys: Array<String>;
	var downVirtualKeys: Array<String>;
	var releasedVirtualKeys: Array<String>;

	public var lastKeyCodeDown(default, null): Int;

	var repeatKey = false;
	var repeatTime = 0.0;

	function new() {
		App.notifyOnEndFrame(endFrame);
		App.notifyOnReset(reset);

		// Force virtual keys initialization to keep backward compatibility
		setVirtualKey(0, "");
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
		if (g == null && index >= 0 && index <= 3) gamepads[index] = new Gamepad(index);
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

	/**
		Check if a key is just pressed.
		@param	keyCode An Int representing the key code to check.
		@return	Bool. Returns true if the key starts being pressed.
	**/
	public inline function newStarted(keyCode = 0): Bool {
		return startedKeyCodes.contains(keyCode);
	}

	/**
		Check if a key code is pressed.
		@param	keyCode An Int representing the key code to check.
		@return	Bool. Returns true if the key is down.
	**/
	public inline function newDown(keyCode = 0): Bool {
		return downKeyCodes.contains(keyCode);
	}

	/**
		Check if a key code if just released.
		@param	keyCode An Int representing the key code to check.
		@return	Bool. Returns true if the key stops being pressed.
	**/
	public inline function newReleased(keyCode = 0): Bool {
		return releasedKeyCodes.contains(keyCode);
	}

	/**
		Check if a key code is just pressed inside the repeat interval.
		@param	keyCode An Int representing the key code to check.
		@return	Bool. Returns true if the key starts being pressed inside the repeat interval.
	**/
	public function startedRepeat(keyCode: Int): Bool {
		return newStarted(keyCode) || (repeatKey && newDown(keyCode));
	}

	/**
		Check if a key code is just released inside the repeat interval.
		@param	keyCode An Int representing the key code to check.
		@return	Bool. Returns true if the key stops being pressed inside the repeat interval.
	**/
	public function releasedRepeat(keyCode: Int): Bool {
		return newReleased(keyCode) || (repeatKey && newReleased(keyCode));
	}

	/**
		Check if any key is just pressed.
		@return	Bool. Returns true if any key starts being pressed.
	**/
	public inline function anyStarted(): Bool {
		return startedKeyCodes.length > 0;
	}

	/**
		Check if any key is down.
		@return	Bool. Returns true if any key is pressed.
	**/
	public inline function anyDown(): Bool {
		return downKeyCodes.length > 0;
	}

	/**
		Check if any key is just released.
		@return	Bool. Returns true if any key stops being pressed.
	**/
	public inline function anyReleased(): Bool {
		return releasedKeyCodes.length > 0;
	}

	/**
		Set the virtual string representation of a key code.
		@param	keyCode The key code to be virtualized
		@param virtualKey A String to represent the key code
		@return Void.
	**/
	public function setVirtualKey(keyCode: Int, virtualKey: String): Void {
		if (virtualKeys == null) {
			virtualKeys = new Map<Int, String>();
			startedVirtualKeys = new Array<String>();
			downVirtualKeys = new Array<String>();
			releasedVirtualKeys = new Array<String>();
		}

		virtualKeys.set(keyCode, virtualKey);
	}

	/**
		Get the virtual string representation of a key code. Call this just if some virtual key was defined before!
		If the key code don't have a string representation, `null` is returned.
		@param	keyCode The key code to get the string representation
		@return Null<String>.
	**/
	public inline function getVirtualKey(keyCode: Int): Null<String> {
		return virtualKeys.get(keyCode);
	}

	/**
		Check if a virtual key is just pressed. Call this just if some virtual key was defined before!
		@param	virtualKey A String representing the key code to check.
		@return	Bool. Returns true if the key starts being pressed.
	**/
	public inline function startedVirtual(virtualKey: String): Bool {
		return startedVirtualKeys.contains(virtualKey);
	}

	/**
		Check if a virtual key is down. Call this just if some virtual key was defined before!
		@param	virtualKey A String representing the virtual key to check.
		@return	Bool. Returns true if the key is down.
	**/
	public inline function downVirtual(virtualKey: String): Bool {
		return downVirtualKeys.contains(virtualKey);
	}

	/**
		Check if a virtual key is just released. Call this just if some virtual key was defined before!
		@param	virtualKey A String representing the virtual key to check.
		@return	Bool. Returns true if the key stops being pressed.
	**/
	public inline function releasedVirtual(virtualKey: String): Bool {
		return releasedVirtualKeys.contains(virtualKey);
	}

	/**
		Check if a virtual key is just pressed inside the repeat interval.
		@param	virtualKey A String representing the virtual key to check.
		@return	Bool. Returns true if the key starts being pressed inside the repeat interval.
	**/
	public function startedRepeatVirtual(virtualKey: String): Bool {
		return startedVirtual(virtualKey) || (repeatKey && downVirtual(virtualKey));
	}

	/**
		Check if a virtual key is just released inside the repeat interval.
		@param	virtualKey A String representing the virtual key to check.
		@return	Bool. Returns true if the key stops being pressed inside the repeat interval.
	**/
	public function releasedRepeatVirtual(virtualKey: String): Bool {
		return releasedVirtual(virtualKey) || (repeatKey && downVirtual(virtualKey));
	}

	// Keep compatibility
	public function repeat(virtualKey: String): Bool {
		return startedRepeatVirtual(virtualKey);
	}

	public inline function setVirtual(virtualKey: String, key: String) {
		for (kc => v in virtualKeys)
			if (v == key)
				setVirtualKey(kc, virtualKey);
	}

	public inline function started(virtualKey = ""): Bool {
		return startedVirtual(virtualKey);
	}

	public inline function down(virtualKey = ""): Bool {
		return downVirtual(virtualKey);
	}

	public inline function released(virtualKey = ""): Bool {
		return releasedVirtual(virtualKey);
	}
	// End

	function keyDown(keyCode: Int) {
		startedKeyCodes.push(keyCode);
		downKeyCodes.push(keyCode);

		if (virtualKeys != null) {
			var str = virtualKeys.get(keyCode);

			if (str != null) {
				startedVirtualKeys.push(str);
				downVirtualKeys.push(str);
			}
		}

		repeatTime = kha.Scheduler.time() + 0.4;

		lastKeyCodeDown = keyCode;

		if (notifyDown != null)
			for (f in notifyDown) f(keyCode);
	}

	function keyUp(keyCode: Int) {
		downKeyCodes.remove(keyCode);
		releasedKeyCodes.push(keyCode);

		if (virtualKeys != null) {
			var str = virtualKeys.get(keyCode);

			if (str != null) {
				downVirtualKeys.remove(str);
				releasedVirtualKeys.push(str);
			}
		}

		if (notifyUp != null)
			for (f in notifyUp) f(keyCode);
	}

	function endFrame() {
		if (anyDown()) { // No need to resize if no key is down
			startedKeyCodes.resize(0);
			releasedKeyCodes.resize(0);

			if (virtualKeys != null) {
				startedVirtualKeys.resize(0);
				releasedVirtualKeys.resize(0);
			}
		}

		if (kha.Scheduler.time() - repeatTime > 0.05) {
			repeatTime = kha.Scheduler.time();
			repeatKey = true;
		}
		else repeatKey = false;
	}

	function reset() {
		downKeyCodes.resize(0);

		if (virtualKeys != null)
			downVirtualKeys.resize(0);

		endFrame();
	}
}

class Keyboard extends Input {
	public function new() {
		super();

		kha.input.Keyboard.get().notify(keyDown, keyUp);

		virtualKeys = [
			KeyboardEnum.KEY_A => "a", KeyboardEnum.KEY_B => "b", KeyboardEnum.KEY_C => "c", KeyboardEnum.KEY_D => "d",
			KeyboardEnum.KEY_E => "e", KeyboardEnum.KEY_F => "f", KeyboardEnum.KEY_G => "g", KeyboardEnum.KEY_H => "h",
			KeyboardEnum.KEY_I => "i", KeyboardEnum.KEY_J => "j", KeyboardEnum.KEY_K => "k", KeyboardEnum.KEY_L => "l",
			KeyboardEnum.KEY_M => "m", KeyboardEnum.KEY_N => "n", KeyboardEnum.KEY_O => "o", KeyboardEnum.KEY_P => "p",
			KeyboardEnum.KEY_Q => "q", KeyboardEnum.KEY_R => "r", KeyboardEnum.KEY_S => "s", KeyboardEnum.KEY_T => "t",
			KeyboardEnum.KEY_U => "u", KeyboardEnum.KEY_V => "v", KeyboardEnum.KEY_W => "w", KeyboardEnum.KEY_X => "x",
			KeyboardEnum.KEY_Y => "y", KeyboardEnum.KEY_Z => "z", KeyboardEnum.KEY_0 => "0", KeyboardEnum.KEY_1 => "1",
			KeyboardEnum.KEY_2 => "2", KeyboardEnum.KEY_3 => "3", KeyboardEnum.KEY_4 => "4", KeyboardEnum.KEY_5 => "5",
			KeyboardEnum.KEY_6 => "6", KeyboardEnum.KEY_7 => "7", KeyboardEnum.KEY_8 => "8", KeyboardEnum.KEY_9 => "9",
			KeyboardEnum.SPACE => "space", KeyboardEnum.BACKSPACE => "backspace", KeyboardEnum.TAB => "tab", KeyboardEnum.ENTER => "enter",
			KeyboardEnum.SHIFT => "shift", KeyboardEnum.CTRL => "control", KeyboardEnum.ALT => "alt", KeyboardEnum.WIN => "win",
			KeyboardEnum.ESC => "escape", KeyboardEnum.DELETE => "delete", KeyboardEnum.UP => "up", KeyboardEnum.DOWN => "down",
			KeyboardEnum.LEFT => "left", KeyboardEnum.RIGHT => "right", KeyboardEnum.BACK => "back", KeyboardEnum.COMMA => ",",
			KeyboardEnum.DECIMAL => ".", KeyboardEnum.COLON => ":", KeyboardEnum.SEMICOLON => ";", KeyboardEnum.LESS_THAN => "<",
			KeyboardEnum.EQUALS => "=", KeyboardEnum.GREATER_THAN => ">", KeyboardEnum.QUESTION => "$", KeyboardEnum.EXCLAMATION => "!",
			KeyboardEnum.DOUBLE_QUOTE => '"', KeyboardEnum.HASH => "#", KeyboardEnum.DOLLAR => "$", KeyboardEnum.PERCENT => "%",
			KeyboardEnum.AMPERSAND => "&", KeyboardEnum.UNDERSCORE => "_", KeyboardEnum.OPEN_PARENTESIS => "(", KeyboardEnum.CLOSE_PARENTESIS => ")",
			KeyboardEnum.ASTERISK => "*", KeyboardEnum.PIPE => "|", KeyboardEnum.OPEN_CURLY_BRACKET => "{", KeyboardEnum.CLOSE_CURLY_BRACKET => "}",
			KeyboardEnum.OPEN_BRACKET => "[", KeyboardEnum.CLOSE_BRACKET => "]", KeyboardEnum.TILDE => "~", KeyboardEnum.BACK_QUOTE => "`",
			KeyboardEnum.SLASH => "/", KeyboardEnum.BACK_SLASH => "\\",  KeyboardEnum.AT => "@", KeyboardEnum.ADD => "+",
			KeyboardEnum.HYPHEN => "-", KeyboardEnum.F1 => "f1", KeyboardEnum.F2 => "f2", KeyboardEnum.F3 => "f3",
			KeyboardEnum.F4 => "f4", KeyboardEnum.F5 => "f5", KeyboardEnum.F6 => "f6", KeyboardEnum.F7 => "f7",
			KeyboardEnum.F8 => "f8", KeyboardEnum.F9 => "f9", KeyboardEnum.F10 => "f10", KeyboardEnum.F11 => "f11",
			KeyboardEnum.F12 => "f12", KeyboardEnum.PLUS => "+", KeyboardEnum.SUB => "-", KeyboardEnum.NUM_0 => "0",
			KeyboardEnum.NUM_1 => "1", KeyboardEnum.NUM_2 => "2", KeyboardEnum.NUM_3 => "3", KeyboardEnum.NUM_4 => "4",
			KeyboardEnum.NUM_5 => "5", KeyboardEnum.NUM_6 => "6", KeyboardEnum.NUM_7 => "7", KeyboardEnum.NUM_8 => "8",
			KeyboardEnum.NUM_9 => "9"
		];
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

	// Set movement delta if it is not blocked
	public function setMovement(x: Int, y: Int) {
		if (blockMovement) return;

		movementX = x;
		movementY = y;
		moved = true;
	}

	// Set position and movement delta if it is not blocked
	public function displaceTo(x: Int, y: Int) {
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
	public inline function set_blockMovement(block: Bool) { return coords.blockMovement = block; }

	override function endFrame() {
		super.endFrame();
		coords.endFrame();
	}
}

class Mouse extends CoordsInput {
	public var wheelDelta(default, null) = 0;
	public var locked(default, set) = false;
	public var hidden(default, set) = false;
	var ignoreMovement = false; // Ignore movement to avoid wrong delta

	public function new() {
		super();

		kha.input.Mouse.get().notify(downListener, upListener, moveListener, wheelListener, function() {
			ignoreMovement = true; // Ignore movement after the cursor leaves the window to avoid wrong delta
		});

		// Reset on foreground state
		kha.System.notifyOnApplicationState(reset, null, null, null, null);

		virtualKeys = [MouseEnum.LEFT => "left", MouseEnum.RIGHT => "right", MouseEnum.MIDDLE => "middle"];
	}

	public function set_locked(locked: Bool) {
		var khaMouse = kha.input.Mouse.get();

		if (khaMouse.canLock()) {
			if (locked) {
				khaMouse.lock();
				this.locked =  this.hidden = true;
				ignoreMovement = true;  // Ignore movement after the cursor is locked to avoid wrong delta
			}
			else {
				khaMouse.unlock();
				this.locked = this.hidden = false;
			}
		}

		return this.locked;
	}

	public function set_hidden(hidden: Bool) {
		var khaMouse = kha.input.Mouse.get();

		if (hidden) {
			khaMouse.hideSystemCursor();
			this.hidden = true;
		
		}
		else {
			khaMouse.showSystemCursor();
			this.hidden = false;
		}

		return this.hidden;
	}

	// Keep compatibility
	public function lock() {
		locked = true;
	}
	
	public function unlock() {
		locked = false;
	}

	public function hide() {
		hidden = true;
	}

	public function show() {
		hidden = false;
	}
	// End

	function downListener(button: Int, x: Int, y: Int) {
		keyDown(button);
		coords.setPos(x, y);
	}

	function upListener(button: Int, x: Int, y: Int) {
		keyUp(button);
		coords.setPos(x, y);
	}

	function moveListener(x: Int, y: Int, movementX: Int, movementY: Int) {
		if (ignoreMovement) ignoreMovement = blockMovement; // Keep ignoring movement case it will be blocked later. If false only the position is set
		else if (!locked) {
			coords.displaceTo(x, y); // Set position and movement if movement is not ignored. Everything is done
			return;
		}
		else coords.setMovement(movementX, movementY); // Set movement if the movement is not ignored. Position must be set later

		coords.setPos(x, y);
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

		kha.input.Pen.get().notify(downListener, upListener, moveListener);

		virtualKeys = [PenEnum.TIP => "tip"];
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

		#if (kha_android || kha_ios)
		var s = kha.input.Surface.get();
		if (s != null) s.notify(touchStartListener, touchEndListener, moveListener);
		#end

		touches = new Array<Coords2D>();
		setMaxTouches(maxTouches);
	}

	/**
		Get the coordinates of a touch containing the fields: x, y, movementX, movementY, moved and blockMovement.
		@param	touchIndex An Int representing touch order to get the coords. First touch is 0, second touch is 1...
		@return	Coords2D.
	**/
	public function getTouchCoords(touchIndex: Int): Null<Coords2D> {
		return touches[touchIndex];
	}

	/**
		Set the maximum number of touches.
		@param	maxTouches An Int representing the maximum number of touches
		@return	Int.
	**/
	public function setMaxTouches(maxTouches: Int): Int {
		if (maxTouches > touches.length) {
			for (i in touches.length...maxTouches)
				touches.push(new Coords2D());
		}
		else if (maxTouches < touches.length) {
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
		for (t in touches)
			t.endFrame();
	}
}

class Gamepad extends Input {
	public final index: Int;
	public final leftStick = new GamepadStick();
	public final rightStick = new GamepadStick();
	final pressures = new Array<Float>();

	var virtualPressures: Null<Map<String, Float>>;

	public function new(index = 0) {
		super();

		this.index = index;

		kha.input.Gamepad.get(index).notify(axisListener, buttonListener);

		virtualKeys = [
			PSEnum.CROSS => "cross", PSEnum.CIRCLE => "circle", PSEnum.SQUARE => "square", PSEnum.TRIANGLE => "triangle",
			PSEnum.L1 => "l1", PSEnum.R1 => "r1", PSEnum.L2 => "l2", PSEnum.R2 => "r2",
			PSEnum.SHARE => "share", PSEnum.MENU => "options", PSEnum.L3 => "l3", PSEnum.R3 => "r3",
			PSEnum.UP => "up", PSEnum.DOWN => "down", PSEnum.LEFT => "left", PSEnum.RIGHT => "right",
			PSEnum.HOME => "home", PSEnum.TOUCHPAD => "touchpad"
		];
	}

	/**
		Get a button code pressure from `0.0` to `1.0` depending on the pressure over the button.
		@param	button An Int representing the button code to get its pressure
		@return	Float.
	**/
	public function getPressure(button: Int): Float {
		var p = pressures[button];
		return p != null ? p : 0.0;
	}

	/**
		Get a virtual button pressure from `0.0` to `1.0` depending on the pressure over the button. Call this just if some virtual key was defined before!
		@param	virtualButton A String representing the virtual button to get its pressure
		@return	Float.
	**/
	public function getVirtualPressure(virtualButton: String): Float {
		var p = virtualPressures.get(virtualButton);
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

		if (virtualPressures != null)
			virtualPressures.set(virtualKeys.get(button), pressure);
	}

	public override function setVirtualKey(keyCode: Int, virtualKey: String) {
		super.setVirtualKey(keyCode, virtualKey);

		if (virtualPressures == null) {
			virtualPressures = new Map<String, Float>();

			for (kc => v in virtualKeys)
				virtualPressures.set(v, 0.0); // Initialize all existent virtual keys pressures
		}
		else virtualPressures.set(virtualKey, 0.0);
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
		kha.input.Sensor.get(kha.input.SensorType.Accelerometer).notify(listener);
	}
}

class Gyroscope extends Sensor {
	public function new() {
		kha.input.Sensor.get(kha.input.SensorType.Gyroscope).notify(listener);
	}
}

@:enum
abstract PenEnum(Int) from Int to Int {
	var TIP;
}

@:enum
abstract MouseEnum(Int) from Int to Int {
	var LEFT;
	var MIDDLE;
	var RIGHT;
}

@:enum
abstract XboxEnum(Int) from Int to Int {
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
abstract PSEnum (Int) from Int to Int {
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
abstract KeyboardEnum(Int) from Int to Int {
	var BACK = KeyCode.Back; // Android RMB

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

	var DOUBLE_QUOTE = KeyCode.DoubleQuote; // "
	var BACK_QUOTE = KeyCode.BackQuote; // `
	var QUOTE = KeyCode.Quote; // '
	var EXCLAMATION = KeyCode.Exclamation; // !
	var AT = KeyCode.At; // @
	var HASH = KeyCode.Hash; // #
	var DOLLAR = KeyCode.Dollar; // $
	var PERCENT = KeyCode.Percent; // %
	var AMPERSAND = KeyCode.Ampersand; // &
	var ASTERISK = KeyCode.Asterisk; // *
	var OPEN_PARENTESIS = KeyCode.OpenParen; // (
	var CLOSE_PARENTESIS = KeyCode.CloseParen; // )
	var UNDERSCORE = KeyCode.Underscore; // _
	var HYPHEN = KeyCode.HyphenMinus; // -
	var PLUS = KeyCode.Plus; // +
	var MINUS = KeyCode.HyphenMinus; // -
	var EQUALS = KeyCode.Equals; // =
	var OPEN_BRACKET = KeyCode.OpenBracket; // [
	var CLOSE_BRACKET = KeyCode.CloseBracket; // ]
	var OPEN_CURLY_BRACKET = KeyCode.OpenCurlyBracket; // {
	var CLOSE_CURLY_BRACKET = KeyCode.CloseCurlyBracket; // {
	var CIRCUMFLEX = KeyCode.Circumflex; // ^
	var TILDE = KeyCode.Tilde; // ~
	var BACK_SLASH = KeyCode.BackSlash; // \
	var SLASH = KeyCode.Slash; // /
	var LESS_THAN = KeyCode.LessThan; // <
	var GREATER_THAN = KeyCode.GreaterThan; // >
	var SEPARATOR = KeyCode.Separator;
	var COMMA = KeyCode.Comma; // ,
	var PERIOD = KeyCode.Period; // .
	var DECIMAL = KeyCode.Decimal; // .
	var COLON = KeyCode.Colon; // :
	var SEMICOLON = KeyCode.Semicolon; // ;
	var QUESTION = KeyCode.QuestionMark; // ?
	var PIPE = KeyCode.Pipe; // |

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
	var ENTER = KeyCode.Return;

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