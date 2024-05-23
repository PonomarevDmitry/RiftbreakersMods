require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")

class 'lift' ( item )

function lift:__init()
	item.__init(self)
end

function lift:OnInit()
	LogService:Log( "OnInit" )
	self.recreateObject = false
	self.forceHolding = false
	self.backupObjectBlueprint = ""
	self.missionName = ""
	self.lastItemType = ""
	self.lastItemEnt = INVALID_ID
	self.aimEnt = INVALID_ID
	self.objectEnt = INVALID_ID
	self.mirrorItem = INVALID_ID

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "lifting", { enter="OnLiftingEnter", exit="OnLiftingExit" } )
	self.sm:AddState( "holding", { enter="OnHoldingEnter", execute="OnHoldingExecute", exit="OnHoldingExit" } )
	self.sm:AddState( "force_holding", { enter="OnForceHoldingEnter", execute="OnHoldingExecute", exit="OnHoldingExit" } )
	self.sm:AddState( "deactivation", { enter="OnDeactivationEnter", exit="OnDeactivationExit" } )

	self.aimBp = self.data:GetString( "aim_bp" )
	self.data:SetString("object_blueprint", "" )
end

function lift:OnLoad()
	item.OnLoad(self)

	self.recreateObject = false
	self.forceHolding = false

	local currentMissionName = MissionService:GetCurrentMissionName()
	if currentMissionName == self.missionName and self.missionName ~= "" then
		if self.sm ~= nil then 
			if self.sm:GetCurrentState() == "holding" or self.sm:GetCurrentState() == "force_holding" then 
				self.recreateObject = true
				self.forceHolding = false
				self.backupObjectBlueprint = self.data:GetStringOrDefault("object_blueprint", "" )

				if self.objectEnt ~= INVALID_ID and EntityService:IsAlive( self.objectEnt ) then
					EntityService:RemoveEntity( self.objectEnt )
				end
				self.objectEnt = INVALID_ID
			end
		end
	end
end

function lift:OnEquipped()
	self:CreateMirrorHolder( "att_l_hand_item")
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0 )
	EntityService:FadeEntity( self.mirrorItem, DD_FADE_OUT, 0.0 )
	self.missionName = MissionService:GetCurrentMissionName()

	if self.recreateObject then
		ItemService:UseEquippedItem( self.owner, "LIFT" )
		self.recreateObject = false
		self.forceHolding = true
		return false
	end
end

function lift:OnUnequipped()

end

function lift:OnActivate()
	if ( not self:IsActivated() ) then
		if self.forceHolding == true then
			self:ActiveActionsSwitchMode()
			self.sm:ChangeState("force_holding")
			self.forceHolding = false
		else 
			self.sm:ChangeState("lifting")
		end

		self.interrupted = false 
	else 
		local currentState = self.sm:GetCurrentState()
		if currentState == "holding" or currentState == "force_holding" then
			self.sm:ChangeState("deactivation")
		end
	end
end

function lift:OnLiftingEnter( state )
	state:SetDurationLimit( 1.5 )
	self:ShowHolderItems()
	local ownerData = EntityService:GetDatabase( self.owner );
	self.lastItemType = ownerData:GetStringOrDefault( "RIGHT_HAND_item_type", "" )
	self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
	if ItemService:GetItemType( self.entity ) == "equipment" then
		ownerData:SetString( "RIGHT_HAND_item_type", "range_weapon" )
	else
		ownerData:SetString( "RIGHT_HAND_item_type", "harvester" )
	end
	ownerData:SetFloat( "RIGHT_HAND_use_speed", 1 )

	EffectService:AttachEffects( self.item, "on_lift" ) 
end

local function GetInteractiveEntity( owner )
	local component = reflection_helper( EntityService:GetComponent(owner, "MechComponent") )
	return component.interactive_ent.id;
end

function lift:OnLiftingExit( state )
	local entity = GetInteractiveEntity( self.owner )
	local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
    if ( interactiveComponent ~= nil and self.interrupted == false ) then
        ItemService:InteractWithEntity( entity, self.owner )
        local itemBp = reflection_helper( interactiveComponent ).item
		self.data:SetString("object_blueprint", itemBp )
        local inventoryItemComponent = EntityService:GetBlueprintComponent( itemBp, "InventoryItemComponent" )
        self.bp = reflection_helper( inventoryItemComponent ).item_bp
		self.sm:ChangeState("holding")
    end 

	local ownerData = EntityService:GetDatabase( self.owner );
	if ownerData ~= nil then
		ownerData:SetString( "RIGHT_HAND_item_type", self.lastItemType )
		ownerData:SetFloat( "RIGHT_HAND_use_speed", 0 );
	end
end

function lift:OnForceHoldingEnter( state )
	self:ShowHolderItems()
	self.data:SetString( "object_blueprint", self.backupObjectBlueprint )
	self:OnHoldingEnter( state )
end

function lift:OnHoldingEnter( state )
	self.objectEnt = EntityService:SpawnAndAttachEntity( self.bp, self.item, "att_tip", "" )
	EntityService:RemoveComponent( self.objectEnt, "InteractiveComponent")
	HealthService:SetImmortality( self.objectEnt, true )
	EntityService:FadeEntity( self.objectEnt, DD_FADE_IN, 0.75 )
	
	self.randomDir = { x=RandFloat( 0.1, 0.9 ), y=0, z=RandFloat( 0.1, 0.9 ) }
	self.randomDir = Normalize( self.randomDir )

	self:ActiveActionsSwitchMode()
	self:RegisterHandler( self.owner, "RiftTeleportStartEvent",  "OnRiftTeleportStartEvent" )
	EffectService:AttachEffects( self.item, "holding" ) 
end

function lift:OnHoldingExecute( state )
	if self.aimEnt == INVALID_ID or EntityService:IsAlive( self.aimEnt ) == false then 
		self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=0, y=0, z=0 })
		EntityService:CreateComponent(self.aimEnt, "NetReplicateToOwnerComponent")
	end

	WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, 0.0 )
	EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )

	if self.objectEnt ~= INVALID_ID then
		if EntityService:IsAlive( self.objectEnt ) then
			local currentTime = state:GetDuration()
			EntityService:Rotate( self.objectEnt, self.randomDir.x, self.randomDir.y, self.randomDir.z, 7 )
			EntityService:SetPosition( self.objectEnt, 0, 1+0.5 * math.cos( 3.14 * currentTime ), 0 )
		else 
			self.sm:ChangeState("deactivation")
		end
	end
end

function lift:OnHoldingExit( state )
	if ( self.objectEnt ~= INVALID_ID and EntityService:IsAlive( self.objectEnt ) ) then
		EntityService:DetachEntity( self.objectEnt )
		WeaponService:ThrowObject( self.objectEnt, self.owner )
		EntityService:RemoveComponent( self.objectEnt, "TypeComponent" )
		EntityService:RemoveComponent( self.objectEnt, "MovementModificatorComponent")
		EntityService:PhysicsSleepNotify( self.objectEnt, true )
		EffectService:AttachEffects( self.objectEnt, "grenade" )
		self.objectEnt = INVALID_ID
	end

	if ( self.aimEnt ~= INVALID_ID ) then 
		EntityService:RemoveEntity( self.aimEnt )
		self.aimEnt = INVALID_ID
	end
	
	self:UnregisterHandlers( "RiftTeleportStartEvent" )
	self.data:SetString("object_blueprint", "" )

	EffectService:AttachEffects( self.item, "on_throw" ) 
	EffectService:DestroyEffectsByGroup( self.item, "holding" )
end

function lift:OnDeactivationEnter( state )
	state:SetDurationLimit( 0.75 )
	self:HideHolderItems()
end

function lift:OnDeactivationExit( state )
	ItemService:StopUsingEquippedItem( self.owner, "LIFT" )
end

function lift:OnRiftTeleportStartEvent()
	ItemService:StopUsingEquippedItem( self.owner, "LIFT" )
end

function lift:CanPassInterrupt()
	local currentState = self.sm:GetCurrentState()
	if currentState == "holding" or currentState == "force_holding" then
		self.sm:ChangeState("deactivation")
		return false
	elseif currentState == "deactivation" then
		return false
	end
	return true
end

function lift:OnDeactivate( forced )
	local currentState = self.sm:GetCurrentState()
	if currentState == "lifting" then
		self.sm:Deactivate()
		self:HideHolderItems()
	end

	self.interrupted = true
	self:DeactiveActionsSwitchMode()
	return true 
end

function lift:ActiveActionsSwitchMode()
	local inventoryItemComponent = reflection_helper( EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent" ) )
    inventoryItemComponent.force_switch_mode = true
    inventoryItemComponent.internal_block = true
end

function lift:DeactiveActionsSwitchMode()
	local inventoryItemComponent = reflection_helper( EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent" ) )
    inventoryItemComponent.force_switch_mode = false
    inventoryItemComponent.internal_block = false
end

function lift:ShowHolderItems()
	self.lastRightItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
	self.lastLeftItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "LEFT_HAND" )
	
	EntityService:FadeEntity( self.lastRightItemEnt, DD_FADE_OUT, 0.75 )
	EntityService:FadeEntity( self.lastLeftItemEnt, DD_FADE_OUT, 0.75 )
	EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75 )
	EntityService:FadeEntity( self.mirrorItem, DD_FADE_IN, 0.75 )
end

function lift:HideHolderItems()
	EntityService:FadeEntity( self.lastRightItemEnt, DD_FADE_IN, 0.75 )
	EntityService:FadeEntity( self.lastLeftItemEnt, DD_FADE_IN, 0.75 )
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.75 )
	EntityService:FadeEntity( self.mirrorItem, DD_FADE_OUT, 0.75 )
end

function lift:CreateMirrorHolder( attachment )
	local meshId = EntityService:GetMeshName( self.item )
	local materialId = EntityService:GetOverridenMaterial( self.item )
	self.mirrorItem = EntityService:SpawnAndAttachEntity( self.owner, attachment )
	EntityService:CreateComponent( self.mirrorItem, "MeshComponent" )
	EntityService:CreateComponent( self.mirrorItem, "BoundsComponent" )
	EntityService:ChangeMesh( self.mirrorItem,"meshes/items/weapons/power_fist_basic_mirror.mesh" )
	--EntityService:ChangeMesh( self.mirrorItem, WeaponService:GetMirrorMeshName( meshId ) )
	EntityService:SetMaterial( self.mirrorItem, materialId, "default" )
end

function lift:DissolveShow()

end

return lift
