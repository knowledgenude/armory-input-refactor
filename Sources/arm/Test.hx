package arm;

import libs.Input;

class Test extends iron.Trait {
	var k = Input.getKeyboard();  

	public function new() {
		super();

		iron.Scene.active.notifyOnInit(function() {
			k.setVirtualKey("test", KeyboardKey.KEY_W);
		});

		notifyOnUpdate(function() {
			if (k.started("test") || k.started("space")) {
				trace("key started");
			}
		});
	}
}
