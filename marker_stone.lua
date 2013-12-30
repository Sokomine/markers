
minetest.register_node("markers:stone", {
	description = "Boundary marker for land administration",
	tiles = {"markers_stone.png", "markers_stone.png", "markers_stone_side.png",
                "markers_stone_side.png", "markers_stone_side.png", "markers_stone_side.png" },
-- no facedir here - we want a fixed north indication!
--	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,

	on_rightclick = function(pos, node, clicker)

           minetest.show_formspec( clicker:get_player_name(), "markers:info",
                markers.get_area_list_formspec( clicker, 'pos', pos, pos, nil ));
         return;

	end,
})


minetest.register_craft({
   output = "markers:stone",
   recipe = { { "markers:mark" },
              { "default:cobble" },
             } });

