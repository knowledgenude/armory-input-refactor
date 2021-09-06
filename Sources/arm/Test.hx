package arm;

import libs.Input;

class Test extends iron.Trait {
	var m = Input.getMouse();
	var k = Input.getKeyboard();  

	public function new() {
		super();

		iron.Scene.active.notifyOnInit(function() {
			// m.locked = true;
		});

		notifyOnUpdate(function() {
			if (m.started(MouseButton.LEFT)) {
				trace("mouse");
			}

			if (k.started(KeyboardKey.NUM_5)) {
				trace("keyboard");
			}
		});
	}
}
