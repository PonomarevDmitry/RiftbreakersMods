local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")

class 'tower_antimatter' ( tower )

function tower_antimatter:__init()
	tower.__init(self,self)
end

function tower_antimatter:OnInit()
    tower.OnInit(self)
	
	self.antimatter_ball = self.data:GetStringOrDefault("antimatter_ball_mesh", "effects/weapons_energy/antimatter_ball_blue_base")

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnWorkingEnter", execute="OnWorkingExecute", exit="OnWorkingExit" } )
end

function tower_antimatter:OnActivate()
	tower:OnActivate()
	self.fsm:ChangeState( "working" )
	self.antimatter_ball_ready = true
end

function tower_antimatter:OnDeactivate()
	tower:OnDeactivate()
	self.fsm:Deactivate()
	self.antimatter_ball_ready = false
end

function tower_antimatter:OnWorkingEnter( state )
	self.antimatter_ball_generate = EntityService:SpawnAndAttachEntity( self.antimatter_ball, self.entity, "att_bomb", "" )
	EntityService:SetScale( self.antimatter_ball_generate, 0.4, 0.4, 0.4 )
	self.antimatter_ball_ready = true
end

function tower_antimatter:OnWorkingExecute( state )

	local progress = math.min(WeaponService:GetWeaponReloadProgress( self.entity ), 1.0)

    local ball_scale = math.max(0.01, math.sin( 1.57 * progress) / 2.5)
    if self.antimatter_ball_ready then
        EntityService:SetScale( self.antimatter_ball_generate, ball_scale, ball_scale, ball_scale )
    end
end

function tower_antimatter:OnWorkingExit( state )
	EntityService:RemoveEntity( self.antimatter_ball_generate )
	self.antimatter_ball_ready = false
end

return tower_antimatter
