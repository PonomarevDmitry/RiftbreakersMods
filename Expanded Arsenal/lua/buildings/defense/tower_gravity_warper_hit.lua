local item = require("lua/items/item.lua")

class 'tower_gravity_warper_hit' ( item )

function tower_gravity_warper_hit:__init()
	item.__init(self,self)
end

function tower_gravity_warper_hit:OnInit()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "closed", { enter="OnClosedEnter", execute="OnClosedExecute", exit="OnClosedExit" } )
	self.fsm:AddState( "opening", { enter="OnOpeningEnter", execute="OnOpeningExecute", exit="OnOpeningExit" } )
	self.fsm:AddState( "opened", { enter="OnOpenedEnter", execute="OnOpenedExecute", exit="OnOpenedExit" } )
	self.fsm:AddState( "closing", { enter="OnClosingEnter", execute="OnClosingExecute", exit="OnClosingExit" } )
	self.fsm:ChangeState( "closed" )
	
	-- Animation time parameters
	self.closedTime = 0.25
	self.openingTime = 0.4
	self.openedTime = 3.0
	self.closingTime = 0.2
	
	-- Damage parameters
	self.idleSlowDown = self.data:GetStringOrDefault("slowdown","")
	
	-- Graphics parameters
	self.idleRadius = self.data:GetStringOrDefault("radius","items/warheads/singularity_warhead_radius")
	self.closedEffect = self.data:GetStringOrDefault("closed_effect","items/warheads/singularity_warhead_closed")
	self.refract = self.data:GetStringOrDefault("refract_effect","items/warheads/singularity_warhead_refract")
	
	-- Sound parameters
	self.initSound = self.data:GetStringOrDefault("init_sound","items/warheads/singularity_warhead_init_sound")
	self.openSound = self.data:GetStringOrDefault("open_sound","items/warheads/singularity_warhead_open_sound")
	self.idleSound = self.data:GetStringOrDefault("idle_sound","items/warheads/singularity_warhead_idle_sound")
	self.closeSound = self.data:GetStringOrDefault("close_sound","items/warheads/singularity_warhead_close_sound")
end

function tower_gravity_warper_hit:OnClosedEnter( state )
	state:SetDurationLimit( self.closedTime )
	EntityService:SpawnAndAttachEntity( self.initSound, self.entity )

	self.closedEnt = EntityService:SpawnAndAttachEntity( self.closedEffect, self.entity )
	self.initialPos = EntityService:GetPosition( self.entity )
	EntityService:SetScale( self.entity, 0.01, 0.01, 0.01 )
end

function tower_gravity_warper_hit:OnClosedExecute( state )
	local currentProgress = ( state:GetDuration() / self.closedTime )
	local scale = 0.5 * currentProgress * currentProgress
	EntityService:SetScale( self.entity, scale, scale, scale )
	EntityService:SetPosition( self.entity, self.initialPos.x, self.initialPos.y + 5 * currentProgress, self.initialPos.z )
end

function tower_gravity_warper_hit:OnClosedExit( state )
	self.fsm:ChangeState( "opening" )
	EntityService:RemoveEntity( self.closedEnt )
end

function tower_gravity_warper_hit:SetItemCreator(entity)
	local item_creator = ItemService:GetItemCreator(self.entity )
	if item_creator ~= "" then
		ItemService:SetItemCreator( entity, item_creator );
	else
		ItemService:SetItemCreator( entity, self.entity_blueprint );
	end
end

function tower_gravity_warper_hit:OnOpeningEnter( state )
	state:SetDurationLimit( self.openingTime )
	self.idleSlowDownEnt = EntityService:SpawnAndAttachEntity( self.idleSlowDown, self.entity )
	self:SetItemCreator(self.idleSlowDownEnt)
	EntityService:SetTeam( self.idleSlowDownEnt, "player" )
end

function tower_gravity_warper_hit:OnOpeningExecute( state )
	local currentProgress = ( state:GetDuration() / self.openingTime )
	if ( currentProgress > 0.5 ) then
		local scale = 0.5 + ( 0.7 * ( currentProgress - 0.5 ) * 2 ) + 1.0 * math.sin( 3.14 * ( currentProgress - 0.5 ) * 2 )
		EntityService:SetScale( self.entity, scale, scale, scale )
		if self.refractEnt == nil then
			EntityService:SpawnAndAttachEntity( self.openSound, self.entity )
			self.refractEnt = EntityService:SpawnAndAttachEntity( self.refract, self.entity )
			self.vortexEnt = EntityService:SpawnAndAttachEntity( "items/consumables/gravity_hole_vortex", self.entity )
		end
	end
end

function tower_gravity_warper_hit:OnOpeningExit( state )
	self.fsm:ChangeState( "opened" )
end

function tower_gravity_warper_hit:OnOpenedEnter( state )
	state:SetDurationLimit( self.openedTime )
	self.idleSoundEnt = EntityService:SpawnAndAttachEntity( self.idleSound, self.entity )
	self.idleRadiusEnt = EntityService:SpawnAndAttachEntity( self.idleRadius, self.entity )
end

function tower_gravity_warper_hit:OnOpenedExecute( state )
	local currentProgress = ( state:GetDuration() / self.openedTime )
	TornadoService:UpdateGravityHole( self.entity, 3.0, 0.5, 650 )
	if currentProgress > 0.95 and self.refractEnt ~= nil then 
		EntityService:RemoveEntity( self.refractEnt )
		EntityService:RemoveEntity( self.vortexEnt )
		self.refractEnt = nil;
	end
end

function tower_gravity_warper_hit:OnOpenedExit( state )
	self.fsm:ChangeState( "closing" )
	EntityService:RemoveEntity( self.idleSoundEnt )
	EntityService:RemoveEntity( self.idleRadiusEnt )
	EntityService:RemoveEntity( self.idleSlowDownEnt )
	EntityService:SpawnAndAttachEntity( self.closeSound, self.entity )
end

function tower_gravity_warper_hit:OnClosingEnter( state )
	state:SetDurationLimit( self.closingTime )
end

function tower_gravity_warper_hit:OnClosingExecute( state )
	local currentProgress = ( state:GetDuration() / self.closingTime )
	local scale = 1.30 - ( 1.3 * ( 1 - ( ( math.cos( 3.14 * currentProgress ) + 1 ) / 2 ) ) )
	EntityService:SetScale( self.entity, scale, scale, scale )
end

function tower_gravity_warper_hit:OnClosingExit( state )
	EntityService:RemoveEntity( self.entity )
end

return tower_gravity_warper_hit

