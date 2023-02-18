
local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")

class 'sell_tool' ( tool )

function sell_tool:__init()
    tool.__init(self,self)
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
    return {x=1,y=1,z=1}
end

function sell_tool:AddedToSelection( entity )
    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    local buildingComponentHelper = reflection_helper(buildingComponent)
    if ( buildingComponentHelper.m_isSellable == true ) then
		if ( EntityService:IsSkinned(entity ) ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
        end
    else
		if ( EntityService:IsSkinned(entity ) ) then
            EntityService:SetMaterial( entity, "selector/hologram_red_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_red", "selected")
        end
    end
end

function sell_tool:FindEntitiesToSelect( selectorComponent )
    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position 
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for ent in Iter( self.selectedEntities ) do 
        if ( IndexOf( ruins, ent ) == nil and IndexOf( selectedItems, ent ) == nil ) then
            EntityService:RemoveMaterial( ent, "selected")
        end
    end
    for ent in Iter( ruins ) do 
        if ( IndexOf( self.selectedEntities, ent ) == nil ) then
		if ( EntityService:IsSkinned(ent ) ) then
            EntityService:SetMaterial( ent, "selector/hologram_active_skinned", "selected")
        else
            EntityService:SetMaterial( ent, "selector/hologram_active", "selected")
        end

            if ( self.activated )  then
                self:OnActivateEntity( ent )
            end
        end
    end
    
    ConcatUnique( selectedItems, ruins)
    return selectedItems
end


function sell_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_tool:OnUpdate()
    self.repairCosts = {}
    for entity in Iter(self.selectedEntities ) do
        local list = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list) do
            if ( self.repairCosts[resourceCost.first] == nil ) then
               self.repairCosts[resourceCost.first ] = resourceCost.second 
            else
               self.repairCosts[resourceCost.first ] = self.repairCosts[resourceCost.first ] + resourceCost.second 
            end
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.repairCosts)
        BuildingService:OperateSellCosts( self.corners, self.playerId, {})
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId,{})
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.repairCosts)
    end
end

function sell_tool:OnRotate()    

end

function sell_tool:OnActivateEntity( entity )
    if ( EntityService:GetGroup( entity ) == "##ruins##") then
        EntityService:SetGroup( entity, "")
        BuildingService:BlinkBuilding(entity)
        QueueEvent("DissolveEntityRequest", entity, 1.0, 0 )
    else
        QueueEvent("SellBuildingRequest", entity, self.playerId, false )
    end
end

return sell_tool
 