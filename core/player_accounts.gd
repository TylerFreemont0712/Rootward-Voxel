class_name PlayerAccounts
extends RefCounted
## Journey-owned property. Program Undo/Reset cannot duplicate wages or reverse bank transfers.
const LIMIT: int = 9999999
const STACK_LIMIT: int = 99
const ITEMS: Dictionary = {
	"message-card":{"title":"Blank message card","description":"A reusable card for a sign or a workshop routine.","kind":"Material"},
	"brass-token":{"title":"Brass tram token","description":"A stamped token, kept for a later journey.","kind":"Keepsake"},
}

static func fresh() -> Dictionary:
	return {"version":1,"wallet":0,"bank":0,"inventory":{},"receipts":{},"journal":[]}

static func whole(value: Variant, maximum: int = LIMIT) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=0 and value<=maximum

static func restore(raw: Variant) -> Dictionary:
	var result: Dictionary = fresh()
	if not raw is Dictionary or raw.get("version")!=1: return result
	for key: String in ["wallet","bank"]:
		if not whole(raw.get(key)): return fresh()
		result[key]=int(raw[key])
	if not raw.get("inventory",{}) is Dictionary or not raw.get("receipts",{}) is Dictionary: return fresh()
	for id: Variant in raw.get("inventory",{}):
		if id is String and ITEMS.has(id) and whole(raw.inventory[id],STACK_LIMIT) and raw.inventory[id]>0: result.inventory[id]=int(raw.inventory[id])
	for id: Variant in raw.get("receipts",{}):
		if id is String and AreaDef._id(id) and whole(raw.receipts[id]): result.receipts[id]=int(raw.receipts[id])
	for entry: Variant in raw.get("journal",[]) if raw.get("journal",[]) is Array else []:
		if entry is Dictionary and entry.get("text") is String and entry.text.length()<=160 and whole(entry.get("amount")):
			result.journal.append({"text":entry.text,"amount":int(entry.amount)})
	result.journal=result.journal.slice(maxi(0,result.journal.size()-32))
	return result

static func claim(accounts: Dictionary, id: String, amount: int, title: String) -> Dictionary:
	if not AreaDef._id(id) or not whole(amount) or accounts.receipts.has(id): return {"ok":false,"accounts":accounts,"reason":"This payment has already been recorded, or is invalid."}
	if int(accounts.wallet)+amount>LIMIT: return {"ok":false,"accounts":accounts,"reason":"Your purse is full. Deposit some coins first."}
	var next: Dictionary=accounts.duplicate(true)
	next.wallet=int(next.wallet)+amount
	next.receipts[id]=amount
	_record(next,("Payment · " if amount>0 else "Received · ")+title,amount)
	return {"ok":true,"accounts":next,"reason":""}

static func transfer(accounts: Dictionary, amount: Variant, deposit: bool) -> Dictionary:
	if not whole(amount) or amount<=0: return {"ok":false,"accounts":accounts,"reason":"Enter a whole number of pence greater than zero."}
	var source: String="wallet" if deposit else "bank"
	var target: String="bank" if deposit else "wallet"
	if int(accounts[source])<amount: return {"ok":false,"accounts":accounts,"reason":"There isn't that much in your %s." % ("purse" if deposit else "account")}
	if int(accounts[target])+amount>LIMIT: return {"ok":false,"accounts":accounts,"reason":"That balance would exceed the account limit."}
	var next: Dictionary=accounts.duplicate(true)
	next[source]=int(next[source])-int(amount)
	next[target]=int(next[target])+int(amount)
	_record(next,"Bank deposit" if deposit else "Bank withdrawal",int(amount))
	return {"ok":true,"accounts":next,"reason":""}

static func change_item(accounts: Dictionary, id: String, quantity: int) -> Dictionary:
	if not ITEMS.has(id): return {"ok":false,"accounts":accounts,"reason":"That item is not in the inventory catalog."}
	var count: int=int(accounts.inventory.get(id,0))+quantity
	if count<0 or count>STACK_LIMIT: return {"ok":false,"accounts":accounts,"reason":"You don't have enough, or this stack would exceed 99."}
	var next: Dictionary=accounts.duplicate(true)
	if count==0: next.inventory.erase(id)
	else: next.inventory[id]=count
	return {"ok":true,"accounts":next,"reason":""}

static func purchase(accounts: Dictionary, id: String, quantity: int, unit_price: int) -> Dictionary:
	# Foundation for authored shop/puzzle exchanges. No player code can set a price.
	if quantity<=0 or not whole(unit_price) or quantity>STACK_LIMIT: return {"ok":false,"accounts":accounts,"reason":"Invalid purchase."}
	var cost: int=quantity*unit_price
	if accounts.wallet<cost: return {"ok":false,"accounts":accounts,"reason":"Not enough money in your purse."}
	var result: Dictionary=change_item(accounts,id,quantity)
	if not result.ok: return result
	result.accounts.wallet-=cost
	_record(result.accounts,"Purchase · "+str(ITEMS[id].title),cost)
	return result

static func _record(accounts: Dictionary, description: String, amount: int) -> void:
	accounts.journal.append({"text":description.left(160),"amount":amount})
	if accounts.journal.size()>32: accounts.journal.pop_front()
