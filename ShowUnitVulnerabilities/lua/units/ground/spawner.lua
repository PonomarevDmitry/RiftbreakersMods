require("lua/units/units_utils.lua")
require("lua/utils/reflection.lua")

class 'spawner' ( LuaEntityObject )

globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

function spawner:__init()
	LuaEntityObject.__init(self, self)
end

function spawner:init()
	self:RegisterHandler( self.entity, "DestroyRequest",	  "OnDestroyRequest" )
	self:RegisterHandler( self.entity, "SpawnerInfoRequest",  "OnSpawnerInfoRequest" )
	self:RegisterHandler( self.entity, "DamageEvent",  "_OnDamageEvent" )

	local currentDifficulty = DifficultyService:GetCurrentDifficultyName()

	local bpName = UnitSpawnerService:GetSpawnBlueprintName( self.entity )
	local bpNameAlpha = bpName .. "_alpha"
	local bpNameUltra = bpName .. "_ultra"

	if ( ( currentDifficulty == "hard" ) and ( EntityService:IsBlueprintExist( bpNameAlpha ) == true ) ) then
		UnitSpawnerService:ReplaceSpawnBlueprint( self.entity, bpNameAlpha )
	elseif ( (  currentDifficulty == "brutal" ) and ( EntityService:IsBlueprintExist( bpNameUltra ) == true ) ) then
		UnitSpawnerService:ReplaceSpawnBlueprint( self.entity, bpNameUltra )
	end
end

function spawner:OnDestroyRequest( evt )
	AnimationService:StopAnim( self.entity , "working" )	
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), "wreck_big", 0 )
end

function spawner:OnSpawnerInfoRequest( evt )
	SoundService:PlayAnnouncement( "voice_over/announcement/warning_nest_wave_spawn", 20 )
end

function spawner:_OnDamageEvent( evt )
	if not evt:GetDamageOverTime() then 
		self:ShowVulnerabilitiesMenu(evt)
	end
end

function spawner:ShowVulnerabilitiesMenu(evt)

	local owner = evt:GetOwner()
	if ( owner == nil or owner == INVALID_ID ) then
		return
	end

	local ownerBlueprintName = EntityService:GetBlueprintName( owner )
	if ( ownerBlueprintName ~= "player/character" ) then
		return
	end

	if ( EntityService:GetComponent(self.entity, "IsVisibleComponent") == nil ) then
		return
	end

	local resistanceComponent = EntityService:GetComponent(self.entity, "ResistanceComponent")
	if ( resistanceComponent == nil ) then
		return
	end

	local resistanceComponentRef = reflection_helper(resistanceComponent)

	local damageType = evt:GetDamageType()

	local currentResistance = self:GetResistanceToDamage(damageType, resistanceComponentRef)
	if ( currentResistance > 1 ) then
		return
	end

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

function spawner:CreateVulnerabilitiesMenu(blueprintName, vulnerabilities, menuBlueprintName)

	local team = EntityService:GetTeam( self.entity )
	local menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)

	local sizeSelf = EntityService:GetBoundsSize( self.entity )
	EntityService:SetPosition( menuEntity, 0, sizeSelf.y, 0 )

	self:SetMenuValues(menuEntity, vulnerabilities)

	globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

	globalVulnerabilitiesMenuCache[blueprintName] = menuEntity
end

function spawner:GetGlobalMenuEntity(blueprintName)

	globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

	local menuEntity = globalVulnerabilitiesMenuCache[blueprintName]

	if ( menuEntity ~= nil and EntityService:IsAlive( menuEntity ) ) then

		local parent = EntityService:GetParent( menuEntity )

		if ( parent ~= nil and parent ~= INVALID_ID ) then

			if ( EntityService:GetComponent(parent, "IsVisibleComponent") ~= nil ) then
				return menuEntity
			end
		end
	end

	return nil
end

function spawner:SetMenuValues(menuEntity, vulnerabilities)

	local menuDB = EntityService:GetDatabase( menuEntity )
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

function spawner:FindMenuEntity(menuBlueprintName)

	local children = EntityService:GetChildren( self.entity, true )

	for child in Iter(children) do
		local blueprintName = EntityService:GetBlueprintName( child )
		if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

			return child
		end
	end

	return nil
end

function spawner:GetVulnerabilities(resistanceComponentRef)

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

function spawner:GetResistanceToDamage(damageType, resistanceComponentRef)

	local resistances = resistanceComponentRef.resistances

	for i=1,resistances.count do
		local item = resistances[i]

		if ( item.key == damageType ) then
			return item.value.current_value
		end
	end
	
	return 1
end

return spawner