local tower_charge = require("lua/buildings/defense/tower_charge.lua")
require("lua/utils/table_utils.lua")

class 'tower_gravity_warper' ( tower_charge )

function tower_gravity_warper:__init()
	tower_charge.__init(self,self)
end

function tower_gravity_warper:OnInit()
    tower_charge.OnInit(self)
	
	self.projectile = self.data:GetStringOrDefault("projectile_effect", "")

    self.EffectFSM = self:CreateStateMachine()
	self.EffectFSM:AddState( "working", { enter="OnWorkingEnter", execute="OnWorkingExecute", exit="OnWorkingExit" } )
end

function tower_gravity_warper:OnActivate()
	tower_charge.OnActivate(self)
	self.EffectFSM:ChangeState( "working" )
	self.projectile_ready = true
end

function tower_gravity_warper:OnDeactivate()
	tower_charge.OnDeactivate(self)
	
	local state = self.EffectFSM:GetState("working")
	if state ~= nil then
		state:Exit()
	end
	
	self.projectile_ready = false
end

function tower_gravity_warper:OnWorkingEnter( state )
	self.projectile_generate = EntityService:SpawnAndAttachEntity( self.projectile, self.entity, "att_bomb", "" )
	EntityService:SetScale( self.projectile_generate, 0.4, 0.4, 0.4 )
	self.projectile_ready = true
end

function tower_gravity_warper:OnWorkingExecute( state )

	local progress = math.min(WeaponService:GetWeaponReloadProgress( self.entity ), 1.0)

    local projectile_scale = math.max(0.01, math.sin( 1.57 * progress) / 1.1)
    if self.projectile_ready then
        EntityService:SetScale( self.projectile_generate, projectile_scale, projectile_scale, projectile_scale );
		EntityService:Rotate( self.projectile_generate, 0.0, 1.0, 0.0, 7 );
    end
end

function tower_gravity_warper:OnWorkingExit( state )
	EntityService:RemoveEntity( self.projectile_generate )
	self.projectile_ready = false
end

return tower_gravity_warper
