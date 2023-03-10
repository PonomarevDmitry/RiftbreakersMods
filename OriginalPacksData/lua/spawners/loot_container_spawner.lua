require("lua/units/units_utils.lua")
require("lua/utils/table_utils.lua")
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

	local entities = FindService:FindEntitiesByTypeInRadius( self.entity, "prop", 10.0)
	for ent in Iter(entities) do
		EntityService:RemoveEntity( ent )
	end
	
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
end

function loot_container_spawner:OnInteractWithEntityRequest( evt )
	local blueprintName = EntityService:GetBlueprintName(self.entity)
	if string.find(blueprintName, "metallic" ) ~= nil then
		CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_METALLIC_BIOANOMALLY, 1)
	end

	QueueEvent("SpawnFromLootContainerRequest", self.entity, self.rarity )
	QueueEvent("DestroyRequest", self.entity, "default", 100 )
end

function loot_container_spawner:OnHarvestStartEvent( evt )
	if ( self.activated == false ) then
		self.activated = true

		local waveLogic			= self.data:GetStringOrDefault( "wave_logic_file",  "error" )
		local waveLogicMul		= self.data:GetIntOrDefault( "wave_logic_file_mul",  1 )
		local waveSpawnDistance = self.data:GetIntOrDefault( "wave_spawn_distance",  40 )

		if ( ResourceManager:ResourceExists( "FlowGraphTemplate", waveLogic ) ) then
			--LogService:Log( "loot_container_spawner:OnHarvestStartEvent - exist : " .. tostring( waveLogic ) )

			local waveEffect	= self.data:GetStringOrDefault( "wave_started_effect", "" )
			if waveEffect ~= "" then
				EffectService:SpawnEffect(self.entity,waveEffect);
			end

			local spawnPoint = UnitService:CreateDynamicSpawnPoints( self.entity, waveSpawnDistance, waveLogicMul )
		

			for i = 1, #spawnPoint do
				if ( spawnPoint[i] ~= INVALID_ID ) then
					self.data:SetString( "spawn_point", EntityService:GetName( spawnPoint[i] ) )
					MissionService:ActivateMissionFlow( "", waveLogic, "default", self.data )
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

return loot_container_spawner