require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'drexolian' ( base_unit )

function drexolian:__init()
	base_unit.__init(self, self)
end

function drexolian:OnInit()
	self:RegisterHandler( self.entity, "SleepEvent",  "OnSleepEvent" )
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )

	self.uniformFSM = self:CreateStateMachine()
	self.uniformFSM:AddState( "uniform", { execute="OnUniformExecute"} )
	self.uniformFSM:ChangeState( "uniform" )	

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )

	self.waller = self.data:GetStringOrDefault( "waller", "misc/waller" )

	self.currentUniformValue = 1.0
	self.newUniformValue = 1.0
	self.uniformScaleValue = 0.6
	
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
end

function drexolian:OnUniformExecute( state, dt )
	local value = self.currentUniformValue
    value = value + ( ( self.newUniformValue - value ) * dt * self.uniformScaleValue )
	self.currentUniformValue = value
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", self.currentUniformValue )
end

function drexolian:OnSleepEvent( evt )
	self.newUniformValue = evt:GetEmissiveValue()
end

function drexolian:OnShootArtilleryEvent( evt )
	if ( FindService:FindEntityByBlueprint( self.waller ) == INVALID_ID ) then
		local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )
		local targetEntity = UnitService:GetCurrentTarget( evt:GetEntity(), evt:GetTargetTag() )
		
		if  ( targetEntity ~= INVALID_ID ) then
			targetOrigin = VectorAdd( targetOrigin, PlayerService:GetVelocity( targetEntity ) )
		end

		local myOrigin = EntityService:GetPosition( self.entity )

		local entity = EntityService:SpawnEntity( self.waller, targetOrigin.x, targetOrigin.y, targetOrigin.z, "" )

		local forward = Normalize( VectorSub( myOrigin, targetOrigin ) )
		local right= EntityService:GetRightVector( VectorSub( targetOrigin, myOrigin ) )
		local db = EntityService:GetDatabase( entity )

		db:SetVector( "forward", forward )
		db:SetVector( "right", right )
	end
end

function drexolian:OnShootEvent( evt )

	local targetEntity = UnitService:GetCurrentTarget( evt:GetEntity(), "range" )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )

	local extraHeight = 0.5

	if ( targetEntity ~= INVALID_ID ) then
		local size = EntityService:GetBoundsSize( targetEntity )
		extraHeight = size.y / 2
	end

	WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + extraHeight, targetOrigin.z, "att_shoot" )
end

return drexolian
