local sell_by_type_base = require("lua/misc/sell_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_seller_tool' ( sell_by_type_base )

function sell_by_type_seller_tool:__init()
    sell_by_type_base.__init(self,self)
end

function sell_by_type_seller_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_by_type_seller_tool", self.entity)

    self:InitLowUpgradeList()

    self.isGroup = (self.data:GetIntOrDefault("is_group", 0) == 1)

    self.placeRuins = (self.data:GetIntOrDefault("place_ruins", 0) == 1)
end

function sell_by_type_seller_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_seller_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_by_type_seller_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_by_type_seller_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_by_type_seller_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingComponentRef = reflection_helper(buildingComponent)
        if ( buildingComponentRef.m_isSellable == false ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        if ( self.isGroup ) then

            if ( not self:IsBlueprintInLowNameList(blueprintName) ) then
                goto continue
            end
        else

            if ( not self:IsBlueprintInList(blueprintName) ) then
                goto continue
            end
        end


        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_by_type_seller_tool:OnUpdate()

    self.sellCosts = {}
    
    for entity in Iter( self.selectedEntities ) do
    
        local list = BuildingService:GetSellResourceAmount( entity )
        
        for resourceCost in Iter(list) do
        
            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end
            
           self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_by_type_seller_tool:OnRotate()

end

function sell_by_type_seller_tool:OnActivateEntity( entity )

    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation

    local blueprintName = EntityService:GetBlueprintName( entity )

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )

    if ( self.placeRuins ) then

        local ruinsBlueprint = blueprintName .. "_ruins"

        if ( ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then

            local newRuinsEntity = EntityService:SpawnEntity( ruinsBlueprint, position, team )

            EntityService:SetOrientation( newRuinsEntity, orientation )
        end
    end
end

return sell_by_type_seller_tool