require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local event_manager = require( "lua/missions/v2/event_manager.lua" )

class 'dom_mananger' ( event_manager )

function dom_mananger:__init()
    event_manager.__init(self, self)
end

function dom_mananger:init()

	-- ========================================= Configuration ======================================

	LogService:Log( "dom_mananger: ------- DOM MANAGER VER 2.0 ------- " )

	event_manager.init( self )

	-- borderSpawnPointsByDirection : can be more/less
	self.borderSpawnPointGroupNames =
	{
		"spawn_enemy_border_south",
		"spawn_enemy_border_north",
		"spawn_enemy_border_east",
		"spawn_enemy_border_west"
	}

	-- ======================================== DO NOT TOUCH BELOW THE FILE ============================================

	self.DOMEventName_FinishSurvival			= "FinishSurvival"
	self.DOMEventName_PauseDOM					= "PauseDOM"
	self.DOMEventName_ResumeDOM					= "ResumeDOM"
	self.DOMEventName_DOMMaxDifficultyLevel		= "DOMMaxDifficultyLevel"
	self.DOMEventName_DOMResumeAttacks			= "DOMResumeAttacks"
	self.DOMEventName_DOMPauseAttacks			= "DOMPauseAttacks"
	self.DOMEventName_DOMCancelUpcomingAttack	= "DOMCancelUpcomingAttack"
	self.DOMEventName_DOMForceGroupNextAttack	= "DOMForceGroupNextAttack"
	self.DOMEventName_DOMAddAttackGroup			= "DOMAddAttackGroup"
	self.DOMEventName_DOMRemoveAttackGroup		= "DOMRemoveAttackGroup"
	self.DOMEventName_DOMSendMajorAttack		= "DOMSendMajorAttack"

	self.DOMEventName_dump_dom_data				= "dump_dom_data"

	self.defaultAttackGroupName = "default"

	self:RegisterHandler( event_sink, "MissionFlowDeactivatedEvent",   "OnMissionFlowDeactivatedEvent" )
	self:RegisterHandler( event_sink, "MissionFlowActivatedEvent",     "OnMissionFlowActivatedEvent" )
	self:RegisterHandler( event_sink, "BuildingStartEvent",        	   "OnBuildingStartEvent" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent",       		   "OnLuaGlobalEvent" )
	self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
	self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )

    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { enter="OnEnterSpawn", execute="OnExecuteSpawn", exit= "OnExitSpawn" } )
	self.spawner:AddState( "wait", { enter="OnEnterWait", exit= "OnExitWait" } )
	self.spawner:AddState( "cooldown_after_spawn", { enter="OnEnterCooldownAfterSpawnTime", execute="OnExecuteCooldownAfterSpawnTime", exit= "OnExitCooldownAfterSpawnTime" } )
	self.spawner:AddState( "prepare_spawn", { enter="OnEnterPrepareSpawn", execute="OnExecutePrepareSpawn", exit= "OnExitPrepareSpawn" } )
	self.spawner:AddState( "idle", { enter="OnEnterIdle", execute="OnExecuteIdle", exit= "OnExitIdle" } )
	self.spawner:AddState( "streaming", { enter="OnEnterStreaming", execute="OnExecuteStreaming", exit= "OnExitStreaming" } )
	self.spawner:AddState( "sleep", { enter="OnEnterSleep", execute="OnExecuteSleep", exit= "OnExitSleep" } )
	self.spawner:AddState( "dummy_state", { enter="OnEnterDummyState", execute="OnExecuteDummyState", exit= "OnEnterDummyState" } )

	self.upgradeHQ = self:CreateStateMachine()
	self.upgradeHQ:AddState( "hq_entry_logic", { enter="OnHqEnterEntryLogic", exit= "OnHqExitEntryLogic" } )
	self.upgradeHQ:AddState( "hq_attack_logic", { enter="OnHqEnterAttackLogic", execute="OnExecuteAttackLogic", exit= "OnHqExitAttackLogic" } )
	self.upgradeHQ:AddState( "hq_exit_logic", { enter="OnHqEnterExitLogic", exit= "OnHqExitExitLogic" } )

	self.difficultyIncrease = self:CreateStateMachine()
	self.difficultyIncrease:AddState( "difficulty_increase", { enter="OnEnterDifficultyIncrease", exit= "OnExitDifficultyIncrease" } )

	self.currentDifficultyLevel = 0
	self.maxDifficultyLevel     = 9

	self.spawnedAttacks		= {}

	self.randomNumber			   = 0

	self.objectivePrepareForTheAttacLogicFileName		= "objectivePrepareForTheAttacLogicFileName"
	self.objectivePrepareForTheAttacLogicFile			= "logic/missions/survival/next_attack_in.logic" -- TODO

	self.preparedAttacks = {}
	self.preparedAttackMarkers = {}

	self.hqPreparedAttacks				= {}
	self.hqPreparedAttackMarkers		= {}
	self.hqLogicLevel					= {}
	self.upgradeHqWaves					= {}
	self.onUpgradeHqLogicEndFileName	= ""
	self.hqAttackSafeTime				= 600

	self.sleepSafeTime = 1200

	self.dumpAllDifficultyInfo = true

	self.freezedDifficultyLevel = self.maxDifficultyLevel

	self.pauseAttacks = DifficultyService:AreWavesDisabled()

	if ( self.pauseAttacks == false ) then
		self.pauseAttacks = self.rules.pauseAttacks
	end

	local currentDifficulty = DifficultyService:GetCurrentDifficultyName()

	if ( currentDifficulty == "sandbox" ) then
		LogService:Log( "dom_mananger: sandbox mode on - pausing attacks." )	
		self.pauseAttacks = true
	end

	self.isForceAttackGroupEnabled = false
	self.forceAttackGroupName	   = self.defaultAttackGroupName

	self.availableAttackGroups = {}

	self.availableAttackGroups[#self.availableAttackGroups + 1] = self.defaultAttackGroupName
	self:LogicFilesSanityCheck();

end

function dom_mananger:Update()
	if event_manager.Update then
		event_manager.Update(self)
	end

	if not g_debug_dom_manager then
		return
	end

	local debug = "DEBUG DOM MANAGER:"
	debug = debug .. "\n"

	local difficultyState = self.difficultyIncrease:GetCurrentState()
	if difficultyState ~= "" then
		local state = self.difficultyIncrease:GetState( difficultyState )

		debug = debug .. " Current difficulty level: " .. tostring( self.currentDifficultyLevel ) .. "\n"
		debug = debug .. " Max difficulty level : " .. tostring( self.freezedDifficultyLevel ) .. "\n"
		debug = debug .. " Time to next difficulty level : " .. tostring( state:GetDurationLimit() - state:GetDuration() )
	end

	debug = debug .. "\n\n"

	local currentSpawnerState = self.spawner:GetCurrentState()
	if currentSpawnerState ~= "" then
		debug = debug .. "GLOBAL DOM STATE \n"
		debug = debug .. " " .. currentSpawnerState .. "\n"

		local state = self.spawner:GetState( currentSpawnerState )

		if ( currentSpawnerState == "wait" ) then
			debug = debug .. " Time left: " .. tostring( state:GetDurationLimit() - state:GetDuration() )
		elseif ( currentSpawnerState == "cooldown_after_spawn" ) then
			debug = debug .. " Time left: " .. tostring( self.cooldownTimer )
		elseif ( currentSpawnerState == "prepare_spawn" ) then
			debug = debug .. " Time left: " .. tostring( self.waitForSpawnTimer )
		elseif ( currentSpawnerState == "idle" ) then
			debug = debug .. " Time left: " .. tostring( self.idleTimer )
		elseif ( currentSpawnerState == "sleep" ) then
			debug = debug .. " Time left: " .. tostring( self.sleepSafeTime )
		end
	end



	LogService:DebugText( 50, 1000, debug);
end

function dom_mananger:OnLoad()
	LogService:Log( "dom_mananger:OnLoad" )

	if ( self.rulesFile ~= nil ) then
		LogService:Log( "dom_mananger:OnLoad - reloading rules." )

		local rulesOldPath = self.rulesFile
		local currentDifficultyName = DifficultyService:GetCurrentDifficultyName() 

		LogService:Log( "dom_mananger:OnLoad() : rules file path : " .. rulesOldPath )
		LogService:Log( "dom_mananger:OnLoad() : difficulty : " .. currentDifficultyName )

		local rulesOldPathTable = Split( rulesOldPath, "_" )
		local rulesCheckNewPath = ""

		for i = 1, #rulesOldPathTable - 1, 1 do 
			rulesCheckNewPath = rulesCheckNewPath .. rulesOldPathTable[i] .. "_"
		end
		
		rulesCheckNewPath = rulesCheckNewPath .. currentDifficultyName .. ".lua"

		LogService:Log( "dom_mananger:OnLoad - checking if there is a new rule : " .. rulesCheckNewPath )

		if ( rulesCheckNewPath ~= rulesOldPath ) then
			LogService:Log( "dom_mananger:OnLoad - old rules don't match difficulty level. Searching if new one exist" )
			if ( script_exists( rulesCheckNewPath ) == true ) then
				LogService:Log( "dom_mananger:OnLoad - new rules exist. Reloading." )
				self.rulesFile = rulesCheckNewPath
			else
				LogService:Log( "dom_mananger:OnLoad - new rules don't exist" )
			end
		else
			LogService:Log( "dom_mananger:OnLoad - old rules match. Nothing to load." )
		end
		
		self.rules = require( self.rulesFile )()
	end

	LogService:Log( "dom_mananger:OnLoad - current hq state : " .. tostring( self.upgradeHQ:GetCurrentState() ) )
	LogService:Log( "dom_mananger:OnLoad - current dom state : " .. tostring( self.spawner:GetCurrentState() ) )

	self:LogicFilesSanityCheck();

	self:FillInitialParamsEventManager()
end

function dom_mananger:FillInitialParamsDomManager()

end

	-- ======================================== LOGIC ============================================

function dom_mananger:LogicFilesSanityCheck()

	LogService:Log( "dom_mananger: ------- LogicFilesSanityCheck ------- " )

	local failedLogicFile = {}

	self:LogicEntryTableCheck( self.rules.buildingsUpgradeStartsLogic, "rules.buildingsUpgradeStartsLogic : ", failedLogicFile )
	self:LogicEntryTableCheck( self.rules.majorAttackLogic, "rules.majorAttackLogic : ", failedLogicFile )

	for data in Iter( self.rules.objectivesLogic ) do 

		if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data.name ) ) then
			local log = "rules.objectivesLogic : " .. data.name

			table.insert( failedLogicFile, log )
			log = log .. " NOT EXIST"
			LogService:Log( log )
		end
	end

	for data in Iter( self.rules.wavesEntryDefinitions ) do
		if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data ) ) then
			local log = "rules.wavesEntryDefinitions : " .. data

			table.insert( failedLogicFile, log )
			log = log .. " NOT EXIST"			
			LogService:Log( log )
		end

	end


	if ( self.rules.prepareAttackDefinitions ~= nil ) then

		if ( #self.rules.prepareAttackDefinitions ~= self.maxDifficultyLevel ) then
			Assert( false, "rules.prepareAttackDefinitions : size must equal " .. tostring( self.maxDifficultyLevel ) )
		end

		for data in Iter( self.rules.prepareAttackDefinitions ) do

			if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data ) ) then
				local log = "rules.prepareAttackDefinitions : " .. data

				table.insert( failedLogicFile, log )
				log = log .. " NOT EXIST"			
				LogService:Log( log )
			end	
		end
	end

	for group, groupData in pairs( self.rules.waves ) do

		LogService:Log( "rules.waves : " .. tostring( group ) )

		if ( #groupData ~= 0 ) then

			if ( #groupData ~= self.maxDifficultyLevel ) then
				Assert( false, "rules.waves : " .. tostring( group ) .. " size must equal " .. tostring( self.maxDifficultyLevel ) )
			end

			for i = 1, self.maxDifficultyLevel, 1 do 
				for data in Iter( groupData[i] ) do 

					if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data ) ) then
						local log = "rules.waves" .. " " .. tostring( i ) .. " : " .. data
						table.insert( failedLogicFileTable, log )
						log = log .. " NOT EXIST"			
						LogService:Log( log )
					end

				end
			end
		end
	end

	self:LogicTableCheck( self.rules.extraWaves, "rules.extraWaves", failedLogicFile )
	self:LogicTableCheck( self.rules.bosses, "rules.bosses", failedLogicFile )


	if ( #failedLogicFile > 0 ) then
		local log = ""
		for data in Iter( failedLogicFile ) do 
			log = log .. data .. " "
		end

		Assert( false, "Logic files don't exist : " .. log )
	end
end

function dom_mananger:LogicTableCheck( logicTable, logString, failedLogicFileTable )

	if ( #logicTable ~= 0 ) then		
		if ( #logicTable ~= self.maxDifficultyLevel ) then
			Assert( false, logString .. " size must equal " .. tostring( self.maxDifficultyLevel ) )
		end

		for i = 1, self.maxDifficultyLevel, 1 do 
			for data in Iter( logicTable[i] ) do 
				if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data ) ) then
					local log = logString .. " " .. tostring( i ) .. " : " .. data
					table.insert( failedLogicFileTable, log )
					log = log .. " NOT EXIST"			
					LogService:Log( log )
				end
			end
		end
	end
end

function dom_mananger:LogicEntryTableCheck( logicTable, logString, failedLogicFileTable )
	
	if ( logicTable ~= nil ) then
		for data in Iter( logicTable ) do 

			if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data.entryLogic ) ) then
				local log = logString .. data.entryLogic
				table.insert( failedLogicFile, log )
				log = log .. " NOT EXIST"
				LogService:Log( log )
			end

		end

		for data in Iter( logicTable ) do 
			if ( not ResourceManager:ResourceExists( "FlowGraphTemplate", data.exitLogic ) ) then
				local log = logString .. data.exitLogic
				table.insert( failedLogicFile, log )
				log = log .. " NOT EXIST"
				LogService:Log( log )
			end
		end
	end
end

function dom_mananger:OnLuaGlobalEvent( evt )
	
	local eventName = evt:GetEvent()
	local params = evt:GetDatabase()

	if ( eventName == self.DOMEventName_FinishSurvival ) then
		LogService:Log( "dom_mananger:OnLuaGlobalEvent : forced closed" )
		self:CloseStream()
		self:ClosePrepareForTheAttack()
		self:SetSuspended( true )
		CampaignService:OperateDOMPlanetaryJump( true )
	elseif ( eventName == self.DOMEventName_PauseDOM ) then
		self:PauseDOM()
	elseif ( eventName == self.DOMEventName_ResumeDOM ) then
		self:ResumeDOM()
	elseif ( eventName == self.DOMEventName_DOMMaxDifficultyLevel ) then
		self:SetMaxDifficultyLevel( params:GetIntOrDefault( "max_dom_difficulty_level", self.maxDifficultyLevel ) )
	elseif ( eventName == self.DOMEventName_DOMResumeAttacks ) then
		self:ResumeAttacks()
	elseif ( eventName == self.DOMEventName_DOMPauseAttacks ) then
		self:PauseAttacks()
	elseif ( eventName == self.DOMEventName_DOMCancelUpcomingAttack ) then
		self:CancelUpcomingAttack()
	elseif ( eventName == self.DOMEventName_DOMForceGroupNextAttack ) then
		self:ForceGroupNextAttack( params:GetStringOrDefault( "group_name", "default" ) )
	elseif ( eventName == self.DOMEventName_DOMAddAttackGroup ) then
		self:AddAttackGroup( params:GetStringOrDefault( "group_name", "default" ) )
	elseif ( eventName == self.DOMEventName_DOMRemoveAttackGroup ) then
		self:RemoveAttackGroup( params:GetStringOrDefault( "group_name", "default" ) )
	elseif ( eventName == self.DOMEventName_dump_dom_data ) then
		self:DumpDomData()
	elseif ( eventName == self.DOMEventName_DOMSendMajorAttack ) then
		self:SendMajorAttack()
	end
end

function dom_mananger:DumpDomProgress( rules )
	LogService:Log( "dom_mananger:prepare attacks : " .. tostring( rules.prepareAttacks ) )
	
	local difficultyData = {}
	for i = 1, self.maxDifficultyLevel, 1 do 
		difficultyData[i] = {}
		difficultyData[i].level = i
		difficultyData[i].maxTime  = rules.timeToNextDifficultyLevel[i]
		difficultyData[i].minTime = 0

		if ( difficultyData[i].level > 1 ) then
			difficultyData[i].maxTime = difficultyData[i].maxTime + difficultyData[i-1].maxTime
			difficultyData[i].minTime = difficultyData[i-1].maxTime
		end
	end

	for i = 1, #difficultyData, 1 do 
		LogService:Log( "dom_mananger:difficultyData : " .. tostring( difficultyData[i].level ) .. " " .. tostring( difficultyData[i].minTime ) .. "-" .. tostring( difficultyData[i].maxTime ) )
	end

	
	local attackCounter = 1
	local difficultyLevel = 1
	local attackTime = 0
	local prepareAttackTime = 0

	if ( self.pauseAttacks == false ) then
		LogService:Log( "dom_mananger:Attack number : 1 Time : 0 Difficulty level : 1 ");

		for i = 2, 20, 1 do
		
			
			difficultyLevel = self:GetDifficultyLevelFromTime( attackTime, difficultyData )
			attackTime = attackTime + rules.cooldownAfterAttacks[difficultyLevel]
			prepareAttackTime = attackTime
			difficultyLevel = self:GetDifficultyLevelFromTime( attackTime, difficultyData )
			attackTime = attackTime + rules.idleTime[difficultyLevel]
			prepareAttackTime = attackTime

			if ( rules.prepareAttacks == true ) then
				difficultyLevel = self:GetDifficultyLevelFromTime( attackTime, difficultyData )
			end

			attackTime = attackTime + rules.prepareSpawnTime[difficultyLevel]

			if ( rules.prepareAttacks == false ) then
				difficultyLevel = self:GetDifficultyLevelFromTime( attackTime, difficultyData )
				prepareAttackTime = attackTime
			end

			LogService:Log( "dom_mananger:Attack number : " .. tostring( i ) .. " Prepare time " .. tostring( prepareAttackTime ) ..  " Attack time : " .. tostring( attackTime ) ..
							"  Difficulty level : ".. tostring( difficultyLevel ) );

			if ( rules.prepareAttacks == true ) then
				prepareAttackTime = attackTime
			end
		 
		end
	else
		LogService:Log( "dom_mananger:No attacks.");
	end
end

function dom_mananger:DumpDomData()
	LogService:Log( "dom_mananger:DumpDomData" )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : current difficulty level - " .. tostring( self.currentDifficultyLevel ) )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : max difficulty level - " .. tostring( self.maxDifficultyLevel ) )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : current freezed difficulty level - " .. tostring( self.freezedDifficultyLevel ) )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : base time between objectives - " .. tostring( self.objectiveBaseTimeBetweenNext ) )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : difficulty - " .. DifficultyService:GetCurrentDifficultyName() )

	local domType = "error"
	local idleTime = self:GetIdleTime()

	if ( ( self.pauseAttacks == true ) and ( idleTime > 0 ) ) then
		domType = "scout"
	elseif ( ( self.pauseAttacks == true ) and ( idleTime == 0 ) ) then
		domType = "sandbox"
	elseif ( idleTime == 0 ) then
		domType = "survival"
	else
		domType = "HQ/Outpost"
	end

	LogService:Log( "dom_mananger:dom type: " .. domType )

	local rulesOldPathTable = Split( self.rulesFile, "_" )
	local rulesCheckNewPath = ""

	for i = 1, #rulesOldPathTable - 1, 1 do 
		rulesCheckNewPath = rulesCheckNewPath .. rulesOldPathTable[i] .. "_"
	end

	local difficultyName = 
	{
		"default",
		"easy",
		"normal",
		"hard",
		"brutal",
    }

	if ( self.dumpAllDifficultyInfo == true ) then
		for i = 1, #difficultyName, 1 do
			local path = rulesCheckNewPath .. difficultyName[i] .. ".lua"
			if ( script_exists( path ) == true ) then
				LogService:Log( "dom_mananger:difficulty: " .. difficultyName[i] )
				self:DumpDomProgress( require( path )() )
			else
				LogService:Log( "dom_mananger:difficulty: " .. difficultyName[i] .. " the same as default" )
			end
		end
	else
		self:DumpDomProgress( self.rules )
	end
end

function dom_mananger:GetDifficultyLevelFromTime( time, difficultyData )
	for i = 1, #difficultyData, 1 do
		if ( time < difficultyData[i].maxTime ) then
			return difficultyData[i].level
		end
	end

	return self.maxDifficultyLevel
end

function dom_mananger:SendMajorAttack()
	LogService:Log( "dom_mananger:SendMajorAttack" )

	if ( ( self.rules.majorAttackLogic ~= nil ) and ( #self.rules.majorAttackLogic > 0 ) ) then
		LogService:Log( "dom_mananger:SendMajorAttack - ready." )
		
		self:SetSuspended( false )

		self.hqLogicLevel.level       = self.rules.majorAttackLogic[1].level
		self.hqLogicLevel.prepareTime = self.rules.majorAttackLogic[1].prepareTime
		self.hqLogicLevel.entryLogic  = self.rules.majorAttackLogic[1].entryLogic
		self.hqLogicLevel.exitLogic   = self.rules.majorAttackLogic[1].exitLogic
		
		if ( self.rules.majorAttackLogic[1].minLevel ~= nil ) then
			LogService:Log( "dom_mananger:SendMajorAttack - min difficulty level set to " .. tostring( self.rules.majorAttackLogic[1].minLevel ) )
			self.hqLogicLevel.minLevel    = self.rules.majorAttackLogic[1].minLevel
		end

		self:ClosePrepareForTheAttack();

		self.upgradeHQ:ChangeState( "hq_entry_logic" )
		self.spawner:ChangeState( "sleep" )
	else
		LogService:Log( "dom_mananger:SendMajorAttack - rules.majorAttackLogic has no entry." )
	end
end

function dom_mananger:IsGroupWaveExist( groupName )
	for group, groupData in pairs( self.rules.waves ) do
		 if ( groupName == group ) then
			return true
		 end
	end

	return false
end

function dom_mananger:IsAvailableAttackGroupExist( groupName )
	for i = 1, #self.availableAttackGroups, 1 do 
		 if ( groupName == self.availableAttackGroups[i] ) then
			return true
		 end
	end

	return false
end

function dom_mananger:ForceGroupNextAttack( groupName )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMForceGroupNextAttack : " .. tostring( groupName ) )

	if ( self:IsGroupWaveExist( groupName ) == true ) then
		self.isForceAttackGroupEnabled = true
		self.forceAttackGroupName	   = groupName
		
		LogService:Log( "dom_mananger:ForceGroupNextAttack : success - setting next attack to: " .. tostring( groupName ) )
	else
		LogService:Log( "dom_mananger:ForceGroupNextAttack : failed : " .. tostring( groupName ) .. " does not exist in rules.waves" )
	end
end

function dom_mananger:AddAttackGroup( groupName )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMAddAttackGroup : " .. tostring( groupName ) )

	if ( self:IsGroupWaveExist( groupName ) == true ) then
		if ( self:IsAvailableAttackGroupExist( groupName ) == false ) then
			LogService:Log( "dom_mananger:AddAttackGroup : success - adding to the wave pool : " .. tostring( groupName ) )
			self.availableAttackGroups[#self.availableAttackGroups + 1] = groupName
		else
			LogService:Log( "dom_mananger:AddAttackGroup : already added : " .. tostring( groupName ) )
		end		
	else
		LogService:Log( "dom_mananger:AddAttackGroup : failed : " .. tostring( groupName ) .. " does not exist in rules.waves" )
	end

end

function dom_mananger:RemoveAttackGroup( groupName )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMRemoveAttackGroup : " .. tostring( groupName ) )

	if ( self:IsGroupWaveExist( groupName ) == true ) then
		if ( self:IsAvailableAttackGroupExist( groupName ) == true ) then
			LogService:Log( "dom_mananger:RemoveAttackGroup : success - removing from the wave pool: " .. tostring( groupName ) )
			
			for i = 1, #self.availableAttackGroups, 1 do 
				if ( groupName == self.availableAttackGroups[i] ) then
					table.remove( self.availableAttackGroups, i )
					break
				end
			end

		else
			LogService:Log( "dom_mananger:RemoveAttackGroup : not exist in the wave pool : " .. tostring( groupName ) )
		end		
	else
		LogService:Log( "dom_mananger:RemoveAttackGroup : failed : " .. tostring( groupName ) .. " does not exist in rules.waves" )
	end
end

function dom_mananger:PauseDOM()
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_PauseDOM" )
	self:SetSuspended( true )
	CampaignService:OperateDOMPlanetaryJump( true )
end

function dom_mananger:ResumeDOM()
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_ResumeDOM" )
	self:SetSuspended( false )
end

function dom_mananger:CancelUpcomingAttack()
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMCancelUpcomingAttack" )
	self.cancelTheAttack = true
	self:ClosePrepareForTheAttack()
end


function dom_mananger:PauseAttacks()
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : pausing attacks" )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMPauseAttacks" )
end

function dom_mananger:ResumeAttacks()
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : resuming attacks" )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : DOMEventName_DOMPauseAttacks" )
end

function dom_mananger:SetMaxDifficultyLevel( maxDifficultyLevel )
	maxDifficultyLevel = Clamp( maxDifficultyLevel, 1, self.maxDifficultyLevel )

	LogService:Log( "dom_mananger:OnLuaGlobalEvent : changing max difficulty level" )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : current freezed difficulty level - " .. tostring( self.freezedDifficultyLevel ) )
	LogService:Log( "dom_mananger:OnLuaGlobalEvent : current difficulty level - " .. tostring( self.currentDifficultyLevel ) )

	self.freezedDifficultyLevel = maxDifficultyLevel

	LogService:Log( "dom_mananger:OnLuaGlobalEvent : changed freezed difficulty level - " .. tostring( self.freezedDifficultyLevel ) )

	if ( self.currentDifficultyLevel > self.freezedDifficultyLevel ) then
		LogService:Log( "dom_mananger:OnLuaGlobalEvent : current difficulty level is higher than freezed one." )

		self.currentDifficultyLevel = self.freezedDifficultyLevel

		LogService:Log( "dom_mananger:OnLuaGlobalEvent : current difficulty level is - " .. tostring( self.currentDifficultyLevel ) )
	end

	if ( self.currentEventLevel > self.freezedDifficultyLevel ) then
		LogService:Log( "dom_mananger:OnLuaGlobalEvent : current event level is higher than freezed one." )

		self.currentEventLevel = self.freezedDifficultyLevel

		LogService:Log( "dom_mananger:OnLuaGlobalEvent : current event level is - " .. tostring( self.currentEventLevel ) )
	end
end

function dom_mananger:ClosePrepareForTheAttack()
	LogService:Log( "dom_mananger:ClosePrepareForTheAttack : trying to close prepare fo the attack timer" )

	if ( MissionService:IsGraphActive( self.objectivePrepareForTheAttacLogicFileName ) == true ) then
		LogService:Log( "dom_mananger:ClosePrepareForTheAttack : is active - MissionService:DeactivateMissionFlow" )
		MissionService:DeactivateMissionFlow( self.objectivePrepareForTheAttacLogicFileName )
	end

	for data in Iter( self.preparedAttackMarkers ) do 
		if EntityService:IsAlive( data ) then
			EntityService:RemoveEntity( data )

			LogService:Log( "dom_mananger:Removing SpawnWaveIndicator : " .. tostring( data ) )

		end
	end

	self.preparedAttackMarkers = {}

	CampaignService:OperateDOMPlanetaryJump( true )
end

function dom_mananger:OnBuildingStartEvent( evt )
	
	local isUpgrading = evt:GetUpgrading();
	if ( isUpgrading == false ) then
		return
	end
	
	local buildingName = BuildingService:GetBuildingName( evt:GetEntity() );
	local upgradeTime = BuildingService:CalculateBuildTime( evt:GetEntity() )

	--LogService:Log( "dom_mananger:Upgrading building : " .. buildingName .. " in time " .. tostring( upgradeTime ) )

	for i = 1, #self.rules.buildingsUpgradeStartsLogic, 1 do 
		--LogService:Log( "Compare : " .. self.rules.buildingsUpgradeStartsLogic[i].name .. " " .. buildingName )
		if ( self.rules.buildingsUpgradeStartsLogic[i].name == buildingName ) then
			
			self:SetSuspended( false )

			self.hqLogicLevel.level       = self.rules.buildingsUpgradeStartsLogic[i].level
			self.hqLogicLevel.prepareTime = self.rules.buildingsUpgradeStartsLogic[i].prepareTime
			self.hqLogicLevel.entryLogic  = self.rules.buildingsUpgradeStartsLogic[i].entryLogic
			self.hqLogicLevel.exitLogic   = self.rules.buildingsUpgradeStartsLogic[i].exitLogic

			if ( self.rules.buildingsUpgradeStartsLogic[i].minLevel ~= nil ) then
				LogService:Log( "dom_mananger:Upgrading hq - min difficulty level set to " .. tostring( self.rules.buildingsUpgradeStartsLogic[i].minLevel ) )
				self.hqLogicLevel.minLevel    = self.rules.buildingsUpgradeStartsLogic[i].minLevel
			end

			self:ClosePrepareForTheAttack();

			self.upgradeHQ:ChangeState( "hq_entry_logic" )
			self.spawner:ChangeState( "sleep" )
		end
	end
end

function dom_mananger:OnMissionFlowDeactivatedEvent( event )

	local logicFile = event:GetName()
	
	for i = 1, #self.spawnedAttacks, 1 do 
		if self.spawnedAttacks[i] == logicFile then
			table.remove( self.spawnedAttacks, i )		
		end
	end

	for i = 1, #self.upgradeHqWaves, 1 do 
		if self.upgradeHqWaves[i] == logicFile then
			table.remove( self.upgradeHqWaves, i )		
		end

		if ( #self.upgradeHqWaves == 0 ) then
			self.upgradeHQ:ChangeState( "hq_exit_logic" )
		end
	end

	if ( logicFile == self.onUpgradeHqLogicEndFileName ) then
		LogService:Log( "dom_mananger:OnMissionFlowDeactivatedEvent : onUpgradeHqLogicEndFileName finished : " .. self.onUpgradeHqLogicEndFileName )
		self.onUpgradeHqLogicEndFileName = ""
	
		if ( self.spawner:GetCurrentState() == "sleep" ) then
			self.spawner:ChangeState( "cooldown_after_spawn" )
			self.upgradeHQ:Deactivate()
		end
	end

	self:CheckObjectiveLogicFile( logicFile )
end

function dom_mananger:OnMissionFlowActivatedEvent( event )

end

function dom_mananger:Activated()
	
	self.currentDifficultyLevel = 1
		 
	self.difficultyIncrease:ChangeState( "difficulty_increase" )
	
	self.spawner:ChangeState( "wait" )

end 

function dom_mananger:OnEnterDifficultyIncrease( state )
	state:SetDurationLimit( self.rules.timeToNextDifficultyLevel[self.currentDifficultyLevel] )	
end

function dom_mananger:OnExitDifficultyIncrease( state )
	
	LogService:Log( "dom_mananger:OnExitDifficultyIncrease : Changing difficulty level." )

	if ( self.currentDifficultyLevel < self.maxDifficultyLevel ) then

		self.currentDifficultyLevel = self.currentDifficultyLevel + 1

		if ( self.currentDifficultyLevel > self.freezedDifficultyLevel ) then
			LogService:Log( "dom_mananger:OnExitDifficultyIncrease : Difficulty level will not rise. Clamped to  " .. tostring( self.freezedDifficultyLevel ) )
			self.currentDifficultyLevel = self.freezedDifficultyLevel
		end

		LogService:Log( "dom_mananger:OnExitDifficultyIncrease : Difficulty level : " .. tostring( self.currentDifficultyLevel ) )

		self:IncreamentEventLevel( self.freezedDifficultyLevel )

		self.difficultyIncrease:ChangeState( "difficulty_increase" )
	else
		LogService:Log( "dom_mananger:OnExitDifficultyIncrease : Difficulty level is max - " .. tostring( self.currentDifficultyLevel ) )
	end

end

function dom_mananger:RandomizeSpawnPoint( borderSpawnPointGroupName )
	self.spawnPointPool = FindService:FindEntitiesByGroup( borderSpawnPointGroupName )
	
	if #self.spawnPointPool == 0 then
		return "none";
	end

	if #self.spawnPointPool > 1 then
		repeat
			self.tempRandomNumber = RandInt( 1,#self.spawnPointPool )
		until self.tempRandomNumber ~= self.randomNumber
		self.randomNumber = self.tempRandomNumber
	else
		self.randomNumber = 1
	end
	
	local spawnPointName = EntityService:GetName( self.spawnPointPool[self.randomNumber] )
	Assert( spawnPointName ~= "", "Entity without name used as spawn point!");

	LogService:Log( "dom_mananger:Current spawn point :" .. spawnPointName )
	return spawnPointName;
end

function dom_mananger:GetWavePool( currentDifficultyLevel )

	local availableAttackPool = self.availableAttackGroups

	local availableWaves = {}

	if ( self.isForceAttackGroupEnabled == true ) then
		LogService:Log( "dom_mananger:GetWavePool - forced group attack : " .. self.forceAttackGroupName )
		
		self.isForceAttackGroupEnabled = false

		availableAttackPool = {}
		availableAttackPool[#availableAttackPool + 1] = self.forceAttackGroupName
	else
		LogService:Log( "dom_mananger:GetWavePool - available groups." )

		for i = 1, #self.availableAttackGroups, 1 do 
			LogService:Log( tostring( self.availableAttackGroups[i] ) )
		end	
	end
		
	for group in Iter ( availableAttackPool )  do
		local waves = self.rules.waves[ group ]
		
		currentDifficultyLevel = Clamp( currentDifficultyLevel, 0, #waves )

		if ( currentDifficultyLevel > 0 ) then
			for data in Iter( waves[currentDifficultyLevel] ) do 
				LogService:Log( "dom_mananger:Adding wave to the wave pool : " .. data )
				availableWaves[#availableWaves + 1] = data
			end
		end
	end

	return availableWaves
end

function dom_mananger:GetBossPool()
	local currentDifficultyLevel = self.currentDifficultyLevel	
	currentDifficultyLevel = Clamp( currentDifficultyLevel, 0, #self.rules.bosses )	

	if ( currentDifficultyLevel > 0 ) then
		return self.rules.bosses[currentDifficultyLevel]
	else
		return {}
	end
end

function dom_mananger:GetExtraWavePool()
	local currentDifficultyLevel = self.currentDifficultyLevel	
	currentDifficultyLevel = Clamp( currentDifficultyLevel, 0, #self.rules.extraWaves )	

	if ( currentDifficultyLevel > 0 ) then
		return self.rules.extraWaves[currentDifficultyLevel]
	else
		return {}
	end
end

function dom_mananger:GetAttackCount( currentDifficultyLevel )	
	return self.rules.maxAttackCountPerDifficulty[currentDifficultyLevel]
end

function dom_mananger:GetPrepareSpawnTime()
	return self.rules.prepareSpawnTime[self.currentDifficultyLevel]
end

function dom_mananger:GetIdleTime()
	return self.rules.idleTime[self.currentDifficultyLevel]
end

--------------------------------------------------- wait -------------------------------------------------

function dom_mananger:OnEnterWait( state )
	LogService:Log( "dom_mananger:OnEnterWait" )

	self:SetSuspended( true )
	CampaignService:OperateDOMPlanetaryJump( true )

	state:SetDurationLimit( 5 )
end

function dom_mananger:OnExitWait( state )
	LogService:Log( "dom_mananger:OnExitWait" )

	--if ( self.wavesDisabled == false ) then
	--	self.spawner:ChangeState( "streaming" )
	--else
	--	self.spawner:ChangeState( "prepare_spawn" )
	--end

	if ( self.upgradeHQ:GetCurrentState() ~= "hq_entry_logic" ) then
		local idleTime = self:GetIdleTime()

		if ( ( self.pauseAttacks == true ) and ( idleTime > 0 ) ) then
			self.spawner:ChangeState( "idle" )
		elseif ( ( self.pauseAttacks == true ) and ( idleTime == 0 ) ) then
			self.spawner:ChangeState( "prepare_spawn" )
		else
			self.spawner:ChangeState( "streaming" )
		end
	end

end

-------------------------------------------- prepare_spawn -------------------------------------------------

function dom_mananger:OnEnterPrepareSpawn( state )

	LogService:Log( "dom_mananger:OnEnterPrepareSpawn" )

	CampaignService:OperateDOMPlanetaryJump( false )

	self.waitForSpawnTimer = self:GetPrepareSpawnTime()

	self.eventActivateTime	= self.waitForSpawnTimer - ( self.waitForSpawnTimer * self.idleTimeEventMul )
	self.eventActivated		= false	

	self.objectiveActivateTime	= self.waitForSpawnTimer - ( self.waitForSpawnTimer * self.idleTimeObjectiveMul )
	self.objectiveActivated		= false	


	if ( ( self.pauseAttacks == false ) and ( self.cancelTheAttack == false ) ) then
		self.data:SetFloat( "time_max", self.waitForSpawnTimer )
		MissionService:ActivateMissionFlow( self.objectivePrepareForTheAttacLogicFileName, self.objectivePrepareForTheAttacLogicFile, "default", self.data )

		if ( self.rules.prepareAttackDefinitions ~= nil ) then
			MissionService:ActivateMissionFlow( "", self.rules.prepareAttackDefinitions[self.currentDifficultyLevel], "default" )
		end

		self.preparedAttacks = {}
		self.preparedAttackMarkers = {}

		if ( self.rules.prepareAttacks == true ) then
			local borderSpawnPointGroupName = self.borderSpawnPointGroupNames[RandInt( 1,#self.borderSpawnPointGroupNames )]

			LogService:Log( "dom_mananger:Border spawn point group :" .. borderSpawnPointGroupName )
			LogService:Log( "dom_mananger:Difficulty Level : " .. tostring(self.currentDifficultyLevel ) )

			self:PrepareWave( self:GetAttackCount( self.currentDifficultyLevel ), borderSpawnPointGroupName, self:GetWavePool( self.currentDifficultyLevel ), "OnEnterPrepareSpawn: Prepare attack name : ", self.waitForSpawnTimer, self.preparedAttacks, self.preparedAttackMarkers )
		end
	end

	--if ( self.wavesDisabled == false ) then
	--	self.data:SetFloat( "time_max", self.waitForSpawnTimer )
	--	MissionService:ActivateMissionFlow( self.objectivePrepareForTheAttacLogicFileName, self.objectivePrepareForTheAttacLogicFile, "default", self.data )	
	--end



end

function dom_mananger:OnExecutePrepareSpawn( state, dt )
	self.waitForSpawnTimer  = self.waitForSpawnTimer - dt

	if ( self.waitForSpawnTimer < 0 ) then

		if ( self.pauseAttacks == true ) then
			self.spawner:ChangeState( "dummy_state" )
		else
			self.spawner:ChangeState( "streaming" )
		end
	end

	if ( self.rules.eventsPerPrepareState ~= 0 ) then
		if ( ( self.waitForSpawnTimer < self.eventActivateTime ) and ( self.eventActivated == false ) ) then
			self:StartAnEvent( "IDLE" )
			self.eventActivated = true
		end

		if ( ( self.waitForSpawnTimer < self.objectiveActivateTime ) and ( self.objectiveActivated == false ) ) then
			self:StartObjective()
			self.objectiveActivated = true
		end
	end
end

function dom_mananger:OnExitPrepareSpawn( state )
	LogService:Log( "dom_mananger:OnExitPrepareSpawn" )

	CampaignService:OperateDOMPlanetaryJump( true )
end

--------------------------------------------------- cooldown_after_spawn -------------------------------------------------

function dom_mananger:OnEnterCooldownAfterSpawnTime( state )
	LogService:Log( "dom_mananger:OnEnterCooldownAfterSpawnTime" )
	self.cooldownTimer = self.rules.cooldownAfterAttacks[self.currentDifficultyLevel]
end

function dom_mananger:OnExecuteCooldownAfterSpawnTime( state, dt )
	self.cooldownTimer  = self.cooldownTimer - dt

	if ( self.cooldownTimer < 0 ) then
		self.spawner:ChangeState( "idle" )
	end
end

function dom_mananger:OnExitCooldownAfterSpawnTime( state )
	LogService:Log( "dom_mananger:OnExitCooldownAfterSpawnTime" )
end

--------------------------------------------------- idle -------------------------------------------------

function dom_mananger:OnEnterIdle( state )
	LogService:Log( "dom_mananger:OnEnterIdle" )

	local stateDuration = self.rules.idleTime[self.currentDifficultyLevel]

	self.idleTimer = stateDuration

	--state:SetDurationLimit( stateDuration )

	self.allowEvents = false
	local numberOfEvents = self.rules.eventsPerIdleState

	if ( self.rules.eventsPerIdleState > 0 ) then
		self.allowEvents = true

		if ( self.idleTimer < 400 ) then
			numberOfEvents = 1
			LogService:Log( "dom_mananger:OnEnterIdle - clamping number of events to : " .. tostring( numberOfEvents ) )
		end
	else
		numberOfEvents = 1
	end

	self.timePerEvent = stateDuration / numberOfEvents
	self.currentTimePerEvent = self.timePerEvent

	self.eventActivateTime	= self.timePerEvent
	self.eventActivated		= false	

	self.objectiveActivateTime	= self.timePerEvent - ( self.timePerEvent * self.idleTimeObjectiveMul )
	self.objectiveActivated		= false	


	LogService:Log( "dom_mananger:OnEnterIdle - Duration : " .. tostring( stateDuration ) )
	LogService:Log( "dom_mananger:OnEnterIdle - Objective activate time : " .. tostring( self.objectiveActivateTime ) )
	LogService:Log( "dom_mananger:OnEnterIdle - Allow events: " .. tostring( self.allowEvents ) )


	if ( self.rules.eventsPerIdleState > 0 ) then
		LogService:Log( "dom_mananger:OnEnterIdle - Number of events: " .. tostring( numberOfEvents ) )
		LogService:Log( "dom_mananger:OnEnterIdle - Time per event : " .. tostring( self.timePerEvent ) )
		LogService:Log( "dom_mananger:OnEnterIdle - Event activate time : " .. tostring( self.eventActivateTime ) )
	end
end

function dom_mananger:OnExecuteIdle( state, dt )
	self.idleTimer  = self.idleTimer - dt

	if ( self.idleTimer < 0 ) then

		local idleTime = self:GetIdleTime()
		
		if ( ( self.pauseAttacks == true ) and ( idleTime > 0 ) ) then
			self.spawner:ChangeState( "dummy_state" )
		else
			self.spawner:ChangeState( "prepare_spawn" )
		end
	end

	self.currentTimePerEvent  = self.currentTimePerEvent - dt

	if ( self.currentTimePerEvent < 0 ) then
		self.currentTimePerEvent = self.timePerEvent
		self.eventActivated = false
	end

	if ( ( self.currentTimePerEvent < self.eventActivateTime ) and ( self.eventActivated == false ) ) then

		if ( self.allowEvents == true ) then
			self:StartAnEvent( "IDLE" )
		end

		self.eventActivated = true
	end

	if ( ( self.currentTimePerEvent < self.objectiveActivateTime ) and ( self.objectiveActivated == false ) ) then
		self:StartObjective()
		self.objectiveActivated = true
	end


end

function dom_mananger:OnExitIdle( state )
	LogService:Log( "dom_mananger:OnExitIdle" )
end

--------------------------------------------------- dummy_state -------------------------------------------------

function dom_mananger:OnEnterDummyState( state )
	LogService:Log( "dom_mananger:OnEnterDummyState" )
end


function dom_mananger:OnExecuteDummyState( state, dt )
	local idleTime = self:GetIdleTime()

	if ( ( self.pauseAttacks == true ) and ( idleTime > 0 ) ) then
		self.spawner:ChangeState( "idle" )
	elseif ( ( self.pauseAttacks == true ) and ( idleTime == 0 ) ) then
		self.spawner:ChangeState( "prepare_spawn" )
	else
		self.spawner:ChangeState( "cooldown_after_spawn" )
	end
end


function dom_mananger:OnExitDummyState( state )
	LogService:Log( "OnExitDummyState" )
end

--------------------------------------------------- sleep -------------------------------------------------

function dom_mananger:OnEnterSleep( state )
	LogService:Log( "dom_mananger:OnEnterSleep - stoping base mission flow." )

	self:CloseStream()

	self.sleepSafeTimer = self.sleepSafeTime
end

function dom_mananger:OnExecuteSleep( state, dt )
	self.sleepSafeTimer  = self.sleepSafeTimer - dt

	if ( self.sleepSafeTimer < 0 ) then
		self.spawner:ChangeState( "cooldown_after_spawn" )
	end

end

function dom_mananger:OnExitSleep( state )
	LogService:Log( "dom_mananger:OnExitSleep - resuming base mission flow." )

	CampaignService:OperateDOMPlanetaryJump( true )
end

--------------------------------------------------- hq_entry_logic -------------------------------------------------

function dom_mananger:OnHqEnterEntryLogic( state )
	LogService:Log( "dom_mananger:OnHqEnterEntryLogic" )

	CampaignService:OperateDOMPlanetaryJump( false )

	self.data:SetFloat( "time_max", self.hqLogicLevel.prepareTime )

	LogService:Log( "dom_mananger:HQ upgrade time : " .. self.hqLogicLevel.prepareTime )
	LogService:Log( "dom_mananger:HQ upgrade entry logic : " .. self.hqLogicLevel.entryLogic )

	MissionService:ActivateMissionFlow( "", self.hqLogicLevel.entryLogic, "default", self.data )

	state:SetDurationLimit( self.hqLogicLevel.prepareTime )

	self.hqPreparedAttacks       = {}
	self.hqPreparedAttackMarkers = {}
	self.upgradeHqWaves			 = {}

	if ( self.rules.prepareAttacks == true ) then

		local borderSpawnPointGroupName = self.borderSpawnPointGroupNames[RandInt( 1,#self.borderSpawnPointGroupNames )]

		LogService:Log( "dom_mananger:Border spawn point group :" .. borderSpawnPointGroupName )

		local difficultyLevel = self.currentDifficultyLevel + self.hqLogicLevel.level

		if ( self.hqLogicLevel.minLevel ~= nil ) and ( difficultyLevel < self.hqLogicLevel.minLevel ) then
			difficultyLevel = self.hqLogicLevel.minLevel
		end

		difficultyLevel = Clamp( difficultyLevel, 1, self.maxDifficultyLevel )

		LogService:Log( "dom_mananger:Difficulty Level : " .. tostring( self.currentDifficultyLevel ) .. " changed to : " .. tostring( difficultyLevel ) )

		local wavePool = self:GetWavePool( difficultyLevel );

		self:PrepareWave( self:GetAttackCount( difficultyLevel ), borderSpawnPointGroupName, wavePool, "OnHqEnterEntryLogic: Prepare attack name : ", self.hqLogicLevel.prepareTime, self.hqPreparedAttacks, self.hqPreparedAttackMarkers )
	end
end

function dom_mananger:OnHqExitEntryLogic( state )
	LogService:Log( "dom_mananger:OnHqExitEntryLogic" )
	self.upgradeHQ:ChangeState( "hq_attack_logic" )
end


--------------------------------------------------- hq_attack_logic -------------------------------------------------

function dom_mananger:OnHqEnterAttackLogic( state )
	LogService:Log( "dom_mananger:OnHqEnterAttackLogic" )

	if ( self.rules.prepareAttacks == true ) then
		self:SpawnPreparedWave( "dom_mananger:OnHqExitEntryLogic: Spawn attack name : ", true, self.hqPreparedAttacks, self.upgradeHqWaves )
	else
		local borderSpawnPointGroupName = self.borderSpawnPointGroupNames[RandInt( 1,#self.borderSpawnPointGroupNames )]

		LogService:Log( "dom_mananger:Border spawn point group :" .. borderSpawnPointGroupName )

		local difficultyLevel = self.currentDifficultyLevel + self.hqLogicLevel.level

		if ( self.hqLogicLevel.minLevel ~= nil ) and ( difficultyLevel < self.hqLogicLevel.minLevel ) then
			difficultyLevel = self.hqLogicLevel.minLevel
		end

		difficultyLevel = Clamp( difficultyLevel, 1, self.maxDifficultyLevel )

		local wavePool = self:GetWavePool( difficultyLevel );

		self:SpawnWave( self:GetAttackCount( difficultyLevel ), borderSpawnPointGroupName, wavePool, "OnHqEnterAttackLogic: Spawn attack name : ", true, "", "label_small", 0, self.upgradeHqWaves )
	end
	self.hqAttackSafeTimer = self.hqAttackSafeTime
end

function dom_mananger:OnExecuteAttackLogic( state, dt )
	self.hqAttackSafeTimer  = self.hqAttackSafeTimer - dt

	if ( self.hqAttackSafeTimer < 0 ) then
		self.upgradeHQ:ChangeState( "hq_exit_logic" )
	end
end

function dom_mananger:OnHqExitAttackLogic( state )
	LogService:Log( "dom_mananger:OnHqExitAttackLogic" )
end

--------------------------------------------------- hq_exit_logic -------------------------------------------------

function dom_mananger:OnHqEnterExitLogic( state )
	LogService:Log( "dom_mananger:OnHqEnterExitLogic" )

	self.onUpgradeHqLogicEndFileName = MissionService:ActivateMissionFlow( "", self.hqLogicLevel.exitLogic, "default", self.data )
end

function dom_mananger:OnHqExitExitLogic( state )
	LogService:Log( "dom_mananger:OnHqExitExitLogic" )
end

function dom_mananger:PrepareLabels( labels, labelName, labelsPercentageUse )
	self.data:SetString( "labels", labels )
	self.data:SetString( "label_name", labelName )
	self.data:SetInt( "labels_percentage_use", labelsPercentageUse )
end

function dom_mananger:PrepareWave( attackCount, borderSpawnPointGroupName, wavePool, log, indicatorTimer, attacks, markers )

	for i = 1, attackCount do
		local spawnPointName = self:RandomizeSpawnPoint( borderSpawnPointGroupName )
		if ( spawnPointName ~= "none" ) then

			local waveName = wavePool[RandInt( 1, #wavePool )]

			local index = #attacks + 1

			attacks[index] = {}
			attacks[index].waveName = waveName
			attacks[index].spawnPointName = spawnPointName

			markers[#markers + 1] = self:SpawnWaveIndicator( indicatorTimer, spawnPointName, "effects/messages_and_markers/wave_marker" )


			LogService:Log( log .. waveName )
		end
	end

end

function dom_mananger:SpawnPreparedWave( log, shouldAddtoSpawnedAttacks, preparedAttacks, spawnedAttacks )
	for preparedWave in Iter( preparedAttacks ) do 
		self.data:SetString( "spawn_point", preparedWave.spawnPointName )

		LogService:Log( log .. preparedWave.waveName )

		self:PrepareLabels( "", "label_small", 0 )

		local currentLogicFile = MissionService:ActivateMissionFlow( "", preparedWave.waveName, "default", self.data )
		self:SpawnWaveIndicator( 45, preparedWave.spawnPointName, "effects/messages_and_markers/wave_marker" )				

		if ( shouldAddtoSpawnedAttacks == true ) then
			spawnedAttacks[#spawnedAttacks + 1] = currentLogicFile
		end
	end
end

function dom_mananger:SpawnWave( attackCount, borderSpawnPointGroupName, wavePool, log, shouldAddtoSpawnedAttacks, participants, labelName, participantsPercentageUse, spawnedAttacks )
	for i = 1, attackCount do
		local spawnPointName = self:RandomizeSpawnPoint( borderSpawnPointGroupName )
		if ( spawnPointName ~= "none" ) then

			local waveName = wavePool[RandInt( 1, #wavePool )]

			LogService:Log( log .. waveName )

			self:PrepareLabels( participants, labelName, participantsPercentageUse )

			self.data:SetString( "spawn_point", spawnPointName )

			local currentLogicFile = MissionService:ActivateMissionFlow( "", waveName, "default", self.data )
			self:SpawnWaveIndicator( 45, spawnPointName, "effects/messages_and_markers/wave_marker" )				

			if ( shouldAddtoSpawnedAttacks == true ) then
				spawnedAttacks[#spawnedAttacks + 1] = currentLogicFile
			end
		end
	end

end
--------------------------------------------------- spawn -------------------------------------------------

function dom_mananger:OnEnterSpawn( state )

	LogService:Log( "dom_mananger:OnEnterSpawn" )

	if ( self.cancelTheAttack == true ) then
		LogService:Log( "dom_mananger:Canceling the attack." )
		self.cancelTheAttack = false
	else
		if ( #self.spawnedAttacks <= 1 ) then	
		
			local borderSpawnPointGroupName = self.borderSpawnPointGroupNames[RandInt( 1,#self.borderSpawnPointGroupNames )]

			LogService:Log( "dom_mananger:Border spawn point group :" .. borderSpawnPointGroupName )
			LogService:Log( "dom_mananger:Difficulty Level : " .. tostring(self.currentDifficultyLevel) )

			if ( #self.preparedAttacks > 0 ) then
				self:SpawnPreparedWave( "dom_mananger:OnEnterSpawn: Prepare attack name : ", true, self.preparedAttacks, self.spawnedAttacks )
			else
				local wavePool = self:GetWavePool( self.currentDifficultyLevel )
				self:SpawnWave( self:GetAttackCount( self.currentDifficultyLevel ), borderSpawnPointGroupName, wavePool, "dom_mananger:OnEnterSpawn: Normal attack name : ", true, "", "label_small", 0, self.spawnedAttacks )
			end

			self:SpawnWave( self.extraAttacks, borderSpawnPointGroupName, self:GetExtraWavePool(), "dom_mananger:OnEnterSpawn: Extra attack name : ", true, self.participants, "label_small", self.participantsPercentageUse, self.spawnedAttacks )

			if ( self.spawnBoss == true ) then
				self:SpawnWave( 1, borderSpawnPointGroupName, self:GetBossPool(), "dom_mananger:OnEnterSpawn: Boss attack name : ", false, self.participants, "label_medium", self.participantsPercentageUse, self.spawnedAttacks )
			end		

			if ( self.currentDifficultyLevel <= #self.rules.wavesEntryDefinitions ) then
				MissionService:ActivateMissionFlow( "", self.rules.wavesEntryDefinitions[self.currentDifficultyLevel], "default", self.data )	
			end
		end
	end



	self.extraAttacks = 0
	self.spawnBoss = false
	self.participants = ""
	self.participantsPercentageUse = 0
end

function dom_mananger:OnExecuteSpawn( state, dt )
	self.spawner:ChangeState( "cooldown_after_spawn" )
end

function dom_mananger:OnExitSpawn( state )
	LogService:Log( "dom_mananger:OnExitSpawn" )	
end

function dom_mananger:SpawnWaveIndicator( indicatorTimer, spawnPoint, markerName )
		
	local indicatorID = EntityService:SpawnEntity( markerName, spawnPoint, "no_team" )
	EntityService:CreateLifeTime( indicatorID, indicatorTimer, "normal" )
	LogService:Log( "dom_mananger:SpawnWaveIndicator : " .. tostring( indicatorID ) )
	return indicatorID
end

	-- ======================================== STREAMING ============================================

function dom_mananger:OnEnterStreaming( state )

	LogService:Log( "dom_mananger:OnEnterStreaming" )

	LogService:Log( "dom_mananger:Current attacks count : " .. tostring( #self.spawnedAttacks ) )

	while ( #self.spawnedAttacks >= 2 ) do

		LogService:Log( "dom_mananger:Removing extra attack : " .. tostring( self.spawnedAttacks[1] ) )

		LogService:Log( "dom_mananger:MissionService:DeactivateMissionFlow by force : " .. self.spawnedAttacks[1] )
		MissionService:DeactivateMissionFlow( self.spawnedAttacks[1] )

		table.remove( self.spawnedAttacks, 1 )	
	end

	self:StartAnEvent( "ATTACK" )
end

function dom_mananger:OnExecuteStreaming( state )
	
	if ( ( GameStreamingService:IsInStreamEvent() == false ) or ( GameStreamingService:IsStreamingSessionStarted() == false ) ) then
		self.spawner:ChangeState( "spawn" )
	end

end

function dom_mananger:OnExitStreaming( state )
	LogService:Log( "dom_mananger:OnExitStreaming" )
end

function dom_mananger:OnRespawnFailedEvent()
	LogService:Log( "dom_mananger:Mission failed" )
    LampService:ReportGameFailed()
	MissionService:ShowEndGameHud( 5.0, false )
	local failedAction = MissionService:GetCurrentMissionFailedAction();
	if ( failedAction ~= MFA_REMAIN ) then
		MissionService:DeactivateAllFlows()
	end
end

function dom_mananger:DestroyPlayerItems( owner )
	local count = DifficultyService:GetNumberOfItemsRemovedOnDeath();

	if ( count == 0 ) then
		return
	end
	local status = CampaignService:GetMissionStatus( CampaignService:GetCurrentMissionId() )
	if ( status ~= MISSION_STATUS_IN_PROGRESS and status ~= MISSION_STATUS_NONE ) then
		return
	end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND" )
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND" ) )   
	count = math.min( count, #items )

	local name = ""
	local lvl = ""
	for i=1,count,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		EntityService:RemoveEntity( entity)
	end

end

function dom_mananger:DropPlayerItems( owner )
	local dropItemsCount = DifficultyService:GetNumberOfItemsDroppedOnDeath();
	if ( dropItemsCount == 0 ) then
		return
	end

	--local status = CampaignService:GetMissionStatus( CampaignService:GetCurrentMissionId() )
	--if ( status ~= MISSION_STATUS_IN_PROGRESS and status ~= MISSION_STATUS_NONE ) then
	--	return
	--end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND" )
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND" ) )   
	dropItemsCount = math.min( dropItemsCount, #items )

	local dropped = {}
	local name = ""
	local lvl = ""
	for i=1,dropItemsCount,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Insert(dropped, entity )
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		PlayerService:DropItem( entity, owner, owner )
	end

	if dropItemsCount >= (#items + #dropped) then
		CampaignService:UnlockAchievement(ACHIEVEMENT_LEAVING_EMPTY_HANDED);
	end
end

function dom_mananger:OnPlayerDiedEvent( evt )
	--LogService:Log("dom_mananger:OnPlayerDiedEvent")
	self:DestroyPlayerItems(evt:GetEntity())
	self:DropPlayerItems(evt:GetEntity())
end

return dom_mananger