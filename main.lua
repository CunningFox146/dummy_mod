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
	[1] = EQUIPSLOTS.HEAD,
	[2] = EQUIPSLOTS.BODY,
	[3] = EQUIPSLOTS.HANDS,
}

local containers = require "containers"
local params = {}

params.dummy =
{
	widget =
	{
		slotpos =
		{
			Vector3(0, 64 + 32 + 8 + 4 - 15, 0), 
			Vector3(0, -15, 0),
			Vector3(0, -(64 + 32 + 8 + 4) - 15, 0), 
		},
		slotbg =
		{
			{ image = "equip_slot_head.tex" },
			{ image = "equip_slot_body.tex" },
			{ image = "equip_slot.tex" },
		},
		animbank = "ui_cookpot_1x4",
		animbuild = "ui_cookpot_1x4",
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

