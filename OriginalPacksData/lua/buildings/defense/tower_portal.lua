local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")

class 'tower_portal' ( tower )

function tower_portal:__init()
	tower.__init(self,self)
end

function tower_portal:OnInit()
    tower.OnInit(self)

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnWorkingEnter", execute="OnWorkingExecute", exit="OnWorkingExit" } )

	self.sfsm = self:CreateStateMachine()
	self.sfsm:AddState( "shooting", { enter="OnShootingEnter", execute="OnShootingExecute" } )
	self.sfsm:AddState( "shooting_start", { enter="OnShootingStartEnter", execute="OnShootingStartExecute", exit="OnShootingStartExit" } )
	self.sfsm:AddState( "shooting_delay", { enter="OnShootingDelayEnter", exit="OnShootingDelayExit"} )
	self.sfsm:AddState( "shooting_end", { enter="OnShootingEndEnter", execute="OnShootingEndExecute", exit="OnShootingEndExit" } )
	self.sfsm:AddState( "shooting_disabled", { enter="OnShootingDisabledEnter" } )
end

function tower_portal:OnActivate()
	tower:OnActivate()

	self.fsm:ChangeState( "working" )
	self.sfsm:ChangeState( "shooting" )
end

function tower_portal:OnDeactivate()
	tower:OnDeactivate()

	self.fsm:Deactivate()
	self.sfsm:ChangeState( "shooting_disabled" )
end

function tower_portal:OnWorkingEnter( state )
	self.pendingBomb = EntityService:SpawnAndAttachEntity( "buildings/defense/tower_portal_bomb", self.entity, "att_bomb", "" )
    EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 )
    self.readyBomb = nil
end

function tower_portal:OnWorkingExecute( state )
	local progress = WeaponService:GetWeaponReloadProgress( self.entity );
	local currentTime = state:GetDuration()
	
	if self.readyBomb ~= nil then 
		if progress < 1.0 then 
			local downDir = { x=0, y=-1, z=0 }
			AnimationService:StartAnim( self.readyBomb, "hide_bomb", false, 1.5 )
			EntityService:SetGraphicsUniform( self.readyBomb, "cDissolveAmount", 0 )
			MoveService:MoveInDirection( self.readyBomb, 0, 2, 2, downDir )
			EntityService:DissolveEntity( self.readyBomb, 0.5 )
			self.readyBomb = nil

			self.pendingBomb = EntityService:SpawnAndAttachEntity( "buildings/defense/tower_portal_bomb", self.entity, "att_bomb", "" )
		 	EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 )
		else
			EntityService:SetPosition( self.readyBomb, 0, 0.25 * math.cos( 3.14 * currentTime ), 0 )
			EntityService:Rotate( self.readyBomb, 0.0, 1.0, 0.0, 7 )
		end
	end

	if self.pendingBomb ~= nil then
		if progress > 0 and progress < 1.0 then 
    		EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 - progress )
			EntityService:Rotate( self.pendingBomb, 0.0, 1.0, 0.0, 2 )
			EntityService:SetPosition( self.pendingBomb, 0, 0.25 * math.cos( 3.14 * currentTime ), 0 )
		elseif progress >= 1 then
	    	EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 0 )
	    	self.readyBomb = self.pendingBomb;
	    	self.pendingBomb = nil
		end
	end
end

function tower_portal:OnWorkingExit( state )
	if self.readyBomb ~= nil then
		EntityService:DissolveEntity( self.readyBomb, 0.2 )
		self.readyBomb = nil 
	end

	if self.pendingBomb ~= nil then
		EntityService:DissolveEntity( self.pendingBomb, 0.2 )
		self.pendingBomb = nil 
	end
end

function tower_portal:OnShootingEnter( state )
	EffectService:DestroyEffectsByGroup( self.entity, "portal_pending" )
  	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 2 )
end

function tower_portal:OnShootingExecute( state )
	local progress = WeaponService:GetWeaponReloadProgress( self.entity )
	if progress > 0.9 then
		if self.portalTriangle == nil then 
			self.portalTriangle = EntityService:SpawnAndAttachEntity( "buildings/defense/tower_portal_triangle", self.entity, "att_triangle", "" )
	    	EntityService:SetScale( self.portalTriangle, 0.6, 0.6, 0.6 )
		end
    	self.sfsm:ChangeState("shooting_start")
    end
end

function tower_portal:OnShootingStartEnter( state )
	AnimationService:StartAnim( self.portalTriangle, "show_portal", false, 1 )
	EffectService:AttachEffects( self.entity, "portal_ready" )
  	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 1 )
end

function tower_portal:OnShootingStartExecute( state )
    if not AnimationService:IsAnimActive( self.portalTriangle, "show_portal" ) then
    	local progress = WeaponService:GetWeaponReloadProgress( self.entity )
    	if progress ~= 1.0 then
        	self.sfsm:ChangeState("shooting_delay")
        end
    end
end

function tower_portal:OnShootingStartExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "portal_ready" )
end

function tower_portal:OnShootingDelayEnter( state )
	state:SetDurationLimit( 0.16 )
end

function tower_portal:OnShootingDelayExit( state )
   self.sfsm:ChangeState("shooting_end")
end

function tower_portal:OnShootingEndEnter( state )
	AnimationService:StartAnim( self.portalTriangle, "hide_portal", false, 3 )
	EffectService:AttachEffects( self.entity, "portal_pending" )
end

function tower_portal:OnShootingEndExecute( state )
    if not AnimationService:IsAnimActive( self.portalTriangle, "hide_portal" ) then
    	local progress = WeaponService:GetWeaponReloadProgress( self.entity )
    	if progress > 0.9 then
        	self.sfsm:ChangeState("shooting_start")
        end
    end
end

function tower_portal:OnShootingEndExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "portal_pending" )
  	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 2 )
end

function tower_portal:OnShootingDisabledEnter( state )
	if self.portalTriangle ~= nil then
		EntityService:DissolveEntity( self.portalTriangle, 0.2 )	
		AnimationService:StartAnim( self.portalTriangle, "hide_portal", false, 5.0 )
		self.portalTriangle = nil 
	end
end

return tower_portal
