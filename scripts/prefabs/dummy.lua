local assets =
{
    Asset("ANIM", "anim/dummy02.zip"),
}

local SYMBOLS = {
    [EQUIPSLOTS.HEAD] = "swap_hat",
    [EQUIPSLOTS.BODY] = "swap_body",
    [EQUIPSLOTS.HANDS] = "swap_object",
}

local function UpdateEquip(inst, data)
	print("**********\nUpdateEquip")
	local items_to_unequip = {}
	
	for i, v in pairs(inst.items) do
		print("CHECK", v, inst.components.container:GetItemSlot(v), v.components.inventoryitem.owner)
		if v and not inst.components.container:GetItemSlot(v) then
			table.insert(items_to_unequip, v)
			inst.items[i] = nil
		end
	end
	
	for i, item in ipairs(items_to_unequip) do
		local symbol = SYMBOLS[item.components.equippable.equipslot]
		
		item.components.equippable:Unequip(inst)
		
		inst.AnimState:ClearOverrideSymbol(symbol)
		inst.AnimState:HideSymbol(symbol)
		print("UNEQUIP", item)
	end
	
	if data.item and data.item.components.equippable then
		print("EQUIP", data.item)
		local symbol = SYMBOLS[data.item.components.equippable.equipslot]
		data.item.components.equippable:Equip(inst)
		inst.AnimState:ShowSymbol(symbol)
		
		for i = 1, 3 do
			if not inst.items[i] then
				inst.items[i] = data.item
				break
			end
		end
	end
	
	printwrap("items", inst.items)
	print("**********\n")
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
    if workleft > 0 then
        inst.AnimState:PlayAnimation("hit")

        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("dummy")
    inst.AnimState:SetBuild("dummy02")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:HideSymbol("swap_hat")
    inst.AnimState:HideSymbol("swap_object")
    inst.AnimState:HideSymbol("swap_body")
	
	inst:AddTag("structure")

	MakeObstaclePhysics(inst, .3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
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
	-- inst.components.container.onopenfn = onopen
	-- inst.components.container.onclosefn = onclose

	MakeHauntableWork(inst)
	
	inst:ListenForEvent("onbuilt", OnBuild)
	inst:ListenForEvent("itemget", UpdateEquip)
	inst:ListenForEvent("itemlose", UpdateEquip)

    return inst
end

return Prefab("dummy", fn, assets, prefabs)
