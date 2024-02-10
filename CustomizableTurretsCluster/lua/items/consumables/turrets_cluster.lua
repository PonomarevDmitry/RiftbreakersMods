local item = require("lua/items/item.lua")

class 'turrets_cluster' ( item )

function turrets_cluster:__init()
    item.__init(self,self)
end

function turrets_cluster:OnInit()

    LogService:Log("OnInit ")

end

function turrets_cluster:OnLoad()

    LogService:Log("OnLoad ")

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
end

function turrets_cluster:OnEquipped()
end

function turrets_cluster:OnActivate()

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        return
    end

    local position = {}
    position.x = pos.second.x
    position.y = pos.second.y
    position.z = pos.second.z

    for i=1,3 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        LogService:Log("OnActivate modItemBlueprint " .. tostring(modItemBlueprint))

        if ( modItemBlueprint ~= nil and modItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then

            local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

            if ( blueprintDatabase and blueprintDatabase:HasString("blueprint") ) then

                LogService:Log("OnActivate position.x " .. tostring(position.x) .. " position.y " .. tostring(position.y) .. " position.z " .. tostring(position.z))

                local turretBlueprint = blueprintDatabase:GetString("blueprint")
                local timeout = blueprintDatabase:GetFloatOrDefault("timeout", 20.0)

                LogService:Log("OnActivate turretBlueprint " .. tostring(turretBlueprint))

                local tower = PlayerService:BuildBuildingAtSpot( turretBlueprint, position )
                ItemService:SetItemCreator( tower, self.entity_blueprint )
                EntityService:DissolveEntity( tower, 1.0, timeout )

                position.z = position.z + 2

                LogService:Log("OnActivate tower " .. tostring(tower))
            end
        end
    end
end

function turrets_cluster:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        return false
    end

    for i=1,3 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint ~= nil and modItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then

            local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

            if ( blueprintDatabase and blueprintDatabase:HasString("blueprint") ) then

                return true
            end
        end
    end

    return false
end

return turrets_cluster