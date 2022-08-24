extends Node

const TEXTURE_ATLAS_SIZE := Vector2(8,2)

enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

enum {
	AIR,
	DIRT,
	GRASS,
	STONE
}

const types = {
	AIR:{
		SOLID:false
	},
	DIRT:{
		TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
		RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0),
		SOLID:true
	},
	GRASS:{
		TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
		RIGHT:Vector2(1, 0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0),
		SOLID:true
	},
	STONE:{
		TOP:Vector2(3, 0), BOTTOM:Vector2(3, 0), LEFT:Vector2(3, 0),
		RIGHT:Vector2(3, 0), FRONT:Vector2(3, 0), BACK:Vector2(3, 0),
		SOLID:true
	}
}

var noise := OpenSimplexNoise.new()

func get_block_type(i: int, j: int, k: int):
	var height = int((noise.get_noise_2d(i, k) + 1) * 32)
	
	var block = AIR
	
	if j < height / 2:
		block = STONE
	elif j < height:
		block = DIRT
	elif j == height:
		block = GRASS
	return block
