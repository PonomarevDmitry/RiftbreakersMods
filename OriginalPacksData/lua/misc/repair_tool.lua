
local tool = require("lua/misc/tool.lua")

class 'repair_tool' ( tool )

function repair_tool:__init()
    tool.__init(self,self)
end

function repair_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_repair", self.entity)
end
function repair_tool:OnPreInit()
    self.initialScale = {x=8,y=1,z=8}
end

function repair_tool:OnUpdate()

end

function repair_tool:AddedToSelection( entity )

end

function repair_tool:FindEntitiesToSelect( selectorComponent )
    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position 
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins)
    return selectedItems
end

function repair_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function repair_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function repair_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    for  ent in Iter(selectedEntities ) do
        local healthComponent = EntityService:GetComponent(ent, "HealthComponent") 
        if ( healthComponent == nil ) then goto continue end

        local helper = reflection_helper(healthComponent)

        if ( helper.health < helper.max_health ) then
            Insert(entities, ent)
        end

        ::continue::
    end

    return entities
end


function repair_tool:OnUpdate()
    self.repairCosts = {}
    for entity in Iter(self.selectedEntities ) do
        local skinned = EntityService:IsSkinned(entity)
        local child = EntityService:GetChildByName(entity, "##repair##") 
        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        
        local ruins = false
        local ruinsBlueprint = ""
        local canRepair = true
        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode ~= 2 ) then canRepair = false end 
        elseif( EntityService:GetGroup( entity ) == "##ruins##" ) then
            local database = EntityService:GetDatabase( entity )
            if ( database ) then
                ruinsBlueprint = database:GetString("blueprint")
                canRepair = BuildingService:CanAffordBuilding( ruinsBlueprint, self.playerId)
                ruins = true
            end
        end

        if ( canRepair and (( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(child))) or ruins )  then
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        else
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
            end
        end

        if(canRepair and not EntityService:IsAlive(child)) then
            local list = {}
            if (ruins ) then
                list = BuildingService:GetBuildCosts( ruinsBlueprint, self.playerId )                
            else
                list = BuildingService:GetRepairCosts( entity )
            end
            for resourceCost in Iter(list) do
                if ( self.repairCosts[resourceCost.first] == nil ) then
                   self.repairCosts[resourceCost.first ] = resourceCost.second 
                else
                   self.repairCosts[resourceCost.first ] = self.repairCosts[resourceCost.first ] + resourceCost.second 
                end
            end
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateRepairCosts( self.infoChild, self.playerId, self.repairCosts)
        BuildingService:OperateRepairCosts( self.corners, self.playerId, {})
    else
        BuildingService:OperateRepairCosts( self.infoChild , self.playerId,{})
        BuildingService:OperateRepairCosts( self.corners, self.playerId, self.repairCosts)
    end
end

function repair_tool:OnRotate()
end

function repair_tool:OnActivateEntity( entity )
    if( EntityService:GetGroup( entity ) == "##ruins##" ) then
        local database = EntityService:GetDatabase( entity )
        if ( database ) then
            ruinsBlueprint = database:GetString("blueprint")
            canRepair = BuildingService:CanAffordBuilding( ruinsBlueprint, self.playerId)
            local transform = EntityService:GetWorldTransform( entity )
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, ruinsBlueprint, transform, true )
        end
    else
        local child = EntityService:GetChildByName(entity, "##repair##") 
        if ( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(child)) then
            local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
            if ( buildingComponent ~= nil ) then
                local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
                if ( mode ~= 2 ) then return end 
            end

            QueueEvent("ScheduleRepairBuildingRequest", entity, self.playerId)
        end
    end
end

return repair_tool
 