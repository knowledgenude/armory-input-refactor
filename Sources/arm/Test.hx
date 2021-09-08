package arm;

import libs.Input;

class Test extends iron.Trait {
	var k = Input.getKeyboard();  

	public function new() {
		super();

		iron.Scene.active.notifyOnInit(function() {

		});

		notifyOnUpdate(function() {

		});
	}
}
