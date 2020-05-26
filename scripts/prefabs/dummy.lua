local assets =
{
    Asset("ANIM", "anim/dummy.zip"),
	
    Asset("IMAGE", "images/inventoryimages/dummy.tex"),
    Asset("ATLAS", "images/inventoryimages/dummy.xml"),
}

local pass = function() return true end

local builder = require("components/builder")

local SLOTS_INDEX = DUMMY_SLOTS
local SLOTS_COUNT = 3

-- Generate symbol swaps dynamicly for mod compatibility
local SYMBOLS = {}

local slot_swaps = {
    [1] = "swap_object",
    [2] = "swap_body",
    [3] = "swap_hat",
}

for name, id in pairs(DUMMY_SLOTS) do
	SYMBOLS[name] = slot_swaps[id]
end

local function Jump(inst)
	inst.AnimState:PlayAnimation("open")
	inst.AnimState:PushAnimation("idle")
end

local function Upequip(inst, item)
	local symbol = SYMBOLS[item.components.equippable.equipslot]
	
	item.components.equippable:Unequip(inst)
	
	if item.components.useableitem and item.components.useableitem._onusefn then
		item.components.useableitem.onusefn = item.components.useableitem._onusefn
		item.components.useableitem._onusefn = nil
	end
	
	inst.AnimState:ClearOverrideSymbol(symbol)
	inst.AnimState:HideSymbol(symbol)
end

local function UpdateEquip(inst, data)
    if inst:HasTag("burnt") then
        return
    end
	
	local items_to_unequip = {}
	local play_jump = false
	
	for i, v in pairs(inst.items) do
		if v and not inst.components.container:GetItemSlot(v) then
			table.insert(items_to_unequip, v)
			inst.items[i] = nil
		end
	end
	
	for i, item in ipairs(items_to_unequip) do
		Upequip(inst, item)
		play_jump = true
	end
	
	if data.item and data.item.components.equippable then
		local symbol = SYMBOLS[data.item.components.equippable.equipslot]
		data.item.components.equippable:Equip(inst)
		inst.AnimState:ShowSymbol(symbol)
		play_jump = true
		
		-- We don't want items to be used on dummy
		if data.item.components.useableitem then
			data.item.components.useableitem._onusefn = data.item.components.useableitem.onusefn
			data.item.components.useableitem.onusefn = pass
		end
		
		for i = 1, SLOTS_COUNT do
			if not inst.items[i] then
				inst.items[i] = data.item
				break
			end
		end
	end
	
	if play_jump then
		Jump(inst)
	end
end

local function OnBuild(inst)
	inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end


local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnAt("collapse_small", inst)
    fx:SetMaterial("wood")
	
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
	
    inst:Remove()
end

local function onworked(inst, worker, workleft)
    if workleft > 0 and not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")

        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function OnBurnt(inst)
	for slot, item in pairs(inst.items) do
		Upequip(inst, item)
		inst.items[slot] = nil
	end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("dummy")
    inst.AnimState:SetBuild("dummy")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:HideSymbol("swap_hat")
    inst.AnimState:HideSymbol("swap_object")
    inst.AnimState:HideSymbol("swap_body")
    inst.AnimState:Hide("LANTERN_OVERLAY")
	
    inst.MiniMapEntity:SetIcon("dummy.tex")

	inst:AddTag("structure")

	MakeObstaclePhysics(inst, .3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	-- FOX: Dirty hack for eyebrella and purple staff. Fake DynamicShadow.
	inst.DynamicShadow = {}
	for fn, _ in pairs(DynamicShadow) do
		inst.DynamicShadow[fn] = pass
	end
	
	inst.items = {}
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onworkfinished)
	inst.components.workable:SetOnWorkCallback(onworked)

    inst:AddComponent("inspectable")
	
    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("dummy")
	inst.components.container.onopenfn = Jump
	inst.components.container.onclosefn = Jump
	
	-- We can't just put item in the next slot. We need to find a valid one first!
	local _GiveItem = inst.components.container.GiveItem
	function inst.components.container:GiveItem(item, slot, ...)
		if item and item.components.equippable and SLOTS_INDEX[item.components.equippable.equipslot] then
			slot = SLOTS_INDEX[item.components.equippable.equipslot]
		end
		if slot then
			return _GiveItem(self, item, slot, ...)
		end
		return false
	end
	
	-- Strange, right? But most of the items just assume that owner has SG
	-- So it's better just add it
	inst:SetStateGraph("SGdummy")
	
	-- We don't really want to add builder component.
	-- But green amulet doesn't check for it.
	-- I mean, what other way we have to do it?
	inst.components.builder = {}
	for k, _ in pairs(builder) do
		inst.components.builder[k] = pass
	end

	MakeHauntableWork(inst)	
	MakeSmallBurnable(inst, nil, nil, true)
	MakeSmallPropagator(inst)
	
	inst:ListenForEvent("onbuilt", OnBuild)
	inst:ListenForEvent("itemget", UpdateEquip)
	inst:ListenForEvent("itemlose", UpdateEquip)
	inst:ListenForEvent("burntup", OnBurnt)
	
	inst.OnSave = onsave
	inst.OnLoad = onload
	
    return inst
end

local function formal()
	local inst = fn()
	
	inst.MiniMapEntity:SetIcon("dummy_formal.tex")
	
	inst.AnimState:SetBuild("dummy_formal")
	
	return inst
end

local function placer(inst, ...)
    inst.AnimState:HideSymbol("swap_hat")
    inst.AnimState:HideSymbol("swap_object")
    inst.AnimState:HideSymbol("swap_body")
    inst.AnimState:Hide("LANTERN_OVERLAY")
	
	inst.ApplySkin = function(inst, skin)
		inst.AnimState:SetBuild("dummy_formal")
	end
end

return Prefab("dummy", fn, assets, prefabs),
	MakePlacer("dummy_placer", "dummy", "dummy", "anim", nil, nil, nil, nil, nil, nil, placer),
	CreateModPrefabSkin("dummy_formal",
	{
		assets = {
			Asset("ANIM", "anim/dummy_formal.zip"),
		},
		base_prefab = "dummy",
		fn = formal,
		rarity = "Timeless",
		reskinable = true,
		
		build_name_override = "dummy_formal",
		
		type = "item",
		skin_tags = { },
		release_group = 0,
	})
