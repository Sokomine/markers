
-- TODO: offer teleport button?


-- returns the first area found
markers.get_area_by_pos1_pos2 = function(pos1, pos2)
   for id, area in pairs(areas.areas) do

      if( ((area.pos1.x == pos1.x and area.pos1.z == pos1.z )
        or (area.pos1.x == pos1.x and area.pos1.z == pos2.z )
        or (area.pos1.x == pos2.x and area.pos1.z == pos1.z )
        or (area.pos1.x == pos2.x and area.pos1.z == pos2.z ))

       and((area.pos2.x == pos1.x and area.pos2.z == pos1.z )
        or (area.pos2.x == pos1.x and area.pos2.z == pos2.z )
        or (area.pos2.x == pos2.x and area.pos2.z == pos1.z )
        or (area.pos2.x == pos2.x and area.pos2.z == pos2.z ))) then

          -- at least pos1 needs to have a hight value that fits in
          if(  (area.pos1.y <= pos1.y and area.pos2.y >= pos1.y)
            or (area.pos1.y >= pos1.y and area.pos2.y <= pos1.y)) then

             local found = area;
             found[ 'id' ] = id;
             return found;

          end
      end
   end
   return nil;
end


-- protect/buy an area
markers.marker_on_receive_fields = function(pos, formname, fields, sender)

   if( not( pos )) then
      minetest.chat_send_player( name, 'Sorry, could not find the marker you where using to access this formspec.' );
      return;
   end


   local meta  = minetest.get_meta( pos );

   local name  = sender:get_player_name();

   local coords_string = meta:get_string( 'coords' );
   if( not( coords_string ) or coords_string == '' ) then
      minetest.chat_send_player( name, 'Could not find marked area. Please dig and place your markers again!');
      return;
   end
   local coords = minetest.deserialize( coords_string );


   -- do not protect areas twice
   local area = markers.get_area_by_pos1_pos2( coords[1], coords[2] );
   if( area ) then

      minetest.chat_send_player( name, 'This area is already protected.');
      return;
   end


   -- check input
   local add_height = tonumber( fields['add_height'] );
   local add_depth  = tonumber( fields['add_depth']  );

   local error_msg = '';
   if(     not( add_height ) or add_height < 0 or add_height > markers.MAX_HEIGHT ) then
      minetest.chat_send_player( name, 'Please enter a number between 0 and '..tostring( markers.MAX_HEIGHT )..
		' in the field where the height of your area is requested. Your area will stretch that many blocks '..
		'up into the sky from the position of this marker onward.');
      error_msg = 'The height value\nhas to be larger than 0\nand smaller than '..tostring( markers.MAX_HEIGHT );

   elseif( not( add_depth  ) or add_depth  < 0 or add_depth  > markers.MAX_HEIGHT ) then
      minetest.chat_send_player( name, 'Please enter a number between 0 and '..tostring( markers.MAX_HEIGHT )..
		' in the field where the depth of your area is requested. Your area will stretch that many blocks '..
		'into the ground from the position of this marker onward.');
      error_msg = 'The depth value\nhas to be larger than 0\nand smaller than '..tostring( markers.MAX_HEIGHT );

   elseif( add_height + add_depth > markers.MAX_HEIGHT ) then
      minetest.chat_send_player( name,  'Sorry, your area exceeds the height limit. Height and depth added have to '..
		'be smaller than '..tostring( markers.MAX_HEIGHT )..'.');
      error_msg = 'height + depth has to\nbe smaller than '..tostring( markers.MAX_HEIGHT )..'.'

   elseif( not( fields[ 'set_area_name' ] ) or fields['set_area_name'] == 'please enter a name' ) then
      minetest.chat_send_player( name, 'Please provide a name for your area, i.e. \"'..
		tostring( name )..'s first house\" The name ought to describe what you intend to build here.');
      error_msg = 'Please provide a\nname for your area!';

   else
      error_msg = nil;
   end


   if( error_msg ~= nil ) then
      minetest.show_formspec( name, "markers:mark", markers.get_marker_formspec(sender, pos, error_msg));
      return;
   end


   -- those coords lack the height component
   local pos1 = coords[1];
   local pos2 = coords[2];
   -- apply height values from the formspeck
   pos1.y = pos1.y - add_depth;
   pos2.y = pos2.y + add_height;

   pos1, pos2 = areas:sortPos( pos1, pos2 );

   --minetest.chat_send_player('singleplayer','INPUT: '..minetest.serialize( pos1  )..' pos2: '..minetest.serialize( pos2 ));
   minetest.log("action", "[markers] /protect invoked, owner="..name..
                                " areaname="..fields['set_area_name']..
                                " startpos="..minetest.pos_to_string(pos1)..
                                " endpos="  ..minetest.pos_to_string(pos2));

   local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, name)
   if not canAdd then
      minetest.chat_send_player(name, "You can't protect that area: "..errMsg)
      minetest.show_formspec( name, "markers:mark", markers.get_marker_formspec(sender, pos, errMsg));
      return
   end

   local id = areas:add(name, fields['set_area_name'], pos1, pos2, nil)
   areas:save()

   minetest.chat_send_player(name, "Area protected. ID: "..id)

   minetest.show_formspec( name, "markers:mark", markers.get_marker_formspec(sender, pos, nil));
end


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
      title  = 'All areas which contain position..';
      tlabel = '<'..minetest.pos_to_string( mode_data )..'>:';

      for id, area in pairs(areas.areas) do

         if( mode_data.x >= area.pos1.x and mode_data.x <= area.pos2.x and
             mode_data.y >= area.pos1.y and mode_data.y <= area.pos2.y and
             mode_data.z >= area.pos1.z and mode_data.z <= area.pos2.z )then

            table.insert( id_list, id );
         end
      end

   -- expects a playername in mode_data
   elseif( mode=='player' ) then

      title  = 'All areas owned by player..';
      tlabel = '<'..tostring( mode_data )..'>:';

      for id, area in pairs(areas.areas) do

         if( area.owner == mode_data ) then
            table.insert( id_list, id );
         end
      end

   -- expects an area_id in mode_data
   elseif( mode=='subareas' ) then

      title  = 'All subareas of area..';
      tlabel = '<'..tostring( areas.areas[ mode_data ].name )..'> ['..tostring( mode_data )..']:';

      for id, area in pairs(areas.areas) do

         if( area.parent and area.parent == mode_data ) then
            table.insert( id_list, id );
         end
      end

   -- show only areas that do not have parents
   elseif( mode=='main_areas' ) then
      title  = 'All main areas withhin '..tostring( markers.AREA_RANGE )..' m:';
      tlabel = '*all main areas*';
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
      title  = 'All areas withhin '..tostring( markers.AREA_RANGE )..' m:';
      tlabel = '*all areas*';

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

   local formspec = 'size[10,9]';

   title  = minetest.formspec_escape( title );
   tlabel = minetest.formspec_escape( tlabel );

   formspec = formspec..
	"label[0.5,0;"..title.."]"..
	"label[4.7,0;"..tlabel.."]"..
	"label[0.5,8.5;Doubleclick to select area.]"..
	"label[4.7,8.5;Areas found: "..tostring( #id_list )..".]"..
	"textlist[0.5,0.5;7,8;markers_area_list_selection;"; 

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
               markers.show_compass_marker( 8.5, 3.0, false, pos, this_area.pos1, this_area.pos2 );


      if( this_area.parent) then
         formspec = formspec..
               'button[8.0,0.5;2,0.5;show_parent;'.. 
			minetest.formspec_escape( areas.areas[ this_area.parent ].name )..']';
      end

      if( #subareas > 0 ) then
         formspec = formspec..
               'button[8.0,1.0;2,0.5;list_subareas;'..
                        minetest.formspec_escape( 'List subareas ('..tostring( #subareas )..')')..']';
      end
 

      if( mode=='player' ) then
         formspec = formspec..
               'label[8.0,1.5;'..
			minetest.formspec_escape( this_area.owner..'\'s areas')..']';
      else
         formspec = formspec..
               'button[8.0,1.5;2,0.5;list_player_areas;'..
			minetest.formspec_escape( this_area.owner..'\'s areas')..']';
      end

   end

   formspec = formspec..
               'button[8.0,8.5;2,0.5;list_main_areas;List all main areas]';

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

   local formspec  = 'size[10,9]'..
	'label[2.5,0.0;Area information and management]'..
	'button_exit[4.7,7.0;1,0.5;abort;OK]';

   -- general information about the area
   formspec = formspec..
	'label[0.5,1.0;This is area number ]'..
        'label[4.7,1.0;'..tostring( id )..']'..

	'label[0.5,1.5;The area is called ]'..
        'label[4.7,1.5;'..minetest.formspec_escape( this_area.name or '-not set-')..']'..

	'label[0.5,2.0;It is owned by ]'..
        'label[4.7,2.0;'..minetest.formspec_escape( this_area.owner)..']';


   -- these functions are only available to the owner of the area
   if( is_owner ) then
      formspec = formspec..
        'button_exit[8.0,0.0;2,0.5;change_owner;Change owner]'..
        'button_exit[8.0,1.0;2,0.5;delete;Delete]'..
        'button_exit[8.0,1.5;2,0.5;rename;Rename]'..
        'button_exit[8.0,2.0;2,0.5;list_player_areas;My areas]';

   -- subareas of own areas can be deleted (but not renamed)
   elseif( not( is_owner )
      and this_area.parent
      and areas.areas[ this_area.parent ]
      and areas.areas[ this_area.parent ].owner == pname ) then
 
      formspec = formspec..
        'button_exit[8.0,1.0;2,0.5;delete;Delete subarea]'..
        'button_exit[8.0,2.0;2,0.5;list_player_areas;Player\'s areas]';

   else
      formspec = formspec..
        'button_exit[8.0,2.0;2,0.5;list_player_areas;Player\'s areas]';
   end


   -- players with the areas priv get an extra menu
   if( minetest.check_player_privs(pname, {areas=true})) then
      formspec = formspec..
              'label[8.0,6.0;Admin commands:]'..
        'button_exit[8.0,6.5;2,0.5;change_owner;Change owner]'..
        'button_exit[8.0,7.0;2,0.5;delete;Delete]'..
        'button_exit[8.0,7.5;2,0.5;rename;Rename]';
   end


   -- show subowners and areas with the same coordinates
   formspec = formspec..
	'label[0.5,2.5;Further owners of the entire area:]';
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
	        'button_exit[8.0,2.5;2,0.5;add_owner;Add]';
      end
   else
      formspec = formspec..
        'label[4.7,2.5;-none-]';
 
      if( is_owner ) then
         formspec = formspec..
		'button_exit[8.0,2.5;2,0.5;add_owner;Add]';
      end
   end  


   -- is the area a subarea?
   if( this_area.parent ) then
      formspec = formspec..
	'label[0.5,3.0;This area is a sub-area of area]'..
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
	'label[0.5,4.0;Number of defined subareas:]'..
        'label[4.7,4.0;'..tostring( #sub_areas )..']'..
        'button_exit[8.0,4.0;2,0.5;list_subareas;List subareas]';
   else
      formspec = formspec..
	'label[0.5,4.0;There are no subareas defined.]';
   end


   -- give information about the size of the area
   local length_x = (math.abs( this_area.pos2.x - this_area.pos1.x )+1);
   local length_y = (math.abs( this_area.pos2.y - this_area.pos1.y )+1);
   local length_z = (math.abs( this_area.pos2.z - this_area.pos1.z )+1);

   formspec = formspec..
               'label[0.5,4.5;The area extends from]'..
               'label[4.7,4.5;'..minetest.pos_to_string( this_area.pos1 )..' to '..minetest.pos_to_string( this_area.pos2 )..'.]'..
               'label[4.7,4.75;It spans '..tostring( length_x )..
                                   ' x '..tostring( length_z )..
                                   ' = '..tostring( length_x * length_z )..
                                   ' m^2. Height: '..tostring( length_y )..' m.]';


   formspec = formspec..
               markers.show_compass_marker( 2.0, 7.0, true, pos, this_area.pos1, this_area.pos2 );

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
         formspec = 'field[delete_confirm;'..minetest.formspec_escape( 'Really delete area \"'..area.name..
                            '\" (owned by '..area.owner..')? Confirm with YES:')..';-type yes in capitals to confirm-]';

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

      formspec = 'size[4,3]'..
 		'label[0.5,0.5;This position is not protected.]'..
		     'button[1.0,1.5;2,0.5;list_main_areas;List all main areas]'..
		'button_exit[3.0,1.5;1,0.5;abort;OK]';
 
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



markers.get_marker_formspec = function(player, pos, error_msg)
   local formspec = "";

   local meta  = minetest.get_meta( pos );
   local owner = meta:get_string( 'owner' );

   local name  = player:get_player_name();

   local formspec_info = "size[6,4]"..
             "button_exit[2,2.5;1,0.5;abort;OK]"..
             "textarea[1,1;4,2;info;Information;";
   if( owner ~= nil and owner ~= '' and owner ~= name ) then
      return formspec_info.."This marker\ncan only be used by\n"..tostring( owner )..", who\nplaced the markers.]";
   end

   if( not( markers.positions[ name ]) or #markers.positions[name]<1) then
      return formspec_info.."Information about the positions\nof your other markers\ngot lost.\nPlease dig and place\nyour markers again!]";
   end

   local n = #markers.positions[ name ];

	 if ( n < 2 ) then
	   return formspec_info.."Please place 2 or more markers\n - at least one in each corner\n of your area first]";
   end


	 local coords={}
	 coords[1],coords[2] = markers.get_box_from_markers(name)

   -- save data
      meta:set_string( 'coords', minetest.serialize( coords ) );

   if( not( coords ) or #coords < 2 or not( coords[1] ) or not( coords[2] )) then
      return formspec_info.."Error in markers.]";
   end

   -- the coordinates are set; we may present an input form now

    -- has the area already been defined?
    local area = markers.get_area_by_pos1_pos2( coords[1], coords[2] );
	
    local size = (math.abs( coords[1].x - coords[2].x )+1)
               * (math.abs( coords[1].z - coords[2].z )+1);

    -- check if area is too large
    if( markers.MAX_SIZE < size ) then
       return formspec_info.."Error: You can only protect\nareas of up to "..tostring( markers.MAX_SIZE ).."m^2.\n"..
                             "Your marked area is "..tostring( size ).." m^2 large.]";
    end

    local formspec = 'size[10,7]'..
               'label[0.5,1;The area you marked extends from]'..
               'label[4.7,1;'..minetest.pos_to_string( coords[ 1 ] )..' to '..minetest.pos_to_string( coords[ 2 ] )..'.]'..
               'label[4.7,1.5;It spans '..tostring( math.abs( coords[1].x - coords[2].x )+1 )..
                               ' x '..tostring( math.abs( coords[1].z - coords[2].z )+1 )..
                               ' = '..tostring( size )..' m^2.]';

    -- display the error message (if there is any)
    if( error_msg ~= nil ) then
       formspec = formspec..
                    'label[0.5,0.0;Error: ]'..
                    'textarea[5.0,0;4,1.5;info;;'..error_msg..']';
    end

    if( area and area['id'] ) then
       formspec =   formspec..
                    'label[0.5,2.0;This is area number ]'..
                    'label[4.7,2.0;'..tostring( area['id'] )..'.]'..
                    'label[0.5,2.5;It is owned by ]'..
                    'label[4.7,2.5;'..tostring( area['owner'] )..'.]'..
                    'label[0.5,3.0;The area is called ]'..
                    'label[4.7,3.0;'..tostring( area['name'] )..'.]'..
                    "button_exit[2,6.0;2,0.5;abort;OK]";
    else
       formspec =   formspec..
--                    'label[0.5,2.0;Buying this area will cost you ]'..
--                    'label[4.7,2.0;'..markers.calculate_area_price_text( coords[1], coords[2], name )..'.]'..

                    'label[0.5,3.0;Your area ought to go..]'..
                    'label[0.5,3.5;this many blocks up:]'..
                    'field[5.0,4.0;1,0.5;add_height;;40]'..
                    'label[6.0,3.5;(above '..coords[2].y..' )]'..

                    'label[0.5,4.0;and this many blocks down:]'..
                    'field[5.0,4.5;1,0.5;add_depth;;10]'..
                    'label[6.0,4.0;(below '..coords[1].y..' )]'..

                    'label[0.5,4.5;The area shall be named]'..
                    'field[5.0,5.0;6,0.5;set_area_name;;please enter a name]'..

                    "button_exit[2,6.0;2,0.5;abort;Abort]"..
                    -- code the position in the "Buy area" field
                    "button_exit[6,6.0;2,0.5;"..minetest.pos_to_string(pos)..";Protect area]";
    end

   return formspec;
end
