local item = require("lua/items/item.lua")

class 'invisible' ( item )

function invisible:__init()
	item.__init(self,self)
end

function invisible:OnInit()
	self.mode = false

	self.invisibleVersion = 1
	self.invisibilityFsm = self:CreateStateMachine()
	self.invisibilityFsm:AddState( "invisibility_enter", {enter="OnInvisibilityEnterEnter", execute="OnInvisibilityEnterExecute"} )
	self.invisibilityFsm:AddState( "invisibility_exit", {enter="OnInvisibilityExitEnter", execute="OnInvisibilityExitExecute", exit="OnInvisibilityExitExit" } )
end

function invisible:OnEquipped()
	self:RegisterHandler( self.owner, "ItemEquippedEvent",  "OnItemEquippedEvent" )
	self:RegisterHandler( self.owner, "RiftTeleportStartEvent",  "OnRiftTeleportStartEvent" )

end

function invisible:OperateInvisibile()
	--LogService:Log( tostring( self.mode ) .. " operating invisibility" )
	ItemService:ActivateCooldown(self.entity )
	ItemService:SetInvisible( self.owner, self.mode )
	
	if ( self.mode == true ) then
		self:RegisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
	else
		self:UnregisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
	end

	if ( self.mode == true ) then
		self.invisibilityFsm:ChangeState( "invisibility_enter" )
	else
		self.lastOwner = self.owner
		self.invisibilityFsm:ChangeState( "invisibility_exit" )
	end
end

function invisible:OnActivate()
	self.mode = true
	self:OperateInvisibile()
end

function invisible:OnDeactivate()
	if ( self.mode == false ) then
		return
	end
	self.mode = false
	self:OperateInvisibile()
	return true
end

function invisible:OnDamageEvent( evt )
	local damageValue = evt:GetDamageValue()
	if ( damageValue > 0 ) then
		self:_Deactivate( false )
	end
end

function invisible:OnUnequipped()
	if ( self.mode == true ) then
		self:_Deactivate( false )
		self:UnregisterHandler( self.owner, "ItemEquippedEvent",  "OnItemEquippedEvent" )
		self:UnregisterHandler( self.owner, "RiftTeleportStartEvent",  "OnRiftTeleportStartEvent" )
	end
end

function invisible:OnLoad()
    item.OnLoad(self)
	
	if ( self.invisibleVersion == nil or self.invisibleVersion < 1 ) then
		self.invisibleVersion = 1
		
		self.invisibilityFsm = self:CreateStateMachine()
		self.invisibilityFsm:AddState( "invisibility_enter", {enter="OnInvisibilityEnterEnter", execute="OnInvisibilityEnterExecute"} )
		self.invisibilityFsm:AddState( "invisibility_exit", {enter="OnInvisibilityExitEnter", execute="OnInvisibilityExitExecute", exit="OnInvisibilityExitExit" } )

		if ( self:IsEquipped() ) then
			self:RegisterHandler( self.owner, "ItemEquippedEvent",  "OnItemEquippedEvent" )
			self:RegisterHandler( self.owner, "RiftTeleportStartEvent",  "OnRiftTeleportStartEvent" )
		end
	end
end


function invisible:OnInvisibilityEnterEnter( state )
	state:SetDurationLimit( 0.5 )
	EntityService:SetMaterial( self.owner, "player/mech_distortion", "1_invisiblity" )
	EffectService:AttachEffects( self.owner, "invisiblity" )
	local children = EntityService:GetChildren( self.owner, false )
	for child in Iter(children) do
		local itemType =ItemService:GetItemType(child);
		if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "") then
			local meshChildren =  EntityService:GetChildren( child, true )
			for meshChild in Iter(meshChildren) do
				if ( EntityService:IsSkinned( meshChild )) then
					EntityService:SetMaterial( meshChild, "player/item_distortion_skinned", "1_invisiblity" )
				else
					EntityService:SetMaterial( meshChild, "player/item_distortion", "1_invisiblity" )
				end
			end
		end
	end
end

function invisible:OnInvisibilityEnterExecute( state )
	local duration = state:GetDuration()
	local durationLimit = state:GetDurationLimit()

	local factor = duration / durationLimit
	EntityService:SetGraphicsUniform( self.owner, "cDistortionFactor", factor )
	EntityService:SetGraphicsUniform( self.owner, "cDissolveAmount", factor )

	local children = EntityService:GetChildren( self.owner, false )
	for child in Iter(children) do
		local itemType =ItemService:GetItemType(child);
		if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "") then
			local meshChildren =  EntityService:GetChildren( child, true )
			for meshChild in Iter(meshChildren) do
				EntityService:SetGraphicsUniform( meshChild, "cDistortionFactor", factor )
				EntityService:SetGraphicsUniform( meshChild, "cDissolveAmount", factor )
			end
		end
	end
end

function invisible:OnInvisibilityExitEnter( state )
	state:SetDurationLimit( 0.5 )
end

function invisible:OnInvisibilityExitExit( state )
	state:SetDurationLimit( 0.5 )
	EffectService:DestroyEffectsByGroup( self.lastOwner, "invisiblity" )
	EntityService:RemoveMaterial( self.lastOwner, "1_invisiblity" )
	local children =  EntityService:GetChildren( self.lastOwner, false )
	for child in Iter(children) do
		local itemType =ItemService:GetItemType(child);
		if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "" ) then
			local meshChildren =  EntityService:GetChildren( child, true )
			for meshChild in Iter(meshChildren) do
				EntityService:RemoveMaterial( meshChild, "1_invisiblity" )
			end
		end
	end
	self.lastOwner = self.owenr
end

function invisible:OnInvisibilityExitExecute( state )
	local duration = state:GetDuration()
	local durationLimit = state:GetDurationLimit()
	if (self.lastOwner == nil ) then
		self.lastOwner = self.owner
	end
	local factor = 1.0 - ( duration / durationLimit)
	EntityService:SetGraphicsUniform( self.lastOwner, "cDistortionFactor", factor )
	EntityService:SetGraphicsUniform( self.lastOwner, "cDissolveAmount", factor )

	local children =  EntityService:GetChildren( self.lastOwner, false )
	for child in Iter(children) do
		local itemType =ItemService:GetItemType(child);
		if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "lift" and itemType ~= "") then
			local meshChildren =  EntityService:GetChildren( child, true )
			for meshChild in Iter(meshChildren) do
				EntityService:SetGraphicsUniform( meshChild, "cDistortionFactor", factor )
				EntityService:SetGraphicsUniform( meshChild, "cDissolveAmount", factor )
			end
		end
	end

end

function  invisible:OnItemEquippedEvent( evt)
	if ( self.mode == true ) then
		local item = evt:GetItem()
		local itemType =ItemService:GetItemType(item);
			if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "" and itemType ~= "lift" ) then
				local meshChildren =  EntityService:GetChildren( item, true )
				for meshChild in Iter(meshChildren) do
					if ( EntityService:IsSkinned( meshChild )) then
						EntityService:SetMaterial( meshChild, "player/item_distortion_skinned", "1_invisiblity" )
					else
						EntityService:SetMaterial( meshChild, "player/item_distortion", "1_invisiblity" )
					end
					
					EntityService:SetGraphicsUniform( meshChild, "cDistortionFactor", 1.0 )
					EntityService:SetGraphicsUniform( meshChild, "cDissolveAmount", 1.0 )
				end
			end
	end
	
end

function  invisible:OnRiftTeleportStartEvent( evt)
	if ( self.mode == true ) then
		self:_Deactivate( false )
	end
	
end


return invisible
