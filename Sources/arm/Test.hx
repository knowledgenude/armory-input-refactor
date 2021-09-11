package arm;

import libs.Input as NewInput;
import iron.system.Input;

class Test extends iron.Trait {
	var k = Input.getKeyboard();

	public function new() {
		super();

		iron.Scene.active.notifyOnInit(function() {
			// k.setVirtualKey(KeyboardEnum.KEY_W, "w");
		});

		notifyOnUpdate(function() {
			if (k.repeat("w")) {
				trace("repeat");
			}
		});
	}
}
