class 'item' ( LuaEntityObject )

function item:__init()
	LuaEntityObject.__init(self,self)
end

function item:init()
	self:RegisterHandler( self.entity, "EquipItemEvent", 	     "_OnEquipped" )
	self:RegisterHandler( self.entity, "UnequipedItemEvent", 	 "_OnUnequipped" )		
	self:RegisterHandler( self.entity, "DroppedItemEvent", 	 	 "_OnDropItemEvent" )
	self:RegisterHandler( self.entity, "PickedUpItemEvent", 	 "_OnPickEventLua" )	

	self.entity_blueprint = EntityService:GetBlueprintName(self.entity);
	self:OnInit()
	
	if ( self.data:HasInt("activated") == false ) then
		self.data:SetInt( "activated", 0 )
	end

	if ( self.data:HasInt("equipped" ) == false ) then
		self.data:SetInt( "equipped", 0 );
	end

	self.data:SetInt( "equipped_entity", INVALID_ID )
	self.slot = "" 
end

function item:_OnEquipped( evt )
	if ( self.data:GetInt("equipped" ) == 0  ) then
		local invItemComponent = EntityService:GetComponent( self.entity, "InventoryItemComponent")
		invItemComponent:GetField( "equipped" ):SetValue("1")		
		
		self:RegisterHandler( self.entity, "ActivateItemRequest", 	 "_OnActivate" )
		self:RegisterHandler( self.entity, "ActivateOnceItemRequest", 	 "_OnActivateOnce" )
		self:RegisterHandler( self.entity, "DeactivateItemRequest", "_OnDeactivate" )
		self.item = evt:GetItemEnt()
		self.owner = evt:GetOwner()
		self.slot = evt:GetSlot()

		if ( self.item ~= INVALID_ID ) then 
			ItemService:SetItemCreator( self.item, self.entity_blueprint )

			EffectService:AttachEffects( self.item, self.slot ) 
			EffectService:AttachEffects( self.item, "item_equipped" ) 
		end
		
		self.data:SetInt( "equipped", 1 )
		self.data:SetInt( "equipped_entity", self.item )

		self:DissolveShow()
		self:OnEquipped()
	end
end

function item:_OnActivate(evt)
	--LogService:Log( "_OnActivate!" )
	if ( self.data:GetInt("equipped")== 1 ) then
		local continous = evt:GetContinous()
		if( continous == true or self.data:GetInt( "activated" ) == 0 ) then	
			ItemService:SetActivationStatus( self.entity, true );
			if ( self.data:GetInt( "activated" ) == 0 ) then
				EffectService:AttachEffects( self.item, "item_activated_once" )
			end

			EffectService:AttachEffects( self.item, "item_activated" ) 
			self:OnActivate()
			self.data:SetInt( "activated", 1 ) 
		end
	end
end

function item:_OnActivateOnce(evt)
	--LogService:Log( "_OnActivate!" )
	if ( self.data:GetInt("equipped")== 1 ) then
	
		if ( self.OnActivateOnce == nil ) then
			local continous = evt:GetContinous()
			if( continous == true or self.data:GetInt( "activated" ) == 0 ) then	
				ItemService:SetActivationStatus( self.entity, true );
				if ( self.data:GetInt( "activated" ) == 0 ) then
					EffectService:AttachEffects( self.item, "item_activated_once" )
				end
	
				EffectService:AttachEffects( self.item, "item_activated" ) 
				self:OnActivate()
				self.data:SetInt( "activated", 1 ) 
			end
			
			EffectService:AttachEffects( self.item, "item_deactivated" ) 
			local deactivated = self:OnDeactivate( forced )
			if ( deactivated  == true or forced == true) then
				--LogService:Log("forced deactivation")
				ItemService:SetActivationStatus( self.entity, false );
				self.data:SetInt( "activated", 0 ) 
			end		
		else
			if ( self.data:GetInt( "activated" ) == 0 ) then
				EffectService:AttachEffects( self.item, "item_activated_once" )
			end
	
			EffectService:AttachEffects( self.item, "item_activated" ) 
			self:OnActivateOnce()
			EffectService:AttachEffects( self.item, "item_deactivated" ) 
		end
		
	end



end

function item:_Deactivate( forced )
	--LogService:Log( "_Deactivate!" )
	if ( self.data:GetIntOrDefault( "activated", 0 ) == 1 ) then
		EffectService:AttachEffects( self.item, "item_deactivated" ) 
		EffectService:DestroyEffectsByGroup( self.item, "item_activated" )
		EffectService:DestroyEffectsByGroup( self.item, "item_activated_once" )
		local deactivated = self:OnDeactivate( forced )
		if ( deactivated  == true or forced == true) then
			--LogService:Log("forced deactivation")
			ItemService:SetActivationStatus( self.entity, false );
			self.data:SetInt( "activated", 0 ) 
		end		
	end	
end

function item:_OnDeactivate( evt )
	local forced = evt:GetForced()
	self:_Deactivate( forced )
end

function item:_OnUnequipped( evt )	

	if ( self.data:GetIntOrDefault("equipped", 0) == 1 ) then
		self:UnregisterHandler( self.entity, "ActivateItemRequest", 	"_OnActivate" )
		self:UnregisterHandler( self.entity, "ActivateOnceItemRequest", "_OnActivateOnce" )
		self:UnregisterHandler( self.entity, "DeactivateItemRequest", 	"_OnDeactivate" )
		self.owner = evt:GetOwner()
		local invItemComponent = EntityService:GetComponent( self.entity, "InventoryItemComponent")
		if invItemComponent then
			invItemComponent:GetField( "equipped" ):SetValue("0")
		end
		self.data:SetInt( "equipped", 0 )

		self:_Deactivate( true )
		self:OnUnequipped()	

		self.data:SetInt( "equipped_entity", INVALID_ID )
		self.owner = INVALID_ID;
	end
end

function item:_OnDropItemEvent(evt)
	self.item = evt:GetItem()
	self.owner = INVALID_ID
	self:OnDrop()
end

function item:_OnPickEventLua( evt )
	self.item = INVALID_ID

	if ( self.data:HasInt("#subslot#") ) then
		local subslot = self.data:GetInt("#subslot#")
		local slot = self.data:GetString("#slot#")
		local owner = evt:GetInventory()
		ItemService:TryEquipItemInSlot( owner, self.entity, slot, subslot)
		ItemService:ClearNewItemMark( owner, self.entity )
	end
	
	self:OnPickUp()
end

function item:OnInit()
end

function item:OnLoad()
	self.slot = self.slot or ""
	if ( self.dissolveSM and self.dissolveSM:GetCurrentState() == "") then
		self:RemoveDissolveStateMachine()
    end
end

function item:OnEquipped()
end

function item:OnActivate()
	
end

function item:OnDeactivate()
	return true
end

function item:OnUnequipped()
end

function item:OnDrop()
end

function item:OnPickUp()
end

function item:IsPickable( owner )
	return true
end

function item:DissolveShow()
	self.dissolveSM = self:CreateStateMachine()
	self.dissolveSM:AddState( "dissolve_show", { from="*", enter="OnDissolveShowEnter", execute="OnDissolveShowExecute",  exit="OnDissolveShowExit" } )
	self.dissolveSM:ChangeState( "dissolve_show" )
	EntityService:SetGraphicsUniform( self.item, "cDissolveAmount", 1 )
end

function item:OnDissolveShowEnter( state )
	EntityService:SetGraphicsUniform( self.item, "cDissolveAmount", 1 )
	state:SetDurationLimit( 0.75 )
end

function item:OnDissolveShowExecute( state )
	EntityService:SetGraphicsUniform( self.item, "cDissolveAmount", 1 - ( state:GetDuration() / 0.75 ) )
end

function item:RemoveDissolveStateMachine()
	if self.dissolveSM == nil then return end

	self:DestroyStateMachine( self.dissolveSM )
	self.dissolveSM = nil
end

function item:OnDissolveShowExit( state )
	EntityService:SetGraphicsUniform( self.item, "cDissolveAmount", 0 )
	self:RemoveDissolveStateMachine()
end

return item