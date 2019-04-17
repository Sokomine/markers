--+++++++++++++++++++++++++++++++++++++++
--
-- convert_to_areas
-- get region datatable from id and
-- makes an area table
--
--+++++++++++++++++++++++++++++++++++++++
-- input: region ID 
-- msg/error handling: no
-- returns this_area as table in the area-format
function markers:convert_to_areas(id)
	local this_area = {}
	local pos1,pos2,data = raz:get_region_data_by_id(id) 
	this_area[ 'id' ] = id
	this_area[ 'owner' ] = data.owner
	this_area[ 'name' ] = data.region_name
	this_area[ 'pos1' ] = pos1
	this_area[ 'pos2' ] = pos2
	this_area[ 'guests' ] = raz:convert_string_to_table(data.guests, ",")
	return this_area
end

--+++++++++++++++++++++++++++++++++++++++
--
-- check_region_mark
-- checks if pname is owner of an region and has the correct privileg
-- or is region_admin	
--
--+++++++++++++++++++++++++++++++++++++++
-- input: region ID 
-- msg/error handling: no
-- returns true - is owner with privileg or region_admin
function markers:check_region_mark(pname, owner)
	if( owner == pname and minetest.check_player_privs(pname, { region_mark = true }) )
	  or minetest.check_player_privs(pname, { region_admin = true })  then
		return true;
	end
	return false
end

--+++++++++++++++++++++++++++++++++++++++
--
-- check_region_mark
-- checks if pname is owner of an region and has the correct privileg
-- or is region_admin	
--
--+++++++++++++++++++++++++++++++++++++++
-- input: region ID 
-- msg/error handling: no
-- returns true - is owner with privileg or region_admin
function markers:check_region_set(pname, owner)
	if( owner == pname and minetest.check_player_privs(pname, { region_set = true }) )
	  or minetest.check_player_privs(pname, { region_admin = true })  then
		return true;
	end
	return false
end

--+++++++++++++++++++++++++++++++++++++++
--
-- get area by pos1 uand pos2
-- looks for the region in the pos1-pos2 zone
--
--+++++++++++++++++++++++++++++++++++++++
-- input: pos1, pos2 as vector (table) 
-- returns the first area found
-- msg/error handling: no
-- return nil 	if the is no area
-- return area-table with id of the first found area
markers.get_area_by_pos1_pos2 = function(pos1, pos2)
	local found_id = raz:get_area_by_pos1_pos2(pos1, pos2) 
	if found_id ~= nil then

		local return_table = markers:convert_to_areas(found_id)

		return return_table
	else
		return nil
	end
end

-----------------------------------------
--
-- player can add region
--
-----------------------------------------
-- check ich name has the privileg
-- pos1 and pos2 are not in an other region
-- the player/name has less when MAX-Regions set
-- msg/error handling: 
-- return false, err-text
-- return true, nil
function markers:player_can_add_region(pos1, pos2, name)
	if not minetest.check_player_privs(name, { region_mark = true }) then 
		return false, "You dont have the privileg 'region_mark' "
	end
	local err = raz:player_can_mark_region(pos1, pos2, name)
	minetest.log("action", "[" .. markers.modname .. "] markers:player_can_add_region(pos1, pos2, name) err = "..tostring(err) )
	if err ~= true then
--	if raz:get_area_by_pos1_pos2(pos1, pos2) ~= nil then 
		raz:msg_handling(err, name) --  message and error handling
		return false, "The pos1,pos2 are in an other region! - You can not mark the region."
	end

	return true, nil
end


-- protect an region
markers.marker_on_receive_fields = function(pos, formname, fields, sender)
	
	if( not( pos )) then
		minetest.log("action", "[" .. markers.modname .. "] markers.marker_on_receive_fields nor )pos) sender = "..tostring(sender) )
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
		minetest.log("action", "[" .. markers.modname .. "] markers.marker_on_receive_fields area = :"..tostring(area) )
		minetest.chat_send_player( name, 'This area is already protected.');
		return;
	end


	-- check input
	local add_height = tonumber( fields['add_height'] );
	local add_depth  = tonumber( fields['add_depth']  );

	local error_msg = '';
	if(	  not( add_height ) or add_height < 0 or add_height > markers.MAX_HEIGHT ) then
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

	-- sort pos1 and pos2
	pos1, pos2 = markers:sortPos( pos1, pos2 );

	minetest.log("action", "[markers] /protect invoked, owner="..name..
										  " areaname="..fields['set_area_name']..
										  " startpos="..minetest.pos_to_string(pos1)..
										  " endpos="  ..minetest.pos_to_string(pos2));

	local canAdd, errMsg = markers:player_can_add_region(pos1, pos2, name)
	if canAdd == false then
		minetest.chat_send_player(name, "You can't protect that area: "..tostring(errMsg))
		minetest.show_formspec( name, "markers:mark", markers.get_marker_formspec(sender, pos, errMsg));
		return
	end

	local data = raz:create_data(name,fields['set_area_name'],true)
	local id = raz:set_region(pos1,pos2,data)
	minetest.chat_send_player(name, "Area protected. ID: "..tostring(id))

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
--local COLOR_RED	= "#FF0000";
--local COLOR_GREEN = "#00FF00";
--local COLOR_WHITE = "#FFFFFF";


-- we need to store which list we present to which player
markers.menu_data_by_player = {}


markers.get_area_by_pos = function(pos)

	local found_areas = raz.raz_store:get_areas_for_pos(pos) --{};

	return found_areas;
end



-- ppos: current player (or marker stone) position - used for sorting the list
-- mode: can be pos, player, all, subarea, main_areas
-- mode_data: content depends on mode
-- selected: display information about the area the player single-clicked on
markers.get_area_list_formspec = function(ppos, player, mode, pos, mode_data, selected )


	local id_list = {};
	local title	= '???';
	local tlabel  = '';


	-- expects a position in mode_data
	if(	  mode=='pos' ) then
		-- title would be too long for a label
		title  = 'All areas which contain position..';
		tlabel = '<'..minetest.pos_to_string( mode_data )..'>:';
		id_list = raz.raz_store:get_areas_for_pos(pos)


	-- expects a playername in mode_data
	elseif( mode=='player' ) then

		title  = 'All areas owned by player..';
		tlabel = '<'..tostring( mode_data )..'>:';
		local counter = 0
		local data = {}
		while raz.raz_store:get_area(counter) do
			data = raz:get_region_datatable(counter)

			  if( data.owner == mode_data ) then
				  table.insert( id_list, counter );
			  end
			counter = counter + 1
		end


	-- expects an area_id in mode_data
	elseif( mode=='subareas' ) then

		minetest.log("error", "[" .. markers.modname .. "] {markers.get_area_list_formspec} there are no subareas in raz-mod.")


	-- show only regions that do have parent attribute = true
	elseif( mode=='main_areas' ) then
		title  = 'All parent region withhin '..tostring( markers.AREA_RANGE )..' m:';
		tlabel = '*all parent regions *';
		local counter = 0
		local data = {}
		while raz.raz_store:get_area(counter) do
			data = raz:get_region_datatable(counter)

			  if( data.parent == true ) then
				  table.insert( id_list, counter );
			  end
			counter = counter + 1
		end
 
	-- show all regions
	elseif( mode=='all' ) then
		title  = 'All regions withhin '..tostring( markers.AREA_RANGE )..' m:';
		tlabel = '*all regions*';

		local counter = 0
		local data = {}
		while raz.raz_store:get_area(counter) do
			  table.insert( id_list, counter );
			counter = counter + 1
		end
	end

	-- Sort the list of regions so the nearest comes first
	local nearsorter = function(a, b)
		  return vector.distance(vector.interpolate(raz.raz_store:get_area(a).min, raz.raz_store:get_area(a).max, 0.5), ppos) <
		vector.distance(vector.interpolate(raz.raz_store:get_area(b).min, raz.raz_store:get_area(b).max, 0.5), ppos)
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
	local liste_string = ""
	for i,v in ipairs( id_list ) do
		if( liste ~= '' ) then
			liste = liste..',';
		end
		list_string = "ID = "..v.." - "..raz:get_region_attribute(v, "region_name") 
		liste = liste..minetest.formspec_escape( list_string ) 
			
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
		and raz.raz_store:get_area( id_list[ selected ]) ) then

		local this_area = markers:convert_to_areas( id_list[ selected ]);

		formspec = formspec..
					markers.show_compass_marker( 8.5, 3.0, false, pos, this_area.pos1, this_area.pos2 );

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
	  typ		 = 'area_list',
			 mode		= mode,
			 pos		 = pos,
			 mode_data = mode_data,
			 list		= id_list,

	  selected  = id_list[ selected ],
	};
			
	  
	return formspec;
end




-- shows a formspec with information about a particular area
-- pos is the position of the marker stone or place where the player clicked
-- with the land title register; it is used for relative display of coordinates
markers.get_area_desc_formspec = function( id, player, pos )

	if( not id  or not raz.raz_store:get_area( id )) then
		return 'field[info;Error:;Area not found.]';
	end

	-- build the this_area table from raz_store data
	local this_area =  markers:convert_to_areas(id) 

	local pname	  = player:get_player_name();

	-- show some buttons only if area is owned by the player
	local has_region_mark = markers:check_region_mark(pname, this_area.owner)
	local has_region_set = markers:check_region_set(pname, this_area.owner)
	

	local formspec  = 'size[10,9]'..
	'label[2.5,0.0;Area information and management]'..
	'button_exit[4.7,7.0;1,0.5;abort;OK]';

	-- general information about the region
	formspec = formspec..
	'label[0.5,1.0;This is area number ]'..
		  'label[4.7,1.0;'..tostring( id )..']'..

	'label[0.5,1.5;The area is called ]'..
		  'label[4.7,1.5;'..minetest.formspec_escape( this_area.name or '-not set-')..']'..

	'label[0.5,2.0;It is owned by ]'..
		  'label[4.7,2.0;'..minetest.formspec_escape( this_area.owner)..']';


	-- these functions are only available to the owner of the region with privileg region_set
	if has_region_set then
		formspec = formspec..
		  'button_exit[8.0,0.0;2.2,0.7;change_owner;Change owner]';
	end

	-- these functions are only available to the owner of the region with privileg region_mark
	if has_region_mark then
		formspec = formspec..
		  'button_exit[8.0,1.0;2.2,0.7;delete;Delete]'..
		  'button_exit[8.0,1.7;2.2,0.7;rename;Rename]'
	end

	-- show subowners and areas with the same coordinates
	formspec = formspec..
	'label[0.5,2.5;invited Guests of the area:]';
	local guests = this_area.guests--{};

	if( #guests > 0 ) then

		formspec = formspec..
		  'label[4.7,2.5;'..minetest.formspec_escape( table.concat( guests, ', '))..'.]';

		if( has_region_set ) then
			formspec = formspec..
			  'button_exit[8.0,2.5;2.2,0.7;add_guest;Add Guest]'..
	 		  'button_exit[8.0,3.2;2.2,0.7;ban_guest;remove Guest]';
		end
	else
		formspec = formspec..
		  'label[4.7,2.5;-none-]';
 
		if( has_region_set ) then
			formspec = formspec..
			  'button_exit[8.0,2.5;2.2,0.7;add_guest;Add Guest]'..
	 		  'button_exit[8.0,3.2;2.2,0.7;ban_guest;remove Guest]';
		end
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

	--local pname = player:get_player_name();
	if( not( markers.menu_data_by_player[ pname ] )) then
		markers.menu_data_by_player[ pname ] = {};
	end

	-- we need to remember especially the id_list - else it would be impossible to know what the
	-- player selected
	markers.menu_data_by_player[ pname ] =
	{ typ		 = 'show_area',
			 mode		= nil, 
			 pos		 = pos,
			 mode_data = nil,
			 list		= nil,

	  selected  = id,
	};
			
	return formspec;
end





-- formspec input needs to be handled diffrently
markers.form_input_handler_areas = function( player, formname, fields)
	
	-- player name
	local pname = player:get_player_name();
	local ppos = player:getpos()

	if( formname ~= "markers:info"
		or not( player )
		or not(  markers.menu_data_by_player[ pname ] )) then
	
		return false;
	end
  
	local menu_data = markers.menu_data_by_player[ pname ];
	local formspec = '';

	-----------------------------------------------------------------------
	-- rename an region 
	-- only region_admin or owner with region_mark can rename region
	if( fields.rename 													-- rename
			 and menu_data.selected										-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then		-- there is an region for this ID 
	
		-- there are no checks here - those happen when the region will renamed
		local area = markers:convert_to_areas(menu_data.selected) 		-- get raz_store converted to an areas-table

		if( not( area.name )) then
			area.name = '-enter area name-';
		end
		formspec = 'field[rename_new_name;Enter new name for area:;'..minetest.formspec_escape( area.name )..']';

	elseif( fields.rename_new_name 										-- rename_new_name
			 and menu_data.selected										-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then		-- there is an region for this ID 


		local area = markers:convert_to_areas(menu_data.selected) 		-- get raz_store converted to an areas-table

		-- check owner with privileg or region admin
		if markers:check_region_mark(pname, area.owner) then			-- owner with privileg or admin

			-- actually rename the area
			local err = raz:region_set_attribute(pname, menu_data.selected, "region_name", fields.rename_new_name)		
			if err then
				minetest.chat_send_player( pname, 'Region successfully renamed.');

				-- shwo the renamed area
				formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
 			else 
					raz:msg_handling(err, pname)
			end
		else
			if area.owner ~= pname 	then
				minetest.chat_send_player( pname, 'Permission denied. You are not owner of this region!');
			else
				minetest.chat_send_player( pname, "Permission denied. Missing privileg \'region_mark\'!");
			end
		end

	-----------------------------------------------------------------------
	-- change owner the area
	-- only region_admin or owner with region_set can change owner
	elseif( fields.change_owner											-- change_owner
			 and menu_data.selected										-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected)) then		-- there is an region for this ID 

		-- there are no checks here - those happen when the area is transferred
		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table
		formspec = 'field[change_owner_name;Give area \"'..minetest.formspec_escape( area.name )..'\" to player:;-enter name of NEW OWNER-]';

	elseif( fields.change_owner_name									-- change_owner_name
			 and menu_data.selected										-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected)) then		-- there is an region for this 


		local area = markers:convert_to_areas(menu_data.selected) 		-- get raz_store converted to an areas-table
		
		-- check new owner is player
		if( not( minetest.player_exists( fields.change_owner_name ))) then

			minetest.chat_send_player( pname, 'That player does not exist.');

		-- check owner with privileg or region admin
		elseif markers:check_region_set(pname, area.owner) then			-- owner with privileg or admin
		
				-- actually change the owner
				local err = raz:region_set_attribute(pname, menu_data.selected, "owner", fields.change_owner_name) 
				if err then

					minetest.chat_send_player( pname, 'Your region '..tostring( area.name )..' has been transfered to '..tostring( fields.change_owner_name )..'.');

					minetest.chat_send_player( fields.change_owner_name, pname..' has given you control over an region.')
				else 
					raz:msg_handling(err, pname)
				end
	 
		elseif area.owner ~= pname 	then
				minetest.chat_send_player( pname, 'Permission denied. You are not owner of this region!');
		else
				minetest.chat_send_player( pname, "Permission denied. Missing privileg \'region_set\'!");
		end

		formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );


	-----------------------------------------------------------------------
	-- add a guest - check id / region with ID
	elseif( fields.add_guest
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then		-- there is an region for this ID 
	
		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table

		formspec = 'field[add_guest_name;Invite a player to your region: \"'..minetest.formspec_escape( area.name )..'\";-enter player name-]';

	elseif( fields.add_guest_name 
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then	-- there is an region for this ID 

		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table


		-- does the player exist?
		if( not( minetest.player_exists( fields.add_guest_name ))) then
			minetest.chat_send_player( pname, 'That player does not exist.');
			-- show the formspec
			formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
		
		-- check owner with privileg or region admin
		elseif markers:check_region_set(pname, area.owner) then			-- owner with privileg or admin

			-- log add guest
			minetest.log("action", pname.." add_guest through the markers-mod. guest = "..fields.add_guest_name..
										  " AreaName = "..area.name.." ParentID = "..menu_data.selected..
										  " StartPos = "..area.pos1.x..","..area.pos1.y..","..area.pos1.z..
										  " EndPos = "  ..area.pos2.x..","..area.pos2.y..","..area.pos2.z)

			-- actually add the guest
			if raz:region_set_attribute(pname, menu_data.selected, "guest", fields.add_guest_name, true) then


				minetest.chat_send_player( fields.add_guest_name,
											  "You have been invitedinto the region #"..
											  menu_data.selected..". Type /region list to show your region.")

				minetest.chat_send_player( pname, 'The player may now build and dig in your area.');

				-- shwo the new area
				formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );

			else
				minetest.chat_send_player( pname, "ther is a player with this name {".. fields.ban_guest_name.."} in your guestlist!");
			end
				
		elseif area.owner ~= pname 	then
				minetest.chat_send_player( pname, 'Permission denied. You are not owner of this region!');
		else
				minetest.chat_send_player( pname, "Permission denied. Missing privileg \'region_setz\'!");
		end
		

	-----------------------------------------------------------------------
	-- ban a guest
	elseif( fields.ban_guest
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then	-- there is an region for this ID 
	
		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table

		formspec = 'field[ban_guest_name;Grant access to area \"'..minetest.formspec_escape( area.name )..'\" to player:;-enter player name-]';

	elseif( fields.ban_guest_name 
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then	-- there is an region for this ID 

		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table


		-- does the player exist?
		if( not( minetest.player_exists( fields.ban_guest_name ))) then
			minetest.chat_send_player( pname, 'That player does not exist.');
			-- show the formspec
			formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
		
		-- check owner with privileg or region admin
		elseif markers:check_region_set(pname, area.owner) then			-- owner with privileg or admin

			-- log ban guest
			minetest.log("action", pname.." ban_guest through the markers-mod. guest = "..fields.ban_guest_name..
										  " AreaName = "..area.name.." ParentID = "..menu_data.selected..
										  " StartPos = "..area.pos1.x..","..area.pos1.y..","..area.pos1.z..
										  " EndPos = "  ..area.pos2.x..","..area.pos2.y..","..area.pos2.z)

			-- actually add the guest
			if raz:region_set_attribute(pname, menu_data.selected, "guest", fields.ban_guest_name, false) then


				minetest.chat_send_player( fields.ban_guest_name,
											  "You have been banned from the region #"..
											  menu_data.selected..". Type /region list to show your region.")

				minetest.chat_send_player( pname, "You have banned player ".. fields.ban_guest_name.." from your region {"..area.name.."}");

				-- shwo the new area
				formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
			else
				minetest.chat_send_player( pname, "No player {".. fields.ban_guest_name.."} in your guestlist of region {"..area.name.."}");
			end

		else

			minetest.chat_send_player( pname, 'Permission denied. You do not have the correct privileg.');

		end

	-----------------------------------------------------------------------
	-- delete area
	elseif( fields.delete 
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then		-- there is an region for this ID 

		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table

		-- a player can only delete own regions with privileg - region_mark or as admin
		-- check owner with privileg or region admin
		if markers:check_region_mark(pname, area.owner) then			-- owner with privileg or admin
 
			-- get name of region
			formspec = 'field[rename_new_name;Enter new name for area:;'..minetest.formspec_escape( area.name )..']';
			-- confirm 
			formspec = 'field[delete_confirm;'..minetest.formspec_escape( 'Really delete area \"'..area.name..
					 '\" (owned by '..area.owner..')? Confirm with YES:')..';-type yes in capitals to confirm-]';

		elseif raz:get_region_attribute(menu_data.selected, "owner" ) ~= pname 	then
				minetest.chat_send_player( pname, 'Permission denied. You are not owner of this region!');
		else
				minetest.chat_send_player( pname, "Permission denied. missing privileg \'region_mark\'!");

				-- show the area where the renaming failed
				formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );	
		end

	elseif( fields.delete_confirm 
			 and menu_data.selected									-- raz_store-ID is set
			 and raz.raz_store:get_area(menu_data.selected) ) then		-- there is an region for this ID 

		-- there are no checks here - those happened before
		local area = markers:convert_to_areas(menu_data.selected) 	-- get raz_store converted to an areas-table

				-- a player can only delete own areas
		-- check owner with privileg or region admin
		if markers:check_region_mark(pname, area.owner) then			-- owner with privileg or admin
 
			-- avoid accidents
			if( fields.delete_confirm ~= 'YES' ) then
				minetest.chat_send_player( pname, 'Delition of area \"'..tostring( area.name )..'\" (owned by '..area.owner..') aborted.');
				formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );
			else
				
				minetest.chat_send_player( pname, 'Area \"'..tostring( area.name )..'\" (owned by '..area.owner..') deleted.');
				-- really delete
				raz:delete_region(menu_data.selected)
				-- show the list of areas owned by the previous owner
				formspec = markers.get_area_list_formspec(ppos, player, 'player',	menu_data.pos, area.owner, nil );
			end
		else

			minetest.chat_send_player( pname, 'Permission denied. You are not owner of this region!');
			-- shwo the area where the renaming failed
			formspec = markers.get_area_desc_formspec( menu_data.selected, player, menu_data.pos );				

		end


	-----------------------------------------------------------------------
	-- list_main_areas
	elseif( fields.list_main_areas ) then

	  formspec = markers.get_area_list_formspec(ppos, player, 'main_areas', menu_data.pos, nil, nil );

		  
	-----------------------------------------------------------------------
	-- list_areas_at
	elseif( fields.list_areas_at
		  and menu_data.pos ) then

--	  formspec = markers.get_area_list_formspec(ppos, player, 'pos', menu_data.pos, menu_data.pos, nil );
	  formspec = markers.get_area_list_formspec(ppos, player, 'all', menu_data.pos, menu_data.pos, nil );


	-----------------------------------------------------------------------
	-- markers_area_list_selection
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

	local pname		 = player:get_player_name();
	local ppos = pos

	-- this table stores the list the player may have selected from; at the beginning, there is no list 
	if( not( markers.menu_data_by_player[ pname ]  )) then
		markers.menu_data_by_player[ pname ] = {
	  typ		 = 'area_list',
			 mode		= 'main_areas',
			 pos		 = pos,
			 mode_data = pos,
			 list		= {},

	  selected  = nil,
		};
	end


	local formspec		  = '';

	local found_areas	  = {};
	local min_area_size	= 100000000000;

	for id, area in pairs(raz.raz_store:get_areas_for_pos(pos)) do

		-- ignore y (height) value because some areas may go from bottom to top
		local area_size = math.abs( area.max.x - area.min.x )
							 * math.abs( area.max.z - area.min.z );

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


	-- no areas found; display error message and selection menu
	if(	  #found_areas < 1 ) then

		formspec = 'size[4,3]'..
 			'label[0.5,0.5;This position is not protected.]'..
			'button[1.0,1.5;2,0.5;list_main_areas;List all main areas]'..
			'button_exit[3.0,1.5;1,0.5;abort;OK]';
 
	-- found exactly one areaa - display it
	elseif( #found_areas == 1 ) then

		formspec = markers.get_area_desc_formspec( found_areas[ 1 ], player, pos );

	-- found more than one area; we have saved only those with the smallest size
	else

		local own_area	 = 0;
		local parent_area = 0;
		local upper_area  = 0;
--[[
		for i,v in ipairs( found_areas ) do

			local area = areas.areas[ v ];

			-- owned by player?
			if(			 area.owner == pname ) then
				own_area	 = v;

			-- parentless area?
			elseif( not( area.parent )) then
				parent_area = v;

			-- the parent has diffrent coordinates?
			elseif(		areas.areas[ area.parent ].pos1.x ~= area.pos1.x
						 or areas.areas[ area.parent ].pos1.y ~= area.pos1.y
						 or areas.areas[ area.parent ].pos1.z ~= area.pos1.z
						 or areas.areas[ area.parent ].pos2.x ~= area.pos2.x
						 or areas.areas[ area.parent ].pos2.y ~= area.pos2.y
						 or areas.areas[ area.parent ].pos2.z ~= area.pos2.z ) then
				upper_area = v;
			end
		end
]]--
		-- the area owned by the player is most intresting
		if(	  own_area	 > 0 ) then

			formspec = markers.get_area_desc_formspec( own_area,	 player, pos );
--[[
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
]]--
		else

		  formspec = markers.get_area_list_formspec(ppos, player, 'pos', pos, pos, nil );
		end
	end

	minetest.show_formspec( player:get_player_name(), "markers:info", formspec );
end
