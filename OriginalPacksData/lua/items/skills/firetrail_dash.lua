local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")

class 'firetrail_dash' ( item )

function firetrail_dash:__init()
	item.__init(self,self)
end

function firetrail_dash:OnInit()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "dash", { execute="OnDashExecute" } )
	self.trailTime = self.data:GetFloatOrDefault( "trail_time", 1 )
	self.trailSpacing = self.data:GetFloatOrDefault( "trail_spacing", 1 )
	self.trailExtend = self.data:GetFloatOrDefault( "trail_extend_time", 0.5 )
	self.trailEffect = self.data:GetString( "trail_effect" )
end

function firetrail_dash:OnEquipped()
	self.lastPosition = nil
end

function firetrail_dash:OnActivate()
	EntityService:Dash( self.owner, self.item);
	self.set = false
	self.lastPosition = nil
	self.machine:ChangeState("dash")
end

function firetrail_dash:OnDashExecute( state )
	if ( self.lastPosition == nil ) then
		if ( EntityService:IsAlive( self.owner) == false ) then
			state:Exit()
			return
		end
		self.lastPosition = EntityService:GetPosition( self.owner )

		local trail =	EntityService:SpawnEntity( self.trailEffect, self.owner, "" )
		ItemService:SetItemCreator( trail, self.entity_blueprint );
		EntityService:DissolveEntity( trail, self.trailTime, 1.0 )
	else
		local currentPosition = EntityService:GetPosition( self.owner )
		local distance =  Distance( currentPosition , self.lastPosition )

		if ( distance >= self.trailSpacing  ) then
			self.lastPosition = currentPosition
			self.lastPosition.x = self.lastPosition.x + RandFloat( -0.5, 0.5 )

			local trail = EntityService:SpawnEntity(self.trailEffect, self.owner, "" )
			ItemService:SetItemCreator( trail, self.entity_blueprint );
			EntityService:DissolveEntity( trail, self.trailTime, 1.0 )
		end
	end

	if (self.set == false and EntityService:IsDashing( self.owner ) == false   ) then
		state:SetDurationLimit(self.trailExtend )
		self.set = true
	end 
end

function firetrail_dash:OnUnequipped()
	self.lastPosition = nil
end


return firetrail_dash
