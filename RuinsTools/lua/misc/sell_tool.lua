local tool_highlight_ruins = require("lua/misc/tool_highlight_ruins.lua")
require("lua/utils/reflection.lua")

class 'sell_tool' ( tool_highlight_ruins )

function sell_tool:__init()
    tool_highlight_ruins.__init(self,self)
end

function sell_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell", self.entity)
end

function sell_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_tool:AddedToSelection( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    local buildingComponentHelper = reflection_helper(buildingComponent)

    if ( buildingComponentHelper.m_isSellable == true ) then

        self:SetEntitySelectedMaterial( entity, "hologram/active" )

    else

        self:SetEntitySelectedMaterial( entity, "hologram/red" )
    end
end

function sell_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function sell_tool:FindEntitiesToSelect( selectorComponent )
    local selectedItems = tool_highlight_ruins.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for entity in Iter( self.selectedEntities ) do
        if ( IndexOf( ruins, entity ) == nil and IndexOf( selectedItems, entity ) == nil ) then

            sell_tool:RemovedFromSelection( entity )
        end
    end

    for entity in Iter( ruins ) do

        if ( IndexOf( self.selectedEntities, entity ) == nil ) then

            self:SetEntitySelectedMaterial( entity, "hologram/active" )

            if ( self.activated ) then
                self:OnActivateEntity( entity )
            end
        end
    end

    ConcatUnique( selectedItems, ruins )
    return selectedItems
end

function sell_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function sell_tool:OnUpdate()

    self:HighlightRuins()


    self.sellCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter( list ) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
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

function sell_tool:OnRotate()

end

function sell_tool:OnActivateEntity( entity )
    if ( EntityService:GetGroup( entity ) == "##ruins##" ) then
        EntityService:SetGroup( entity, "" )
        BuildingService:BlinkBuilding(entity)
        QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
    else
        QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
    end
end

return sell_tool