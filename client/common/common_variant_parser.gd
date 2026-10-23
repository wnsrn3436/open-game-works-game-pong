class_name CommonVariantParser
extends RefCounted
## Workaround for an engine race (Godot 4.7.2): the text resource parser fills a shared type name table the first
## time it reads a typed array (`Array[...]`), with no lock. When two threaded loads read their first typed array at
## the same time, both write the table and the process crashes (signal 11). The match tween presets have typed arrays
## and load in parallel. `warm` reads one typed array on the calling thread so the table is full before any threaded
## load. The content entries call it on the main thread before the boot starts.


static func warm() -> void:
	str_to_var("Array[int]([])")
