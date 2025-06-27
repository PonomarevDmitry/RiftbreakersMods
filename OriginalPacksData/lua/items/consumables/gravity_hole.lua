local item = require("lua/items/item.lua")

class 'gravity_hole' ( item )

function gravity_hole:__init()
	item.__init(self,self)
end

function gravity_hole:OnInit()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "closed", { enter="OnClosedEnter", execute="OnClosedExecute", exit="OnClosedExit" } )
	self.fsm:AddState( "opening", { enter="OnOpeningEnter", execute="OnOpeningExecute", exit="OnOpeningExit" } )
	self.fsm:AddState( "opened", { enter="OnOpenedEnter", execute="OnOpenedExecute", exit="OnOpenedExit" } )
	self.fsm:AddState( "closing", { enter="OnClosingEnter", execute="OnClosingExecute", exit="OnClosingExit" } )
	self.fsm:ChangeState( "closed" )
	self.closedTime = 0.25
	self.openingTime = 0.75
	self.openedTime = 10.0
	self.closingTime = 0.5
	
	self.initialBlast =  self.data:GetStringOrDefault("initial_blast","items/consumables/gravity_hole_initial_blast")
	self.damage =  self.data:GetStringOrDefault("damage","items/consumables/gravity_hole_damage")
	
	EntityService:SetTeam( self.entity, "player" )
end

function gravity_hole:OnClosedEnter( state )
	state:SetDurationLimit( self.closedTime )
	EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_init_sound", self.entity )

	local entity = EntityService:SpawnAndAttachEntity( self.initialBlast, self.entity )
	self:SetItemCreator(entity)

	self.closedEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_closed", self.entity )
	self.initialPos = EntityService:GetPosition( self.entity )
	EntityService:SetScale( self.entity, 0.01, 0.01, 0.01 )
end

function gravity_hole:OnClosedExecute( state )
	local currentProgress = ( state:GetDuration() / self.closedTime )
	local scale = 0.5 * currentProgress * currentProgress
	EntityService:SetScale( self.entity, scale, scale, scale )
	EntityService:SetPosition( self.entity, self.initialPos.x, self.initialPos.y + 5 * currentProgress, self.initialPos.z )
end

function gravity_hole:OnClosedExit( state )
	self.fsm:ChangeState( "opening" )
	EntityService:RemoveEntity( self.closedEnt )
end

function gravity_hole:SetItemCreator(entity)
	local item_creator = ItemService:GetItemCreator(self.entity )
	if item_creator ~= "" then
		ItemService:SetItemCreator( entity, item_creator );
	else
		ItemService:SetItemCreator( entity, self.entity_blueprint );
	end
	EntityService:PropagateEntityOwner( entity, self.entity )
end

function gravity_hole:OnOpeningEnter( state )
	state:SetDurationLimit( self.openingTime )
	
	self.idleDamageEnt = EntityService:SpawnAndAttachEntity( self.damage, self.entity )
	self:SetItemCreator(self.idleDamageEnt)
end

function gravity_hole:OnOpeningExecute( state )
	local currentProgress = ( state:GetDuration() / self.openingTime )
	if ( currentProgress > 0.5 ) then
		local scale = 0.5 + ( 0.7 * ( currentProgress - 0.5 ) * 2 ) + 1.0 * math.sin( 3.14 * ( currentProgress - 0.5 ) * 2 )
		EntityService:SetScale( self.entity, scale, scale, scale )
		if self.refractEnt == nil then
			EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_open_sound", self.entity )
			self.refractEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_refract", self.entity )
			self.vortexEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_vortex", self.entity )
		end
	end
end

function gravity_hole:OnOpeningExit( state )
	self.fsm:ChangeState( "opened" )
end

function gravity_hole:OnOpenedEnter( state )
	state:SetDurationLimit( self.openedTime )
	self.idleSoundEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_idle_sound", self.entity )
	self.idleRadiusEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_radius", self.entity )
end

function gravity_hole:OnOpenedExecute( state )
	local currentProgress = ( state:GetDuration() / self.openedTime )
	if TornadoService then
		TornadoService:UpdateGravityHole( self.entity, 10.0, 0.5, 650 )
	end
	if currentProgress > 0.95 and self.refractEnt ~= nil then 
		EntityService:RemoveEntity( self.refractEnt )
		EntityService:RemoveEntity( self.vortexEnt )
		self.refractEnt = nil;
	end
end

function gravity_hole:OnOpenedExit( state )
	self.fsm:ChangeState( "closing" )
	EntityService:RemoveEntity( self.idleSoundEnt )
	EntityService:RemoveEntity( self.idleRadiusEnt )
	EntityService:RemoveEntity( self.idleDamageEnt )
	EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_close_sound", self.entity )
end

function gravity_hole:OnClosingEnter( state )
	state:SetDurationLimit( self.closingTime )
end

function gravity_hole:OnClosingExecute( state )
	local currentProgress = ( state:GetDuration() / self.closingTime )
	local scale = 1.30 - ( 1.3 * ( 1 - ( ( math.cos( 3.14 * currentProgress ) + 1 ) / 2 ) ) )
	EntityService:SetScale( self.entity, scale, scale, scale )
end

function gravity_hole:OnClosingExit( state )
	EntityService:RemoveEntity( self.entity )
end

return gravity_hole
