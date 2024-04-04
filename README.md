# Introduction

SceneBuilder is a system for efficiently building 3D scenes in Godot. Scene builder is logically divided into two main parts,


## Scene builder commands

In Godot's main bar, click `Project > Tools > Scene Builder` to see a list of productivity command with their associated keyboard shortcuts.

If you would like to know more about how these commands work, please see the command's respective gdscript file for more information, which is located,

	`res://addons/SceneBuilder/Commands/`

Implementation details: The script `scene_builder_commands.gd` is loaded by `scene_builder_plugin.gd`, which is the class registed to EditorPlugin via `plugin.cfg`. The script `scene_builder_commands.gd` adds commands to the Godot toolbar and also listens for keyboard shortcuts. Each command's implementation is contained within the command's respective gdscript file.


## The scene builder dock

The scene builder dock requires manual set up. This isn't an ideal user experience, but doing things this way leads to very simple and stable solutions, please bear with us!

In order to set-up the scene builder dock, follow these steps,

### Initialize your data folder

1) Create an empty folder,

	`res://Data/SceneBuilderCollections`

	Note: This folder path is hard coded into SceneBuilder.

2) Create a CollectionNames resource at the following location by first creating a new Resource, then by attaching the script: `scene_builder_collections.gd`,

	`res://Data/SceneBuilderCollections/collection_names.tres`

	Note: This resource path is hard coded into the scene builder dock.

3) Enter your desired collection names into the CollectionNames resource, then create empty folders with matching names.

	Note 1: For example, if you would like a collection named "Furniture," then write "Furniture" in the CollectionNames resource. Next, create an empty folder "Furniture" at location: `res://Data/SceneBuilderCollections/Furniture/`
	
	Note 2: If you have a folder in `res://Data/SceneBuilderCollections/` that is not listed in the CollectionNames resource, then it will simply be ignored. Conversely, if a collection name is written in CollectionNames, then an error will occur if a matching folder is not found.
	
	Note 3: SceneBuilder only provides space for 12 collections, however, you can make additional folders. We can update which 12 collections are currently in use by swapping out names in the CollectionNames resource, then hitting the "Reload all items" button in the scene builder dock.
	
	Note 4: The decision to have 12 collections was an arbitrary one, though it does fit nicely into the UI dock.

Your data folder is now initialized. 

You can enable the plugin now to preview your collection names in the scene builder dock. However, since our collection folders are empty, you will see a harmless error: `Directory exists, but contains no items: Furniture`.


### Manually create one item

Usually, we will want to create `SceneBuilderItem` resources in bulk. However, for demonstration purposes, let us create our first item manually.

Continuing with the furniture example, we assume in this section that you have already added "Furniture" to collection names, and have created an empty "Furniture" folder,

1) Create a `PackedScene` that we will use as an item to place. For this example, I will assume that you already have "Chair.glb" or "Chair.gltf" somewhere in your project files. It doesn't matter where your chair scene is located in FileSystem.

	Note 1: SceneBuilder will only work with files ending in .glb or .tscn

	Note 2: The root node of the imported scenes must derive from Node3D

2) Create two sub folders "Item" and "Thumbnail" at locations,

	`res://Data/SceneBuilderCollections/Furniture/Item/`
	`res://Data/SceneBuilderCollections/Furniture/Thumbnail/`

3) Create a new resource at the following location, then attach the script `scene_builder_item.gd` to it,

	`res://Data/SceneBuilderCollections/Furniture/Item/Chair.tres`

by convention, the resource should have the same name as the corresponding PackedScene, though it does not matter.

4) Fill out the fields in Chair.tres

	Collection name would be "Furniture" in this example
	
	By convention, a png file with a name matching the item name should be placed in the Thumbnail folder, though the location and name does not actually matter. Icons are not resized, they should be around 78x78 pixels in order to fit in the dock. A temporary icon is included for demonstration. We demonstrate how to automatically generate icons in the next step.
	
	Item name can be anything, but by convention is the same as the base of the path name. "Chair" in this case
	
	Scene path is the path to Chair.glb or Chair.gltf
	
	Do not edit fields in the Hidden group. (Todo: does Godot have @export_hidden yet?)

Note 1: The result of scene path being a field of a given SceneBuilderItem instance is that if the item PackedScene is moved around in the FileSystem, then item will no longer be found by SceneBuilder. Todo: How can we update paths when moving PackedScene files? For now, we should manually update scene path fields, or simply delete then recreate SceneBuilderItem resources in bulk.

Note 2: Although we demonstrate how to automatically generate items and icons in the next section, once SceneBuilderItem are made, they must be edited by hand for any further changes.

### Batch creation of items

1) Select paths in FileSystem that contain an imported scene with a root note that derives from type Node3D. These paths must end in either .glb or .tscn.
2) Run the "Create scene builder items" command by going to Project > Tools > Scene Builder > Create scene builder items, or by pressing the keyboard shortcut Alt + /
3) Fill out the fields in the popup window, then hit okay.
4) When the command "Create scene builder items" is run, the scene icon_studio will be opened. Please close the scene when it's done without saving any changes to icon_studio.tscn
5) In the scene builder dock, click the button "Reload all items"
