require("lua/units/units_utils.lua")

class 'orb_fly' ( LuaEntityObject )

function orb_fly:__init()
	LuaEntityObject.__init(self, self)
end

function orb_fly:init()
	self.rotateSpeed = self.data:GetFloat( "rotate_speed" )
	self.lifeTime = self.data:GetFloat( "life_time" )

	self.attack = self:CreateStateMachine()
	self.attack:AddState( "attack", { enter="OnEnterAttack",execute="OnExecuteAttack" } )

    self.scale = self:CreateStateMachine()
    self.scale:AddState( "scale", { enter="OnEnterScale", execute="OnExecuteScale" } )
    self.scale:ChangeState( "scale" )

    self.maxScale = 1
    self.currentScale = 0.0
	self.growSpeed = 0.25
	self.randomSign = ( math.random ( 0, 1 ) * 2 ) - 1

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )

	EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, RandFloat( 0.0, 360.0 ) )

	EntityService:SetScale( self.entity, self.currentScale, self.currentScale, self.currentScale )
	
	local pos = EntityService:GetPosition( self.entity ) 
	EntityService:SetPosition( self.entity, pos.x, pos.y + 2, pos.z )
end

function orb_fly:OnEnterScale( state )
    EntityService:SetVisible( self.entity, true )
end

function orb_fly:OnExecuteScale( state, dt )	
	if ( self.currentScale >= self.maxScale ) then
        self.attack:ChangeState( "attack" )
		state:Exit()
	else
		self.currentScale = self.currentScale + ( ( 1.0 / self.growSpeed ) * dt )
		EntityService:SetScale( self.entity, self.currentScale, self.currentScale, self.currentScale )
	end
end

function orb_fly:OnEnterAttack( state )
    WeaponService:StartShoot( self.entity )
end

function orb_fly:OnExecuteAttack( state, dt )
	EntityService:Rotate( self.entity, 0.0, self.randomSign, 0.0, self.rotateSpeed )

	self.lifeTime = self.lifeTime - dt

	if ( self.lifeTime < 0.0 ) then
		WeaponService:StopShoot( self.entity )
		EntityService:DissolveEntity( self.entity, 1.5 )
		state:Exit()
	end
end


return orb_fly
