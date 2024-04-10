local tower = require("lua/buildings/defense/tower.lua")

class 'tower_orbital_laser' ( tower )

function tower_orbital_laser:__init()
	tower.__init(self,self)
end

function tower_orbital_laser:OnInit()

	self.range = self.data:GetFloatOrDefault("range", 35 )
	self.start_distance = self.data:GetFloatOrDefault("laser_start_multiplier", 0.2)
	self.reload = self.data:GetIntOrDefault("reload", 10 )
	self.laser_speed = self.data:GetFloatOrDefault("laser_move_speed", 15 )
	self.weapon = self.data:GetStringOrDefault("laser_weapon", "items/skills/orbital_laser_advanced")
	self.marker = self.data:GetStringOrDefault("marker_effect", "effects/enemies_gnerot/spike_warning")

	self.fsm = self:CreateStateMachine();
	self.fsm:AddState("TowerShoot", {execute = "OnTowerShootLoop", exit = "OnTowerShootStart", interval = 0.1});
	self.fsm:AddState("TowerReload", {enter = "OnTowerReloadStart", exit = "OnTowerReloadEnd"});
end

function tower_orbital_laser:OnBuildingStart()
	self.laser = nil
	self.CurrentTarget = nil
	self.target_position = nil
	self.laser_origin = nil
end


function tower_orbital_laser:OnActivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.powered = true
	
	if not self.reloading then
		self.fsm:ChangeState("TowerShoot")
	end
end

function tower_orbital_laser:OnDeactivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.powered = false
	
	local state = self.fsm:GetState("TowerShoot") 
	if state ~= nil then 
		state:Exit()
	end

end


function tower_orbital_laser:OnTowerShootLoop( state )
	
	self.predicate = {
		signature = "TeamComponent",
		type="ground_unit",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt( 0 ), entity, "hostility")
		end
	};
	
	local target = FindClosestEntity( self.entity, FindService:FindEntitiesByPredicateInRadius( self.entity, self.range, self.predicate ) )
	if target == INVALID_ID then return end
	
	self.TowerOrigin = EntityService:GetPosition(self.entity)
	
	self.target_position = EntityService:GetPosition(target)
    
    local RangeDifference = EntityService:GetDistance2DBetween(self.entity, target)
    
    self.laser_origin = {x = ((self.target_position.x - self.TowerOrigin.x) / (RangeDifference * self.start_distance)) + self.TowerOrigin.x, y = 30, z = ((self.target_position.z - self.TowerOrigin.z) / (RangeDifference * self.start_distance)) + self.TowerOrigin.z}
	
	self.fsm:ChangeState("TowerReload")
end

function tower_orbital_laser:OnTowerShootStart( state )

	if not self.powered then return end
	
	self.CurrentTarget = EntityService:SpawnEntity( self.marker, self.target_position, EntityService:GetTeam( self.entity ) )
	self.laser = EntityService:SpawnEntity( self.weapon, self.laser_origin, EntityService:GetTeam( self.entity ) )
	EntityService:SetForward(self.laser, 0, -1, 0)
	
	WeaponService:UpdateWeaponStatComponent( self.laser, self.laser );
	WeaponService:StartShoot( self.laser );
	MoveService:MoveToTarget(self.laser, self.CurrentTarget, self.laser_speed * 2);
	
	self:RegisterHandler( self.laser , "MoveEndEvent", "OnMoveEnd")
end

function tower_orbital_laser:OnMoveEnd( event )

	EntityService:RemoveEntity(self.CurrentTarget)
	EntityService:RemoveEntity(self.laser)
	self:UnregisterHandler(self.laser, "MoveEndEvent", "OnMoveEnd")
	
	self.laser = nil
	self.CurrentTarget = nil
	self.target_position = nil
	self.laser_origin = nil
end


function tower_orbital_laser:OnTowerReloadStart(state)
	BuildingService:AttachGuiTimer(self.entity, self.reload, true)
	state:SetDurationLimit(self.reload)

	self.reloading = true
end

function tower_orbital_laser:OnTowerReloadEnd(state)
	
	if self.powered then
		self.fsm:ChangeState("TowerShoot")
	end
	
	self.reloading = false
end

return tower_orbital_laser