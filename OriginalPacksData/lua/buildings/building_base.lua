require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/building_utils.lua")

local day_cycle_machine = require("lua/utils/day_cycle_machine.lua")

class 'building_base' ( day_cycle_machine )

function building_base:__init()
	day_cycle_machine.__init(self,self)
end

local function CalculateBuildingBuildTime( entity )
	if ( BuildingService.CalculateBuildTime ) then
		return BuildingService:CalculateBuildTime( entity );
	end
	local time self.data:GetFloatOrDefault( "building_time", 1 )
	return time * BuildingService:GetBuildingSpeedMultiplier() * DifficultyService:GetBuildingSpeedMultiplier()
end

function building_base:init()
	self.version = 2
	SetupBuildingScale( self.entity, self.data )

	if ( not EntityService:HasTeam( self.entity ) ) then
		EntityService:SetTeam( self.entity, "player" )
	end
	self.meshEnt = BuildingService:GetMeshEntity(self.entity);

	----LogService:Log("Initialize building " .. tostring( self.entity ) ) 
	self:RegisterHandler( self.entity, "StartBuildingEvent",  "_OnBuildNew" )
	self:RegisterHandler( self.entity, "StartBuildingEvent",  "OnStartBuildingEvent" )
	self:RegisterHandler( self.entity, "BuildingSellEvent",  "_OnSell" )
	self:RegisterHandler( self.entity, "BuildingOverrideEvent",  "_OnOverride" )
	self:RegisterHandler( self.entity, "ActivateBuildingEvent",  "_OnActivate" )
	self:RegisterHandler( self.entity, "DeactivateBuildingEvent", "_OnDeactivate" )
	self:RegisterHandler( self.entity, "BuildingPoweredEvent",  "_OnBuildingPoweredEvent" )
	self:RegisterHandler( self.entity, "BuildingPowerOffEvent", "_OnBuildingPowerOffEvent" )
	self:RegisterHandler( self.entity, "BuildingResourceGrantedEvent",  "_OnBuildingResourceGranted" )
	self:RegisterHandler( self.entity, "BuildingResourceMissingEvent", "_OnBuildingResourceMissing" )
	self:RegisterHandler( self.entity, "BuildingModifiedEvent", "_OnBuildingModifiedEvent" )
	self:RegisterHandler( self.entity, "BuildingBuildEvent", "OnBuild" )
	self:RegisterHandler( self.entity, "BuildingBuildEndEvent", "_OnBuildingEnd" )
	self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" )

	self.power = self.data:GetIntOrDefault("power", -1 )
	self.resource = self.data:GetIntOrDefault("resource", -1 )

	local playerId = PlayerService:GetPlayerForEntity( self.entity )
	if ( self.data:HasInt("owner") == false ) then
		self.data:SetInt( "owner", playerId )
	end
	
	self.buildingTime = math.max( 0.1, CalculateBuildingBuildTime( self.entity ) )
	self.sellTime = 2
	self.materials = self:GetMaterials()

	self:OnInit()
	local buildingComponent = EntityService:GetComponent(self.entity, "BuildingComponent")
	self.buildingType = buildingComponent:GetField("type"):GetValue()
	self.buildingName = buildingComponent:GetField("name"):GetValue()
	
	self:CreateBuildingStateMachine()
	self.extendLength = 0.5
	self.lastProgress = 0
	self.currentLines = {}
	self.lines = {}
	self.currentCubes = {}
	self.cubes = {}
	self.buildingFinished = 0
	self.buildingSell = false
	self.buildingUnderAttack = INVALID_ID
	self.hasHealth = false
	self.printingLine1 = nil
	self.printingLine2 = nil
	self.printingCube  = nil
	self.working = false;
	self.data:SetFloat("is_working", 0.0 )
	self.dissolveCurrent = 0
	self.forwardTime = 0
	self.timeMachine = 0
	self.isFloor = self.buildingType == "floor"
	self.checkCollision = self.isFloor == false and  self.data:GetIntOrDefault("check_collison", 1 )
	self.nextState = ""
	self.disabledTreasures = {}

	if ( self.data:HasInt("time_machine") == true ) then
		self.timeMachine = self.data:GetInt("time_machine")
	end	

	if ( self.timeMachine == 1 ) then
		self:EnableTimeStateMachine()
	end

	self:InitializeDisplayRadiusHandlers()
end

function building_base:CreateBuildingStateMachine()
	if ( self.buildingSM) then
		return 
	end

	self.buildingSM = self:CreateStateMachine()
	self.buildingSM:AddState( "cube_fly", { from="*", enter="_OnCubeFlyEnter", exit="_OnCubeFlyExit", execute="_OnCubeFlyExecute" } )
	self.buildingSM:AddState( "cube_fly_selling", { from="*", enter="_OnCubeFlySellEnter", exit="_OnCubeFlySellExit" } )
	self.buildingSM:AddState( "building", { from="*", enter="_OnBuildingEnter", execute="_OnBuildingExecute", exit="_OnBuildingExit" } )
	self.buildingSM:AddState( "wait", { from="*", enter="_OnWaitEnter", exit="_OnWaitExit" } )
	self.buildingSM:AddState( "big_building_state1", { from="*", enter="_OnBigBuildingEnterState1", execute="_OnBigBuildingExecuteState1", exit="_OnBigBuildingExitState1" } )
	self.buildingSM:AddState( "big_building_state2", { from="*", enter="_OnBigBuildingEnterState2", execute="_OnBigBuildingExecuteState2", exit="_OnBigBuildingExitState2" } )
	self.buildingSM:AddState( "big_building_state3", { from="*", enter="_OnBigBuildingEnterState3", execute="_OnBigBuildingExecuteState3", exit="_OnBigBuildingExitState3" } )
	self.buildingSM:AddState( "big_building_state4", { from="*", enter="_OnBigBuildingEnterState4", execute="_OnBigBuildingExecuteState4", exit="_OnBigBuildingExitState4" } )
	self.buildingSM:AddState( "hide_scaffolding", { from="*", enter="_OnHideScafoldingEnter", execute="_OnHideScafoldingExecute", exit="_OnHideScafoldingExit" } )
	self.buildingSM:AddState( "selling", { from="*", enter="_OnSellEnter", execute="_OnSellExecute", exit="_OnSellExit", interval=0.1 } )
	self.buildingSM:AddState( "wait_for_space", { from="*", execute="_OnWaitForSpace" } )
	
end

function building_base:GetMaterials()
	if self.materials then 
		return self.materials 
	end

	local materials = EntityService:GetOverridenMaterials( self.meshEnt )
	if ( #materials >= 1 ) then
		if ( string.find( materials[1], "_dissolve" ) == nil ) then
			self.materials = materials
		end
	
		if self.materials then 
			return self.materials
		end
	end
	return {}
end

function building_base:OnRelease()
	self:OnRemove()
	self:RemoveAllBuilidingEntities()
end

function building_base:OnDestroyRequest(evt)
	self:EnableTreasuresUnder()
	self.meshEnt = BuildingService:GetMeshEntity(self.entity);
	self:OnDestroy(evt)
end

function building_base:OnDestroy()
end

function building_base:CreateBaseCubes()
	local createCubes = self.data:GetIntOrDefault("create_cubes", 1) == 1
	local cubes =  BuildingService:FlyCubesToBuilding(self.entity, self.data:GetIntOrDefault( "owner", 0), not self.isFloor and createCubes , not self.isFloor and createCubes)		
	self.cubeEnt = cubes.first
	self.endCubeEnt = cubes.second
end

function building_base:_OnBuildNew(evt)
	local buildingComponent  = EntityService:GetConstComponent(self.entity, "BuildingDesc")
	if (buildingComponent ~= nil ) then
		local hide_treasures = buildingComponent:GetField( "hide_treasures" ):GetValue()		
		if ( hide_treasures == "1" ) then
			self:DisableTreasuresUnder()
		end
	end

	self:OnCubeFlyStart()
end

function building_base:OnStartBuildingEvent()
	self:OnBuildingStart()
end

function building_base:_OnBuild(evt)
	return
end

function building_base:_OnSell(evt)
	self:EnableTreasuresUnder()
	self.meshEnt = BuildingService:GetMeshEntity(self.entity);
	if ( self.buildingSell == true ) then
		return
	end
	self.buildingSell = true;
	if ( self.buildingFinished > 0 ) then
		self:RemoveAllBuilidingEntities()
	end

	self:CreateBuildingStateMachine()
	self.cubeEnt = evt:GetCubeEnt()
	self.playerIdOnSell = evt:GetPlayerId()

	if(  not EntityService:IsAlive( self.cubeEnt ) ) then
		local cubes	= nil
		if ( self.isFloor )then
			cubes =  BuildingService:FlyCubesToBuilding(self.entity, self.playerIdOnSell, false, false )		
		else
			local createCubes = self.data:GetIntOrDefault( "create_cubes", 1 ) == 1
			cubes =  BuildingService:FlyCubesToBuilding(self.entity, self.playerIdOnSell, createCubes , false )		
		end
		self.cubeEnt = cubes.first
	end

	local children = EntityService:GetChildren( self.entity, true )
	self.childrenToUpdate = {}
	if (self.isFloor == false ) then
		EntityService:SetMaterial( self.meshEnt, "hologram/current", "sell" )
		for child in Iter( children ) do
			if ( EntityService:HasComponent( child, "MeshComponent" ) ) then
				EntityService:SetMaterial( child, "hologram/current", "sell" )
				Insert( self.childrenToUpdate, child )
			end
		end
	end
	if (evt:GetForced() == false )then
		EffectService:AttachEffect( self.entity,"effects/buildings_and_machines/building_sell" )
	end

	self.nextState = ""
	self.buildingSM:ChangeState("cube_fly_selling")
	self:OnSellStart()
end

function building_base:_OnOverride(evt)
	self:OnOverride()
end

function building_base:_OnBuildingModifiedEvent(evt)
end

function building_base:_OnWaitEnter( state )
	state:SetDurationLimit( self.nextStateWaitDuration )
end

function building_base:_OnWaitExit( state )
	if (self.buildingSell == true  ) then
		return
	end
	self.buildingSM:ChangeState(self.nextState)
	self.nextState = ""
end

function building_base:_OnCubeFlyEnter( state )
	if ( AnimationService:HasAnim( self.cubeEnt, "fly_and_scale") ) then
		AnimationService:StartAnim( self.cubeEnt, "fly_and_scale", false, 4 )
	end
	EffectService:AttachEffects(self.cubeEnt, "fly")
	EntityService:SetMaterial( self.meshEnt, "hologram/blue_depth", "default"  )

	self:OnCubeFlyStart()
	Insert(self.cubes, self.cubeEnt )
	
	self:RegisterHandler( self.entity, "BuildingFastForwardEvent", "_OnBuildingFastForwardEvent" )
	if (  BuildingService:IsFloor( self.entity ) ) then	
		state:Exit();
	elseif ( EntityService:IsAlive( self.cubeEnt ) == true ) then
		self:RegisterHandler( self.cubeEnt, "MoveEndEvent", "OnMoveEndEvent" )
	end
end

function building_base:_OnCubeFlyExecute( state )
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_base:_OnCubeFlyExit( state )
	if ( self.buildingSell == false ) then
		EffectService:DestroyEffectsByGroup(self.cubeEnt, "fly")

		local spaceOccupied = BuildingService:IsBuildingSpaceOccupied( self.entity )
		if ( spaceOccupied == false or self.checkCollision == false ) then

			BuildingService:EnablePhysics( self.entity )
			
			if ( EntityService:IsAlive( self.endCubeEnt ) == true and self.forwardTime <= 0 and not BuildingService:IsFloor( self.entity )  ) then
				self.height = EntityService:GetPositionY( self.endCubeEnt )
				local x1 = EntityService:GetPositionX( self.cubeEnt )
				local x2 = EntityService:GetPositionX( self.endCubeEnt )
				self.width = ( math.abs( x2 - x1 ) / 2 ) * 0.7
				EffectService:AttachEffects(self.cubeEnt, "hit_ground")
				self.nextState = "big_building_state1"
				self.nextStateWaitDuration = 0.1
				self.buildingSM:ChangeState("wait")
			else
				self.height = EntityService:GetPositionY( self.cubeEnt )
				self.buildingSM:ChangeState("building")
			end
			 EntityService:SetGraphicsUniform( self.meshEnt, "cMaxHeight", self.height - 1.0 )
		else
			if ( self.timerEnt ~= nil ) then
				BuildingService:PauseGuiTimer( self.timerEnt )
			end
			self.buildingSM:ChangeState("wait_for_space")
		end
	end
end

function building_base:OnMoveEndEvent( evt )
	if (self.buildingSM ~= nil and  evt:GetEntity() == self.cubeEnt) then
		self.buildingSM:Deactivate()
	end
end

function building_base:_OnCubeFlySellEnter( state )
	if ( AnimationService:HasAnim( self.cubeEnt, "fly_and_scale") ) then
		AnimationService:StartAnim( self.cubeEnt, "fly_and_scale", false, 4 )
	end
	self:OnCubeFlyStart()
	Insert(self.cubes, self.cubeEnt )
	if (  BuildingService:IsFloor( self.entity ) ) then	
		state:Exit();
	else
		EffectService:AttachEffects(self.cubeEnt, "fly")
		self:RegisterHandler( self.cubeEnt, "MoveEndEvent", "OnMoveEndEvent" )
	end
end


function building_base:_OnCubeFlySellExit( state )
	--LogService:Log("_OnCubeFlySellExit" )
	EffectService:DestroyEffectsByGroup(self.cubeEnt, "fly")
	self.height = EntityService:GetPositionY( self.cubeEnt )
	self.buildingSM:ChangeState("selling")
	EntityService:SetGraphicsUniform( self.meshEnt, "cMaxHeight", self.height - 1.0 )
	for child in Iter( self.childrenToUpdate ) do
		EntityService:SetGraphicsUniform( child, "cMaxHeight", self.height - 1.0 )
	end
end

function building_base:_OnWaitForSpace( state )
	--LogService:Log("_OnWaitForSpace")
	if (self.buildingSell == true  ) then
		return
	end
		local spaceOccupied = BuildingService:IsBuildingSpaceOccupied( self.entity )
		if ( spaceOccupied == false ) then
			if ( self.timerEnt ~= nil ) then
				BuildingService:ResumeGuiTimer( self.timerEnt )
			end
			BuildingService:EnablePhysics( self.entity )
			if ( EntityService:IsAlive( self.endCubeEnt ) == true ) then
				self.height = EntityService:GetPositionY( self.endCubeEnt )
				local x1 = EntityService:GetPositionX( self.cubeEnt )
				local x2 = EntityService:GetPositionX( self.endCubeEnt )
				self.width = ( math.abs( x2 - x1 ) / 2 ) * 0.7
				EffectService:AttachEffects(self.cubeEnt, "hit_ground")
				self.nextState = "big_building_state1"
				self.nextStateWaitDuration = 0.1
				self.buildingSM:ChangeState("wait")
			else
				
				self.height = EntityService:GetPositionY( self.cubeEnt )
				self.buildingSM:ChangeState("building")
			end
			 EntityService:SetGraphicsUniform( self.meshEnt, "cMaxHeight", self.height - 1.0 )
		end
end

function building_base:_OnBuildingEnter( state )
	self:OnBuildingStart()
	
	self.buildingFinished = 1
	self.printingOrigin = EntityService:SpawnEntity( "player/cube_builder_effect", self.cubeEnt, "" )

	if ( self.cubeEffects == true ) then
		if ( self.data:HasString("cone_effect") == true ) then
			EffectService:AttachEffects(self.printingOrigin, self.data:GetString( "cone_effect" ) )
			EffectService:AttachEffects(self.cubeEnt, "build_cube_laser")
		else
			EffectService:AttachEffects(self.printingOrigin, "build_cone")
			EffectService:AttachEffects(self.cubeEnt, "build_cube_laser")
		end
	end

	state:SetDurationLimit( self.buildingTime  )

	for i, material in ipairs(self:GetMaterials()) do
		EntityService:SetSubMeshMaterial( self.meshEnt, material .. "_dissolve", i - 1, "default" )
	end
	EntityService:SetMaterial( self.meshEnt, "hologram/blue_depth" , "dissolve" )

    if ( self.printingCube ~= nil ) then
		self.printingData1 = { EntityService:GetPositionX( self.printingCube ), EntityService:GetPositionY( self.printingCube ), EntityService:GetPositionZ( self.printingCube ) }
		self.printingData2 = { EntityService:GetPositionX( self.printingLine1 ), EntityService:GetPositionY( self.printingLine1 ), EntityService:GetPositionZ( self.printingLine1 ) }
		self.printingData3 = { EntityService:GetPositionX( self.printingLine2 ), EntityService:GetPositionY( self.printingLine2 ), EntityService:GetPositionZ( self.printingLine2 ) }
	end
	if ( self.upgrading and self.hasHealth  ) then 
		HealthService:SetHealth( self.entity, HealthService:GetMaxHealth( self.entity) )
	end
	
end

function building_base:_OnBuildingExecute( state )
	local currentDuration = state:GetDuration() + self.forwardTime
	self.meshEnt = BuildingService:GetMeshEntity(self.entity);

    local progress = currentDuration / state:GetDurationLimit()
	local healthMod = progress - self.lastProgress
	if ( self.hasHealth == true and self.upgrading == false ) then 
		HealthService:AddHealthInPercentage( self.entity, healthMod * 100 )
	end
	self.lastProgress = progress

    if ( self.printingCube ~= nil ) then
    	local offset1 = math.sin( progress * 45 * self.width / 20 )
    	local progress2 = progress * 45 * self.width / 100
    	local offset2 = 2 *  math.asin( math.sin( 2 * 3.14 * progress2 ) ) / 3.14
    	EntityService:SetPosition( self.printingCube, self.width * offset1 + self.printingData1[1], self.printingData1[2], self.width * offset2 + self.printingData1[3] );
    	EntityService:SetPosition( self.printingLine1, self.width * offset1 + self.printingData2[1], self.printingData2[2], self.printingData2[3] );
    	EntityService:SetPosition( self.printingLine2, self.width * offset1 + self.printingData3[1], self.printingData3[2], self.printingData3[3] );
    end
	if ( progress >= 1 ) then
		state:Exit()
	end
end

function building_base:_OnBuildingFastForwardEvent( evt )
	self.forwardTime = self.forwardTime + evt:GetDeltaTime()
end

function building_base:_OnBuildingExit( state )
	self.forwardTime = 0
	self:UnregisterHandler( self.entity, "BuildingFastForwardEvent", "_OnBuildingFastForwardEvent" )
	if ( self.buildingSell == true ) then
		return
	end
	
	EntityService:RemoveMaterial( self.meshEnt, "dissolve" )
	for i, material in ipairs( self.materials ) do
		EntityService:SetSubMeshMaterial( self.meshEnt, material, i - 1, "default" )
	end

	EffectService:DestroyEffectsByGroup(self.cubeEnt, "build_cone")
	if ( EntityService:IsAlive(self.endCubeEnt) == true ) then
		EntityService:RemoveEntity( self.endCubeEnt )
		self.endCubeEnt = nil
	end

	self.buildingSM:ChangeState("hide_scaffolding")
	self.buildingFinished = 0;

	local buildingComponent  = EntityService:GetComponent(self.entity, "BuildingComponent")
	if (buildingComponent ~= nil ) then
		local name = buildingComponent:GetField( "name" ):GetValue()		
		local type = buildingComponent:GetField( "type" ):GetValue()
		local owner = buildingComponent:GetField( "owner" ):GetValue()
		QueueEvent("BuildingBuildEvent", self.entity, self.upgrading, name, type, tonumber( owner ) )
	else
		QueueEvent("BuildingBuildEvent", self.entity, self.upgrading, "", "", INVALID_PLAYER_ID )
	end

    if ( self.printingCube ~= nil ) then
		self.printingData1 = nil
		self.printingData2 = nil
		self.printingData3 = nil
		self.printingCube = nil
		self.printingLine1 = nil
		self.printingLine2 = nil
	end

	self.upgrading = false;
	EntityService:RemoveEntity( self.printingOrigin )
	self.printingOrigin = nil
	
	if ( self.timerEnt ~= nil and EntityService:IsAlive( self.timerEnt ) ) then
		EntityService:RemoveEntity(self.timerEnt)
	end
	
	self.timerEnt = nil
end

function building_base:_OnSellEnter( state )
	self.meshEnt = BuildingService:GetMeshEntity(self.entity);
	if ( self.data:HasString("cone_effect_sell") == true  ) then
		EffectService:AttachEffects(self.cubeEnt, self.data:GetString( "cone_effect_sell" ) )
	else
		EffectService:AttachEffects(self.cubeEnt, "sell_medium")
	end
    state:SetDurationLimit( self.sellTime )
	if ( self.buildingFinished > 0 ) then
		for i, material in ipairs(self:GetMaterials()) do
			EntityService:SetSubMeshMaterial( self.meshEnt, material .. "_dissolve", i - 1, "default"  )
		end
		
	end
	EntityService:SetGraphicsUniform( self.meshEnt, "cMaxHeight", self.height - 1.0 )
	EntityService:FadeEntity( self.meshEnt, DD_FADE_OUT, self.sellTime )

	for child in Iter( self.childrenToUpdate ) do
		for i, material in ipairs(self:GetMaterials()) do
			EntityService:SetSubMeshMaterial( child, material .. "_dissolve", i - 1, "default"  )
		end
		EntityService:SetGraphicsUniform( child, "cMaxHeight", self.height - 1.0 )
		EntityService:FadeEntity( child, DD_FADE_OUT, self.sellTime )
	end

	self:OnSell()
end

function building_base:_OnSellExecute( state )
end

function building_base:_OnSellExit( state )
	EntityService:SendBuildingSellEndEvent( self.entity, self.playerIdOnSell )
	if ( self.data:HasString("cone_effect_sell") == true  ) then
		EffectService:DestroyEffectsByGroup(self.cubeEnt, self.data:GetString( "cone_effect_sell" ) )
	else
		EffectService:DestroyEffectsByGroup(self.cubeEnt, "sell_medium")
	end	
	EntityService:RemoveMaterial(self.meshEnt, "sell")
end

function building_base:_CreateLine( ent1, ent2, dir, lengthMultiplier )
	local line1 = EntityService:SpawnEntity("player/cube_builder_arm", ent1, "" ) 
	local expand1 = EntityService:SpawnAndAttachEntity( "effects/buildings_and_machines/building_cube_line_expand", line1, "att_expand", "" ) 
	
	local length = 0
	local endPosX = EntityService:GetPositionX(ent1)
	local endPosY = EntityService:GetPositionY(ent1)
	local endPosZ = EntityService:GetPositionZ(ent1)

	if ( dir == 0 ) then
		local posEnd = EntityService:GetPositionX(ent2)
		local posStart = endPosX
		length =  posEnd - posStart
		endPosX = posEnd
		--------LogService:Log( tostring(dir) .. " s: " .. tostring( posStart ) .. ", e: " .. tostring( posEnd ) .. ", length: " .. tostring(length) )
		EntityService:SetForward(line1,length,0,0)	
	elseif( dir == 1 ) then
		local posEnd = EntityService:GetPositionY(ent2)
		local posStart = endPosY
		length =  posEnd - posStart
		endPosY = posEnd
		--------LogService:Log( tostring(dir) .. " s: " .. tostring( posStart ) .. ", e: " .. tostring( posEnd ) .. ", length: " .. tostring(length) )
		EntityService:SetForward(line1,0,length,0)
	elseif( dir == 2 ) then
		local posEnd = EntityService:GetPositionZ(ent2)
		local posStart = endPosZ
		length =  posEnd - posStart
		endPosZ = posEnd
		--------LogService:Log( tostring(dir) .. " s: " .. tostring( posStart ) .. ", e: " .. tostring( posEnd ) .. ", length: " .. tostring(length) )
		EntityService:SetForward(line1,0,0,length)
	end
	EntityService:SetScale( line1, 0.01, 1, 1 )
	EntityService:SetScale( expand1, 100, 1, 1 )
	length = math.abs( length )
	local line = { line1, length * lengthMultiplier , endPosX, endPosY, endPosZ, expand1 }
	Insert( self.currentLines, line )
	return line1
end

function building_base:_OnBigBuildingEnterState1( state )
    state:SetDurationLimit( self.extendLength )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 0, 1 )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 1, 1 )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 2, 1 )
	
	EffectService:SpawnEffect( self.entity, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	--LogService:Log("_OnBigBuildingEnter1" )
end

function building_base:_UpdateLines( progress, lines )
	progress = math.min( progress, 1)
	progress = math.max( progress, 0)
	progress = progress * progress
	for line in Iter( lines ) do
		local scale =  (line[2] / 2) * progress
		EntityService:SetScale( line[1], scale,1,1 )
		EntityService:SetScale( line[6], 1/scale,1,1 )
    end
end

function building_base:_OnBigBuildingExecuteState1( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_base:_OnBigBuildingExitState1( state )
	--LogService:Log("_OnBigBuildingExit1" )
	for line in Iter( self.currentLines ) do
		Insert(self.lines, line)
		EntityService:RemoveEntity(line[6])
		if ( self.buildingSell == false ) then
			local endCube = EntityService:SpawnEntity( "player/cube_builder", line[3], line[4], line[5], "" )
			AnimationService:StartAnim( endCube, "scale", false )
			EffectService:AttachEffects(endCube, "spawn")
			Insert( self.currentCubes, endCube )
		end
    end
	
	Clear( self.currentLines )
	
	if ( self.buildingSell == false ) then
		self.nextState = "big_building_state2"
		self.nextStateWaitDuration = 0.5
		self.buildingSM:ChangeState("wait")
	end
end

function building_base:_OnBigBuildingEnterState2( state )
    state:SetDurationLimit( self.extendLength )
	local i = 0
	for cube in Iter( self.currentCubes ) do 
		if ( i == 0 ) then
			self:_CreateLine(cube, self.endCubeEnt, 1, 1 )
			self:_CreateLine(cube, self.endCubeEnt, 2, 1 )
		elseif ( i == 1) then
			self:_CreateLine(cube, self.endCubeEnt, 0, 1 )
			self:_CreateLine(cube, self.endCubeEnt, 2, 1 )
		elseif ( i == 2 ) then
			self:_CreateLine(cube, self.endCubeEnt, 0, 1 )
			self:_CreateLine(cube, self.endCubeEnt, 1, 1 )
		end		
		i = i + 1 
	end
	
	EffectService:SpawnEffect( self.entity, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	--LogService:Log("_OnBigBuildingEnter2" )
end


function building_base:_OnBigBuildingExecuteState2( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_base:_OnBigBuildingExitState2( state )
	--LogService:Log("_OnBigBuildingExit2" )
	for cube in Iter( self.currentCubes ) do
		Insert(self.cubes, cube )
	end
	
	Clear( self.currentCubes ) 
	if ( self.buildingSell == false ) then

		local i = 0
		for line in Iter( self.currentLines ) do
			Insert(self.lines, line)
			EntityService:RemoveEntity(line[6])

			if i == 0 or i == 1 or i == 3 then
				local endCube = EntityService:SpawnEntity( "player/cube_builder", line[3], line[4], line[5], "" )
				AnimationService:StartAnim( endCube, "scale", false )
				EffectService:AttachEffects(endCube, "spawn")
				Insert(self.currentCubes, endCube )
			end
			i = i + 1
    	end

		Clear( self.currentLines )
		self.nextState = "big_building_state3"
		self.nextStateWaitDuration = 0.5
		self.buildingSM:ChangeState("wait")
	end
end

function building_base:_OnBigBuildingEnterState3( state )
    state:SetDurationLimit( self.extendLength )
	local i = 0
	--LogService:Log( "Ile kjubow: " .. tostring( #self.currentCubes ) ) 
	for cube in Iter( self.currentCubes ) do 
		if ( i == 0 ) then
			--------LogService:Log( "here?" )
			self:_CreateLine(cube, self.endCubeEnt, 2, 1 )
		elseif ( i == 1) then
			--------LogService:Log( "or here?" )
			self:_CreateLine(cube, self.endCubeEnt, 1, 1 )
		elseif ( i == 2 ) then
			--------LogService:Log( "or or here?" )
			self:_CreateLine(cube, self.endCubeEnt, 0, 1 )
		end		
		i = i + 1 
	end
	
	EffectService:SpawnEffect( self.entity, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end


function building_base:_OnBigBuildingExecuteState3( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_base:_OnBigBuildingExitState3( state )
	--LogService:Log("_OnBigBuildingExit3" )
	for cube in Iter( self.currentCubes ) do
		Insert(self.cubes, cube )
	end
	
	Clear( self.currentCubes ) 
	local i = 0
	for line in Iter( self.currentLines ) do
		Insert(self.lines, line)
		EntityService:RemoveEntity(line[6])

		if i == 0  then
			local endCube = EntityService:SpawnEntity( "player/cube_builder", line[3], line[4], line[5], "" )
			AnimationService:StartAnim( endCube, "scale", false )
			EffectService:AttachEffects(endCube, "spawn")
			Insert(self.cubes, endCube )
		end
		i = i + 1
    end
			
	Clear( self.currentLines )
	if ( self.buildingSell == false ) then
	
		local startPosX = EntityService:GetPositionX(self.cubeEnt)
		local startPosZ = EntityService:GetPositionZ(self.cubeEnt)
		local endPosX = EntityService:GetPositionX(self.endCubeEnt)
		local endPosZ = EntityService:GetPositionZ(self.endCubeEnt)
		local endPosY = EntityService:GetPositionY(self.endCubeEnt)

		local pX = startPosX + (endPosX - startPosX) / 2.0
		local endCube1 = EntityService:SpawnEntity( "player/cube_builder", pX, endPosY, startPosZ, "" )
		AnimationService:StartAnim( endCube1, "scale", false )
		Insert(self.currentCubes, endCube1 )
		local endCube2 = EntityService:SpawnEntity( "player/cube_builder", pX, endPosY, endPosZ, "" )
		AnimationService:StartAnim( endCube2, "scale", false )
		Insert(self.currentCubes, endCube2 )
		
		self.topPosition = { pX ,endPosY, startPosZ + ( endPosZ - startPosZ ) / 2.0 }
	
		self.nextState = "big_building_state4"
		self.nextStateWaitDuration = 0.5
		self.buildingSM:ChangeState("wait")
	end
end


function building_base:_OnBigBuildingEnterState4( state )
	--LogService:Log("_OnBigBuildingEnterState4")

	state:SetDurationLimit( self.extendLength / 2.0 )
	self.printingLine1 = self:_CreateLine(self.currentCubes[1], self.currentCubes[2], 2, 0.5 )
	self.printingLine2 = self:_CreateLine(self.currentCubes[2], self.currentCubes[1], 2, 0.5 )
	Insert(self.cubes, self.currentCubes[1] )
	Insert(self.cubes, self.currentCubes[2] )
	Clear( self.currentCubes )
	EffectService:SpawnEffect( self.entity, "effects/buildings_and_machines/building_cube_line_expand_sound" )
end


function building_base:_OnBigBuildingExecuteState4( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_base:_OnBigBuildingExitState4( state )
	--LogService:Log("_OnBigBuildingExitState4")

	local i = 0
	for line in Iter( self.currentLines ) do
		Insert(self.lines, line)
		EntityService:RemoveEntity(line[6])
    end

	Clear( self.currentLines )
	if ( self.buildingSell == false ) then
		local spawningCube = EntityService:SpawnEntity( "player/cube_builder", self.topPosition[1], self.topPosition[2], self.topPosition[3], "" )
		AnimationService:StartAnim( spawningCube, "scale", false )
		EffectService:AttachEffects(spawningCube, "spawn")
		Insert(self.cubes, spawningCube )
		self.cubeEnt = spawningCube
		self.printingCube = self.cubeEnt

		self.nextState = "building"
		self.nextStateWaitDuration = 0.5
		self.buildingSM:ChangeState("wait")
	end
end

function building_base:_OnHideScafoldingEnter( state )
	state:SetDurationLimit( self.extendLength * 2 )
	--state:SetDurationLimit( 5 )
	self.startState = 0
	self.sizeState = #self.lines / 7
	--LogService:Log( "state.start: " .. tostring(self.startState) .. ", size: " .. tostring(self.sizeState) )
end

function building_base:_OnHideScafoldingExecute( state )
	local minTime = 0
	if ( self.startState > 0 ) then
		minTime = state:GetDuration() - ((state:GetDurationLimit() / 7 ) * self.startState)
	else
		minTime = state:GetDuration()
	end
	
	local maxTime = state:GetDurationLimit() / 7
	
	local progress = minTime / maxTime
	progress = 1 - progress
	progress = math.min( progress, 1)
	progress = math.max( progress, 0)
	progress = progress * progress
	--------LogService:Log( "Min: " .. tostring(minTime) .. ", Max: " .. tostring(maxTime) )
	--------LogService:Log( "Progres: " .. tostring(progress ) )
	--------LogService:Log( "Start: " .. tostring(self.startState ) .. ", size: " .. tostring( self.sizeState ) )
	--------LogService:Log( "LineCount: " .. tostring(#self.lines ) )
	--self:_UpdateLines( 1 - progress, self.lines )	
	local i = 0
	for idx = #self.lines, 1, -1  do
		if ( i >= (self.startState * self.sizeState) and i < (self.startState + 1) * self.sizeState) then
			--------LogService:Log( tostring(i) ) 
			local scale =  (self.lines[idx][2] / 2) * progress
			EntityService:SetScale( self.lines[idx][1], scale,1,1 )
		end
		i = i + 1
    end
	if ( progress <= 0 ) then 
	

		local i = 0
		for idx = #self.lines, 1, -1  do
			if ( i >= (self.startState * self.sizeState) and i < (self.startState + 1) * self.sizeState) then
				EntityService:RemoveEntity( self.lines[idx][1] ) 
				self.lines[idx][1] = INVALID_ID
			end
			i = i + 1
		end
		local i = 0
		for idx = #self.cubes, 1, -1  do
			if ( i < self.sizeState) then
				EffectService:AttachEffects( self.cubes[idx], "vanish")
				if ( AnimationService:HasAnim( self.cubes[idx], "scale_down") ) then
					AnimationService:StartAnim( self.cubes[idx], "scale_down", false )
				end
				EntityService:CreateLifeTime( self.cubes[idx], 0.5, "" ) 
				self.cubes[idx] = nil
			end
			i = i + 1
		end
		self.startState = self.startState + 1
	end
	
end

function building_base:_OnHideScafoldingExit( state )
	for line in Iter( self.lines ) do
		EntityService:RemoveEntity( line[1]  )
    end
	Clear( self.lines )
	
	for cube in Iter( self.cubes ) do
		EffectService:AttachEffects( cube, "vanish")	
		if ( AnimationService:HasAnim( cube, "scale_down") ) then
			AnimationService:StartAnim( cube, "scale_down", false )
		end
		EntityService:CreateLifeTime( cube, 0.5, "" ) 
    end
	
	Clear( self.cubes )

	self:RemoveBuildingStateMachine()
end

function building_base:_OnActivate()
	EffectService:AttachDelayedEffects(self.entity, "working", 0.1)	
	self.working = true
	self.data:SetFloat("is_working", 1.0 )
	self:OnActivate()
	if ( self.hasTurret ) then
		self:SetTurretMode("3")
	end
	BuildingService:OperateBuildingStorage(self.entity, true)
end

function building_base:_OnDeactivate()
	EffectService:DestroyEffectsByGroup(self.entity, "powered")
	self.working = false;
	self.data:SetFloat("is_working", 0.0 )
	EffectService:DestroyEffectsByGroup(self.entity, "working")	
	self:OnDeactivate()	
	
	if ( self.hasTurret ) then
		self:SetTurretMode("2")
	end
	
	BuildingService:OperateBuildingStorage(self.entity, false )
end


function building_base:OnActivate()
end

function building_base:OnDeactivate()
end

function building_base:OnInit()
end

function building_base:OnBuildingStart()
end

function building_base:OnBuild()
end

function building_base:OnCubeFlyStart()
end

function building_base:OnBuildingEnd()
end

function building_base:_OnBuildingEnd()
	self:OnBuildingEnd()
	self.hasTurret = EntityService:GetComponent(self.entity, "TurretComponent" ) ~= nil
	if ( self.hasTurret ) then
		if ( self.working ) then
			self:SetTurretMode("3")
		else
			self:SetTurretMode("2")
		end
	end
	if ( self.buildingSell == false and self.buildingFinished == 0 and self.data:GetIntOrDefault("remove_lua_after_build", 0) == 1) then
		QueueEvent("RemoveBuildingLuaComponent", self.entity )
	end

end
function building_base:OnSellStart()
end

function building_base:OnOverride()
end

function building_base:OnSell()
end

function building_base:_OnBuildingPoweredEvent()
	if ( self.power == -1 or self.power == 0 ) then 	
		self.power = 1
		self.data:SetInt("power", self.power )
		EntityService:SetGraphicsUniform( self.meshEnt, "cGlowFactor", 1 )
		EffectService:AttachEffects(self.entity, "powered")
	end
	
end

function building_base:_OnBuildingPowerOffEvent()
	if ( self.power == -1 or self.power == 1 ) then
		self.power = 0
		self.data:SetInt("power", self.power)
		EntityService:SetGraphicsUniform( self.meshEnt, "cGlowFactor", 0 )
		EffectService:DestroyEffectsByGroup(self.entity, "powered")
	end
end

function building_base:_OnBuildingResourceGranted()
	if ( self.resource == -1 or self.resource == 0 ) then 	
		self.resource = 1
		self.data:SetInt("resource", self.resource )
	end
end

function building_base:_OnBuildingResourceMissing()
	if ( self.resource == -1 or self.resource == 1 ) then
		self.resource = 0
		self.data:SetInt("resource", self.resource)
	end
end

function building_base:RemoveAllBuilidingEntities()
	if ( self.printingOrigin ~= nil ) then
		EntityService:RemoveEntity( self.printingOrigin )
		self.printingOrigin = nil
	end
	if ( self.cubes ~= nil and #self.cubes > 0 ) then
		for line in Iter( self.lines ) do
			EntityService:RemoveEntity( line[1]  )
			EntityService:RemoveEntity( line[6]  )
		end
		for line in Iter( self.currentLines ) do
			EntityService:RemoveEntity( line[1]  )
			EntityService:RemoveEntity( line[6]  )
		end
		Clear( self.lines )
		Clear( self.currentLines )


		for cube in Iter( self.cubes ) do
			AnimationService:StopAnims( cube )
			if ( AnimationService:HasAnim( cube, "scale_down") ) then
				AnimationService:StartAnim( cube, "scale_down", false )
			end
			EntityService:CreateLifeTime( cube, 0.5, "" ) 
		end
		for cube in Iter( self.currentCubes) do
			AnimationService:StopAnims( cube )
			if ( AnimationService:HasAnim( cube, "scale_down") ) then
				AnimationService:StartAnim( cube, "scale_down", false )
			end
			EntityService:CreateLifeTime( cube, 0.5, "" ) 
		end
		
		Clear( self.cubes )
		Clear( self.currentCubes )
	end
end


function building_base:OnRemove()
	return false
end

function building_base:BuildingModified()
end

function building_base:RemoveBuildingStateMachine()
	if (Assert( self.buildingSM ~= nil,"Error: trying to destroy empty state machine") and self.buildingSell == false and self.buildingFinished == 0) then
		self:DestroyStateMachine( self.buildingSM )
		self.buildingSM = nil
	end
end

function building_base:OnLoad()
	day_cycle_machine.OnLoad( self )
	self.childrenToUpdate = self.childrenToUpdate or {} 
	self.isFloor = self.isFloor or self.buildingType == "floor"
	self.meshEnt = self.meshEnt or BuildingService:GetMeshEntity(self.entity)
	self.hasTurret = self.hasTurret or EntityService:GetComponent(self.entity, "TurretComponent" ) ~= nil
	if ( self.hasTurret ) then
		if ( self.working ) then
			self:SetTurretMode("3")
		else
			self:SetTurretMode("2")
		end
	end
	local buildingComponent = EntityService:GetComponent(self.entity, "BuildingComponent")
	local buildingType = buildingComponent:GetField("type"):GetValue()
	self.buildingType = buildingType
	self.buildingName = buildingComponent:GetField("name"):GetValue()

	if ( self.buildingSM and self.buildingSM:GetCurrentState() == "") then
		self:RemoveBuildingStateMachine()
	end

	if ( self.version == nil or self.version < 1 ) then
		self:UnregisterHandler( self.entity, "BuildingBuildEndEvent", "OnBuildingEnd" )
		self:RegisterHandler( self.entity, "BuildingBuildEndEvent", "_OnBuildingEnd" )
		EntityService:LoadMissingDatabaseKeysFromBlueprint( self.entity )
		self.version = 1
	end
	if ( self.version < 2 ) then
		self.data:RemoveKey("activated")
	end
	local blueprintDatabase = EntityService:GetBlueprintDatabase( self.entity )
	if ( self.buildingSell == false and self.buildingFinished == 0 and blueprintDatabase:GetIntOrDefault("remove_lua_after_build", 0) == 1) then
		QueueEvent("RemoveBuildingLuaComponent", self.entity )
	end

    if ( BuildingService:IsBuildingFinished( self.entity ) and not EntityService:GetComponent( self.entity, "InteractiveComponent" ) ) then
		local blueprint = ResourceManager:GetBlueprint( EntityService:GetBlueprintName( self.entity ))
        if ( blueprint ) then
			local interactive = blueprint:GetComponent( "InteractiveComponent" )
			if ( interactive ) then
				QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "InteractiveComponent" )
			end
		end
	end

	if not self.display_radius_size then
		self:InitializeDisplayRadiusHandlers();
	end

	if ( not self.disabledTreasures  ) then
		self.disabledTreasures = {}
		local buildingComponent  = EntityService:GetConstComponent(self.entity, "BuildingDesc")
		if (buildingComponent ~= nil ) then
			local hide_treasures = buildingComponent:GetField( "hide_treasures" ):GetValue()		
			if ( hide_treasures == "1" ) then
				self:DisableTreasuresUnder()
			end
		end
	end
end

function building_base:DisableTreasuresUnder()
    local predicate = {
        signature="TreasureComponent",
    };
	local size = BuildingService:GetBuildingGridSize( self.entity )
	local position = EntityService:GetPosition( self.entity )

	self.disabledTreasures = FindService:FindEntitiesByPredicateInBox( VectorSub(position,size), VectorAdd(position, size), predicate );
	
	for ent in Iter( self.disabledTreasures ) do
		EntityService:DisableComponent( ent, "TreasureComponent" )
		EntityService:DisableComponent( ent, "InteractiveComponent" )
		EntityService:DisableComponent( ent, "MinimapItemComponent" )
	end
end

function building_base:EnableTreasuresUnder()
	for ent in Iter( self.disabledTreasures ) do
		EntityService:EnableComponent( ent, "TreasureComponent" )
		EntityService:EnableComponent( ent, "InteractiveComponent" )
		EntityService:EnableComponent( ent, "MinimapItemComponent" )
	end
	self.disabledTreasures = {}

end

function building_base:SetTurretMode( mode )
	local turretComponent = EntityService:GetComponent( self.entity, "TurretComponent")
	if ( turretComponent ) then
		turretComponent:GetField("mode"):SetValue(mode)
	end
end

function building_base:InitializeDisplayRadiusHandlers()
	local min, max = GetBuildingDisplayRadius(self.entity)
	if max ~= nil then
		self:RegisterHandler( event_sink, "LuaGlobalEvent", "_OnShowHideDisplayRadius" )
		self:RegisterHandler( self.entity, "OperateActionMenuEvent", "_OnOperateActionMenuEvent")

		local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
		self.display_radius_size = { min = min or 0, max = max }
		self.display_effect_blueprint = database:GetStringOrDefault( "display_radius_blueprint", "effects/decals/range_circle" )
		self.display_radius_group = database:GetStringOrDefault( "display_radius_group", tostring(self.entity) )
		self.display_radius_requesters = {}
	end
end

function building_base:_OnShowHideDisplayRadius(evt)
	local eventName = evt:GetEvent()
	if eventName == EVENT_SHOW_BUILDING_DISPLAY_RADIUS and evt:GetDatabase():GetString("display_radius_group") == self.display_radius_group then
		self:UpdateDisplayRadiusVisibility(true, evt:GetEntity());
	elseif eventName == EVENT_HIDE_BUILDING_DISPLAY_RADIUS and evt:GetDatabase():GetString("display_radius_group") == self.display_radius_group then
		self:UpdateDisplayRadiusVisibility(false, evt:GetEntity());
	end
end

function building_base:_OnOperateActionMenuEvent(evt)
	if not self.display_radius_size then
		return
	end

	if evt:GetMenu() then
		if not ShowBuildingDisplayRadiusAround( self.entity, self.entity ) then
			self:UpdateDisplayRadiusVisibility( true, self.entity );
		end
	else
		if not HideBuildingDisplayRadiusAround( self.entity, self.entity ) then
			self:UpdateDisplayRadiusVisibility( false, self.entity );
		end
	end
end

function building_base:UpdateDisplayRadiusVisibility( show, entity )
	if show then
		if self.display_radius_requesters[ entity ] then
			return
		end

		self.display_radius_requesters[ entity ] = true

		local count = 0
		for entity,_ in pairs(self.display_radius_requesters) do
			count = count + 1
		end

		if count == 1 then
			EntityService:RemoveComponent( self.entity, "DisplayRadiusComponent" );

			local component = reflection_helper( EntityService:CreateComponent(self.entity,"DisplayRadiusComponent") );
			component.min_radius = self.display_radius_size.min;
			component.max_radius = self.display_radius_size.max;
			component.max_radius_blueprint = self.display_effect_blueprint;
		end
	else
		self.display_radius_requesters[ entity ] = nil

		local count = 0
		for entity,_ in pairs(self.display_radius_requesters) do
			count = count + 1
		end
		
		if count == 0 then
			EntityService:RemoveComponent( self.entity, "DisplayRadiusComponent" );
		end
	end
end

return building_base
