extends SceneTree
var checks: int=0
var failures: Array[String]=[]
func _initialize()->void:
	var original: Dictionary=PlayerAccounts.fresh()
	var wage: Dictionary=PlayerAccounts.claim(original,"landing-light",6,"Stair lantern")
	_check(wage.ok and wage.accounts.wallet==6 and original.wallet==0,"Payments are detached atomic proposals")
	_check(not PlayerAccounts.claim(wage.accounts,"landing-light",6,"Again").ok,"A repeated quest cannot farm its wage")
	var deposit: Dictionary=PlayerAccounts.transfer(wage.accounts,4,true)
	_check(deposit.ok and deposit.accounts.wallet==2 and deposit.accounts.bank==4,"Deposit preserves total money")
	var withdrawal: Dictionary=PlayerAccounts.transfer(deposit.accounts,3,false)
	_check(withdrawal.ok and withdrawal.accounts.wallet==5 and withdrawal.accounts.bank==1,"Withdrawal preserves total money")
	for amount: Variant in [0,-1,1.5,"2",true,INF,NAN,100000000]:
		_check(not PlayerAccounts.transfer(withdrawal.accounts,amount,true).ok,"Invalid bank amount rejected: "+str(amount))
	_check(not PlayerAccounts.transfer(withdrawal.accounts,6,true).ok,"Cannot overdraw purse")
	_check(not PlayerAccounts.transfer(withdrawal.accounts,2,false).ok,"Cannot overdraw bank")
	var stocked: Dictionary=PlayerAccounts.change_item(withdrawal.accounts,"message-card",2)
	_check(stocked.ok and stocked.accounts.inventory["message-card"]==2 and withdrawal.accounts.inventory.is_empty(),"Inventory grants preserve original")
	_check(not PlayerAccounts.change_item(stocked.accounts,"message-card",-3).ok,"Cannot spend absent material")
	_check(not PlayerAccounts.change_item(stocked.accounts,"message-card",98).ok,"Stack cap enforced")
	_check(not PlayerAccounts.change_item(stocked.accounts,"invented",1).ok,"Unknown item rejected")
	var purchase: Dictionary=PlayerAccounts.purchase(stocked.accounts,"message-card",2,2)
	_check(purchase.ok and purchase.accounts.wallet==1 and purchase.accounts.inventory["message-card"]==4,"Purchase moves coins and stock in one proposal")
	_check(not PlayerAccounts.purchase(stocked.accounts,"message-card",3,2).ok and stocked.accounts.wallet==5,"Unfunded purchase changes neither balance nor stock")
	_check(PlayerAccounts.restore(JSON.parse_string(JSON.stringify(purchase.accounts)))==purchase.accounts,"Accounts, receipts and quantities round trip through JSON")
	var bad: Dictionary=purchase.accounts.duplicate(true)
	bad.wallet=-2
	_check(PlayerAccounts.restore(bad)==PlayerAccounts.fresh(),"Malformed balances never introduce negative money")
	_finish()
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message)
func _finish()->void:
	for failure:String in failures:printerr("FAIL: ",failure)
	print("Property and banking: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
