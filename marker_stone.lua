
minetest.register_node("markers:stone", {
	description = "Boundary marker for land administration",
	tiles = {"markers_stone.png", "markers_stone.png", "markers_stone_side.png",
                "markers_stone_side.png", "markers_stone_side.png", "markers_stone_side.png" },
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
})


minetest.register_craft({
   output = "markers:stone",
   recipe = { { "markers:mark" },
              { "default:cobble" },
             } });

