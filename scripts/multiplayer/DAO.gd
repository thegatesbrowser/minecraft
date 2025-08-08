extends RefCounted
class_name DAO

var db
var table


func _init():
	if is_server(): 
		db = SQLite.new()
		db.path = "res://data.db"
		db.open_db()
		
		table = {
			"id" : {"data_type": "int", "primary_key" : true, "not_null" : true, "auto_increment"  : true},
			"salt" :{"data_type" : "int", "not_null" : true},
			"health":{"data_type" : "int"},
			"hunger":{"data_type" : "float"},
			"Position_x":{"data_type": "float"},
			"Position_y":{"data_type": "float"},
			"Position_z":{"data_type": "float"},
			"Inventory":{"data_type": "String"},
			"Hotbar":{"data_type": "String"},
			"item_data": {"data_type": "String"},
			"client_id": {"data_type" : "String"},
		}
		
		db.create_table("players", table)


func InsertUserData(client_id, salt):
	var data = {
		"client_id" : client_id,
		"salt" : salt
	}
	db.insert_row("players", data)


func change_data(client_id:String, change_name:String, change):
	#db.update_rows("players", "client_id = '" + client_id + "'", {"health":10})
	db.update_rows("players", "client_id = '" + client_id + "'", {change_name:change})


func GetUserFromDB(client_id):
	var query = "SELECT salt, id, health, hunger, Position_x,Position_y,Position_z, Inventory, Hotbar, item_data from players where client_id = ?"
	var paramBindings = [client_id]
	db.query_with_bindings(query, paramBindings)
	#print( db.query_result)
	for i in db.query_result:
		return{
			"id" : i["id"],
			"salt" : i["salt"],
			"health":  i["health"],
			"hunger": i["hunger"],
			"Position_x": i["Position_x"],
			"Position_y": i["Position_y"],
			"Position_z": i["Position_z"],
			"Inventory": i["Inventory"],
			"Hotbar": i["Hotbar"],
			"item_data": i["item_data"],
			"client_id" : client_id,
		}

func HasUserId(client_id:String) -> bool:
	var query = "SELECT id from players where client_id = ?"
	var paramBindings = [client_id]
	db.query_with_bindings(query, paramBindings)
	return db.query_result.size() > 0


static func is_server() -> bool:
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return "--server" in args
