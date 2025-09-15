if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "SpawnResourceDepositsTools" )
    if ( stringNumber ~= 1 ) then
        return
    end

    -- local mapperName = "SpawnResourceDepositsTools|" .. tostring(self.playerId)
    --                                           .. "|" .. tostring(self.cellEntity)
    --                                           .. "|" .. tostring(self.veinName)
    --                                           .. "|" .. tostring(self.resourceName)
    --                                           .. "|" .. tostring(self.currentValue)


    local splitArray = Split( mapperName, "|" )
    if ( #splitArray ~= 6 ) then
        return
    end

    local playerIdStr = splitArray[2]

    local playerId = tonumber(playerIdStr)
    if ( playerId == nil ) then
        return
    end



    local cellEntityStr = splitArray[3]

    local cellEntity = tonumber(cellEntityStr)

    if ( cellEntity == nil ) then
        return
    end

    if ( not EntityService:IsAlive( cellEntity ) ) then
        return
    end

    local veinName = splitArray[4]
    local resourceName = splitArray[5]

    local currentValueStr = splitArray[6]

    local currentValue = tonumber(currentValueStr)
    if ( currentValue == nil ) then
        return
    end

    if ( currentValue <= 0 ) then
        return
    end

    local announcementsDict = {
        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",

        ["uranium"] = "voice_over/announcement/not_enough_uranium",
        ["uranium_ore"] = "voice_over/announcement/not_enough_uranium",
    }

    local annoucement = ""
    if ( announcementsDict[resourceName] ~= nil ) then
        annoucement = announcementsDict[resourceName]
    end



    local playerEntity = PlayerService:GetPlayerControlledEnt( playerId )



    local unlimitedMoney = false

    if ( ConsoleService and ConsoleService.GetConfig ) then

        unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    end

    if ( unlimitedMoney == false ) then

        local leadingPlayer = PlayerService:GetLeadingPlayer()

        local resourceCount = PlayerService:GetResourceAmount( leadingPlayer, resourceName )
        if ( resourceCount < currentValue ) then

            if ( annoucement ~= nil and annoucement ~= "" ) then

                QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 1.0, annoucement, playerEntity, false )
            end

            return
        end
    end



    local position = FindService:GetCellOrigin(cellEntity)

    local currentTarget = EntityService:SpawnEntity( position )

    EntityService:CreateLifeTime( currentTarget, 0.5, "normal" )



    local treasureSpotFind = FindService:FindEmptySpotInRadius( currentTarget, 1.0, "", "" )
    if ( treasureSpotFind.first == false ) then
        return
    end

    local team = EntityService:GetTeam( playerEntity )

    local position = treasureSpotFind.second




    local entityScript = EntityService:SpawnEntity( "misc/spawn_resource_deposits/script", position, team )

    local database = EntityService:GetOrCreateDatabase( entityScript )

    database:SetInt( "player_id", playerId )
    database:SetString( "annoucement", annoucement )
    database:SetString( "vein_name", veinName )
    database:SetString( "resource_name", resourceName )
    database:SetFloat( "current_value", currentValue )

end)