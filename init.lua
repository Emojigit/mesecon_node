function Set (list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local function shallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
local mesewire_rules =
{
	{x = 1, y = 0, z = 0},
	{x =-1, y = 0, z = 0},
	{x = 0, y = 1, z = 0},
	{x = 0, y =-1, z = 0},
	{x = 0, y = 0, z = 1},
	{x = 0, y = 0, z =-1},
}
mesecon_node = {}
function mesecon_node.register_node(srcname)
	srcnode = minetest.registered_nodes[srcname]
	dstname = srcname.."_mesecon_node"
	dstname_on = dstname.."_on"
	dstnode = shallowCopy(srcnode)
	dstnode.drop = dstname
	dstnode.mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = dstname_on,
		rules = mesewire_rules
	}}
	dstnode.is_ground_content = false
	dstnode.description = "Mesecon "..srcnode.description
	minetest.register_node(":"..dstname, dstnode)
	minetest.log("action","Registered mesecon node "..dstname)
	onnode_group = shallowCopy(srcnode.groups)
	onnode_group.not_in_creative_inventory = 1
	minetest.register_node(":"..dstname_on, mesecon.mergetable(minetest.registered_nodes[dstname], {
		drop = dstname,
		light_source = 5,
		mesecons = {conductor = {
			state = mesecon.state.on,
			offstate = dstname,
			rules = mesewire_rules
		}},
		groups = onnode_group,
		on_blast = mesecon.on_blastnode,
	}))
	minetest.log("action","Registered mesecon node "..dstname_on)
end

mesecon_node.no_mesecon_list = {}

function mesecon_node.register_no_mesecon(name)
	mesecon_node.no_mesecon_list[name] = true
end

function mesecon_node.auto_register_rules(key, val)
	if not(val.mesecons) and not(val.liquidtype == "source") and not(mesecon_node.no_mesecon_list[key]) and not(val.liquidtype == "flowing") and not(val.groups.bed) then
		return true
	else
		return false
	end
end
mesecon_node.register_no_mesecon("ignore")

minetest.register_on_mods_loaded(function()
	for key, val in pairs(minetest.registered_nodes) do
		if mesecon_node.auto_register_rules(key, val) then
			mesecon_node.register_node(key)
			minetest.register_craft({
				type = "shapeless",
				output = key.."_mesecon_node 2",
				recipe = {key, "default:mese"},
			})
		end
	end
end)