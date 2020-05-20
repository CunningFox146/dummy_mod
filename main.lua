local MOBS_LIST = GetModConfigData("mobs")
PrefabFiles = {
	"dummy",
}

local env = env
GLOBAL.setfenv(1, GLOBAL)

if not env.MODROOT:find("workshop-") then
	CHEATS_ENABLED = true
end

DUMMY_SLOTS = {
	[1] = EQUIPSLOTS.HANDS,
	[2] = EQUIPSLOTS.BODY,
	[3] = EQUIPSLOTS.HEAD,
}

local containers = require "containers"
local params = {}

params.dummy =
{
	widget =
	{
		slotpos =
		{
			Vector3(-64 - 16, 0, 0), 
			Vector3(0, 0, 0),
			Vector3(64 + 16, 0, 0), 
		},
		slotbg =
		{
			{ image = "equip_slot.tex" },
			{ image = "equip_slot_body.tex" },
			{ image = "equip_slot_head.tex" },
		},
		animbank = "ui_chest_3x1",
		animbuild = "ui_chest_3x1",
		pos = Vector3(200, 0, 0),
	},
	acceptsstacks = false,
	type = "chest",
}

function params.dummy.itemtestfn(container, item, slot)
	return item.replica and item.replica.equippable and item.replica.equippable:EquipSlot() == DUMMY_SLOTS[slot]
end

local _widgetsetup = containers.widgetsetup
containers.widgetsetup = function(container, prefab, ...)
	local t = params[prefab or container.inst.prefab]
    if t then
        for k, v in pairs(t) do
            container[k] = v
        end
        return container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    end
	return _widgetsetup(container, prefab, ...)
end

env.AddRecipe("dummy",
{Ingredient("boards", 2), Ingredient("log", 1), Ingredient("beefalowool", 4)},
RECIPETABS.TOWN,
TECH.SCIENCE_TWO,
"dummy_placer",
nil,
nil,
nil,
nil,
"images/inventoryimages/dummy.xml",
"dummy.tex")

STRINGS.NAMES.DUMMY = "Dummy"
STRINGS.RECIPE_DESC.DUMMY = "It's like a chest, but for armor."

STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUMMY = "Looks dumb. Maybe I should dress it with something else?"
