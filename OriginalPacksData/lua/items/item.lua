class 'item' ( LuaEntityObject )
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

function item:__init()
	LuaEntityObject.__init(self,self)
end

function item:IsActivated()
	local runtimeData = EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent")
	if ( runtimeData == nil ) then
		return false
	end
	
	return runtimeData:GetField( "activated" ):GetValue() == "1"
end

function item:IsEquipped()
	local runtimeData = EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent")
	if ( runtimeData == nil ) then
		return false
	end
	
	return runtimeData:GetField( "equipped" ):GetValue() == "1"
end


function item:init()
	self:RegisterHandler( self.entity, "EquipItemEvent", 	     "_OnEquipped" )
	self:RegisterHandler( self.entity, "UnequipedItemEvent", 	 "_OnUnequipped" )		
	self:RegisterHandler( self.entity, "DroppedItemEvent", 	 	 "_OnDropItemEvent" )
	self:RegisterHandler( self.entity, "PickedUpItemEvent", 	 "_OnPickEventLua" )	

	self.entity_blueprint = EntityService:GetBlueprintName(self.entity);
	self:OnInit()

	self.slot = "" 
	self.subSlot = nil 
	self.references = {}
	self.pickup = false

	self.version = 2
end

function item:SpawnReferenceEntity( blueprint, target, team )
	local ent = EntityService:SpawnEntity( blueprint, target, team or EntityService:GetTeam( self.entity ) )
	ItemService:SetItemReference( ent, self.entity, self.entity_blueprint )
	table.insert( self.references, ent )
	return ent
end

function item:_OnEquipped( evt )
	local equipped = self:IsEquipped()
	if ( not equipped  ) then
		local invItemComponent = EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent")
		invItemComponent:GetField( "equipped" ):SetValue("1")		
		
		self:RegisterHandler( self.entity, "ActivateItemRequest", 	 "_OnActivate" )
		self:RegisterHandler( self.entity, "ActivateOnceItemRequest", 	 "_OnActivateOnce" )
		self:RegisterHandler( self.entity, "DeactivateItemRequest", "_OnDeactivate" )
		self.item = evt:GetItemEnt()
		self.owner = evt:GetOwner()
		self.slot = evt:GetSlot()
		self.subSlot = ItemService:GetItemSubSlot( self.owner, self.entity )

		if ( self.item ~= INVALID_ID ) then 
			ItemService:SetItemCreator( self.item, self.entity_blueprint )
			EntityService:PropagateEntityOwner( self.item, self.owner )

			EffectService:AttachEffects( self.item, self.slot ) 
			EffectService:AttachEffects( self.item, "item_equipped" ) 
		end
		
		self:DissolveShow()
		self:OnEquipped()
	end
end

function item:_OnActivate(evt)
	--LogService:Log( "_OnActivate!" )
	if ( self:IsEquipped() ) then
		local continous = evt:GetContinous()
		local activated = self:IsActivated()
		if( continous == true or not activated ) then	
			if ( not activated ) then
				EffectService:AttachEffects( self.item, "item_activated_once" )
			end

			EffectService:AttachEffects( self.item, "item_activated" ) 
			self:OnActivate()
			ItemService:SetActivationStatus( self.entity, true );
		end
	end
end

function item:_OnActivateOnce(evt)
	--LogService:Log( "_OnActivateOnce!" )
	if ( self:IsEquipped() ) then
		local activated = self:IsActivated()
		if ( self.OnActivateOnce == nil ) then
			local continous = evt:GetContinous()
			if( continous == true or not activated ) then	
				if ( not activated ) then
					EffectService:AttachEffects( self.item, "item_activated_once" )
				end
	
				EffectService:AttachEffects( self.item, "item_activated" ) 
				self:OnActivate()
				ItemService:SetActivationStatus( self.entity, true );
			end
			
			EffectService:AttachEffects( self.item, "item_deactivated" ) 
			local deactivated = self:OnDeactivate( forced )
			if ( deactivated  == true or forced == true) then
				--LogService:Log("forced deactivation")
				ItemService:SetActivationStatus( self.entity, false );
			end		
		else
			if ( not activated ) then
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
	local activated = self:IsActivated()
	if ( activated ) then
		EffectService:AttachEffects( self.item, "item_deactivated" ) 
		EffectService:DestroyEffectsByGroup( self.item, "item_activated" )
		EffectService:DestroyEffectsByGroup( self.item, "item_activated_once" )
		local deactivated = self:OnDeactivate( forced )
		if ( deactivated  == true or forced == true) then
			--LogService:Log("forced deactivation")
			ItemService:SetActivationStatus( self.entity, false );
		end		
	end	
end

function item:_OnDeactivate( evt )
	local forced = evt:GetForced()
	self:_Deactivate( forced )
end

function item:ValidateEntityReference( entity )
	if ( entity ~= nil and entity ~= INVALID_ID and not ItemService:IsItemReference( entity, self.entity) ) then
		return false
	end
	return true
end

function item:DespawnReferenceEntities(  )
	for entity in Iter(self.references ) do
		if ( ItemService:IsItemReference( entity, self.entity) ) then
			QueueEvent("DissolveEntityRequest", entity, 0.2, 0.0 )
		end
	end
	self.references = {}
end

function item:_OnUnequipped( evt )	

	if ( self:IsEquipped() ) then
		if ( self:HasEventHandler( self.entity, "ActivateItemRequest" ) ) then
			self:UnregisterHandler( self.entity, "ActivateItemRequest", 	"_OnActivate" )
			self:UnregisterHandler( self.entity, "ActivateOnceItemRequest", "_OnActivateOnce" )
			self:UnregisterHandler( self.entity, "DeactivateItemRequest", 	"_OnDeactivate" )
		end
		self.owner = evt:GetOwner()
		local invItemComponent = EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent")
		if invItemComponent then
			invItemComponent:GetField( "equipped" ):SetValue("0")
		end

		self:_Deactivate( true )
		self:OnUnequipped()	
		self:DespawnReferenceEntities()
		self.owner = INVALID_ID;
	end
end

function item:_OnDropItemEvent(evt)
	self.item = evt:GetItem()
	if ( evt:GetPlayerId() ~= INVALID_ID  ) then
		self.pickup = true
	end
	self.owner = INVALID_ID
	self:OnDrop()
end

function item:_OnPickEventLua( evt )
	self.item = INVALID_ID
	local owner = evt:GetInventory()
	if ( self.pickup == true ) then
		if ( self.slot ~= "" and self.subSlot ~= nil ) then
			ItemService:TryEquipItemInSlot( owner, self.entity, self.slot, self.subSlot)
		else
			ItemService:TryEquipItemInEmptySlot( owner, self.entity )
		end
		ItemService:ClearNewItemMark( owner, self.entity )

	end
	
	self:OnPickUp( owner)
end

function item:OnInit()
end

function item:OnLoad()
	self.references = self.references or {}
	self.slot = self.slot or ""
	if ( self.dissolveSM and self.dissolveSM:GetCurrentState() == "") then
		self:RemoveDissolveStateMachine()
    end

	if ( self.version == nil ) then
		self.data:RemoveKey( "activated" )
		self.data:RemoveKey( "equipped" )

		self.subSlot = self.data:GetIntOrDefault( "#subslot#", 0 )
		self.data:RemoveKey( "#slot#" )
		self.data:RemoveKey( "#subslot#" )
		self.version = 1
	end
	if ( self.version <= 1 ) then
		self.pickup =  (self.slot ~= "" and self.subSlot ~= nil)
		self.version = 2
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
	if ( EntityService:IsAlive( self.item )) then
		EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75 )
	end
end

function item:OnDissolveShowEnter( state )
end

function item:OnDissolveShowExecute( state )
end

function item:RemoveDissolveStateMachine()
end

function item:OnDissolveShowExit( state )
end

function item:CanActivate()

	if ( self.data:HasString("disabled_conditions") == true ) then
		local disabledConditions = self.data:GetString("disabled_conditions")
		local conditions = Split( disabledConditions, "," )

		local disabledValues = self.data:GetStringOrDefault("disabled_values", "")
		local values = Split( disabledValues, "," )

		for condition  in Iter( conditions ) do
			if ( condition == "biome") then
				local currentBiome = MissionService:GetCurrentBiomeName()
				if ( IndexOf( values, currentBiome ) ~= nil ) then
					return false
				end
			end
		end
	end
	return true
end

return item