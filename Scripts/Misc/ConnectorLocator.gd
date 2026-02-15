extends Node2D
class_name Room

var connectors: Dictionary = {
	"UpConnector": null,
	"LeftConnector": null,
	"RightConnector": null,
	"DownConnector": null
}

var occupied_connectors: Dictionary = {
	"UpConnector": false,
	"LeftConnector": false,
	"RightConnector": false,
	"DownConnector": false
}

func LocateConnectors():
	var children: Array[Node] = get_children()
	for child in children:
		if child.name in connectors:
			if occupied_connectors[child.name] == false:
				connectors[child.name] = child

func GetFirstConnector():
	for connector in connectors:
		if connectors[connector] != null:
			return connector
	return null

func GetFirstOccupiedConnector():
	for connector in connectors:
		if connectors[connector] != null && occupied_connectors[connector] == true:
			return connector
	return null

func GetAllUnoccupiedConnectors():
	var unocuppied_connectors: Array[String]
	for connector in connectors:
		if connectors[connector] != null && occupied_connectors[connector] == false:
			unocuppied_connectors.append(connector)
	return unocuppied_connectors
