-- Minetest: builtin/item.lua

local SCALE = 0.667

local facedir_to_euler = {
    {y = 0, x = 0, z = 0},
    {y = -math.pi/2, x = 0, z = 0},
    {y = math.pi, x = 0, z = 0},
    {y = math.pi/2, x = 0, z = 0},
    {y = math.pi/2, x = -math.pi/2, z = math.pi/2},
    {y = math.pi/2, x = math.pi, z = math.pi/2},
    {y = math.pi/2, x = math.pi/2, z = math.pi/2},
    {y = math.pi/2, x = 0, z = math.pi/2},
    {y = -math.pi/2, x = math.pi/2, z = math.pi/2},
    {y = -math.pi/2, x = 0, z = math.pi/2},
    {y = -math.pi/2, x = -math.pi/2, z = math.pi/2},
    {y = -math.pi/2, x = math.pi, z = math.pi/2},
    {y = 0, x = 0, z = math.pi/2},
    {y = 0, x = -math.pi/2, z = math.pi/2},
    {y = 0, x = math.pi, z = math.pi/2},
    {y = 0, x = math.pi/2, z = math.pi/2},
    {y = math.pi, x = math.pi, z = math.pi/2},
    {y = math.pi, x = math.pi/2, z = math.pi/2},
    {y = math.pi, x = 0, z = math.pi/2},
    {y = math.pi, x = -math.pi/2, z = math.pi/2},
    {y = math.pi, x = math.pi, z = 0},
    {y = -math.pi/2, x = math.pi, z = 0},
    {y = 0, x = math.pi, z = 0},
    {y = math.pi/2, x = math.pi, z = 0}
}

--
-- Falling stuff
--

core.register_entity("hallucinations:hallucinated_node", {
    initial_properties = {
        visual = "item",
        visual_size = vector.new(SCALE, SCALE, SCALE),
        textures = {},
        is_visible = false,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},

        physical = false,
        pointable = false,
        static_save = false,
    },

    node = {},

    set_node = function(self, node)
        node.param2 = node.param2 or 0
        self.node = node
        local def = core.registered_nodes[node.name]
        if not def then
            -- Don't allow unknown nodes to be hallucinated
            core.log("info",
                "Unknown hallucinated node removed at "..
                core.pos_to_string(self.object:get_pos()))
            self.object:remove()
            return
        end

        -- Set entity visuals
        if def.drawtype == "torchlike" or def.drawtype == "signlike" then
            local textures
            if def.tiles and def.tiles[1] then
                local tile = def.tiles[1]
                if type(tile) == "table" then
                    tile = tile.name
                end
                if def.drawtype == "torchlike" then
                    textures = { "("..tile..")^[transformFX", tile }
                else
                    textures = { tile, "("..tile..")^[transformFX" }
                end
            end
            local vsize
            if def.visual_scale then
                local s = def.visual_scale
                vsize = vector.new(s, s, s)
            end
            self.object:set_properties({
                is_visible = true,
                visual = "upright_sprite",
                visual_size = vsize,
                textures = textures,
                glow = def.light_source,
            })
        elseif def.drawtype ~= "airlike" then
            local itemstring = node.name
            if core.is_colored_paramtype(def.paramtype2) then
                itemstring = core.itemstring_with_palette(itemstring, node.param2)
            end
            -- FIXME: solution needed for paramtype2 == "leveled"
            -- Calculate size of falling node
            local s = {}
            s.x = (def.visual_scale or 1) * SCALE
            s.y = s.x
            s.z = s.x
            -- Compensate for wield_scale
            if def.wield_scale then
                s.x = s.x / def.wield_scale.x
                s.y = s.y / def.wield_scale.y
                s.z = s.z / def.wield_scale.z
            end
            self.object:set_properties({
                is_visible = true,
                wield_item = itemstring,
                visual_size = s,
                glow = def.light_source,
            })
        end

        -- Set collision box (certain nodeboxes only for now)
        local nb_types = {fixed=true, leveled=true, connected=true}
        if def.drawtype == "nodebox" and def.node_box and
            nb_types[def.node_box.type] and def.node_box.fixed then
            local box = table.copy(def.node_box.fixed)
            if type(box[1]) == "table" then
                box = #box == 1 and box[1] or nil -- We can only use a single box
            end
            if box then
                if def.paramtype2 == "leveled" and (self.node.level or 0) > 0 then
                    box[5] = -0.5 + self.node.level / 64
                end
                self.object:set_properties({
                    collisionbox = box
                })
            end
        end

        -- Rotate entity
        if def.drawtype == "torchlike" then
            self.object:set_yaw(math.pi*0.25)
        elseif ((node.param2 ~= 0 or def.drawtype == "nodebox" or def.drawtype == "mesh")
                and (def.wield_image == "" or def.wield_image == nil))
                or def.drawtype == "signlike"
                or def.drawtype == "mesh"
                or def.drawtype == "normal"
                or def.drawtype == "nodebox" then
            if (def.paramtype2 == "facedir" or def.paramtype2 == "colorfacedir") then
                local fdir = node.param2 % 32 % 24
                -- Get rotation from a precalculated lookup table
                local euler = facedir_to_euler[fdir + 1]
                if euler then
                    self.object:set_rotation(euler)
                end
            elseif (def.paramtype2 == "4dir" or def.paramtype2 == "color4dir") then
                local fdir = node.param2 % 4
                -- Get rotation from a precalculated lookup table
                local euler = facedir_to_euler[fdir + 1]
                if euler then
                    self.object:set_rotation(euler)
                end
            elseif (def.drawtype ~= "plantlike" and def.drawtype ~= "plantlike_rooted" and
                    (def.paramtype2 == "wallmounted" or def.paramtype2 == "colorwallmounted" or def.drawtype == "signlike")) then
                local rot = node.param2 % 8
                if (def.drawtype == "signlike" and def.paramtype2 ~= "wallmounted" and def.paramtype2 ~= "colorwallmounted") then
                    -- Change rotation to "floor" by default for non-wallmounted paramtype2
                    rot = 1
                end
                local pitch, yaw, roll = 0, 0, 0
                if def.drawtype == "nodebox" or def.drawtype == "mesh" then
                    if rot == 0 then
                        pitch, yaw = math.pi/2, 0
                    elseif rot == 1 then
                        pitch, yaw = -math.pi/2, math.pi
                    elseif rot == 2 then
                        pitch, yaw = 0, math.pi/2
                    elseif rot == 3 then
                        pitch, yaw = 0, -math.pi/2
                    elseif rot == 4 then
                        pitch, yaw = 0, math.pi
                    end
                else
                    if rot == 1 then
                        pitch, yaw = math.pi, math.pi
                    elseif rot == 2 then
                        pitch, yaw = math.pi/2, math.pi/2
                    elseif rot == 3 then
                        pitch, yaw = math.pi/2, -math.pi/2
                    elseif rot == 4 then
                        pitch, yaw = math.pi/2, math.pi
                    elseif rot == 5 then
                        pitch, yaw = math.pi/2, 0
                    end
                end
                if def.drawtype == "signlike" then
                    pitch = pitch - math.pi/2
                    if rot == 0 then
                        yaw = yaw + math.pi/2
                    elseif rot == 1 then
                        yaw = yaw - math.pi/2
                    end
                elseif def.drawtype == "mesh" or def.drawtype == "normal" or def.drawtype == "nodebox" then
                    if rot >= 0 and rot <= 1 then
                        roll = roll + math.pi
                    else
                        yaw = yaw + math.pi
                    end
                end
                self.object:set_rotation({x=pitch, y=yaw, z=roll})
            elseif (def.drawtype == "mesh" and def.paramtype2 == "degrotate") then
                local p2 = (node.param2 - (def.place_param2 or 0)) % 240
                local yaw = (p2 / 240) * (math.pi * 2)
                self.object:set_yaw(yaw)
            elseif (def.drawtype == "mesh" and def.paramtype2 == "colordegrotate") then
                local p2 = (node.param2 % 32 - (def.place_param2 or 0) % 32) % 24
                local yaw = (p2 / 24) * (math.pi * 2)
                self.object:set_yaw(yaw)
            end
        end
    end,

    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})

        local SECONDS = 1000000
        self.timeout = minetest.get_us_time() + math.random(10 * SECONDS, 30 * SECONDS)
    end,

    on_step = function(self)
        if minetest.get_us_time() >= self.timeout then
            -- print("[trying to remove hallucination]")

            local observer
            for name in pairs(self.object:get_observers()) do
                observer = minetest.get_player_by_name(name)
                break
            end

            if observer and hallucinations.can_player_see_node(observer, self.object:get_pos()) then
                -- print("cancelling, someone could see")
                return
            end

            -- print("removing")
            self.object:remove()
        end
    end,
})

function hallucinations.add_hallucinated_node(player, pos, node)
    -- print("[trying to add hallucination]")

    if hallucinations.can_player_see_node(player, pos) then
        -- print("cancelling, player could see")
        return
    end

    local concurrents = minetest.get_objects_inside_radius(pos, 0.001)
    for _, obj in ipairs(concurrents) do
        local ent = obj:get_luaentity()
        if ent.name == "hallucinations:hallucinated_node" then
            -- print("cancelling to avoid duplicates")
            return
        end
    end

    local obj = core.add_entity(pos, "hallucinations:hallucinated_node")
    if not obj then
        return
    end

    obj:get_luaentity():set_node(node)
    obj:set_observers({ [player:get_player_name()] = true })

    print("added hallucination for " .. player:get_player_name() .. " at " .. pos:to_string())

    return obj
end
