class_name BallStateData
extends RefCounted

## Everything that belongs to one ball lives here.
##
## The paddles and score belong to the whole match, but velocity, spin, and a
## motion trail belong to one particular ball. Keeping those ideas separate is
## what lets the same physics functions update one ball or twenty balls.

var node: Node2D
var velocity := Vector2.ZERO
var speed := 0.0
var spin := 0.0
var visual_rotation := 0.0
var sideways_stall_time := 0.0
var last_hitter_direction := 0.0
var mode := 0
var held_by_direction := 0.0
var held_offset_y := 0.0
var trail: Array[Vector2] = []


func _init(ball_node: Node2D) -> void:
	node = ball_node
