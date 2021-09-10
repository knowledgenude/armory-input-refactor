package arm;

import libs.Input as NewInput;
import iron.system.Input;

class Test extends iron.Trait {
	var k = NewInput.getKeyboard();

	public function new() {
		super();

		iron.Scene.active.notifyOnInit(function() {
			// k.setVirtualKey(KeyboardEnum.KEY_W, "w");
		});

		notifyOnUpdate(function() {

			for (i in 0...500000) {
				if (k.down("w")) {}
			}
		});
	}
}
