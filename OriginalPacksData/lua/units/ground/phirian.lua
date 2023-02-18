require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'phirian' ( base_unit )

function phirian:__init()
	base_unit.__init(self, self)
end

function phirian:OnInit()
	self:RegisterHandler( self.entity, "EnterDashEvent",  "OnEnterDashEvent" )
	self:RegisterHandler( self.entity, "MiddleDashEvent",  "OnMiddleDashEvent" )
	self:RegisterHandler( self.entity, "ExitDashEvent",  "OnExitDashEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	self.dashTargets = {}
end

function phirian:OnEnterDashEvent( evt )
	LogService:Log( "phirian:OnEnterDashEvent" )
	self.dashTargets = {}
end

function phirian:OnMiddleDashEvent( evt )
	
	local target = evt:GetTarget()
	local dmg = evt:GetDamage()

	for entity in Iter( self.dashTargets ) do 		
		if ( entity == target ) then
			return
		end
	end

	Insert( self.dashTargets, target )
	QueueEvent( "DamageRequest", target, dmg, "physical", 1, 0 )

end

function phirian:OnExitDashEvent( evt )
	LogService:Log( "phirian:OnExitDashEvent" )
	self.dashTargets = {}
end

return phirian
