local MOBS_LIST = GetModConfigData("mobs")

PrefabFiles =
{
	"dummy",
}

Assets =
{
    Asset("IMAGE", "minimap/minimap_dummy.tex"),
    Asset("ATLAS", "minimap/minimap_dummy.xml"),
}

AddMinimapAtlas("minimap/minimap_dummy.xml")

local env = env
GLOBAL.setfenv(1, GLOBAL)

if not env.MODROOT:find("workshop-") then
	CHEATS_ENABLED = true
end

env.modimport("scripts/libs/skins_api.lua")

DUMMY_SLOTS = {
	[EQUIPSLOTS.HANDS] = 1,
	[EQUIPSLOTS.BODY] = 2,
	[EQUIPSLOTS.HEAD] = 3,
}

-- Extra equip slots compatibility
if EQUIPSLOTS.BACK then
	DUMMY_SLOTS[EQUIPSLOTS.BACK] = 2
end

if EQUIPSLOTS.NECK then
	DUMMY_SLOTS[EQUIPSLOTS.NECK] = 2
end

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

-- Chek if item:
-- 1. Is equippable
-- 2. Is item slot avalible
-- 3. Make sure to use replicas since this is also called on client
-- Convert slots back from modded slots

local function GetSlot(item)
	local slot = item.replica.equippable:EquipSlot()
	
	if EQUIPSLOTS.BACK and slot == EQUIPSLOTS.BACK then
		return EQUIPSLOTS.BODY
	end

	if EQUIPSLOTS.NECK and slot == EQUIPSLOTS.NECK then
		return EQUIPSLOTS.BODY
	end
	
	return slot
end

function params.dummy.itemtestfn(container, item, slot)
	if item.replica and item.replica.equippable then
		local inst = container.inst
		local replica = inst.replica.container
		for i = 1, replica:GetNumSlots() do
			local equip = replica:GetItemInSlot(i)
			if equip and equip.replica and
			GetSlot(equip) == GetSlot(item) then
				return false
			end
		end
		return true
	end
	return false
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

-- This is a hack to stop item consumption when equipped on dummy
env.AddComponentPostInit("fueled", function(self)
	local _StartConsuming = self.StartConsuming
	function self:StartConsuming(...)
		if not self.accepting and self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner and
		self.inst.components.inventoryitem.owner.prefab == "dummy" then
			return true
		end
		return _StartConsuming(self, ...)
	end
end)

local rec = env.AddRecipe("dummy",
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

MadeRecipeSkinnable("dummy", {
	dummy_formal = {
		atlas = "images/inventoryimages/dummy.xml",
		image = "dummy_formal.tex",
	},
})

STRINGS.SKIN_NAMES.dummy_formal = "Formal dummy"

STRINGS.NAMES.DUMMY = "Dummy"
STRINGS.RECIPE_DESC.DUMMY = "It's like a chest, but for armor."

STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUMMY = "Looks dumb. Maybe I should dress it with something else?"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.DUMMY = "This looks strange. Maybe a little fire would help?"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.DUMMY = "Is a wooden man."
STRINGS.CHARACTERS.WENDY.DESCRIBE.DUMMY = "It looks like a corpse on a stick."
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.DUMMY = "Ah, the dummy. I shall decorate it!"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.DUMMY = "What a waste of wood."
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.DUMMY = "I shall decorate it."
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.DUMMY = "To show my enemies my mighty armor!"
STRINGS.CHARACTERS.WEBBER.DESCRIBE.DUMMY = "We saw something like this in the shops!"
STRINGS.CHARACTERS.WINONA.DESCRIBE.DUMMY = "I'm not a fashion designer, but this looks weird."
STRINGS.CHARACTERS.WARLY.DESCRIBE.DUMMY = "Le Mannequin! Maybe I should decorate it?"
STRINGS.CHARACTERS.WORTOX.DESCRIBE.DUMMY = "Hyuyu, I like how it looks!"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.DUMMY = "Friend for fancy things"
STRINGS.CHARACTERS.WURT.DESCRIBE.DUMMY = "Is he alive, florp?"

-- Debug commands
if CHEATS_ENABLED then
	local BLACKLIST = {
		world = true,
		cave = true,
		forest = true,
		lavaarena = true,
		quagmire = true,
		forest_network = true,
		cave_network = true,
		lavaarena_network = true,
		quagmire_network = true,
		shard_network = true,
		shard = true,
	}

	-- Equips every equippable item in game on dummy to check for crashes
	function dum_TestItems(slot)
		local items = {}
		local dummy = SpawnAt("dummy", ThePlayer or Vector3(0, 0, 0))
		
		for pref, data in pairs(Prefabs) do
			pcall(function()
				if not BLACKLIST[pref] and data.fn then
					print("TESTING", pref)
					local item = SpawnPrefab(pref)
					if item then
						if item.components.equippable and (not slot or item.components.equippable.equip_slot == slot) then
							table.insert(items, item)
						else
							item:Remove()
						end
					end
				end
			end)
		end
		
		for i, item in ipairs(items) do
			dummy.components.container:GiveItem(item)
			dummy.components.container:RemoveItem(item):Remove()
		end
	end
end
