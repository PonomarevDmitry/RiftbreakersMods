local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")

class 'tower_power_rod' ( tower )

function tower_power_rod:__init()
	tower.__init(self,self)
end

function tower_power_rod:OnInit()
    tower.OnInit(self)

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnWorkingEnter", execute="OnWorkingExecute" } )
	self.fsm:AddState( "cooldown", { enter="OnCooldownEnter", exit="OnCooldownExit" } )
	self.fsm:AddState( "disabled", { enter="OnDisabledEnter" } )

	self.crosshairBp = self.data:GetStringOrDefault( "crosshair_bp", "" )
	self.rocketBp = self.data:GetStringOrDefault( "rocket_bp", "" )
    self.areaRadius = self.data:GetFloatOrDefault( "rocket_radius", 10.0 )
    self.areaHeight = self.data:GetFloatOrDefault( "rocket_height", 100.0 )
    self.rocketInitialHeight = self.data:GetFloatOrDefault( "rocket_initial_height", 10.0 )
end

function tower_power_rod:OnActivate()
	tower.OnActivate(self)

	self.fsm:ChangeState( "working" )
end

function tower_power_rod:OnDeactivate()
	tower.OnDeactivate(self)

	self.fsm:ChangeState( "disabled" )
end

function tower_power_rod:OnWorkingEnter( state )
	self.pendingRocket = EntityService:SpawnAndAttachEntity( self.rocketBp, self.entity, "att_rocket", "" )
    self.readyRocker = nil
end

function tower_power_rod:OnWorkingExecute( state )
	local progress = WeaponService:GetWeaponReloadProgress( self.entity );
	local currentTime = state:GetDuration()
	
	if self.readyRocker ~= nil then 
		if progress < 1.0 then 
			self:DetachAndFireRocket( self.readyRocker )
			self.readyRocker = nil

			if self.crosshairBp ~= "" then
				local targetEnt = WeaponService:GetTurretTarget( self.entity )
				if targetEnt ~= INVALID_ID then 
					local targetPos = EntityService:GetPosition( targetEnt )
					WeaponService:SpawnDangerMarker( self.crosshairBp, targetPos, self.areaRadius, 4.0 )
				end
			end

			self.pendingRocket = EntityService:SpawnAndAttachEntity( self.rocketBp, self.entity, "att_rocket", "" )
			self.fsm:ChangeState( "cooldown" )
		end
	end

	if self.pendingRocket ~= nil then
		self.data:SetInt("is_ready", 1 )
		if progress > 0 and progress < 1.0 then
	    	EntityService:SetPosition( self.pendingRocket, self.rocketInitialHeight * progress, 0, 0 )
		elseif progress >= 1 then
	    	self.readyRocker = self.pendingRocket;
	    	self.pendingRocket = nil
		end
	end

	local targetEnt = WeaponService:GetTurretTarget( self.entity )
	if targetEnt ~= INVALID_ID then 
		local targetPos = EntityService:GetPosition( targetEnt )
		local muzzlePos = { x = targetPos.x, y = self.areaHeight - ( 0.1 * self.areaHeight ), z = targetPos.z }
		EntityService:SetBonePosition( self.entity, "att_muzzle_1", muzzlePos )
	end
end

function tower_power_rod:OnCooldownEnter( state )
	state:SetDurationLimit( 1.0 )
end

function tower_power_rod:OnCooldownExit( state )
	self.data:SetInt("is_ready", 0 )
	self.fsm:ChangeState( "working" )
end

function tower_power_rod:OnDisabledEnter( state )
	if self.readyRocker ~= nil then
		EntityService:DissolveEntity( self.readyRocker, 0.2 )
		self.readyRocker = nil 
	end

	if self.pendingRocket ~= nil then
		EntityService:DissolveEntity( self.pendingRocket, 0.2 )
		self.pendingRocket = nil 
	end

	self.data:SetInt("is_ready", 0 )
end

function tower_power_rod:DetachAndFireRocket( rocketEnt )
	MoveService:MoveInDirection( rocketEnt, 0, 30.0, 15.0, { x=1, y=0, z=0 } )
	QueueEvent( "DissolveEntityRequest", rocketEnt, 2.0, 3.0 )
	EffectService:AttachEffects( rocketEnt, "exhaust" )
end
return tower_power_rod
