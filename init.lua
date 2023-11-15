hallucinations = {}

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/falling.lua")

local MIN_PLAYER_DISTANCE = 3
local MAX_PLAYER_DISTANCE = 30

function hallucinations.get_eye_pos(player)
    local eye_pos = player:get_pos()
    eye_pos.y = eye_pos.y + player:get_properties().eye_height
    return eye_pos
end

function hallucinations.can_player_see_node(player, node_pos)
    local eye_pos = hallucinations.get_eye_pos(player)

    if vector.distance(eye_pos, node_pos) < MIN_PLAYER_DISTANCE then
        return true
    end

    local bad_dir = vector.direction(eye_pos, node_pos)
    local actual_dir = player:get_look_dir()

    if vector.dot(bad_dir, actual_dir) > 0 then
        return true
    end

    return false
end

local function make_hallucination(player)
    local eye_pos = hallucinations.get_eye_pos(player)

    local dir = player:get_look_dir() * -1
    local xrot = math.random() * math.pi - math.pi / 2
    local yrot = math.random() * math.pi - math.pi / 2
    dir = dir:rotate(vector.new(xrot, yrot, 0))

    local ray = minetest.raycast(
            eye_pos + dir * MIN_PLAYER_DISTANCE,
            eye_pos + dir * MAX_PLAYER_DISTANCE)

    for pointed in ray do
        if pointed.type == "node" then
            local node_real = minetest.get_node(pointed.above)
            local def_real = minetest.registered_nodes[node_real.name]
            if not def_real or def_real.paramtype ~= "light" then
                -- print("not placing hallucination inside non-lit node")
                return
            end

            local node_fake = minetest.get_node(pointed.under)
            -- for debugging
            -- local node_fake = {name = "default:mese"}

            local def_fake = minetest.registered_nodes[node_fake.name]
            if not def_fake or def_fake.drawtype == "plantlike" then
                -- print("not placing plant node as hallucination")
                return
            end

            hallucinations.add_hallucinated_node(player, pointed.above, node_fake)
            return
        end
    end
end

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()

    for _, player in ipairs(players) do
        make_hallucination(player)
    end
end)
