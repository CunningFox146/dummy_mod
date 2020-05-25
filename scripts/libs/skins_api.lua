-- Made by CunningFox
-- Original code by Ysovuka/Kzisor

local env = env
GLOBAL.setfenv(1, GLOBAL)

local OFFICIAL_PREFABS = {}

local _RegisterPrefabs = ModManager.RegisterPrefabs
ModManager.RegisterPrefabs = function(self, ...)
	if not next(OFFICIAL_PREFABS) then
		for k, v in pairs(Prefabs) do
			OFFICIAL_PREFABS[v.name] = true
		end
	end
	return _RegisterPrefabs(self, ...)
end

local function IsOfficial(item)
	return OFFICIAL_PREFABS[item]
end

local function RecipePopupPostConstruct(self)
    local _GetSkinsList = self.GetSkinsList
    self.GetSkinsList = function(self, ...)
        if IsOfficial(self.recipe.product) then
            return _GetSkinsList(self, ...)
        end
        
        self.skins_list = {}
        if self.recipe and PREFAB_SKINS[self.recipe.name] then
            for _, item_type in pairs(PREFAB_SKINS[self.recipe.name]) do
                local data = {
				    type = type,
				    item = item_type,
				    -- timestamp = nil
				}
				table.insert(self.skins_list, data)
			end
	    end
	    
	    return self.skins_list
    end
    
    local _GetSkinOptions = self.GetSkinOptions
    self.GetSkinOptions = function(self, ...)
        if IsOfficial(self.recipe.product) then
            return _GetSkinOptions(self, ...)
        end
		
        local skin_options = {}

        table.insert(skin_options, 
        {
            text = STRINGS.UI.CRAFTING.DEFAULT,
            data = nil, 
            colour = SKIN_RARITY_COLORS.Common,
            new_indicator = false,
            image =  {self.recipe.atlas or "images/inventoryimages.xml", self.recipe.image or self.recipe.name..".tex", "default.tex"},
        })
		
        if self.skins_list and TheNet:IsOnlineMode() then 
			-- local recipe_timestamp = Profile:GetRecipeTimestamp(self.recipe.name)
            for i, data in ipairs(self.skins_list) do
                local item = data.item 
				
                local rarity = GetRarityForItem(item) or "Common"
                local colour = SKIN_RARITY_COLORS[rarity]
                local text_name = STRINGS.SKIN_NAMES[item] or STRINGS.SKIN_NAMES.missing
                -- local new_indicator = not data.timestamp or (data.timestamp > recipe_timestamp)

				local image_name = item
				local atlas = self.recipe.skin_img_data and self.recipe.skin_img_data[item].atlas or self.recipe.atlas or "images/inventoryimages.xml"
				
				if self.recipe.skin_img_data then
					image_name = self.recipe.skin_img_data[item].image
				else
					if image_name == "" then 
						image_name = "default"
					else
						image_name = string.gsub(image_name, "_none", "")
					end
					image_name = image_name .. ".tex"
				end

                table.insert(skin_options,  
                {
                    text = text_name, 
                    data = nil,
                    colour = colour,
                    -- new_indicator = new_indicator,
                    image = {atlas, image_name, "poop.tex"},
                })
            end
	    else 
    		self.spinner_empty = true
	    end

	    return skin_options
    end
end

local function BuilderSkinPostInit(self)
    local _MakeRecipeFromMenu = self.MakeRecipeFromMenu
    self.MakeRecipeFromMenu = function(self, recipe, skin, ...)
        if IsOfficial(recipe.product) then
            return _MakeRecipeFromMenu(self, recipe, skin, ...)
        end
		
		if not recipe.placer then
			if self:KnowsRecipe(recipe.name) then
				if self:IsBuildBuffered(recipe.name) or self:CanBuild(recipe.name) then
					self:MakeRecipe(recipe, nil, nil, skin)
				end
			elseif CanPrototypeRecipe(recipe.level, self.accessible_tech_trees) and
				self:CanLearn(recipe.name) and
				self:CanBuild(recipe.name) then
				self:MakeRecipe(recipe, nil, nil, skin, function()
					self:ActivateCurrentResearchMachine()
					self:UnlockRecipe(recipe.name)
				end)
			end
		end 
    end
	
    local _DoBuild = self.DoBuild
	-- Fox: We don't use Klei's skinned prefabs system, we just spawn a skin prefab
	-- Change the product of the prefab to a skin, call Build fn, revert changes.
    self.DoBuild = function(self, recname, pt, rotation, skin, ...)
		local rec = GetValidRecipe(recname)
        if rec and not IsOfficial(rec.product) then
            if skin then
                if not AllRecipes[recname]._product then
                    AllRecipes[recname]._product = AllRecipes[recname].product
                end
                AllRecipes[recname].product = skin
            else
                if AllRecipes[recname]._product then
                    AllRecipes[recname].product = AllRecipes[recname]._product
                end
            end
        end
        
        local val = {_DoBuild(self, recname, pt, rotation, skin, ...)}
		
		if AllRecipes[recname]._product then
			AllRecipes[recname].product = AllRecipes[recname]._product
		end
		AllRecipes[recname]._product = nil
		
		return unpack(val)
    end
end

env.AddClassPostConstruct("widgets/recipepopup", RecipePopupPostConstruct)
env.AddComponentPostInit("builder", BuilderSkinPostInit)

-- Apply item's skin to placer
env.AddComponentPostInit("playercontroller", function(self)
	local _StartBuildPlacementMode = self.StartBuildPlacementMode
	function self:StartBuildPlacementMode(...)
		local val = {_StartBuildPlacementMode(self, ...)}
		
		if self.placer and self.placer.ApplySkin and self.placer_recipe_skin then
			self.placer:ApplySkin(self.placer_recipe_skin)
		end
		
		return unpack(val)
	end
end)

function CreateModPrefabSkin(item, info)
	-- Fox: This is never even gets called, but CreatePrefabSkin requires it
	if not rawget(_G, info.base_prefab.."_clear_fn") then
		rawset(_G, info.base_prefab.."_clear_fn", function(inst)  basic_clear_fn(inst, info.build_name_override) end)
	end
	
	if not PREFAB_SKINS[info.base_prefab] then
		PREFAB_SKINS[info.base_prefab] = {}
	end
	table.insert(PREFAB_SKINS[info.base_prefab], item)
	
	info.fn = info.fn or function(...) print("ERROR: Tried to create a skinned prefab without base fn!") end
	
	local prefab = CreatePrefabSkin(item, info)
	prefab.fn = function(...)
		local inst = info.fn(...)
		if not info.custom_name then
			inst:SetPrefabNameOverride(info.base_prefab)
		end
		return inst
	end
	
	return prefab
end

function MadeRecipeSkinnable(rec_name, data)
	local rec = AllRecipes[rec_name]
	if not rec then
		print("ERROR: Tried to make skinnable recipe but failed to find the recipe itself! Recipe:", rec_name)
		return
	end
	
	rec.skinnable = true
	
	if data then
		rec.skin_img_data = {}
		for name, img_data in pairs(data) do
			rec.skin_img_data[name] =
			{
				atlas = img_data.atlas,
				image = img_data.image,
			}
		end
	end
end

env.MadeRecipeSkinnable = MadeRecipeSkinnable