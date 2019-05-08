
local function dump_matrix(m)
	return "{"..m[1]..", "..m[2]..", "..m[3]..", "..
		"\n "..m[4]..", "..m[5]..", "..m[6]..", "..
		"\n "..m[7]..", "..m[8]..", "..m[9].."}"
end

local function get_player_head_pos(player)
	local pos = vector.add(player:get_pos(), player:get_eye_offset())
	pos.y = pos.y + player:get_properties().eye_height
	return pos
end

local function spawnent(player)
	local pos = vector.add(get_player_head_pos(player), vector.multiply(player:get_look_dir(), 2))
	return minetest.add_entity(pos, "matrix_test:ent")
end

minetest.register_craftitem("matrix_test:item", {
	description = "matrix testitem",
	inventory_image = "default_tool_steelaxe.png^[transformR180",
	on_secondary_use = function(itemstack, user, pointed_thing)
		minetest.chat_send_all("spawn test entity")
		spawnent(user)
	end,
	on_use = function(itemstack, user, pointed_thing)
		if not pointed_thing.under then
			minetest.chat_send_all("no pointed_thing.under")
			return
		end
		minetest.chat_send_all("spawning facedir_to_matrix test particle")
		local node = minetest.get_node(pointed_thing.under)
		local facedir_matrix = minetest.facedir_to_matrix(node.param2, true)
		local facedir_matrix
		if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].paramtype2 == "wallmounted" then
			facedir_matrix = minetest.wallmounted_to_matrix(node.param2, true)
		else
			facedir_matrix = minetest.facedir_to_matrix(node.param2, true)
		end
		--~ minetest.chat_send_all(dump_matrix(facedir_matrix))
		local relative_pos = {x=0.2, y=0.4, z=-0.6}
		minetest.chat_send_all(minetest.pos_to_string(matrix.multiply(facedir_matrix, relative_pos)))
		minetest.add_particle({
			pos = vector.add(pointed_thing.under, matrix.multiply(facedir_matrix, relative_pos)),
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 5,
			size = 3,
			texture = "bubble.png",
			glow = 14,
		})
	end,
})

minetest.register_entity("matrix_test:ent", {
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	--~ textures = {},
	textures = {"yp.png", "yn.png", "xp.png", "xn.png", "zp.png", "zn.png"},
	static_save = false,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		minetest.chat_send_all("ent:on_punch")
	end,
	on_step = function(self, dtime)
		if self.wait and self.wait ~= 0 then
			self.wait = self.wait - 1
			return
		end
		self.wait = 20
		local rot = self.object:get_rotation()
		--~ minetest.chat_send_all("bla")
		--~ minetest.chat_send_all(minetest.pos_to_string(rot))
		--~ rot = vector.add(rot, vector.multiply(vector.new(1, 1, 0), dtime))
		local oldm = matrix.from_yaw_pitch_roll(rot)
		local rotchange = matrix.rotation_around_vector(vector.new(1,0,0), 0.1)
		local mat = matrix.multiply(rotchange, oldm)
		--~ local mat = matrix.multiply(matrix.identity, oldm)
		local nrot = matrix.to_yaw_pitch_roll(mat)
		--~ nrot = vector.add(nrot, vector.multiply(vector.new(0, 1, 0), dtime))
		minetest.chat_send_all(minetest.pos_to_string(vector.divide(nrot, math.pi)))
		self.object:set_rotation(nrot)
		--~ local mat = matrix.from_yaw_pitch_roll(rot)
		--~ mat = matrix.round(mat)

		-- add particles that rotate around the object
		local relative_pos = {x=0.2, y=0.4, z=-0.6}
		minetest.add_particle({
			pos = vector.add(self.object:get_pos(), matrix.multiply(mat, relative_pos)),
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = dtime*1,
			size = 2,
			texture = "bubble.png",
			glow = 14,
		})
		relative_pos.x = -2
		minetest.add_particle({
			pos = vector.add(self.object:get_pos(), matrix.multiply(mat, relative_pos)),
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = dtime*1,
			size = 2,
			texture = "bubble.png",
			glow = 14,
		})
	end,
})

minetest.register_chatcommand("nent", {
	params = "",
	description = "",
	privs = {},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		spawnent(player)
		return true, "new ent"
	end,
})

local playerbubble = {
	pos = {x=2, y=0, z=0},
	rotmat = matrix.new(matrix.identity),
}

minetest.register_globalstep(function(dtime)
	local player = minetest.get_player_by_name("singleplayer")
	if not player then
		return
	end
	--~ minetest.chat_send_all(dump_matrix(playerbubble.rotmat))
	--~ minetest.chat_send_all(dump(playerbubble.pos))
	playerbubble.pos = matrix.multiply(playerbubble.rotmat, playerbubble.pos)
	local playerpos = get_player_head_pos(player)
	minetest.add_particle({
		pos = vector.add(playerpos, playerbubble.pos),
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = dtime,
		size = 3,
		texture = "bubble.png",
		glow = 14,
	})
end)

minetest.register_chatcommand("pb", {
	params = "",
	description = "",
	privs = {},
	func = function(name, param)
		local a = minetest.string_to_pos(param)
		if not a then
			return false, "no_vec"
		end
		playerbubble.rotmat = matrix.rotation_around_vector(a, 0.1)
		return true, "ok"
	end,
})
