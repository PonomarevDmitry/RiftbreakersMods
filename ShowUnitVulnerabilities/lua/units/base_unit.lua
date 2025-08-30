require("lua/units/units_utils.lua")
require("lua/utils/reflection.lua")

class 'base_unit' ( LuaEntityObject )

globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

function base_unit:__init()
	LuaEntityObject.__init(self, self)
end

local FXSYSTEM_HANDLES_SOUND	= 2
local CURRENT_BASE_UNIT_VERSION	= FXSYSTEM_HANDLES_SOUND

function base_unit:init()
	SetupUnitScale( self.entity, self.data )

	self.lastDamageGenericTime = 0
	self.normalExplodeProbability = 1
	self.leaveBodyProbability = 5
	self.wreckMinSpeed = 8
	self.disallowDeathAnim = ""

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

function base_unit:_OnDamageEvent( evt )
	-- `damage_generic` spawning moved to FxSystem so it is done only on client side!
	if not evt:GetDamageOverTime() then 
		self:ShowVulnerabilitiesMenu(evt)
	end

	if self.OnDamageEvent then
		self:OnDamageEvent(evt)
	end
end

function base_unit:CreateNormalExplode()
	EntityService:RequestDestroyPattern( self.entity, "wreck" )	
end

function base_unit:_OnDestroyRequest( evt )
	if self.OnDestroyRequest then
		self:OnDestroyRequest(evt)
	end

	local menuEntity = self:FindMenuEntity("misc/unit_vulnerabilities_menu")
	if ( menuEntity ~= nil ) then
		EntityService:CreateOrSetLifetime( menuEntity, 3, "normal" )
	end

	local damageType = evt:GetDamageType()

	if ( ( UnitService:IsOnHeightGround( self.entity ) == true ) or ( damageType == 'gravity' ) ) then
		self:CreateNormalExplode()
	else
		local BehaviorRange1 = 0 + self.normalExplodeProbability
		local BehaviorRange2 = BehaviorRange1 + self.leaveBodyProbability	
		local probabilitySum = self.normalExplodeProbability + self.leaveBodyProbability    
		local behaviorNumber = RandInt( 0, probabilitySum )

		--LogService:Log( "base_unit : " .. tostring( self.normalExplodeProbability) .. " " .. tostring( self.leaveBodyProbability ) ) 

		UnitService:SetRandomDeathAnimation( self.entity, self.wreckMinSpeed, "death", self.disallowDeathAnim )

		if ( behaviorNumber >= 0 and behaviorNumber <= BehaviorRange1 and BehaviorRange1 > 0 ) then
			self:CreateNormalExplode()
		elseif (behaviorNumber > BehaviorRange1 or BehaviorRange1 == 0) and behaviorNumber <= BehaviorRange2  then
			EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), self.wreck_type, self.wreckMinSpeed )
		end	
	end
end

function base_unit:ShowVulnerabilitiesMenu(evt)

	local owner = evt:GetOwner()
	if ( owner == nil or owner == INVALID_ID ) then
		return
	end

	local ownerBlueprintName = EntityService:GetBlueprintName( owner )
	if ( ownerBlueprintName ~= "player/character" ) then
		return
	end

	if ( not EntityService:HasComponent(self.entity, "IsVisibleComponent") ) then
		return
	end

	local resistanceComponent = EntityService:GetComponent(self.entity, "ResistanceComponent")
	if ( resistanceComponent == nil ) then
		return
	end

	local resistanceComponentRef = reflection_helper(resistanceComponent)

	--local damageType = evt:GetDamageType()
	--
	--local currentResistance = self:GetResistanceToDamage(damageType, resistanceComponentRef)
	--if ( currentResistance > 1 ) then
	--	return
	--end

	globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

	local blueprintName = EntityService:GetBlueprintName( self.entity )

	local menuBlueprintName = "misc/unit_vulnerabilities_menu"

	local menuEntity = self:FindMenuEntity(menuBlueprintName)

	local vulnerabilities = self:GetVulnerabilities(resistanceComponentRef)

	if ( menuEntity ~= nil ) then

		EntityService:CreateOrSetLifetime( menuEntity, 5.0, "normal" )

		self:SetMenuValues(menuEntity, vulnerabilities)

		globalVulnerabilitiesMenuCache[blueprintName] = menuEntity

	else

		menuEntity = self:GetGlobalMenuEntity(blueprintName)

		if ( menuEntity == nil ) then

			self:CreateVulnerabilitiesMenu(blueprintName, vulnerabilities, menuBlueprintName)
		end
	end
end

function base_unit:CreateVulnerabilitiesMenu(blueprintName, vulnerabilities, menuBlueprintName)

	local team = EntityService:GetTeam( self.entity )
	local menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)

	local sizeSelf = EntityService:GetBoundsSize( self.entity )

	local height = sizeSelf.y

	height = math.min(height, 12)

	EntityService:SetPosition( menuEntity, 0, height, 0 )

	self:SetMenuValues(menuEntity, vulnerabilities)

	globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

	globalVulnerabilitiesMenuCache[blueprintName] = menuEntity
end

function base_unit:GetGlobalMenuEntity(blueprintName)

	globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

	local menuEntity = globalVulnerabilitiesMenuCache[blueprintName]

	if ( menuEntity ~= nil and EntityService:IsAlive( menuEntity ) ) then

		local parent = EntityService:GetParent( menuEntity )

		if ( parent ~= nil and parent ~= INVALID_ID ) then

			if ( EntityService:HasComponent(parent, "IsVisibleComponent") ) then
				return menuEntity
			end
		end
	end

	return nil
end

function base_unit:SetMenuValues(menuEntity, vulnerabilities)

	local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
	if ( menuDB == nil ) then
		return
	end

	menuDB:SetInt("menu_visible", 1)

	local maxMenuDamageLines = 9

	for damageNumber=1,maxMenuDamageLines do

		local slotNumber = tostring(damageNumber)

		menuDB:SetInt("damage_visible_" .. slotNumber, 0)
		menuDB:SetString("damage_type_" .. slotNumber, "")
		menuDB:SetString("damage_name_" .. slotNumber, "")
	end

	local count = math.min(#vulnerabilities, maxMenuDamageLines)

	for damageNumber=1,count do

		local damage = vulnerabilities[damageNumber]

		local name = string.format("%d", damage.current_value * 100) .. "${gui/menu/inventory/units_percent}"

		local slotNumber = tostring(damageNumber)

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

		if ( item.value.current_value ~= 1 ) then
			
			local damage = {}
			damage.type = item.key
			damage.current_value = item.value.current_value

			Insert(result, damage)
		end
	end

	local sorter = function( damage1, damage2 )

		if (damage1.current_value ~= damage2.current_value) then

			return damage1.current_value > damage2.current_value
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

function base_unit:OnLoad()
	if ( self.baseUnitVersion == nil or self.baseUnitVersion < 1 ) then
		self:UnregisterHandler( self.entity, "IdleStateChangedEvent", "_OnIdleStateChanged" )

		if self.soundFSM then
			self:DestroyStateMachine(self.soundFSM)
		end
		
		self.soundFSM = nil
	elseif self.baseUnitVersion < FXSYSTEM_HANDLES_SOUND then
		self:UnregisterHandler( self.entity, "RunningStateChangeEvent", "_OnRunningStateChange" )

		if self.soundFSM then
			self:DestroyStateMachine(self.soundFSM)
		end

		self.soundFSM = nil
	end
	
	if ( self.normalExplodeProbability == nil ) or ( self.leaveBodyProbability == nil ) then
		self.normalExplodeProbability = 1
		self.leaveBodyProbability = 0
	end

	if ( self.disallowDeathAnim == nil ) then
		self.disallowDeathAnim = ""
	end
	
	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION
end

-- LEGACY
function base_unit:_OnRunningStateChange( evt )
end

function base_unit:_OnSoundMoveEnter( state )
end
function base_unit:_OnSoundMoveExit( state )
end

function base_unit:_OnSoundRunEnter( state )
end

function base_unit:_OnSoundRunExit( state )
end
	
return base_unit
