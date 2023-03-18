require("lua/utils/table_utils.lua")
local building = require("lua/buildings/building.lua")

class 'shield_generator_radio' ( building )

function shield_generator_radio:__init()
	building.__init(self,self)
end

function shield_generator_radio:OnInit()
	self.active = true
	self.selected = {}
	-- Defaults:
	self.interval = 1
	self.radius = 6

	self.radius = self.data:GetFloatOrDefault("radius", 6)
	self.interval = self.data:GetFloatOrDefault("interval", 1)
	self.shieldBp = self.data:GetStringOrDefault("shield_bp", "buildings/defense/shield_generator_radio/shield_radio")
	self.healthChild = INVALID_ID
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "idle", {} )
	self.fsm:AddState( "working", {execute="OnWorkInProgress",exit="OnWorkExit", interval=self.interval} )
	--self.fsm:ChangeState("idle")
end

function shield_generator_radio:OnWorkInProgress( state )
	if ( self.healthChild == INVALID_ID or HealthService:GetHealth( self.healthChild)== -1 ) then
		self.healthChild = EntityService:SpawnAndAttachEntity( self.shieldBp, self.entity )
		return
	end
	local objects = FindService:FindEntitiesByTypeInRadius( self.entity, "building", self.radius )
			
	for i = 1, #objects do			
		if( IndexOf( self.selected, objects[i] ) == nil and BuildingService:IsBuildingFinished( objects[i] ) )
		then
			ItemService:AddHealthLink( objects[i], self.healthChild )
			Insert( self.selected, objects[i] )	
		end
	end		
	
	for i = #self.selected,1,-1  do			
		if( IndexOf( objects, self.selected[i] ) == nil ) then
			ItemService:RemoveHealthLink( self.selected[i], self.healthChild )
			Remove( self.selected, self.selected[i] )	
		end
	end		
end

function shield_generator_radio:OnWorkExit( state )
	for i = #self.selected,1,-1  do		
		ItemService:RemoveHealthLink( self.selected[i], self.healthChild )
	end		
	Clear( self.selected )
end

function shield_generator_radio:OnBuildingEnd()
end

function shield_generator_radio:OnActivate()
	self.fsm:ChangeState("working")
end

function shield_generator_radio:OnDeactivate()
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end	 
end

function shield_generator_radio:OnLoad()
	building.OnLoad(self)
	if ( self.shieldBp == nil ) then
		if ( self.data:HasString("shield_bp")) then
			self.shieldBp = self.data:GetStringOrDefault("shield_bp", "buildings/defense/shield_generator_radio/shield_radio")
		else
			local lvl = BuildingService:GetBuildingLevel( self.entity )
			if ( lvl == 1 ) then
				self.shieldBp = "buildings/defense/shield_generator_radio/shield_radio"
			else
				self.shieldBp = "buildings/defense/shield_generator_radio/shield_radio" .. "_lvl_" .. tostring(lvl)
			end
		end
	end
end

return shield_generator_radio
