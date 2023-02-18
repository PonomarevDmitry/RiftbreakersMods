---------------------------------------------------
        -- Mod created by @SenorRagequit --
        -- Shoutout to Lukasz + Starbugs --
        -- Stop stealing my ideas Pawel! --
---------------------------------------------------

RegisterGlobalEventHandler("PickedUpItemEvent", function(evt)

    local itemEntity = evt:GetEntity()

    local l_blueprint = EntityService:GetBlueprintName( itemEntity )
    
    local maxCountStandard = 32
    local maxCountAdvanced = 32
    local maxCountSuperior = 160
    local maxCountExtreme = 160

    if l_blueprint ~= nil then        
        
        local l_numItemsInInv = ItemService:GetItemCount(PlayerService:GetPlayerControlledEnt(0), l_blueprint)

        if string.find(l_blueprint, "items/loot/weapon_mods") then
        
            if string.find(l_blueprint, "standard") then
            
                if l_numItemsInInv > maxCountStandard then
                
                    EntityService:RemoveEntity( itemEntity )

                    PlayerService:AddResourceAmount( "carbonium", 100 )
                    PlayerService:AddResourceAmount( "steel", 50 )
                end

            elseif string.find(l_blueprint, "advanced") then
            
                if l_numItemsInInv > maxCountAdvanced then
                
                    EntityService:RemoveEntity( itemEntity )

                    PlayerService:AddResourceAmount( "carbonium", 200 )
                    PlayerService:AddResourceAmount( "steel", 75 )
                end

            elseif string.find(l_blueprint, "superior") then
            
                if l_numItemsInInv > maxCountSuperior then
                
                    EntityService:RemoveEntity( itemEntity )

                    PlayerService:AddResourceAmount( "carbonium", 300 )
                    PlayerService:AddResourceAmount( "steel", 100 )
                end

            elseif string.find(l_blueprint, "extreme") then
            
                if l_numItemsInInv > maxCountExtreme then
                
                    EntityService:RemoveEntity( itemEntity )

                    PlayerService:AddResourceAmount( "carbonium", 400 )
                    PlayerService:AddResourceAmount( "steel", 200 )
                end
            end
        end
    end

end)