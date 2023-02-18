require("lua/utils/table_utils.lua")
local building = require("lua/buildings/building.lua")

class 'repair_facility' ( building )

function repair_facility:__init()
	building.__init(self,self)
end

function repair_facility:OnInit()
	self.active = true
	self.selected = {}
	-- Defaults:
	self.interval = 1
	self.radius = 6
	self.healthAmount = 10
	self.healCount = 2
	self.energyCost = 200
	
	if ( self.data:HasFloat("heal_radius") ) then
		self.radius = self.data:GetFloat("heal_radius")
	end
	
	if ( self.data:HasInt("heal_count") ) then
		self.healCount = self.data:GetInt("heal_count")
	end
	
	if ( self.data:HasFloat("interval") ) then
		self.interval = self.data:GetFloat("interval")
	end	
	
	if ( self.data:HasFloat("energy_cost") ) then
		self.energyCost = self.data:GetFloat("energy_cost")
	end
	
	if ( self.data:HasFloat("heal_amount") ) then
		self.healthAmount = self.data:GetFloat("heal_amount")
	end
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "idle", {} )
	self.fsm:AddState( "working", {execute="OnWorkInProgress", interval=self.interval} )
	--self.fsm:ChangeState("idle")
end

function repair_facility:OnWorkInProgress( state )
	if ( Size(self.selected) < self.healCount ) then
		local objects = EntityService:FindEntityWithLowestHealthInRadius( self.entity, self.radius, self.healCount )
		
		if #objects > 0 then								
			for i = 1, #objects do			
				if( IndexOf( self.selected, objects[i] ) == nil ) then
					table.insert( self.selected, objects[i] )	
					if ( #self.selected == self.healCount ) then
						break
					end						
				end
			end
		end				

		
	end

	local worked = false
	for i = #self.selected, 1, -1  do
		local ent = self.selected[i]
		if ( EntityService:IsAlive( ent) ) then
			
			local health = HealthService:GetHealthInPercentage( ent)
	
			if ( health < 1 ) then
				local canAffordRepair = BuildingService:CanAffordRepair( ent, self.healthAmount )
				local decrease = BuildingService:TryDecreaseResourceByEntity( self.entity, "energy", self.energyCost )

				if decrease == false or canAffordRepair == false  then
					table.remove( self.selected, i )
					break
				end
				worked = true
				BuildingService:RepairBuilding ( ent, self.healthAmount )
				--EffectService:AttachEffect( ent, "effects/buildings_generic/building_repair_medium" )
			else
				table.remove( self.selected, i )
			end
	
		else
			table.remove( self.selected, i )
		end
	
	end
	if worked == true then 
		EffectService:AttachEffect( self.entity, "effects/buildings_and_machines/repair_facility_healing_radius", "att_healing_energy" )
	end
end

function repair_facility:OnBuildingEnd()
	EntityService:SetSubMeshMaterial( self.entity, "buildings/defense/repair_facility_energy", 1, "" )
end

function repair_facility:OnActivate()
	self.fsm:ChangeState("working")
end

function repair_facility:OnDeactivate()
	self.selected = {}
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end	 
end

return repair_facility
