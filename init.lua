
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local function lerp(from, to, by)
    return from * (1 - by) + to * by
end

function isValidEntityID (entityId)
  return entityId ~= nil and minetest.registered_entities[entityId] ~= nil
end

minetest.register_chatcommand("entitylist", {
  privs = {
    interact = true
  },
  func = function(name, param)

    for k, v in pairs(minetest.registered_entities) do
      
      if k == "" or string.match(k, param) then
        minetest.chat_send_player(name, k)
      else
        -- minetest.chat_send_player(name, k)
      end

    end
    
    return true, "Listed all entities"
  end
})


function getCommandParams (inputstr)
  local params = {}

  local parts = nil
  local key = nil
  local partcount = 0

  for i = 1, 1,-1 do 
    print(i) 
  end

  for index,str in ipairs(string_split(inputstr, " ")) do 
    parts = string_split(str, "=")

    partcount = #parts
    if partcount == 0 then
      --do nothing, maybe throw an error later?
    elseif partcount >= 1 then
      key = parts[1]
      params[key] = false

      if #parts > 1 then
        local values = string_split(parts[2], ",")

        if #values == 1 then 
          params[key] = values[1]
        elseif #values > 1 then
          params[key] = values
        end
      end
    end
  end

  return params
end

function string_split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end

  local t={}
  
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

minetest.register_chatcommand("spawn", {
  privs = {
    interact = true
  },
  func = function(name, param)
    
    local params = getCommandParams(param)

		local type = params["type"]

		if not isValidEntityID(type) then
			return false, "entity id '" .. type .. "' is not registered, use /entitylist " .. type
		end

		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		local modpos = {
			x = pos.x,
			y = math.floor(pos.y)+1,
			z = pos.z
		}
    
		local en = minetest.add_entity(modpos, type)
		
		-- en:set_animation({x=1,y=20}, 4, 1, true)

    return true, "Spawned Entity type: " .. type .. " at " .. dump(modpos)
  end
})

local ffboard_def = {
    visual = "mesh",
    mesh = "ffboard.blend.x",
    textures = {
      "board_hole.png",
      "dot-blue.png",
      "dot-red.png",
    },
    backface_culling = false,
    collisionbox = {
      -0.5,
      -0.5,
      -0.025,
      0.5,
      0.357142857,
      0.025
    },
    selectionbox = {
        -0.5,
        -0.5,
        -0.025,
        0.5,
        0.357142857,
        0.025
    },
    physical = true,
    _player_red_name = nil,
    _player_blue_name = nil,
    _player_turn_color = "red",
    on_activate = function(self, sd, dtime)
      
    end,
    _state = {
      _columns = {
        {},{},{},{},{},{},{}
      },
      _dots = {
      }
    },
    _init = function (self) 
      local dots = self._state._dots

      local dot = nil

      for i=1,21 do
        dot = dot_create("red", i)
        dots[i] = dot

        dot.x = 7
        dot.y = 6
        dot.rx = 9
        dot.ry = 7
      end
      for i=1,21 do
        dot = dot_create("blue", i)
        dots[i + 21] = dot
        dot.x = -1
        dot.y = 6
        dot.rx = -2
        dot.ry = 7
      end

    end,

    --returns index of first dot with same color and isn't allocated yet
    _aquire_dot = function (self, color)
      local dots = self._state._dots
      
      for i=1,42 do
        local dot = dots[i]
        if (dot.color == color and dot.allocated == false) then
          return i
          -- break
        end
      end
      return -1
    end,

    on_activate = function (self)
      self:_init()
    end,

    on_step = function(self, dtime)
      for index, dot in pairs(self._state._dots) do
        
        local pos_changed = false

        if (dot.x ~= dot.rx) then
          dot.rx = lerp(dot.rx, dot.x, 0.1)
          pos_changed = true
        end
        if (dot.y ~= dot.ry) then
          dot.ry = lerp(dot.ry, dot.y, 0.1)
          pos_changed = true
        end
        
        if (pos_changed) then
          local x = dot.rx
          local y = dot.ry

          x = x - 3
          y = y - 3
    
          x = x * (10/7)
          y = y * (10/7)
    
          self.object:set_bone_position(
            dot.bone_name,
            { x = x, y = 0, z = y }
          )
        end

      end
    end,

    _get_dot_at = function(self, column, row)
      if (column > 0 and column < #self._state._columns+1) then
        local c = self._state._columns[column]
        return c[row+1]
      end
      return nil
    end,
   
    _check = function (self, column, row, color, min)
      minetest.chat_send_all(column..","..row..","..color)
      if (min == nil) then
        min = 4
      end

      local count = 0
      for i=1,min-1 do
        local d = self:_get_dot_at(column+i, row)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end
      for i=1,min-1 do
        local d = self:_get_dot_at(column-i, row)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end

      if (count >= min) then
        return true
      end
      local count = 0

      for i=1,min-1 do
        local d = self:_get_dot_at(column, row+i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end
      for i=1,min-1 do
        local d = self:_get_dot_at(column, row-i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end

      if (count >= min) then
        return true
      end
      local count = 0

      for i=1,min-1 do
        local d = self:_get_dot_at(column+i, row+i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end
      for i=1,min-1 do
        local d = self:_get_dot_at(column-i, row-i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end

      if (count >= min) then
        return true
      end
      local count = 0

      for i=1,min-1 do
        local d = self:_get_dot_at(column-i, row+i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end
      for i=1,min-1 do
        local d = self:_get_dot_at(column+i, row-i)
        if (d == nil or d.color ~= color) then
          break
        end
        count = count + 1
      end

      if (count >= min) then
        return true
      end
    end,

    on_rightclick = function(self, clicker)
      
      local player_name = clicker:get_player_name()

      local world_entity_pos = self.object:get_pos()
      local world_hit_pos = projectLookingDirection(clicker, world_entity_pos)
      
      local local_hit_pos = vector.subtract(world_hit_pos, world_entity_pos)

      local_hit_pos.x = 0.5 - local_hit_pos.x
      local_hit_pos.y = (-local_hit_pos.y)-1

      local render_hit_pos = vector.multiply(local_hit_pos, -7)
      render_hit_pos = vector.add(render_hit_pos, 7)
      
      render_hit_pos.x = math.floor(render_hit_pos.x)
      render_hit_pos.y = math.floor(render_hit_pos.y)
      render_hit_pos.z = math.floor(render_hit_pos.z)

      -- minetest.chat_send_player(player_name, "hit at: "..dump(render_hit_pos))
      local column = self._state._columns[render_hit_pos.x+1]
      render_hit_pos.y = #column

      if (render_hit_pos.y+1 > 6) then --column is full
        minetest.chat_send_player(player_name, "[findfour] column "..(render_hit_pos.x+1).." is full! Try another column :)")
        return
      end

      local dots = self._state._dots
      local idot = self:_aquire_dot(self._player_turn_color)

      if (idot == -1) then
        minetest.chat_send_player(player_name, "[findfour] out of your color! game over!")
        return
      end

      local dot = dots[idot]
      dot.allocated = true
      dot.x = render_hit_pos.x
      dot.y = render_hit_pos.y
      dot.rx = render_hit_pos.x
      dot.ry = 7

      column[#column+1] = dot

      if (self:_check(render_hit_pos.x, render_hit_pos.y, self._player_turn_color, 4)) then
        minetest.chat_send_player(player_name, self._player_turn_color.." found 4! you win!")
        return
      end
      
      if (self._player_turn_color == "red") then
        self._player_turn_color = "blue"
      else
        self._player_turn_color = "red"
      end


      minetest.chat_send_player(player_name, self._player_turn_color.." sets puck "..idot.." at column "..render_hit_pos.x+1)
    end
}

--raycast from player to entity is broken
--so this projects the player camera to an XY plane at an origin
--the origin can be an entity position
--for my use case, this works great
--this one is written by ChatGPT cause I'm brain dead from work
function projectLookingDirection(player, planeOrigin)
  -- Get the player's position and rotation
  local playerPos = player:get_pos()
  local playerDir = player:get_look_dir()

  -- Calculate the distance to the plane along the player's looking direction
  local distance = (planeOrigin.z - playerPos.z) / playerDir.z

  -- Calculate the hit location on the XY plane
  local hitX = playerPos.x + playerDir.x * distance
  local hitY = playerPos.y + playerDir.y * distance
  local hitZ = planeOrigin.z

  -- Return the hit location as a vector
  return {x = hitX, y = hitY, z = hitZ}
end

--didn't feel like doing this manually, or figuring out why
--blender is exporting Armature_ prefix for bones for direct x files
function calc_bone_name (color, index)
  index = index - 1
  local padded_index = tostring(index)
  while (#padded_index < 3) do
    padded_index = "0"..padded_index
  end
  local bone_name = "Armature_"..color.."_"..padded_index
  return bone_name
end

--allocate a struct for a find four puck
function dot_create (color, index)
  return {
    allocated = false, --available to place
    x = 0, --integer
    y = 0, --integer
    rx = 0, --rendered x
    ry = 0, --rendered y
    index = index,
    color = color,
    bone_name = calc_bone_name(color, index)
  }
end

minetest.register_entity("findfour:board", ffboard_def)

minetest.register_on_leaveplayer(function(p, timedout)
    local pname = p:get_player_name()
    
end)

