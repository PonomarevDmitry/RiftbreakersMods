require("lua/utils/reflection.lua")

function GetOwnerPlayer( entity )
    local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent" )
    if ( playerReferenceComponent == nil ) then
        return nil
    end
    return reflection_helper( playerReferenceComponent ).player_id
end
