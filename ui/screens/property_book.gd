class_name PropertyBook
extends Modal
signal transfer_requested(amount: int, deposit: bool)
var _session: GameSession
var _bank: bool = false
var _contents: VBoxContainer
var _amount: SpinBox
var _feedback: Label

func setup(session: GameSession, bank: bool = false) -> void:
	_session=session
	_bank=bank
	theme=PaperTheme.theme()
	card.custom_minimum_size=Vector2(620,0)
	title_row("Haverlund Savings" if bank else "Your belongings", "Purse, carried tools and work payments")
	_contents=UI.vbox(12)
	body.add_child(_contents)
	if bank:
		body.add_child(UI.dim("Move coins between your purse and your account. There are no fees or interest.",17))
		_amount=SpinBox.new()
		_amount.min_value=1
		_amount.max_value=PlayerAccounts.LIMIT
		_amount.step=1
		_amount.value=1
		_amount.suffix=" pence"
		body.add_child(_amount)
		var row:=UI.hbox(12)
		row.add_child(UI.button("Deposit",&"",&"ButtonPrimary",func()->void:transfer_requested.emit(int(_amount.value),true)))
		row.add_child(UI.button("Withdraw",&"",&"",func()->void:transfer_requested.emit(int(_amount.value),false)))
		body.add_child(row)
	_feedback=UI.dim("",16)
	body.add_child(_feedback)
	body.add_child(UI.button("Back",&"",&"ButtonQuiet",close))
	refresh()

func refresh(message: String = "") -> void:
	for child: Node in _contents.get_children():
		_contents.remove_child(child)
		child.queue_free()
	var accounts: Dictionary=_session.accounts
	_contents.add_child(UI.heading("Purse  %d p     ·     Bank  %d p" % [accounts.wallet,accounts.bank],24))
	if not _bank:
		_contents.add_child(UI.rule())
		_contents.add_child(UI.label("CARRIED TOOLS",&"LabelCaps",14,PaperPal.TEAL_DEEP))
		for id: String in _session.state.items:
			_contents.add_child(UI.label(PlayerItems.title(id),&"LabelHeading",20))
		if _session.state.items.is_empty(): _contents.add_child(UI.dim("No tools carried yet.",17))
		for id: String in accounts.inventory:
			_contents.add_child(UI.label("%s  × %d" % [PlayerAccounts.ITEMS[id].title,accounts.inventory[id]],&"LabelHeading",19))
	_contents.add_child(UI.rule())
	_contents.add_child(UI.label("ACCOUNT BOOK · RECENT ENTRIES",&"LabelCaps",14,PaperPal.TEAL_DEEP))
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(560,150)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list:=UI.vbox(8)
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	_contents.add_child(scroll)
	var entries: Array=accounts.journal.duplicate()
	entries.reverse()
	for entry: Dictionary in entries:
		list.add_child(UI.label(str(entry.text)+(" · %d p" % entry.amount if entry.amount>0 else ""),&"",17))
	if entries.is_empty(): list.add_child(UI.dim("Your first paid job will appear here.",17))
	_feedback.text=message
