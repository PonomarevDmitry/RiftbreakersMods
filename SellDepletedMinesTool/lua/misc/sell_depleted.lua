local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'sell_depleted' ( tool )

function sell_depleted:__init()
    tool.__init(self,self)
end

function sell_depleted:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell", self.entity)
    
    self.scaleMap = {
        1,
    }
end

function sell_depleted:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_depleted:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_depleted:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_depleted:AddedToSelection( entity )

    if ( EntityService:IsSkinned( entity ) ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_depleted:OnUpdate()

    self.sellCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0 
            end

            self.sellCosts[resourceCost.first ] = self.sellCosts[resourceCost.first] + resourceCost.second 
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_depleted:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_depleted:FilterSelectedEntities( selectedEntities )

    local entities = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingsComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode <= 2 ) then
            goto continue
        end

        if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
            goto continue
        end

        --if ( BuildingService:IsResourceSupplied( entity ) ) then
        --    goto continue
        --end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        local resourceRequirement = buildingDescRef.resource_requirement
        if ( resourceRequirement == nil or resourceRequirement.count <= 0 ) then
            goto continue
        end

        local isOnResource = self:CheckEntityOnResource( entity, resourceRequirement )
        if ( isOnResource ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_depleted:CheckEntityOnResource( entity, resourceRequirement )

    for i = 1,resourceRequirement.count do

        local resource = resourceRequirement[i]

        if ( resource ~= nil and resource ~= "" ) then

            if ( BuildingService:IsOnResource(entity, resource) ) then
                
            	return true
            end
        end
    end
    
    return false
end

function sell_depleted:OnActivateSelectorRequest()
    
    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do
        QueueEvent("SellBuildingRequest", entity, self.playerId, false )
    end

    self:OnUpdate()
end

function sell_depleted:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
    end

    tool.OnRelease(self)
end

function sell_depleted:OnRotateSelectorRequest(evt)
end

return sell_depleted