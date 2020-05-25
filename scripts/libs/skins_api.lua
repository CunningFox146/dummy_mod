-- Items skins (code by Ysovuka/Kzisor):
local function RecipePopupPostConstruct( widget )

    local _GetSkinsList = widget.GetSkinsList
    widget.GetSkinsList = function( self )
        if self.recipe.skinnable == nil then
            return _GetSkinsList( self )
        end
        
        self.skins_list = {}
        if self.recipe and GLOBAL.PREFAB_SKINS[self.recipe.name] then
            for _,item_type in pairs(GLOBAL.PREFAB_SKINS[self.recipe.name]) do
                local data  = {}
				    data.type = type
				    data.item = item_type
				    data.timestamp = nil
				    table.insert(self.skins_list, data)
			end
	    end
	    
	    return self.skins_list
    end
    
    local _GetSkinOptions = widget.GetSkinOptions
    widget.GetSkinOptions = function( self )
        if self.recipe.skinnable == nil then
            return _GetSkinOptions( self )
        end
        
        local skin_options = {}

        table.insert(skin_options, 
        {
            text = GLOBAL.STRINGS.UI.CRAFTING.DEFAULT,
            data = nil, 
            colour = GLOBAL.SKIN_RARITY_COLORS["Common"],
            new_indicator = false,
            image =  {self.recipe.atlas or "images/inventoryimages.xml", self.recipe.image or self.recipe.name .. ".tex", "default.tex"},
        })

        local recipe_timestamp = GLOBAL.Profile:GetRecipeTimestamp(self.recipe.name)
        --print(self.recipe.name, "Recipe timestamp is ", recipe_timestamp)
        if self.skins_list and GLOBAL.TheNet:IsOnlineMode() then 
            for which = 1, #self.skins_list do 
                local image_name = self.skins_list[which].item 

				local GetName = function(var)
					return GLOBAL.STRINGS.SKIN_NAMES[var]
				end
				
                local rarity = GLOBAL.GetRarityForItem("item", image_name)
                local colour = rarity and GLOBAL.SKIN_RARITY_COLORS[rarity] or GLOBAL.SKIN_RARITY_COLORS["Common"]
                local text_name = GetName(image_name) or GLOBAL.SKIN_STRINGS.SKIN_NAMES["missing"]
                local new_indicator = not self.skins_list[which].timestamp or (self.skins_list[which].timestamp > recipe_timestamp)

                if image_name == "" then 
                    image_name = "default"
                else
                    image_name = string.gsub(image_name, "_none", "")
                end

                table.insert(skin_options,  
                {
                    text = text_name, 
                    data = nil,
                    colour = colour,
                    new_indicator = new_indicator,
                    image = {self.recipe.atlas or image_name .. ".xml" or "images/inventoryimages.xml", image_name..".tex" or "default.tex", "default.tex"},
                })
            end

	    else 
    		self.spinner_empty = true
	    end

	    return skin_options
    
    end
end

AddClassPostConstruct("widgets/recipepopup", RecipePopupPostConstruct)

local function BuilderSkinPostInit( builder )

    local _MakeRecipeFromMenu = builder.MakeRecipeFromMenu
    builder.MakeRecipeFromMenu = function( self, recipe, skin )
        if recipe.skinnable == nil then
            _MakeRecipeFromMenu( self, recipe, skin )
		else
			if recipe.placer == nil then
				if self:KnowsRecipe(recipe.name) then
					if self:IsBuildBuffered(recipe.name) or self:CanBuild(recipe.name) then
						self:MakeRecipe(recipe, nil, nil, skin)
					end
				elseif GLOBAL.CanPrototypeRecipe(recipe.level, self.accessible_tech_trees) and
					self:CanLearn(recipe.name) and
					self:CanBuild(recipe.name) then
					self:MakeRecipe(recipe, nil, nil, skin, function()
						self:ActivateCurrentResearchMachine()
						self:UnlockRecipe(recipe.name)
					end)
				end
			end
        end     
    end
	
    local _DoBuild = builder.DoBuild
    builder.DoBuild = function( self, recname, pt, rotation, skin )
        if GLOBAL.GetValidRecipe(recname).skinnable then
            if skin ~= nil then
                if GLOBAL.AllRecipes[recname]._oldproduct == nil then
                    GLOBAL.AllRecipes[recname]._oldproduct = GLOBAL.AllRecipes[recname].product
                end
                GLOBAL.AllRecipes[recname].product = skin
            else
                if GLOBAL.AllRecipes[recname]._oldproduct ~= nil then
                    GLOBAL.AllRecipes[recname].product = GLOBAL.AllRecipes[recname]._oldproduct
                end
            end
        end
        
        return _DoBuild( self, recname, pt, rotation, skin )
    end
    
end

AddComponentPostInit("builder", BuilderSkinPostInit)