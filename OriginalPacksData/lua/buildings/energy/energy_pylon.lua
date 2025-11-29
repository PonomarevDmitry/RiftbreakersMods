local building = require("lua/buildings/building.lua")
require("lua/utils/table_utils.lua")
class 'energy_pylon' ( building )

function energy_pylon:__init()
	building.__init(self,self)
end

function energy_pylon:OnInit()
    EntityService:SetScale( self.entity, 1.0, 1.0, 1.0 )
    self.blueprint = EntityService:GetBlueprintName( self.entity ) 
    self.list = {}
    
    self.emitMachine = self:CreateStateMachine()
	self.emitMachine:AddState( "emit", { from="*", execute="OnEmit", interval=5} )
    self.emitMachine:ChangeState("emit")

end


function energy_pylon:ShootLightningAtTarget(target_entity)
    local drone_position = EntityService:GetPosition(self.entity)
    local target_position = EntityService:GetPosition(target_entity)

    local lightning = EntityService:SpawnEntity( "effects/buildings_and_machines/energy_pylon_lightning", self.entity, "")
    local component = reflection_helper(EntityService:GetComponent(lightning, "LightningDataComponent"))

    local container = rawget(component.lighning_vec, "__ptr");

    local instance = nil
    if ( container:GetItemCount() == 0 ) then
        instance = reflection_helper(container:CreateItem())
    else 
        instance = reflection_helper(container:GetItem(0))
    end

    local direction = VectorMulByNumber( Normalize( VectorSub( target_position, drone_position ) ), 2.0 )
    drone_position = VectorAdd(drone_position, direction)

    instance.start_point.x = drone_position.x
    instance.start_point.y = drone_position.y + 10
    instance.start_point.z = drone_position.z

    instance.end_point.x = target_position.x
    instance.end_point.y = target_position.y + 10
    instance.end_point.z = target_position.z
end
function energy_pylon:OnEmit()
    local entities = FindService:FindEntitiesByBlueprint( self.blueprint )
    Remove( entities, self.entity )
    if ( #entities == 0 ) then
        return
    end
    local entIdx = RandInt( 1, #entities)
    local selectedEntity = entities[entIdx]    
    self:ShootLightningAtTarget(selectedEntity)
    --local targetPosition = EntityService:GetPosition( self.entity )
    --targetPosition.y = targetPosition.y + 3
    --local testEnt = EntityService:SpawnEntity("buildings/energy/energy_line_ghost", targetPosition, EntityService:GetTeam( self.entity ))
    --EntityService:SetScale( testEnt, 1.0 , 0.1, 0.1)
    --MoveService:MoveToTarget( testEnt, selectedEntity, "att_smoke_1", true, 6 )
    --self:RegisterHandler( testEnt, "MoveEndEvent", "OnLineMoveEndEvent" )
    --Insert( self.list, testEnt )
end

function energy_pylon:OnLineMoveEndEvent( evt)
    EntityService:RemoveEntity( evt:GetEntity() )
    Remove( self.list,  evt:GetEntity() )
end


function energy_pylon:OnDestroy()
    for ent in Iter(self.list ) do
        EntityService:RemoveEntity(ent)
    end
    self.list = {}

	return true
end

return energy_pylon
