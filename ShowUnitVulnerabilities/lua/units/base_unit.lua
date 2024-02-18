require("lua/units/units_utils.lua")
require("lua/utils/reflection.lua")
local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

class 'base_unit' ( LuaEntityObject )

function base_unit:__init()
	LuaEntityObject.__init(self, self)
end

local CURRENT_BASE_UNIT_VERSION = 1

function base_unit:init()
	SetupUnitScale( self.entity, self.data )

	self.lastDamageGenericTime = 0

	self:CreateSoundStateMachine()

	self:RegisterHandler( self.entity, "RunningStateChangeEvent", "_OnRunningStateChange" )
	self:RegisterHandler( self.entity, "DestroyRequest",  "_OnDestroyRequest" )
	self:RegisterHandler( self.entity, "DamageEvent",  "_OnDamageEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "_OnAnimationMarkerReached" )
	self:RegisterHandler( self.entity, "AnimationStateChangedEvent", "_OnAnimationStateChanged" )

	self:OnInit()

	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION

	Assert( self.wreck_type ~= nil, "ERROR: self.wreck_type is required to be set in unit:OnInit!");
	Assert( self.wreckMinSpeed ~= nil, "ERROR: self.wreckMinSpeed is required to be set in unit:OnInit!");
end

function base_unit:OnInit()
end

function base_unit:CreateSoundStateMachine( )
	self.soundFSM = self:CreateStateMachine()
	self.soundFSM:AddState( "idle", {interval=10.0} )
	self.soundFSM:AddState( "move", {enter="_OnSoundMoveEnter", exit="_OnSoundMoveExit", interval=0.5} )
	self.soundFSM:AddState( "run", {enter="_OnSoundRunEnter", exit="_OnSoundRunExit", interval=0.5} )
	self.soundFSM:ChangeState("idle")
end

function base_unit:_OnDamageEvent( evt )
	if not evt:GetDamageOverTime() then 
		local currentTime = GetLogicTime()

		local isResisted = IsEnumFlagSet( evt:GetEffect(), DAMAGE_EFFECT_RESISTED )
		local isThresholded = IsEnumFlagSet( evt:GetEffect(), DAMAGE_EFFECT_THRESHOLDED )

		if self.lastDamageGenericTime + 0.3 < currentTime then

			if not isResisted and not isThresholded then
				EffectService:AttachEffects( self.entity, "damage_generic" )
				self.lastDamageGenericTime = currentTime
			end
		end

		local resistanceComponent = EntityService:GetComponent(self.entity, "ResistanceComponent")
		if ( resistanceComponent ~= nil ) then

			local resistanceComponentRef = reflection_helper(resistanceComponent)

			local damageType = evt:GetDamageType()

			local currentResistance = self:GetResistanceToDamage(damageType, resistanceComponentRef)

			if ( currentResistance < 1 ) then

				LogService:Log("damageType " .. tostring(damageType) .. " " .. tostring(resistanceComponentRef))

				local vulnerabilities = self:GetVulnerabilities(resistanceComponentRef)

				LogService:Log("GetSaveEquipmentInfo " .. debug_serialize_utils:SerializeObject(vulnerabilities))

				local menuBlueprintName = "misc/unit_vulnerabilities_menu"

				local menuEntity = self:FindMenuEntity(menuBlueprintName)

				if ( menuEntity == nil ) then

					LogService:Log("menuEntity " .. tostring(menuEntity))

					local team = EntityService:GetTeam( self.entity )
					menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)

					local sizeSelf = EntityService:GetBoundsSize( self.entity )
					EntityService:SetPosition( menuEntity, 0, sizeSelf.y, 0 )

					LogService:Log("sizeSelf " .. debug_serialize_utils:SerializeObject(sizeSelf))

					self:SetMenuValues(menuEntity, vulnerabilities)
				end
			end
		end
	end

	if self.OnDamageEvent then
		self:OnDamageEvent(evt)
	end
end

function base_unit:SetMenuValues(menuEntity, vulnerabilities)

	local menuDB = EntityService:GetDatabase( menuEntity )
	if ( menuDB == nil ) then
		return
	end

	menuDB:SetInt("menu_visible", 1)

	menuDB:SetInt("damage_visible_1", 0)
	menuDB:SetInt("damage_visible_2", 0)
	menuDB:SetInt("damage_visible_3", 0)

	menuDB:SetString("damage_type_1", "")
	menuDB:SetString("damage_type_2", "")
	menuDB:SetString("damage_type_3", "")

	menuDB:SetString("damage_name_1", "")
	menuDB:SetString("damage_name_2", "")
	menuDB:SetString("damage_name_3", "")

	local count = math.min(#vulnerabilities, 3)

	local numberDelta = 3 - count

	for damageNumber=1,count do

		local damage = vulnerabilities[damageNumber]

		local name = tostring(damage.current_value * 100) .. "${gui/menu/inventory/units_percent}"

		local slotNumber = tostring(damageNumber + numberDelta)

		menuDB:SetInt("damage_visible_" .. slotNumber, 1)
		menuDB:SetString("damage_type_" .. slotNumber, damage.type)
		menuDB:SetString("damage_name_" .. slotNumber, name)
	end
end

function base_unit:FindMenuEntity(menuBlueprintName)

	local children = EntityService:GetChildren( self.entity, true )

	for child in Iter(children) do
		local blueprintName = EntityService:GetBlueprintName( child )
		if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

			return child
		end
	end

	return nil
end

function base_unit:GetVulnerabilities(resistanceComponentRef)

	local result = {}

	local resistances = resistanceComponentRef.resistances

	for i=1,resistances.count do
		local item = resistances[i]

		if ( item.value.current_value > 1 ) then
			
			local damage = {}
			damage.type = item.key
			damage.current_value = item.value.current_value

			Insert(result, damage)
		end
	end

	local sorter = function( damage1, damage2 )

		if (damage1.current_value ~= damage2.current_value) then

			return damage1.current_value < damage2.current_value
		end

		return damage1.type:upper() < damage2.type:upper()
	end

	table.sort(result, sorter)
	
	return result
end

function base_unit:GetResistanceToDamage(damageType, resistanceComponentRef)

	local resistances = resistanceComponentRef.resistances

	for i=1,resistances.count do
		local item = resistances[i]

		if ( item.key == damageType ) then
			return item.value.current_value
		end
	end
	
	return 1
end

function base_unit:_OnDestroyRequest( evt )
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")

	if self.OnDestroyRequest then
		self:OnDestroyRequest(evt)
	end
end

function base_unit:_OnAnimationMarkerReached(evt)
	local markerName = evt:GetMarkerName() 

	local attachEffects = true;
	if self.OnAnimationMarkerReached then
		attachEffects = self:OnAnimationMarkerReached(evt)
	end

	if attachEffects then
		EffectService:AttachEffects( self.entity, markerName  )
	end
end

function base_unit:_OnAnimationStateChanged( evt )
	if self.OnAnimationStateChanged then
		self:OnAnimationStateChanged(evt)
	end
end

function base_unit:ChangeSoundState( name )
	if ( name ~= self.soundFSM:GetCurrentState() ) then
		-- LogService:Log( "ChangeSoundState " .. tostring(self.entity) .. " state: " .. name )	
		self.soundFSM:ChangeState( name )
	end
end

function base_unit:_OnRunningStateChange( evt )
	if evt:GetState() == 1 then
		self:ChangeSoundState("move")
	elseif evt:GetState() == 2 then
		self:ChangeSoundState("run")
	else
		self:ChangeSoundState("idle")
	end
end

function base_unit:_OnSoundMoveEnter( state )
	EffectService:AttachEffects( self.entity, "move_random" )
end
function base_unit:_OnSoundMoveExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "move_random" )
end

function base_unit:_OnSoundRunEnter( state )
	EffectService:AttachEffects( self.entity, "run" )
end
function base_unit:_OnSoundRunExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "run" )
end

function  base_unit:OnLoad()
	if ( self.baseUnitVersion == nil or self.baseUnitVersion < 1 ) then
		self:UnregisterHandler( self.entity, "IdleStateChangedEvent", "_OnIdleStateChanged" )
		self:DestroyStateMachine(self.soundFSM)
		self:CreateSoundStateMachine()
		self.baseUnitVersion = 1
	end
	
	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION
end
	
return base_unit
