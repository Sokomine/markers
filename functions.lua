

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
		'label[0.5,5.5;Dimensions of the area in relation to..]'..
-- TODO: check if there is a marker; else write 'position you clicked on'
		'label[4.7,5.5;the marker at '..minetest.pos_to_string( pos )..':]'..
		'button_exit[8.0,5.5;2,0.5;list_areas_at;Local areas]';
      end
      formspec = formspec..
		'image['..col_offset..','..row_offset..';1,1;markers_stone.png]'..
		'label['..(col_offset-0.8)..','..(row_offset+0.05)..';'..tostring( pos.x - pos1.x         )..' m W]'..
		'label['..(col_offset+1.0)..','..(row_offset+0.05)..';'..tostring(         pos2.x - pos.x )..' m E]'..
		'label['..(col_offset+0.1)..','..(row_offset+0.80)..';'..tostring( pos.z - pos1.z         )..' m S]'..
		'label['..(col_offset+0.1)..','..(row_offset-0.80)..';'..tostring(         pos2.z - pos.z )..' m N]';

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
		'label[0.5,5.5;Position of the area in relation to..]'..
-- TODO: check if there is a marker; else write 'position you clicked on'
		'label[4.7,5.5;the marker at '..minetest.pos_to_string( pos )..':]'..
		'button_exit[8.0,5.5;2,0.5;list_areas_at;Local areas]';
      end
      formspec = formspec..
		'image['..col_offset..','..row_offset..';1,1;compass_side_top.png]'..
		'label['..(col_offset-0.8)..','..(row_offset+0.05)..';'..starts_west..']'..
		'label['..(col_offset+1.0)..','..(row_offset+0.05)..';'..starts_east..']'..
		'label['..(col_offset+0.1)..','..(row_offset-0.80)..';'..starts_north..']'..
		'label['..(col_offset+0.1)..','..(row_offset+0.80)..';'..starts_south..']';
   end
 
   return formspec;
end


-- from areas modified with namespace
-- Modifies positions `pos1` and `pos2` so that each component of `pos1`
-- is less than or equal to its corresponding component of `pos2`,
-- returning the two positions.
function markers:sortPos(pos1, pos2)
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end
