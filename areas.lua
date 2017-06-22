
-- TODO: offer teleport button?

-- Temporary compatibility function - see minetest PR#1180
if not vector.interpolate then
    vector.interpolate = function(pos1, pos2, factor)
	return {x = pos1.x + (pos2.x - pos1.x) * factor,
		y = pos1.y + (pos2.y - pos1.y) * factor,
		z = pos1.z + (pos2.z - pos1.z) * factor}
    end
end

-- taken from mobf
local COLOR_RED   = "#FF0000";
local COLOR_GREEN = "#00FF00";
local COLOR_WHITE = "#FFFFFF";


-- we need to store which list we present to which player
markers.menu_data_by_player = {}


markers.get_area_by_pos = function(pos)

   local found_areas = {};
   for id, area in pairs(areas.areas) do
      if( pos.x >= area.pos1.x and pos.x <= area.pos2.x and
          pos.y >= area.pos1.y and pos.y <= area.pos2.y and
          pos.z >= area.pos1.z and pos.z <= area.pos2.z )then

         area[ 'id' ] = id;
         table.insert(found_areas, area );
      end
   end
   return found_areas;
end



-- ppos: current player (or marker stone) position - used for sorting the list
-- mode: can be pos, player, all, subarea, main_areas
-- mode_data: content depends on mode
-- selected: display information about the area the player single-clicked on
markers.get_area_list_formspec = function(ppos, player, mode, pos, mode_data, selected )


   local id_list = {};
   local title   = '???';
   local tlabel  = '';

   -- expects a position in mode_data
   if(     mode=='pos' ) then
      -- title would be too long for a label
      title  = 'All areas at position: ';
      tlabel = minetest.colorize("#FFFF00", minetest.pos_to_string( mode_data ));

      for id, area in pairs(areas.areas) do

         if( mode_data.x >= area.pos1.x and mode_data.x <= area.pos2.x and
             mode_data.y >= area.pos1.y and mode_data.y <= area.pos2.y and
             mode_data.z >= area.pos1.z and mode_data.z <= area.pos2.z )then

            table.insert( id_list, id );
         end
      end

   -- expects a playername in mode_data
   elseif( mode=='player' ) then

      title  = 'All areas owned by player...';
      tlabel = '<'..tostring( mode_data )..'>:';

      for id, area in pairs(areas.areas) do

         if( area.owner == mode_data ) then
            table.insert( id_list, id );
         end
      end

   -- expects an area_id in mode_data
   elseif( mode=='subareas' ) then

      title  = 'All sub-areas of area...';
      tlabel = '<'..tostring( areas.areas[ mode_data ].name )..'> ['..tostring( mode_data )..']:';

      for id, area in pairs(areas.areas) do

         if( area.parent and area.parent == mode_data ) then
            table.insert( id_list, id );
         end
      end

   -- show only areas that do not have parents
   elseif( mode=='main_areas' ) then
      title  = 'Main areas (within '..tostring( markers.AREA_RANGE )..' m)';
      tlabel = '[main areas]';
      for id, area in pairs(areas.areas) do

         if( not( area.parent )
           -- ppos is always available
           and(   (area.pos1.x >= ppos.x-markers.AREA_RANGE and area.pos1.x <= ppos.x+markers.AREA_RANGE )
                or(area.pos2.x >= ppos.x-markers.AREA_RANGE and area.pos2.x <= ppos.x+markers.AREA_RANGE ))
           and(   (area.pos1.y >= ppos.y-markers.AREA_RANGE and area.pos1.y <= ppos.y+markers.AREA_RANGE )
                or(area.pos2.y >= ppos.y-markers.AREA_RANGE and area.pos2.y <= ppos.y+markers.AREA_RANGE ))
           and(   (area.pos1.z >= ppos.z-markers.AREA_RANGE and area.pos1.z <= ppos.z+markers.AREA_RANGE )
                or(area.pos2.z >= ppos.z-markers.AREA_RANGE and area.pos2.z <= ppos.z+markers.AREA_RANGE ))) then
            table.insert( id_list, id );
         end
      end
 

   elseif( mode=='all' ) then
      title  = 'Areas (within '..tostring( markers.AREA_RANGE )..' m)';
      tlabel = '[all areas]';

      for id, area in pairs(areas.areas) do
         if(  (   (area.pos1.x >= ppos.x-markers.AREA_RANGE and area.pos1.x <= ppos.x+markers.AREA_RANGE )
                or(area.pos2.x >= ppos.x-markers.AREA_RANGE and area.pos2.x <= ppos.x+markers.AREA_RANGE ))
           and(   (area.pos1.y >= ppos.y-markers.AREA_RANGE and area.pos1.y <= ppos.y+markers.AREA_RANGE )
                or(area.pos2.y >= ppos.y-markers.AREA_RANGE and area.pos2.y <= ppos.y+markers.AREA_RANGE ))
           and(   (area.pos1.z >= ppos.z-markers.AREA_RANGE and area.pos1.z <= ppos.z+markers.AREA_RANGE )
                or(area.pos2.z >= ppos.z-markers.AREA_RANGE and area.pos2.z <= ppos.z+markers.AREA_RANGE ))) then
            table.insert( id_list, id );
         end
      end
   end

   -- Sort the list of areas so the nearest comes first
   local nearsorter = function(a, b)
        return vector.distance(vector.interpolate(areas.areas[a].pos1, areas.areas[a].pos2, 0.5), ppos) <
		vector.distance(vector.interpolate(areas.areas[b].pos1, areas.areas[b].pos2, 0.5), ppos)
   end
   table.sort(id_list, nearsorter)

   local formspec = 'size[10,8.5]';

   title  = minetest.formspec_escape( title );
   tlabel = minetest.formspec_escape( tlabel );

   formspec = formspec..
	"label[0,0;"..title.."]"..
	"label[4.7,0;"..tlabel.."]"..
	"label[0,8;Areas found: ".. minetest.colorize("#FFFF00", tostring(#id_list)) .."]"..
	"textlist[0,0.7;7,7;markers_area_list_selection;"

   local liste = '';
   for i,v in ipairs( id_list ) do
      if( liste ~= '' ) then
         liste = liste..',';
      end
      liste = liste..minetest.formspec_escape( areas:toString( v ) );
         
   end

   -- highlight selected entry
   if( selected ) then
      formspec = formspec..liste..';'..selected..';false]';
   else
      formspec = formspec..liste..';]';
   end
   
   local pname = player:get_player_name();
   if( not( markers.menu_data_by_player[ pname ] )) then
      markers.menu_data_by_player[ pname ] = {};
   end

   -- display information about the location of the area the player clicked on
   if( selected 
      and id_list[ selected ]
      and areas.areas[ id_list[ selected ]] ) then

      local this_area = areas.areas[ id_list[ selected ]];

      local subareas = {};
      for i,v in pairs( areas.areas ) do
         if( v.parent and v.parent == id_list[ selected ]) then
            table.insert( subareas, i );
         end
      end

      formspec = formspec..
               markers.show_compass_marker( 8, 3.0, false, pos, this_area.pos1, this_area.pos2 );


      if( this_area.parent) then
         formspec = formspec..
               'button[3.15,8;4,0.5;show_parent;'.. 
			minetest.formspec_escape( areas.areas[ this_area.parent ].name )..']';
      end

      if( #subareas > 0 ) then
         formspec = formspec..
               'button[3.15,8;4,0.5;list_subareas;'..
                        minetest.formspec_escape( 'List subareas ('..tostring( #subareas )..')')..']';
      end
 

      if( mode=='player' ) then
         formspec = formspec..
               'label[8.0,1.5;'..
			minetest.formspec_escape( this_area.owner..'\'s areas')..']';
      else
         formspec = formspec..
               'button[3.15,8;4,0.5;list_player_areas;'..
			minetest.formspec_escape( this_area.owner..'\'s areas')..']';
      end

   end

   formspec = formspec..
               'button[3.15,8;4,0.5;list_main_areas;List all main areas]' ..
                default.gui_bg_img

   -- we need to remember especially the id_list - else it would be impossible to know what the
   -- player selected
   markers.menu_data_by_player[ pname ] = {
	  typ       = 'area_list',
          mode      = mode,
          pos       = pos,
          mode_data = mode_data,
          list      = id_list,

	  selected  = id_list[ selected ],
	};
         
	  
   return formspec;
end




-- shows a formspec with information about a particular area
-- pos is the position of the marker stone or place where the player clicked
--  with the land title register; it is used for relative display of coordinates
markers.get_area_desc_formspec = function( id, player, pos )

   if( not( areas.areas ) or not( id ) or not( areas.areas[ id ] )) then
      return 'field[info;Error:;Area not found.]';
   end
   local this_area = areas.areas[ id ];

   local pname     = player:get_player_name();

   -- show some buttons only if area is owned by the player
   local is_owner  = false;

   if( this_area.owner == pname ) then
      is_owner     = true;
   end

   local formspec  = 'size[10,7]'..
	'label[0,0.0;' .. minetest.colorize("#FFFF00", "Area information and management") .. ']'

   -- general information about the area
   formspec = formspec..
	'label[0,0.8;Area number: ' ..minetest.colorize("#FFFF00", tostring( id ))..']'..

	'label[0,1.3;Area name: ' ..minetest.colorize("#FFFF00",
        minetest.formspec_escape( this_area.name or '-not set-'))..']'..

	'label[0,1.8;Owned by: ' ..minetest.colorize("#FFFF00",
        minetest.formspec_escape( this_area.owner))..']';


   -- these functions are only available to the owner of the area
   if( is_owner ) then
      formspec = formspec..
        'button_exit[7,0.0;3,1;change_owner;Change owner]'..
        'button_exit[7,0.8;3,1;delete;Delete area]'..
        'button_exit[7.0,1.6;3,1;rename;Rename area]'..
        'button_exit[7.0,6.4;3,1;list_player_areas;My areas]';

   -- subareas of own areas can be deleted (but not renamed)
   elseif( not( is_owner )
      and this_area.parent
      and areas.areas[ this_area.parent ]
      and areas.areas[ this_area.parent ].owner == pname ) then
 
      formspec = formspec..
        'button_exit[7.0,1.0;2,0.5;delete;Delete subarea]'..
        'button_exit[7.0,2.0;2,0.5;list_player_areas;Player\'s areas]';

   else
      formspec = formspec..
        'button_exit[7.0,2.0;2,0.5;list_player_areas;Player\'s areas]';
   end


   -- players with the areas priv get an extra menu
   if not is_owner and ( minetest.check_player_privs(pname, {areas=true})) then
      formspec = formspec..
        'button_exit[7.0,0;3,1;change_owner;Change owner]'..
        'button_exit[7.0,0.8;3,1;delete;Delete]'..
        'button_exit[7.0,1.6;3,1;rename;Rename]';
   end


   -- show subowners and areas with the same coordinates
   formspec = formspec..
	'label[0,2.3;Sub-owners:]';
   local further_owners = {};
   for i, area in pairs(areas.areas) do
      if( i ~= id and
          this_area.pos1.x == area.pos1.x and this_area.pos2.x == area.pos2.x and
          this_area.pos1.y == area.pos1.y and this_area.pos2.y == area.pos2.y and
          this_area.pos1.z == area.pos1.z and this_area.pos2.z == area.pos2.z )then

         table.insert( further_owners, area.owner );
      end
   end
   if( #further_owners > 0 ) then

      formspec = formspec..
        'label[4.7,2.5;'..minetest.formspec_escape( table.concat( further_owners, ', '))..'.]';

      -- deleting subowners is done by deleting their areas
      if( is_owner ) then
         formspec = formspec..
	        'button_exit[7.0,4.8;3,1;add_owner;Add owner]';
      end
   else
      formspec = formspec..
        'label[2,2.3;-none-]';
 
      if( is_owner ) then
         formspec = formspec..
		'button_exit[7.0,4.8;3,1;add_owner;Add owner]';
      end
   end  


   -- is the area a subarea?
   if( this_area.parent ) then
      formspec = formspec..
	'label[0,3.0;This area is a sub-area of area]'..
	'label[4.7,3.0;'..minetest.formspec_escape( areas.areas[ this_area.parent ].name..' ['..this_area.parent..']' )..']'..
        'button_exit[8.0,3.0;2,0.5;show_parent;Show main area]';
   end
 

   -- does the area have subareas, i.e. is it a parent area for others?
   local sub_areas = {};
   for i, area in pairs(areas.areas) do
      if( i ~= id and
          area.parent == id ) then

         table.insert( sub_areas, i );
      end
   end
   if( #sub_areas > 0 ) then

      formspec = formspec..
	'label[0.5,2.8;Number of defined subareas: ' ..tostring( #sub_areas )..']'..
        'button_exit[8.0,4.0;2,0.5;list_subareas;List subareas]';
   else
      formspec = formspec..
	'label[0,2.8;There are no subareas defined.]';
   end


   -- give information about the size of the area
   local length_x = (math.abs( this_area.pos2.x - this_area.pos1.x )+1);
   local length_y = (math.abs( this_area.pos2.y - this_area.pos1.y )+1);
   local length_z = (math.abs( this_area.pos2.z - this_area.pos1.z )+1);

   formspec = formspec..
               'label[0,3.3;The area extends from '..
                      minetest.colorize("#FFFF00", minetest.pos_to_string( this_area.pos1 ))..
                      ' to '..
                      minetest.colorize("#FFFF00", minetest.pos_to_string( this_area.pos2 ))..'.]'..
               'label[0,3.8;It spans '..tostring( length_x )..
                                   ' x '..tostring( length_z )..
                                   ' m = '..tostring( length_x * length_z )..
                                   ' m². Height: '..tostring( length_y )..' m.]';


   formspec = formspec..
               markers.show_compass_marker( 2.0, 6.0, true, pos, this_area.pos1, this_area.pos2 ) ..
               default.gui_bg_img

-- TODO: buy / sell button

   local pname = player:get_player_name();
   if( not( markers.menu_data_by_player[ pname ] )) then
      markers.menu_data_by_player[ pname ] = {};
   end

   -- we need to remember especially the id_list - else it would be impossible to know what the
   -- player selected
   markers.menu_data_by_player[ pname ] =
	{ typ       = 'show_area',
          mode      = nil, 
          pos       = pos,
          mode_data = nil,
          list      = nil,

	  selected  = id,
	};
         
   return formspec;
end



-- shows where the area (defined by pos1/pos2) is located relative to the given position pos
-- row_offset/col_offset are offsets for the formspec
markers.show_compass_marker = function( col_offset, row_offset, with_text, pos, pos1, pos2 )

   local formspec = '';
-- TODO: show up/down information somehow
-- TODO: what if checked with a land claim register?

   -- if possible, show how far the area streches into each direction relative to pos
   if(     pos.x >= pos1.x and pos.x <= pos2.x 
       and pos.y >= pos1.y and pos.y <= pos2.y 
       and pos.z >= pos1.z and pos.z <= pos2.z ) then
 
      if( with_text ) then
         formspec = formspec..
		'label[0,4.5;Area dimensions from marker position at '..
        minetest.colorize("#FFFF00", minetest.pos_to_string( pos ))..':]'..
		'button_exit[7.0,5.6;3,1;list_areas_at;Local areas]';
      end
      formspec = formspec..
		'image['..(col_offset+0.1)..','..(row_offset-0.1)..';1,1;markers_stone.png]'..
		'label['..(col_offset-0.8)..','..(row_offset+0.05)..';'..tostring( pos.x - pos1.x         )..' m. ' .. minetest.colorize("#FFFF00", "W") .. ']'..
		'label['..(col_offset+1.0)..','..(row_offset+0.05)..';'..tostring(         pos2.x - pos.x )..' m. ' .. minetest.colorize("#FFFF00", "E") .. ']'..
		'label['..(col_offset+0.1)..','..(row_offset+0.80)..';'..tostring( pos.z - pos1.z         )..' m. ' .. minetest.colorize("#FFFF00", "S") .. ']'..
		'label['..(col_offset+0.1)..','..(row_offset-0.70)..';'..tostring(         pos2.z - pos.z )..' m. ' .. minetest.colorize("#FFFF00", "N") .. ']';

   -- else show how far the area is away
   else

      local starts_north = '';
      local starts_south = '';
      local starts_east  = '';
      local starts_west  = '';
      if( pos.z > pos2.z ) then
         starts_north = '';
         starts_south = tostring( pos.z - pos2.z         )..' m S';
      else
         starts_north = tostring(         pos1.z - pos.z )..' m N';
         starts_south = '';
      end
      if( pos.x > pos2.x ) then
         starts_east  = '';
         starts_west  = tostring( pos.x - pos2.x         )..' m W';
      else
         starts_east  = tostring(         pos1.x - pos.x )..' m E';
         starts_west  = '';
      end


      if( with_text ) then
         formspec = formspec..
		'label[0,4.5;Position of the area, from marker position at '..
        minetest.colorize("#FFFF00", minetest.pos_to_string( pos ))..':]'..
		'button_exit[7.0,5.6;3,1;list_areas_at;Local areas]';
      end
      formspec = formspec..
		'image['..(col_offset+0.1)..','..(row_offset-0.10)..';1,1;compass_side_top.png]'..
		'label['..(col_offset-0.8)..','..(row_offset+0.05)..';'..starts_west:sub(1,-2) .. minetest.colorize("#FFFF00", starts_west:sub(-1))..']'..
		'label['..(col_offset+1.0)..','..(row_offset+0.05)..';'..starts_east:sub(1,-2) .. minetest.colorize("#FFFF00", starts_east:sub(-1))..']'..
		'label['..(col_offset+0.1)..','..(row_offset-0.80)..';'..starts_north:sub(1,-2) .. minetest.colorize("#FFFF00", starts_north:sub(-1))..']'..
		'label['..(col_offset+0.1)..','..(row_offset+0.80)..';'..starts_south:sub(1,-2) .. minetest.colorize("#FFFF00", starts_south:sub(-1))..']'
   end
 
   return formspec;
end



-- formspec input needs to be handled diffrently
markers.form_input_handler_areas = function( player, formname, fields)

   local pname = player:get_player_name();
   local ppos = player:getpos()

   if( formname ~= "markers:info"
      or not( player )
      or not(  markers.menu_data_by_player[ pname ] )) then
   
      return false;
   end
  
   local menu_data = markers.menu_data_by_player[ pname ];
   local formspec = '';


   -- rename an area
   if( fields.rename 
          and menu_data.selected
          and areas.areas[ menu_data.selected ]
          and areas.areas[ menu_data.selected ].owner == pname ) then
   
      local area = areas.areas[ menu_data.selected ];
      if( not( area.name )) then
         area.name = '-enter area name-';
      end
      formspec = 'field[rename_new_name;Enter new name for area:;'..minetest.formspec_escape( area.name )..']';

   elseif( fields.rename_new_name 
          and menu_data.selected
          and  areas.areas[ menu_data.selected ]
          and ((areas.areas[ menu_data.selected ].owner == pname ) 
            or minetest.check_player_privs(pname, {areas=true}))) then
   
      local area = areas.areas[ menu_data.selected ];

      -- actually rename the area
      areas.areas[ menu_data.selected ].name = fields.rename_new_name;
      areas:save();

      minetest.chat_send_player( pname, 'Area successfully renamed.');
      -- shwo the renamed area
      formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
 

   
   -- change owner the area
   elseif( fields.change_owner
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then
   
      -- there are no checks here - those happen when the area is transferred
      local area = areas.areas[ menu_data.selected ];
      formspec = 'field[change_owner_name;Give area \"'..minetest.formspec_escape( area.name )..'\" to player:;-enter name of NEW OWNER-]';

   elseif( fields.change_owner_name
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then

      local area = areas.areas[ menu_data.selected ];

      -- only own areas can be transfered to another player (or if the areas priv is there)
      if( area.owner ~= pname 
        and not( minetest.check_player_privs(pname, {areas=true}))) then
 
         minetest.chat_send_player( pname, 'Permission denied. You do not own the area.');

      elseif( not( areas:player_exists( fields.change_owner_name ))) then

         minetest.chat_send_player( pname, 'That player does not exist.');

      else
         -- actually change the owner
         areas.areas[ menu_data.selected ].owner = fields.change_owner_name;
         areas:save()

         minetest.chat_send_player( pname, 'Your area '..tostring( area.name )..' has been transfered to '..tostring( fields.change_owner_name )..'.');

         minetest.chat_send_player( fields.change_owner_name, pname..'" has given you control over an area.')
      end

      formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );


   -- add an owner to the entire area
   elseif( fields.add_owner
          and menu_data.selected
          and areas.areas[ menu_data.selected ]
          and areas.areas[ menu_data.selected ].owner == pname ) then
   
      local area = areas.areas[ menu_data.selected ];
      formspec = 'field[add_owner_name;Grant access to area \"'..minetest.formspec_escape( area.name )..'\" to player:;-enter player name-]';

   elseif( fields.add_owner_name 
              -- the player has to own the area already; we need a diffrent name here
          and fields.add_owner_name ~= pname
          and menu_data.selected
          and areas.areas[ menu_data.selected ]
          and areas.areas[ menu_data.selected ].owner == pname ) then

      local area = areas.areas[ menu_data.selected ];

      -- does the player exist?
      if( not( areas:player_exists( fields.add_owner_name ))) then
         minetest.chat_send_player( pname, 'That player does not exist.');
         -- show the formspec
         formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

      else
         -- log the creation of the new area
         minetest.log("action", pname.." runs /add_owner through the markers-mod. Owner = "..fields.add_owner_name..
                                " AreaName = "..area.name.." ParentID = "..menu_data.selected..
                                " StartPos = "..area.pos1.x..","..area.pos1.y..","..area.pos1.z..
                                " EndPos = "  ..area.pos2.x..","..area.pos2.y..","..area.pos2.z)

         -- take the name from the old/parent area
         local new_id = areas:add( fields.add_owner_name, area.name, area.pos1, area.pos2, menu_data.selected );
         areas:save()


         minetest.chat_send_player( fields.add_owner_name,
                                "You have been granted control over area #"..
                                new_id..". Type /list_areas to show your areas.")

         minetest.chat_send_player( pname, 'The player may now build and dig in your area.');
         -- shwo the new area
         markers.menu_data_by_player[ pname ].selected = new_id;
         formspec = markers.get_area_desc_formspec( new_id, player, menu_data.pos );
      end



   -- delete area
   elseif( fields.delete 
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then

      local area = areas.areas[ menu_data.selected ];

      -- a player can only delete own areas or subareas of own areas
      if( area.owner ~= pname 
        and not(     area.parent 
                 and areas.areas[ area.parent ] 
                 and areas.areas[ area.parent ].owner
                 and areas.areas[ area.parent ].owner == pname )
        and not( minetest.check_player_privs(pname, {areas=true}))) then
 
         minetest.chat_send_player( pname, 'Permission denied. You own neither the area itshelf nor its parent area.');
         -- shwo the area where the renaming failed
         formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

      else

         formspec = 'field[rename_new_name;Enter new name for area:;'..minetest.formspec_escape( area.name )..']';
         formspec = 'field[delete_confirm;'..minetest.formspec_escape( 'Delete area '..
              minetest.colorize("#FFFF00", area.name)..
              ' (owned by '..minetest.colorize("#FFFF00", area.owner)..')?')..';-type YES (in capitals) to confirm-]';

      end

   elseif( fields.delete_confirm 
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then
   
      local area = areas.areas[ menu_data.selected ];
      local old_owner = area.owner;

      local subareas = {};
      for i,v in pairs( areas.areas ) do
         if( v.parent and v.parent == menu_data.selected ) then
            table.insert( subareas, i );
         end
      end

      -- a player can only delete own areas or subareas of own areas
      if( area.owner ~= pname 
        and not(     area.parent 
                 and areas.areas[ area.parent ] 
                 and areas.areas[ area.parent ].owner
                 and areas.areas[ area.parent ].owner == pname )
        and not( minetest.check_player_privs(pname, {areas=true}))) then
 
         minetest.chat_send_player( pname, 'Permission denied. You own neither the area itshelf nor its parent area.');
         -- shwo the renamed area
         formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

      -- avoid accidents
      elseif( fields.delete_confirm ~= 'YES' ) then
         minetest.chat_send_player( pname, 'Delition of area \"'..tostring( area.name )..'\" (owned by '..old_owner..') aborted.');
         formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

      -- only areas without subareas can be deleted
      elseif( #subareas > 0 ) then 
         minetest.chat_send_player( pname, 'The area has '..tostring( #subareas )..' subarea(s). Please delete those first!');
         formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

      else

         minetest.chat_send_player( pname, 'Area \"'..tostring( area.name )..'\" (owned by '..old_owner..') deleted.');
         -- really delete
         areas:remove( menu_data.selected, false ); -- no recursive delete
         areas:save();
         -- show the list of areas owned by the previous owner
         formspec = markers.get_area_list_formspec(ppos, player, 'player',   menu_data.pos, old_owner, nil );
      end

   

   elseif( fields.show_parent 
          and menu_data.selected
          and areas.areas[ menu_data.selected ]
          and areas.areas[ menu_data.selected ].parent ) then

      formspec = markers.get_area_desc_formspec( areas.areas[ menu_data.selected ].parent, player, menu_data.pos );


   elseif( fields.list_player_areas
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then

      formspec = markers.get_area_list_formspec(ppos, player, 'player',   menu_data.pos, areas.areas[ menu_data.selected ].owner, nil );


   elseif( fields.list_subareas
          and menu_data.selected
          and areas.areas[ menu_data.selected ] ) then

      formspec = markers.get_area_list_formspec(ppos, player, 'subareas', menu_data.pos, menu_data.selected, nil );


   elseif( fields.list_main_areas ) then

      formspec = markers.get_area_list_formspec(ppos, player, 'main_areas', menu_data.pos, nil, nil );
          
   elseif( fields.list_areas_at
          and menu_data.pos ) then

      formspec = markers.get_area_list_formspec(ppos, player, 'pos',      menu_data.pos, menu_data.pos, nil );


   elseif( fields.markers_area_list_selection
          and menu_data.typ
          and menu_data.typ == 'area_list'
          and menu_data.list
          and #menu_data.list > 0 ) then


      local field_data = fields.markers_area_list_selection:split( ':' );
      if( not( field_data ) or #field_data < 2 ) then
         field_data = { '', '' };
      end

      local selected = tonumber( field_data[ 2 ] );
      if( field_data[1]=='DCL' ) then

         -- on doubleclick, show detailed area information
         formspec = markers.get_area_desc_formspec( tonumber( menu_data.list[ selected ] ), player, menu_data.pos );
      else

         -- on single click, just show the position of that particular area
         formspec = markers.get_area_list_formspec(ppos, player, menu_data.mode, menu_data.pos, menu_data.mode_data, selected );
      end

   else
      return false;
   end


   minetest.show_formspec( pname, "markers:info", formspec )
   return true;
end



-- search the area at the given position pos that might be of most intrest to the player
markers.show_marker_stone_formspec = function( player, pos )

   local pname       = player:get_player_name();
   local ppos = pos

   -- this table stores the list the player may have selected from; at the beginning, there is no list 
   if( not( markers.menu_data_by_player[ pname ]  )) then
      markers.menu_data_by_player[ pname ] = {
	  typ       = 'area_list',
          mode      = 'main_areas',
          pos       = pos,
          mode_data = pos,
          list      = {},

	  selected  = nil,
      };
   end


   local formspec        = '';

   local found_areas     = {};
   local min_area_size   = 100000000000;

   for id, area in pairs(areas.areas) do
      if( pos.x >= area.pos1.x and pos.x <= area.pos2.x and
          pos.y >= area.pos1.y and pos.y <= area.pos2.y and
          pos.z >= area.pos1.z and pos.z <= area.pos2.z )then

         -- ignore y (height) value because some areas may go from bottom to top
         local area_size = math.abs( area.pos2.x - area.pos1.x )
                         * math.abs( area.pos2.z - area.pos1.z );

         -- collect subareas that have the same size
         if( area_size == min_area_size ) then
            table.insert(found_areas, id );
         -- we have found a smaller area - that is more intresting here
         elseif( area_size <= min_area_size ) then
            found_areas = {};
            min_area_size = area_size;
            table.insert(found_areas, id );
         end
      end
   end

   -- no areas found; display error message and selection menu
   if(     #found_areas < 1 ) then

      formspec = 'size[4,2]'..
 		'label[0,0;This position is not protected.]'..
		'button[0,0.8;4,0.5;list_main_areas;List all main areas]'..
		'button_exit[1.45,1.7;1.2,0.5;abort;OK]' ..
    default.gui_bg_img
 
   -- found exactly one areaa - display it
   elseif( #found_areas == 1 ) then

      formspec = markers.get_area_desc_formspec( found_areas[ 1 ], player, pos );

   -- found more than one area; we have saved only those with the smallest size
   else

      local own_area    = 0;
      local parent_area = 0;
      local upper_area  = 0;
      for i,v in ipairs( found_areas ) do

         local area = areas.areas[ v ];

         -- owned by player?
         if(          area.owner == pname ) then
            own_area    = v;

         -- parentless area?
         elseif( not( area.parent )) then
            parent_area = v;

         -- the parent has diffrent coordinates?
         elseif(      areas.areas[ area.parent ].pos1.x ~= area.pos1.x
                   or areas.areas[ area.parent ].pos1.y ~= area.pos1.y
                   or areas.areas[ area.parent ].pos1.z ~= area.pos1.z
                   or areas.areas[ area.parent ].pos2.x ~= area.pos2.x
                   or areas.areas[ area.parent ].pos2.y ~= area.pos2.y
                   or areas.areas[ area.parent ].pos2.z ~= area.pos2.z ) then
            upper_area = v;
         end
      end

      -- the area owned by the player is most intresting
      if(     own_area    > 0 ) then

         formspec = markers.get_area_desc_formspec( own_area,    player, pos );

      -- if the player owns none of these areas, show the topmost (parentless) area
      elseif( parent_area > 0 ) then

         formspec = markers.get_area_desc_formspec( parent_area, player, pos );

      -- an area which has a parent with diffrent coordinates from its child may (or may not) be the
      -- parent of all these subareas we've found here; there is no guarantee, but it's a best guess.
      -- If it is not good enough, then the player can still search for himshelf.
      elseif( upper_area  > 0 ) then

         formspec = markers.get_area_desc_formspec( upper_area,  player, pos );

      -- our superficial analysis of the structure of the areas failed; it is up to the player to
      -- find out which of the candidates he is intrested in; we list them all
      else

        formspec = markers.get_area_list_formspec(ppos, player, 'pos', pos, pos, nil );
      end
   end

   minetest.show_formspec( player:get_player_name(), "markers:info", formspec );
end
