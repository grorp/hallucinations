hallucinations = {}

function hallucinations.get_eye_pos(player)
    local eye_pos = player:get_pos()
    eye_pos.y = eye_pos.y + player:get_properties().eye_height
    return eye_pos
end

function hallucinations.can_player_see_node(player, node_pos)
    local eye_pos = hallucinations.get_eye_pos(player)
    local bad_dir = vector.direction(eye_pos, node_pos)

    local actual_dir = player:get_look_dir()

    return vector.dot(bad_dir, actual_dir) > 0
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/falling.lua")

local function make_dir_hallucination(player, dir)
    local eye_pos = hallucinations.get_eye_pos(player)
    local ray = minetest.raycast(eye_pos + dir * 3, eye_pos + dir * 30)

    for pointed in ray do
        if pointed.type == "node" then
            local node_where_to_place = minetest.get_node(pointed.above)
            local def = minetest.registered_nodes[node_where_to_place.name]
            if not def or def.paramtype ~= "light" then
                -- print("not placing hallucination inside non-lit node")
                return
            end

            local node_to_place = minetest.get_node(pointed.under)
            -- local node_to_place = {name = "default:mese"}

            hallucinations.add_hallucinated_node(player, pointed.above, node_to_place)
            return
        end
    end
end

local function make_hallucination(player, dirs)
    for _, dir in ipairs(dirs) do
        make_dir_hallucination(player, dir)
    end
end

local HALLUCINATION_STEP = 3
local dtime_accu = HALLUCINATION_STEP

minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    if #players == 0 then
        return
    end

    dtime_accu = dtime_accu + dtime
    if dtime_accu < HALLUCINATION_STEP then
        return
    end
    dtime_accu = 0

    for _, player in ipairs(players) do
        local base_dir = player:get_look_dir() * -1

        make_hallucination(player, {
            vector.new(base_dir.x, -0.75, base_dir.z):normalize(),
            vector.new(base_dir.x, -0.5,  base_dir.z):normalize(),
            vector.new(base_dir.x, -0.25, base_dir.z):normalize(),
            vector.new(base_dir.x,  0,    base_dir.z):normalize(),
            vector.new(base_dir.x,  0.25, base_dir.z):normalize(),
            vector.new(base_dir.x,  0.5,  base_dir.z):normalize(),
            vector.new(base_dir.x,  0.75, base_dir.z):normalize(),
        })
    end
end)
