extends Node2D
class_name Room

# base of every room, corridor and cap scene.
# connectors are child Marker2Ds named Up/Down/Left/RightConnector, the footprint is the "Area2D" child.
# the generator reads both through RoomShape, so nothing is needed here at runtime
