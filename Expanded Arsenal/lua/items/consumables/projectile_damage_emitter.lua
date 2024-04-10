local item = require("lua/items/item.lua")

class 'projectile_damage_emitter' ( item )

function projectile_damage_emitter:__init()
	item.__init(self,self)
end

function projectile_damage_emitter:OnInit()
	self.active_time = self.data:GetFloatOrDefault("active_time", 3)
	self.arming_time = self.data:GetFloatOrDefault("arming_time", 1)
	local scale = self.data:GetFloatOrDefault("object_scale", 1)
	EntityService:SetScale( self.entity, scale, scale, scale )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "Activated", { enter="OnActivatedStart", exit="OnActivatedExit"} )
	self.fsm:ChangeState("Activated")
	
	self.lifeTimeFSM = self:CreateStateMachine()
	self.lifeTimeFSM:AddState( "Timer", { execute="OnTimerExecute" } )
end


function projectile_damage_emitter:OnActivatedStart( state )
	EntityService:CreateLifeTime( self.entity, self.active_time, "" )
	self.lifeTimeFSM:ChangeState( "Timer" )
	EntityService:SetTeam( self.entity, "player")
	state:SetDurationLimit( self.arming_time )
end

function projectile_damage_emitter:OnActivatedExit( state )
	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
	WeaponService:StartShoot( self.entity )
end

function projectile_damage_emitter:OnTimerExecute( state )
    local lifetime = EntityService:GetLifeTime( self.entity )
	
    if (lifetime <= 0.1) then
		WeaponService:StopShoot( self.entity );
        EntityService:RequestDestroyPattern( self.entity, "default", true );
    end
end

return projectile_damage_emitter
	