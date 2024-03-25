extends Resource
class_name SceneBuilderItem

@export var icon : Texture
@export var item_name : String = "TempItemName"
@export var scene_path : String = ""
@export var collection_name : String = "Temporary"

# Boolean
@export var use_random_rotation : bool = false
@export var use_random_scale : bool = false

# Rotation
@export var random_rot_x : float = 0
@export var random_rot_z : float = 0
@export var random_rot_y : float = 0

# Scale
@export var random_scale_x_min : float = 0.9
@export var random_scale_y_min : float = 0.9
@export var random_scale_z_min : float = 0.9
@export var random_scale_x_max : float = 1.1
@export var random_scale_y_max : float = 1.1
@export var random_scale_z_max : float = 1.1

