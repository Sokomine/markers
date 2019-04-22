
-- markers are useful for measuring distances and for marking areas, regions or zones
-- it should work with areas and raz
-- markers are protected from digging by other players for one day
-- (the protection for the *marker* auto-expires then, and it can be digged)

markers = {


-- Paths and infos to the mod
	worlddir = minetest.get_worldpath(),
	modname = minetest.get_current_modname(),
	modpath = minetest.get_modpath(minetest.get_current_modname()),
	mod_areas_present = nil,
	mod_raz_present = nil,
}


-- load the .luas
dofile(markers.modpath.."/config.lua")
dofile(markers.modpath.."/functions.lua")

-- check if areas or raz is installed
markers.mod_areas_present = minetest.get_modpath("areas")
markers.mod_raz_present = minetest.get_modpath("raz")

if markers.mod_areas_present and markers.mod_raz_present then
	minetest.log("error", "[" .. markers.modname .. "] areas and raz is installed - what shall be used!!!!!!")
elseif markers.mod_areas_present and not markers.mod_raz_present then
		dofile(markers.modpath.."/areas.lua")
		minetest.log("action", "[" .. markers.modname .. "] areas is installed - load areas.lua")
elseif markers.mod_raz_present and not markers.mod_areas_present then
		dofile(markers.modpath.."/raz.lua")
		minetest.log("action", "[" .. markers.modname .. "] raz is installed - load raz.lua")
else
	minetest.log("error", "[" .. markers.modname .. "] I fond no installed version of areas or raz - what shall be used!!!!!!")
end


dofile(markers.modpath.."/marker_stone.lua")
dofile(markers.modpath.."/land_title_register.lua")









-- this function is supposed to return a text string describing the price of the land between pos1 and pos2
-- You can return somethiing like "for free" or "the promise to build anything good" as well as any
-- real prices in credits or materials - it's really just a text here.
-- Make sure you do not charge the player more than what you ask here.
markers.calculate_area_price_text = function( pos1, pos2, playername )

   local price = ( math.abs( pos1.x - pos2.x )+1 )
               * ( math.abs( pos1.z - pos2.z )+1 );

--               * math.ceil( ( math.abs( pos1.y - pos2.y )+1 )/10);

   return tostring( price )..' credits';
end




markers.marker_placed = function( pos, placer, itemstack )

   if( not( pos ) or not( placer )) then
      return;
   end

   local meta = minetest.get_meta( pos );
   local name = placer:get_player_name();

   meta:set_string( 'infotext', 'Marker at '..minetest.pos_to_string( pos )..
				' (placed by '..tostring( name )..'). '..
				'Right-click to update.');
   meta:set_string( 'owner',    name );
   -- this allows protection of this particular marker to expire
   meta:set_string( 'time',     tostring( os.time()) );

   local txt = '';

   if( not( markers.positions[ name ] ) or #markers.positions[name]<1) then
      markers.positions[ name ] = {};
      markers.positions[ name ][ 1 ] = pos;

      minetest.chat_send_player( name,
		'First marker set to position '..
		minetest.pos_to_string( markers.positions[ name ][ 1 ] )..
		'. Please place a second marker to measure distance. '..
		'Place four markers in a square to define an area.');
   else
      table.insert( markers.positions[ name ], pos );

      local n = #markers.positions[ name ];

      local dx = markers.positions[ name ][ n ].x - markers.positions[ name ][ n-1 ].x;
      local dy = markers.positions[ name ][ n ].y - markers.positions[ name ][ n-1 ].y;
      local dz = markers.positions[ name ][ n ].z - markers.positions[ name ][ n-1 ].z;

      local dir_name = "unknown";
      local d = 0;
      if(     dx == 0 and dz > 0 )             then dir_name = "north"; d = math.abs(dz);
      elseif( dx == 0 and dz < 0 )             then dir_name = "south"; d = math.abs(dz);
      elseif( dz == 0 and dx > 0 )             then dir_name = "east";  d = math.abs(dx);
      elseif( dz == 0 and dx < 0 )             then dir_name = "west";  d = math.abs(dx);
      elseif( dx == 0 and dz == 0 and dy > 0 ) then dir_name = "above"; d = math.abs(dy);
      elseif( dx == 0 and dz == 0 and dy < 0 ) then dir_name = "below"; d = math.abs(dy);
      else

         local area   =        (math.abs( dx )+1)
                             * (math.abs( dz )+1);
         local volume = area * (math.abs( dy )+1);

         minetest.chat_send_player( name, 'This marker is at '..
               minetest.pos_to_string( markers.positions[ name ][ n ] )..', while the last one is at '..
               minetest.pos_to_string( markers.positions[ name ][ n-1 ] )..'. Distance (x/y/z): '..
               tostring(math.abs(dx))..'/'..
               tostring(math.abs(dy))..'/'..
               tostring(math.abs(dz))..
              '. Area: '..tostring( area )..' m^2. Volume: '..tostring( volume )..' m^3.');
      end

      -- this marker is aligned to the last one
      if( d > 0 ) then
         minetest.chat_send_player( name, 'Marker placed at '..minetest.pos_to_string( pos )..
				'. Relative to the marker you placed before, this one is '..
 				tostring( d )..' m '..dir_name..'.');
      end

      -- make sure the list does not grow too large
      if( n > markers.MAX_MARKERS ) then
         table.remove( markers.positions[ name ], 1 );
      end
   end
end



markers.marker_can_dig = function(pos,player)

   if( not( pos ) or not( player )) then
      return true;
   end

   local meta  = minetest.get_meta( pos );
   local owner = meta:get_string( 'owner' );
   local time  = meta:get_string( 'time' );

   -- can the marker be removed?
   if( not( owner )
       or owner==''
       or not( time )
       or time==''
       or (os.time() - tonumber( time )) > markers.EXPIRE_AFTER ) then

      return true;

   -- marker whose data got lost anyway
   elseif( not( markers.positions[ owner ] )
            or #markers.positions[ owner ] < 1 ) then

     return true;

   -- marker owned by someone else and still in use
   elseif( owner ~= player:get_player_name()) then

      minetest.chat_send_player( player:get_player_name(),
		'Sorry, this marker belongs to '..tostring( owner )..
		'. If you still want to remove it, try again in '..
		( tostring( markers.EXPIRE_AFTER + tonumber( time ) - os.time()))..' seconds.');
      return false;

   end

   return true;
end




markers.marker_after_dig_node = function(pos, oldnode, oldmetadata, digger)

   if( not(oldmetadata ) or not(oldmetadata['fields'])) then
      return;
   end

   local owner = oldmetadata['fields']['owner'];
   if( not( owner )
       or owner==''
       or not( markers.positions[ owner ] )
       or     #markers.positions[ owner ] < 1 ) then

      return;
   end

   -- remove the markers position from our table of stored positions
   local found = 0;
   for i,v in ipairs( markers.positions[ owner ] ) do
      if(   v.x == pos.x
        and v.y == pos.y
        and v.z == pos.z ) then
         found = i;
      end
   end
   if( found ~= 0 ) then
      table.remove( markers.positions[ owner ], found );
   end
   return true;
end


--this function returns a min_pos and max_pos that are the corners
--of a box that contains ALL of the players active markers.
markers.get_box_from_markers = function(name)
  if (not name) or (not (markers.positions[ name ][ 1 ] )) then
	  return {x=0,y=0,z=0},{x=1,y=1,z=1}
	end
  local min_pos={}
	min_pos.x = markers.positions[ name ][ 1 ].x
	min_pos.y = markers.positions[ name ][ 1 ].y
	min_pos.z = markers.positions[ name ][ 1 ].z
	local max_pos={}
	max_pos.x = markers.positions[ name ][ 1 ].x
	max_pos.y = markers.positions[ name ][ 1 ].y
	max_pos.z = markers.positions[ name ][ 1 ].z
	for i,p in ipairs( markers.positions[ name ] ) do
	  if p.x < min_pos.x then min_pos.x = p.x end
		if p.x > max_pos.x then max_pos.x = p.x end
		if p.y < min_pos.y then min_pos.y = p.y end
		if p.y > max_pos.y then max_pos.y = p.y end
		if p.z < min_pos.z then min_pos.z = p.z end
		if p.z > max_pos.z then max_pos.z = p.z end
	end
	--print("getbox: min_pos.x="..min_pos.x.." y="..min_pos.y.." z="..min_pos.z)
	--print("      : max_pos.x="..max_pos.x.." y="..max_pos.y.." z="..max_pos.z)
  return min_pos, max_pos
end --get_box_from_markers











-- formspec input needs to be handled diffrently
markers.form_input_handler = function( player, formname, fields)

   if( formname == "markers:mark" ) then


      if( not(fields) or fields['abort']) then
         return true;
      end

      --- decode the position of the marker (which is hidden in the Buy-buttons name
      local pos = {};
      for k, v in pairs( fields ) do
         if( v == 'Protect area' ) then
            pos = minetest.string_to_pos( k );
         end
      end
      if( pos and pos.x and pos.y and pos.z ) then
         markers.marker_on_receive_fields(pos, formname, fields, player);
      end
      return true;


   elseif( formname == "markers:info"
      and player
      and markers.menu_data_by_player[ player:get_player_name() ] ) then

      local res = markers.form_input_handler_areas( player, formname, fields);
      if( res ) then
         return true;
      end

      -- TODO
--      minetest.chat_send_player('singleplayer','MARKERS:INFO WITH '..minetest.serialize( fields ));

   else
      -- TODO
--      minetest.chat_send_player('singleplayer','YOU CALLED '..tostring( formname )..' WITH '..minetest.serialize( fields ));

   end

   return false;

end

minetest.register_on_player_receive_fields( markers.form_input_handler)




minetest.register_node("markers:mark", {
	description = "Marker",
	tiles = {"markers_mark.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=1}, --fixed on both buttons dig client crash
	light_source = 1,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.1, -0.5, -0.1, 0.1, 1.5, 0.1 },
			},
		},

        after_place_node = function(pos, placer, itemstack)
           markers.marker_placed( pos, placer, itemstack );
        end,

        -- the node is digged immediately, so we may as well do all the work in can_dig (any wrong digs are not that critical)
        can_dig = function(pos,player)
           return markers.marker_can_dig( pos, player );
        end,

        after_dig_node = function(pos, oldnode, oldmetadata, digger)
           return markers.marker_after_dig_node( pos, oldnode, oldmetadata, digger );
        end,

	on_rightclick = function(pos, node, clicker)

           minetest.show_formspec( clicker:get_player_name(),
				   "markers:mark",
				   markers.get_marker_formspec(clicker, pos, nil)
			);
	end,
})


minetest.register_craft({
   output = "markers:mark 4",
   recipe = { { "group:stick" },
              { "default:apple" },
              { "group:stick" },
             } });

