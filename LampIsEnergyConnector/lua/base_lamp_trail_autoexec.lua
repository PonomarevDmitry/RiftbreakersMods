require("lua/utils/table_utils.lua")

local base_lamp_trail_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/base_lamp_trail",
        "items/skills/crystal_lamp_trail"
    }

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local hashItemUnlocked = {}

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( IndexOf( skillList, unlockedItem ) ~= nil ) then

                hashItemUnlocked[unlockedItem] = true
            end
        end

        for skillName in Iter( skillList ) do

            if (hashItemUnlocked[skillName] == nil) then

                local team = EntityService:GetTeam( player )

                QueueEvent( "NewAwardEvent", INVALID_ID, skillName, true, team )
            end
        end
    end

    for skillName in Iter( skillList ) do

        local itemCount = PlayerService:GetItemNumber( playerId, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    base_lamp_trail_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    base_lamp_trail_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    base_lamp_trail_autoexec(evt)
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
        return
    end

    local parameterName = "$" .. lowName .. "_trail_blueprint"

    local selector = evt:GetEntity()
    if ( selector and selector != INVALID_ID ) then

        local selectorDB = EntityService:GetDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end
    end

    if ( CampaignService.GetCampaignData ) then
    
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase ) then
            campaignDatabase:SetString( parameterName, blueprintName )
        end
    end
end)
