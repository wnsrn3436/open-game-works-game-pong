extends UnitTestCase
## The terms popup prefab: both agree toggles are check boxes with an empty box and a filled box, and a turned-on
## toggle shows the same text color and frame whether the pointer is on it or not, the same for both toggles. The
## confirm button stays disabled with a highlighted hint until both toggles are on. The agree-all toggle turns both
## toggles on and off and is on only while both are on.

const _STATE_COLORS: PackedStringArray = ["font_pressed_color", "font_hover_pressed_color"]


func before_each() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(InputCore.init(), "InputCore.init")
	assert_true(LocalizationCore.init(), "LocalizationCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func popup() -> TermsPopup:
	var scene: PackedScene = await ResourceCore.load(ResourceKey.PREFAB__COMMON__TERMS_POPUP,
		ResourceCore.BaseKind.PACKED_SCENE, ResourceCore.get_global_scope()) as PackedScene
	assert_not_null(scene, "the terms popup prefab")
	var node: TermsPopup = scene.instantiate() as TermsPopup
	assert_not_null(node, "the terms popup root")
	add_child_autofree(node)
	return node


func test_the_agree_toggles_are_check_boxes_with_both_box_icons() -> void:
	var node: TermsPopup = await popup()
	for toggle: Button in [node.terms_toggle, node.privacy_toggle]:
		assert_true(toggle is CheckBox, "%s is a check box" % toggle.name)
		assert_true(toggle.toggle_mode, "%s toggles" % toggle.name)
		assert_true(toggle.has_theme_icon_override("checked"), "%s has the filled box" % toggle.name)
		assert_true(toggle.has_theme_icon_override("unchecked"), "%s has the empty box" % toggle.name)


func test_a_turned_on_toggle_looks_the_same_with_and_without_the_pointer_on_both_toggles() -> void:
	var node: TermsPopup = await popup()
	var terms: Button = node.terms_toggle
	var privacy: Button = node.privacy_toggle
	for toggle: Button in [terms, privacy]:
		assert_eq(toggle.get_theme_color("font_hover_pressed_color"), toggle.get_theme_color("font_pressed_color"),
			"%s text color" % toggle.name)
		assert_eq(toggle.get_theme_stylebox("hover_pressed"), toggle.get_theme_stylebox("pressed"), "%s frame" % toggle.name)
	for color: String in _STATE_COLORS:
		assert_eq(terms.get_theme_color(color), privacy.get_theme_color(color), color)
	assert_eq(terms.get_theme_stylebox("pressed"), privacy.get_theme_stylebox("pressed"), "pressed frame")
	assert_ne(terms.get_theme_color("font_pressed_color"), terms.get_theme_color("font_color"), "on and off text differ")


func test_the_confirm_button_waits_for_both_toggles_with_a_highlighted_hint() -> void:
	var node: TermsPopup = await popup()
	var hint: CommonTermsHint = null
	for child: Node in node.confirm_button.get_parent().get_children():
		if child is CommonTermsHint:
			hint = child as CommonTermsHint
	assert_not_null(hint, "the agree hint")
	assert_false(hint.text.is_empty(), "the hint has text")
	var waiting: Color = hint.get_theme_color("font_color")
	assert_true(node.confirm_button.disabled, "no toggle on: confirm disabled")
	node.terms_toggle.button_pressed = true
	assert_true(node.confirm_button.disabled, "one toggle on: confirm disabled")
	assert_eq(hint.get_theme_color("font_color"), waiting, "one toggle on: hint still highlighted")
	node.privacy_toggle.button_pressed = true
	assert_false(node.confirm_button.disabled, "both toggles on: confirm enabled")
	assert_ne(hint.get_theme_color("font_color"), waiting, "both toggles on: hint calm")
	node.terms_toggle.button_pressed = false
	assert_true(node.confirm_button.disabled, "a toggle off again: confirm disabled")
	assert_eq(hint.get_theme_color("font_color"), waiting, "a toggle off again: hint highlighted")


func agree_all(node: TermsPopup) -> CommonTermsAgreeAll:
	for child: Node in node.confirm_button.get_parent().get_children():
		if child is CommonTermsAgreeAll:
			return child as CommonTermsAgreeAll
	return null


func test_the_agree_all_toggle_turns_both_toggles_and_follows_them() -> void:
	var node: TermsPopup = await popup()
	var all: CommonTermsAgreeAll = agree_all(node)
	assert_not_null(all, "the agree-all toggle")
	assert_false(all.text.is_empty(), "the agree-all toggle has text")
	assert_false(all.button_pressed, "starts off")
	all.button_pressed = true
	assert_true(node.terms_toggle.button_pressed, "agree all on: terms on")
	assert_true(node.privacy_toggle.button_pressed, "agree all on: privacy on")
	assert_true(all.button_pressed, "agree all stays on")
	assert_false(node.confirm_button.disabled, "agree all on: confirm enabled")
	node.privacy_toggle.button_pressed = false
	assert_false(all.button_pressed, "one item off: agree all off")
	assert_true(node.terms_toggle.button_pressed, "the other item stays on")
	assert_true(node.confirm_button.disabled, "one item off: confirm disabled")
	node.privacy_toggle.button_pressed = true
	assert_true(all.button_pressed, "both items on again: agree all on")
	all.button_pressed = false
	assert_false(node.terms_toggle.button_pressed, "agree all off: terms off")
	assert_false(node.privacy_toggle.button_pressed, "agree all off: privacy off")
	assert_true(node.confirm_button.disabled, "agree all off: confirm disabled")
