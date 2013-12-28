



markers.get_area_info = function(pos)
   local found = {}
   for nr, area in pairs(areas.areas) do
      if pos.x >= area.pos1.x and pos.x <= area.pos2.x and
         pos.y >= area.pos1.y and pos.y <= area.pos2.y and
         pos.z >= area.pos1.z and pos.z <= area.pos2.z then
              area[ 'id' ] = nr;
              table.insert( found, area )
      end
   end
   return found;
end



markers.get_area_info_as_text = function(pos, name)

   local text = 'Checking '..minetest.pos_to_string( pos )..'. Owned by: ';

   local found_areas = markers.get_area_info( pos );
--minetest.chat_send_player('singleplayer', 'Areas FOUND: '..minetest.serialize( found_areas ));

   if( not( found_areas ) or #found_areas < 1 ) then
      minetest.chat_send_player( name, text..'-nobody- (unprotected)');
      return;
   end

   local parent = {};
   for _, area in pairs( found_areas ) do
      if( not( area[ 'parent' ] )) then 
         parent = area;
         minetest.chat_send_player(name, '  '..areas:toString( area['id']))
      end
   end

   if( #found_areas > 1 ) then
      minetest.chat_send_player(name, '  Sub-owners of entire area:');
   
      for _, area in pairs( found_areas ) do
         if( area[ 'parent' ]==parent['nr'] ) then
            if(  parent.pos1.x == area.pos1.x
             and parent.pos1.y == area.pos1.y
             and parent.pos1.z == area.pos1.z
             and parent.pos2.x == area.pos2.x
             and parent.pos2.y == area.pos2.y
             and parent.pos2.z == area.pos2.z) then 

               minetest.chat_send_player(name, '    '..areas:toString( area['id']))
            end    
         end
      end
   end


   if( #found_areas > 1 ) then
      minetest.chat_send_player(name, '  Sub-owners:');
   
      for _, area in pairs( found_areas ) do
         if( area[ 'parent' ] ) then 
            minetest.chat_send_player(name, '    '..areas:toString( area['id']))
         end
      end
   end

    minetest.chat_send_player(name, 'ALL owners:');
   for _, area in pairs( found_areas ) do
      minetest.chat_send_player(name, '    '..areas:toString( area['id']))
   end
end


minetest.register_tool( "markers:land_title_register",
{
    description = "Land title register. Left-click with it to get information about the land owner or to protect your own ground.",
    groups = {}, 
    inventory_image = "default_book.png", -- TODO
    wield_image = "",
    wield_scale = {x=1,y=1,z=1},
    stack_max = 1, -- there is no need to have more than one
    liquids_pointable = true, -- ground with only water on can be owned as well
    -- the tool_capabilities are completely irrelevant here - no need to dig
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level=0,
        groupcaps={
            fleshy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
            snappy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
            choppy={times={[3]=0.90}, maxwear=0.05, maxlevel=0}
        }
    },
    node_placement_prediction = nil,

    on_place = function(itemstack, placer, pointed_thing)

       if( placer == nil or pointed_thing == nil) then
          return itemstack; -- nothing consumed
       end
       local name = placer:get_player_name();

       -- the position is what we're actually looking for
       local pos  = minetest.get_pointed_thing_position( pointed_thing, 0 ); --under );
       
       if( not( pos ) or not( pos.x )) then
          minetest.chat_send_player( name, "Position not found.");
          return;
       end

       local found_areas = markers.get_area_info_as_text( pos, placer:get_player_name() );
-- TODO
--       inspector.search_node( pos.x, pos.y, pos.z, name );
       return itemstack; -- nothing consumed, nothing changed
    end,
     

    on_use = function(itemstack, placer, pointed_thing)

       if( placer == nil or pointed_thing == nil) then
          return itemstack; -- nothing consumed
       end
       local name = placer:get_player_name();

       local pos  = minetest.get_pointed_thing_position( pointed_thing, under );
       
       if( not( pos ) or not( pos.x )) then
          minetest.chat_send_player( name, "Position not found.");
          return;
       end
-- TODO
--       inspector.search_node( pos.x, pos.y, pos.z, name );
       local found_areas = markers.get_area_info_as_text( pos, placer:get_player_name() );

       return itemstack; -- nothing consumed, nothing changed
    end,
})

