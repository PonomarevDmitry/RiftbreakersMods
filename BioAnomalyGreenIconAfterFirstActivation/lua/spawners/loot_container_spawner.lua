require("lua/units/units_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
class 'loot_container_spawner' ( LuaEntityObject )

function loot_container_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function loot_container_spawner:init()
	self.rarity = self.data:GetIntOrDefault( "rarity", 0 );
	self.delay = self.data:GetFloatOrDefault( "delay", 0 );
	self.aggressiveRadius = self.data:GetFloatOrDefault( "aggressive_radius", 20 )
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity, "HarvestStartEvent",   "OnHarvestStartEvent" )
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "wait", { from="*", enter="OnEnterWating", exit="OnExitWaiting" } )
	SetupUnitScale( self.entity, self.data )
	
	EntityService:SetGroup( self.entity, "loot_container");

	self.activated = false
end

function loot_container_spawner:OnLoad()
	
	--LogService:Log( "loot_container_spawner:OnLoad" )	

	if ( self.activated == nil ) then
		self.activated = false
	end

	if ( self.aggressiveRadius == nil ) then
		self.aggressiveRadius = self.data:GetFloatOrDefault( "aggressive_radius", 20 )
	end

	if (self.activated == true) then

		local forcedGroup = self.data:GetStringOrDefault( "forced_group", "" ) or ""
		if ( forcedGroup == "" ) then

			self:CreateMinimapIconEntity()
		end
	end
end

function loot_container_spawner:OnInteractWithEntityRequest( evt )

	local blueprintName = EntityService:GetBlueprintName(self.entity)
	if string.find(blueprintName, "metallic" ) ~= nil then
		CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_METALLIC_BIOANOMALLY, 1)
	elseif string.find(blueprintName, "caverns" ) ~= nil then
		CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_CAVERNS_BIOANOMALLY, 1)
	elseif string.find(blueprintName, "poogret_poo" ) ~= nil then
		CampaignService:UpdateAchievementProgress(ACHIEVEMENT_COLLECT_RESOURCES_FROM_POO, 1)
	end

	local owner = evt:GetOwner()
	local playerReferenceComponent = EntityService:GetComponent( owner, "PlayerReferenceComponent")
	if ( playerReferenceComponent ) then
		local forcedGroup = self.data:GetStringOrDefault( "forced_group", "" )
		if ( forcedGroup ~= "" ) then
			QueueEvent("ForceLootContainerTypeRequest", self.entity,	forcedGroup )
		end

		local helper = reflection_helper(playerReferenceComponent)
		QueueEvent("SpawnFromLootContainerRequest", self.entity, self.rarity, helper.player_id )
	end
	QueueEvent("DestroyRequest", self.entity, "default", 100 )
	
	local params = { target = tostring( EntityService:GetName( self.entity ) ) }
	QueueEvent( "LuaGlobalEvent", event_sink, "BioanomalyClose", params )
end

function loot_container_spawner:OnHarvestStartEvent( evt )
	if ( self.activated == false ) then
		self.activated = true

		local forcedGroup = self.data:GetStringOrDefault( "forced_group", "" ) or ""
		if ( forcedGroup == "" ) then
			self:CreateMinimapIconEntity()
		end

		local waveLogic			= self.data:GetStringOrDefault( "wave_logic_file",  "error" )
		local waveLogicMul		= self.data:GetIntOrDefault( "wave_logic_file_mul",  1 )
		local waterOverride		= self.data:GetIntOrDefault( "water_override", 0 )
		local waveSpawnDistance = self.data:GetIntOrDefault( "wave_spawn_distance",  40 )

		local ignoreWater = false

		if ( waterOverride == 1 ) then
			ignoreWater = true
		end

		if ( ResourceManager:ResourceExists( "FlowGraphTemplate", waveLogic ) ) then
			--LogService:Log( "loot_container_spawner:OnHarvestStartEvent - exist : " .. tostring( waveLogic ) )

			local waveEffect	= self.data:GetStringOrDefault( "wave_started_effect", "" )
			if waveEffect ~= "" then
				EffectService:SpawnEffect(self.entity,waveEffect);
			end

			EntityService:SpawnEntity( "items/consumables/radar_pulse", self.entity, "" )

			local spawnPoint = UnitService:CreateDynamicSpawnPoints( self.entity, waveSpawnDistance, waveLogicMul, ignoreWater )
			local params = { target = tostring( EntityService:GetName( self.entity ) ) }
			QueueEvent( "LuaGlobalEvent", event_sink, "BioanomalyOpen", params )

			for i = 1, #spawnPoint do
				if ( spawnPoint[i] ~= INVALID_ID ) then
					self.data:SetString( "spawn_point", EntityService:GetName( spawnPoint[i] ) )
					MissionService:ActivateMissionFlow( "", waveLogic, "default", self.data )

					local pathCleaner = EntityService:SpawnEntity( "misc/path_cleaner", self.entity, "" )
					local db = EntityService:GetDatabase( pathCleaner )			
					db:SetString( "to_entity", tostring( spawnPoint[i] ) )
					db:SetString( "from_entity", tostring( self.entity ) )

				else
					LogService:Log( "loot_container_spawner:OnHarvestStartEvent - could not create a spawn point." )
				end
			end
		else
			LogService:Log( "loot_container_spawner:OnHarvestStartEvent - file does not exist : " .. tostring( waveLogic ) )
		end

		if ( self.delay > 0) then
			local entity = EntityService:SpawnEntity( "props/special/loot_containers/loot_container_delayer", self.entity, "")
			local db = EntityService:GetDatabase( entity )
			db:SetFloat( "delay", self.delay )
			db:SetFloat( "aggressive_radius", self.aggressiveRadius )
		else
			EntityService:MarkEntityAsLootContainer( self.entity, self.rarity )
		end
	else
		--LogService:Log( "loot_container_spawner:OnHarvestStartEvent - already activated." )
	end
end

function loot_container_spawner:CreateMinimapIconEntity()

	local markerBlueprintName = "misc/loot_container_spawner_opened_marker"

	local children = EntityService:GetChildren( self.entity, true )
	for child in Iter(children) do
		local blueprintName = EntityService:GetBlueprintName( child )
		if ( blueprintName == markerBlueprintName and EntityService:GetParent( child ) == self.entity ) then

			return
		end
	end

	local team = EntityService:GetTeam( self.entity )
	EntityService:SpawnAndAttachEntity( markerBlueprintName, self.entity, team )
end

function loot_container_spawner:OnTimerElapsedEvent(evt)
end

return loot_container_spawner