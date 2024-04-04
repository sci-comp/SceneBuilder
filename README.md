# SceneBuilder
A system for efficiently building 3D scenes in Godot

## User guide

SceneBuilder requires a bit of manual set up. This isn't an ideal user experience, but doing this way leads to very simple and stable code, please bear with us!

In order to set-up Scene Builder, follow these steps,

### Initialize your data folder

1) Create an empty folder,
	`res://Data/SceneBuilderCollections`

Note: This folder path is hard coded into SceneBuilder.

2) Create a CollectionNames resource at the following location by first creating a new Resource, then by attaching the script: scene_builder_collections.gd,
	`res://Data/SceneBuilderCollections/collection_names.tres`

Note: This resource path is hard coded into SceneBuilder.

3) Enter your desired collection names into the CollectionNames resource, then create empty folders with matching names.

Note 1: For example, if you would like a collection named "Furniture," then write "Furniture" in the CollectionNames resource. Next, create an empty folder "Furniture" at location: `res://Data/SceneBuilderCollections/Furniture/`
Note 2: If you have a folder in `res://Data/SceneBuilderCollections/` that is not listed in the CollectionNames resource, then it will simply be ignored. Conversely, if a collection name is written in CollectionNames, then an error will occur if a matching folder is not found.
Note 3: SceneBuilder only provides space for 12 collections, however, you can make additional folders. We can update which 12 collections are currently in use by swapping out names in the CollectionNames resource, then hitting the "Reload all items" button in the scene builder dock.
Note 4: The decision to have 12 collections was an arbitrary one, though it does fit nicely into the UI dock.

4) Your data folder is now initialized. 

You can enable the plugin now to preview your collection names in the scene builder dock. However, since our collection folders are empty, you will see an error: `Directory exists, but contains no items: Furniture`

### Manually create one item

Usually, we will want to create `SceneBuilderItem`s in bulk. However, for demonstration purposes, let's create our first item manually.

Let's continue with a "Furniture" category. Assuming you have already added "Furniture" to collection names, and have created an empty "Furniture" folder,

1) Create a PackedScene of your choice. For this example, I will assume that you already have "Chair.glb" or "Chair.gltf" somewhere in your project files.

Note 1: SceneBuilder will only work with files ending in .glb or .gltf. 
Note 2: The root node of the imported scenes must derive from Node3D.

2) Create two sub folders "Item" and "Thumbnail" at locations,
	`res://Data/SceneBuilderCollections/Furniture/Item/`
	`res://Data/SceneBuilderCollections/Furniture/Thumbnail/`

3) Create a new resource 

### Batch creation of items

todo

