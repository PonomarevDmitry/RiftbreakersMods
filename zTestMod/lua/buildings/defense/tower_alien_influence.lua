local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")

class 'tower_alien_influence' ( tower )

function tower_alien_influence:__init()
	tower.__init(self,self)
end

function tower_alien_influence:OnInit()
    tower.OnInit(self)

    self.cfsm = self:CreateStateMachine()
    self.cfsm:AddState( "checker", { execute="OnExecuteChecker", interval=1.0 } )
    self.cfsm:ChangeState("checker")
    self.created = false

    self.active = true
	self.selected = {}
    self.radius = self.data:GetFloatOrDefault("radius", 6)
	self.interval = self.data:GetFloatOrDefault("interval", 1)
	self.shieldBp = self.data:GetStringOrDefault("shield_bp", "buildings/defense/shield_generator/shield")
	self.healthChild = INVALID_ID

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", {execute="OnWorkInProgress",exit="OnWorkExit", interval=self.interval} )

	self:RegisterHandler( self.entity, "SpikeAmmoFiredEvent",  "OnSpikeAmmoFiredEvent" )
end

function tower_alien_influence:OnSpikeAmmoFiredEvent( evt )
	AnimationService:StartAnim( self.entity, "working", false )
end

function tower_alien_influence:OnExecuteChecker( state )
    if (self.working == self.created ) then
        return
    end

    if ( self.working ) then
		local workingTime = BuildingService:GetWorkingTime( self.entity )
        if ( workingTime and workingTime > 1.0 ) then
            local influenceComponent =EntityService:CreateComponent(self.entity, "InfluenceComponent")
            local influenceComponentHelper = reflection_helper(influenceComponent)
            influenceComponentHelper.radius = 13
            influenceComponentHelper.energy_radius = 0
            influenceComponentHelper.emissive_radius = 5
            self.created = true
        end
    else
	    EntityService:RemoveComponent(self.entity, "InfluenceComponent")
        self.created = false
    end

end

function tower_alien_influence:OnWorkInProgress( state )
	if ( self.healthChild == INVALID_ID or HealthService:GetHealth( self.healthChild)== -1 ) then
		self.healthChild = EntityService:SpawnAndAttachEntity( self.shieldBp, self.entity )
		return
	end

    local hashSelected = {}
	for entity in Iter(self.selected) do
        hashSelected[entity] = false
    end

	local objects = FindService:FindEntitiesByTypeInRadius( self.entity, "building", self.radius )

	for i = 1, #objects do
		
		local entity = objects[i]

		if ( hashSelected[entity] ~= nil ) then

			hashSelected[entity] = true

		elseif ( BuildingService:IsBuildingFinished( entity ) ) then

			ItemService:AddHealthLink( entity, self.healthChild )
			Insert( self.selected, entity )

			hashSelected[entity] = true
		end
	end

	for i = #self.selected,1,-1  do

		local entity = self.selected[i]

		if( hashSelected[entity] == false ) then

			ItemService:RemoveHealthLink( entity, self.healthChild )

            local last = #self.selected
            self.selected[i] = self.selected[last]
            self.selected[last] = nil
		end
	end
			
	--for i = 1, #objects do			
	--	if( IndexOf( self.selected, objects[i] ) == nil and BuildingService:IsBuildingFinished( objects[i] ) )
	--	then
	--		ItemService:AddHealthLink( objects[i], self.healthChild )
	--		Insert( self.selected, objects[i] )	
	--	end
	--end		
	--
	--for i = #self.selected,1,-1  do			
	--	if( IndexOf( objects, self.selected[i] ) == nil ) then
	--		ItemService:RemoveHealthLink( self.selected[i], self.healthChild )
	--		Remove( self.selected, self.selected[i] )	
	--	end
	--end		
end

function tower_alien_influence:OnWorkExit( state )
	for i = #self.selected,1,-1  do		
		ItemService:RemoveHealthLink( self.selected[i], self.healthChild )
	end		
	Clear( self.selected )
end


function tower_alien_influence:OnActivate()
	self.fsm:ChangeState("working")
end

function tower_alien_influence:OnDeactivate()
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end	 
end

return tower_alien_influence
