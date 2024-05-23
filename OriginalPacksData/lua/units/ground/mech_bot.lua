require("lua/utils/table_utils.lua")

local mech = require("lua/units/ground/mech.lua")
class 'mech_bot' ( mech )

function mech_bot:__init()
	mech.__init( self,self )
end

function mech_bot:init()
	self.is_bot = true;
	mech.init(self)
end

local CHARGE_WEAPON_TIMER = 0.25
local ATTACK_COUNTER_CHARGE_RELEASE = 5

function mech_bot:_OnInit()
	self:RegisterHandler( self.entity, "StartMeleeEvent",  	"OnStartMeleeEvent" )
	self:RegisterHandler( self.entity, "StopMeleeEvent",  	"OnStopMeleeEvent" )
	self:RegisterHandler( self.entity, "ShootEvent",  		"OnShootEvent" )
	self:RegisterHandler( self.entity, "StopShootEvent",  	"OnStopShootEvent" )
	self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnBotItemEquippedEvent" )
	self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnBotItemUnequippedEvent" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )

	EntityService:RemoveComponent( self.entity, "CharacterControllerComponent" );
	EntityService:RemoveComponent( self.entity, "ActionComponent" );

	self.attackFSM = self:CreateStateMachine()
	self.attackFSM:AddState( "attack", { execute="OnExecuteAttack" } )
	self.attackFSM:ChangeState( "attack" )

	self.useWeapon = false
	self.rangeWeaponList = {}
	self.meleeWeaponList = {}

	self.currentWeaponInUse = {} 

	self.PICK_MELEE_WEAPON	= "PICK_MELEE_WEAPON"
	self.PICK_RANGE_WEAPON	= "PICK_RANGE_WEAPON"

	self.LEFT_HAND  = "LEFT_HAND"
	self.RIGHT_HAND = "RIGHT_HAND"

	self:PrepareBotEquipment()

	UnitService:SetStateMachineParam( self.entity, "player_target_valid", 0 )
end

function mech_bot:PrepareBotEquipment()
	self.useWeapon = false

	UnitService:SetStateMachineParam( self.entity, "has_range_weapon", 0 )
	UnitService:SetStateMachineParam( self.entity, "has_melee_weapon", 0 )

	for slot in Iter({ self.LEFT_HAND, self.RIGHT_HAND } ) do
		local items = ItemService:GetEquippedItemsInSlot( self.entity, slot )
		for item in Iter(items) do
			self:AddItem(item)
		end
	end
end

function mech_bot:OnBotItemEquippedEvent(evt)
	if evt:GetSlot() ~= self.LEFT_HAND and evt:GetSlot() ~= self.RIGHT_HAND then
		return
	end

	self:AddItem( evt:GetItem() )
end

function mech_bot:OnBotItemUnequippedEvent(evt)
	if evt:GetSlot() ~= self.LEFT_HAND and evt:GetSlot() ~= self.RIGHT_HAND then
		return
	end

	self:RemoveItem( evt:GetItem() )
end

function mech_bot:PickRandomWeapon( type )
	if self.useWeapon and self.currentWeaponInUse.item ~= nil then
		ItemService:StopUsingEquippedItem( self.entity, self.currentWeaponInUse.slot )
	end

	self.currentWeaponInUse = {}
	self.useWeapon = false

	local SelectRandomWeapon = function( weapons )
		return weapons[RandInt( 1, #weapons )]
	end

	local selectedWeapon = nil
	if type == self.PICK_MELEE_WEAPON then
		selectedWeapon = SelectRandomWeapon( self.meleeWeaponList )
	elseif type == self.PICK_RANGE_WEAPON then
		selectedWeapon = SelectRandomWeapon( self.rangeWeaponList )
	end

	if selectedWeapon == nil then
		return
	end

	self.currentWeaponInUse = selectedWeapon;
	self.chargeWeaponInUse = type == self.PICK_RANGE_WEAPON and self.currentWeaponInUse.isCharge

	if ( self.currentWeaponInUse.item ~= nil ) then
		if ItemService:GetEquippedItem( self.entity,self.currentWeaponInUse.slot ) ~= self.currentWeaponInUse.item then
			QueueEvent( "ChangeSubSlotRequest", self.entity, self.currentWeaponInUse.slot, self.currentWeaponInUse.subSlot )
		else
			self.useWeapon = true
		end
	end
end

function mech_bot:OnEquipmentSlotChangedEvent( event )
	self.useWeapon = self.currentWeaponInUse.item ~= nil
end

function mech_bot:OnStartMeleeEvent( evt )
	self:PickRandomWeapon( self.PICK_MELEE_WEAPON )
end

function mech_bot:OnStopMeleeEvent( evt )
	self.useWeapon = false

	if self.currentWeaponInUse.item ~= nil then
		ItemService:StopUsingEquippedItem( self.entity, self.currentWeaponInUse.slot )
	end
end

function mech_bot:OnShootEvent( evt )
	self:PickRandomWeapon( self.PICK_RANGE_WEAPON )
end
-- waponstatcomponent WeaponItemComponent
function mech_bot:OnStopShootEvent( evt )
	self.useWeapon = false

	if self.currentWeaponInUse.item ~= nil then
		ItemService:StopUsingEquippedItem( self.entity, self.currentWeaponInUse.slot )
	end
end

function mech_bot:OnExecuteAttack( state, dt )
	local targetEntity = UnitService:GetCurrentTarget( self.entity, "move" )
	if ( ( targetEntity ~= INVALID_ID ) and ( EntityService:IsAlive( targetEntity ) ) ) then
		local origin = EntityService:GetPosition( self.entity )	
		local targetOrigin = EntityService:GetPosition( targetEntity )	

		local distance = Distance( targetOrigin, origin )

		if ( distance > 0.1 ) then
			local forward = Normalize( VectorSub( targetOrigin, origin ) )
			forward.y = 0.0
			local db = EntityService:GetDatabase( self.entity )

			local moveLength = Length( forward )
			
			if ( EntityService:HasComponent( self.entity, "MechComponent" ) ) then

				if ( ( moveLength < 1.1 ) and ( moveLength > 0.9 ) ) then
					PlayerService:SetMoveDir( self.entity, forward)
				end

				local lookForward = VectorAdd( targetOrigin, PlayerService:GetVelocity( targetEntity ) )

				PlayerService:SetAimDir( self.entity, forward )
				EntityService:SetForward( self.entity, forward.x, forward.y, forward.z )

				if ( distance < 50.0 ) then
					PlayerService:SetWeaponLookPoint( self.entity, lookForward )
				end
			end
			
		end
	end

	if EntityService:HasComponent( self.entity, "ActionComponent" ) then
		EntityService:RemoveComponent( self.entity, "ActionComponent" );
	end

	if self.useWeapon and self.currentWeaponInUse.item ~= nil then
		-- release charge!
		local weapon = self.currentWeaponInUse
		if not weapon.attackCounter then
			weapon.attackCounter = 0
		end

		if weapon.chargeTimer ~= nil then
			weapon.chargeTimer = weapon.chargeTimer - dt

			if weapon.chargeTimer < 0.0 then
				weapon.chargeTimer = nil
				ItemService:StopUsingEquippedItem( self.entity, weapon.slot )
			end
		elseif self.chargeWeaponInUse and weapon.attackCounter > ATTACK_COUNTER_CHARGE_RELEASE then
			weapon.chargeTimer = CHARGE_WEAPON_TIMER
			weapon.attackCounter = 0
			ItemService:UseEquippedItem( self.entity, weapon.slot )
		else
			weapon.attackCounter = weapon.attackCounter + 1
			ItemService:UseEquippedItem( self.entity, weapon.slot )
		end
	end


end

function mech_bot:EnableMechFunctionality( value )
	mech.EnableMechFunctionality(self, value)

	if value then
		self:PrepareBotEquipment()
	end
end

function mech_bot:IsEquipped( item )
	for weapon in Iter( self.meleeWeaponList ) do
		if weapon.item == item then
			return true
		end
	end

	for weapon in Iter( self.rangeWeaponList ) do
		if weapon.item == item then
			return true
		end
	end

	return false
end

function mech_bot:AddItem( item )
	if item == INVALID_ID then
		return
	end

	if not EntityService:HasComponent( item, "InventoryItemComponent" ) then
		return
	end

	if self:IsEquipped( item ) then 
		return
	end

	local subSlot = ItemService:GetItemSubSlot( self.entity, item )
	local slot = ItemService:GetItemSlot( self.entity, item )

	local inventoryItemComponent = reflection_helper( EntityService:GetConstComponent( item, "InventoryItemComponent") )

	local iteamTypeName = Split( inventoryItemComponent.item_bp, "/" )
	for type in Iter( iteamTypeName ) do
		if ( type == "skills" ) or ( type == "power_fist_basic" ) then
			return
		end
	end

	local blueprint = ResourceManager:GetBlueprint( inventoryItemComponent.item_bp )
	if ( blueprint ) then
		
		local weapon = {}
		weapon.item     = item
		weapon.slot     = slot
		weapon.subSlot  = subSlot
		weapon.bp		= inventoryItemComponent.item_bp

		local isCharge = false
		local isMelee  = false 

		if ( blueprint:GetComponent( "ChargeWeaponComponent" ) ) then
			isCharge = true
		elseif ( blueprint:GetComponent( "MeleeWeaponDesc" ) ) then
			isMelee = true
		end

		weapon.isCharge = isCharge

		if ( isMelee ) then
			table.insert( self.meleeWeaponList, weapon )
			UnitService:SetStateMachineParam( self.entity, "has_melee_weapon", 1 )
		else
			table.insert( self.rangeWeaponList, weapon )
			UnitService:SetStateMachineParam( self.entity, "has_range_weapon", 1 )
		end
	end
end

function mech_bot:RemoveItem( item )
	if item == INVALID_ID then
		return
	end

	if not self:IsEquipped( item ) then 
		return
	end

	for weapon in Iter( self.meleeWeaponList ) do
		if weapon.item == item then
			return Remove(self.meleeWeaponList, weapon )
		end
	end

	for weapon in Iter( self.rangeWeaponList ) do
		if weapon.item == item then
			return Remove(self.rangeWeaponList, weapon )
		end
	end
end

function mech_bot:OnLuaGlobalEvent( evt )
	local eventName = evt:GetEvent()

	if ( eventName == "bot_aggressive" ) then
		UnitService:SetUnitState( self.entity, UNIT_AGGRESSIVE )
	elseif 	( eventName == "bot_wander" ) then
		UnitService:SetUnitState( self.entity, UNIT_WANDER )
	elseif 	( eventName == "bot_defender" ) then
		UnitService:SetUnitState( self.entity, UNIT_DEFENDER )
	end
end 

return mech_bot