require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/database_utils.lua")

local day_cycle_machine = require("lua/utils/day_cycle_machine.lua")

class 'building_creator' ( day_cycle_machine )

function building_creator:__init()
	day_cycle_machine.__init(self,self)
end

function building_creator:CalculateBuildingBuildTime( database )
	if ( database:HasFloat( "building_time_left") == true ) then
		return database:GetFloat( "building_time_left"  )
	end

	if ( BuildingService.CalculateBuildTime ) then
		return BuildingService:CalculateBuildTime( self.parent );
	end
	
	local time = self.data:GetFloatOrDefault( "building_time", 1 )
	return time * BuildingService:GetBuildingSpeedMultiplier() * DifficultyService:GetBuildingSpeedMultiplier()
end

function GetOwner( entity )
	local buildingComponent = EntityService:GetComponent( entity ,"BuildingComponent")
	if buildingComponent == nil then
		return 0
	end
	local helper = reflection_helper(buildingComponent)
	return helper.owner
end

function building_creator:init()
	self.version = 1

	self.parent = EntityService:GetParent( self.entity )
	self:RegisterHandler( self.parent, "BuildingStartEvent",  "_OnBuild" )
	self:RegisterHandler( self.parent, "BuildingFastForwardEvent", "_OnBuildingFastForwardEvent" )
	self:RegisterHandler( self.parent, "BuildingBuildEvent", "OnBuildingBuildEvent" )
	
	local database = EntityService:GetDatabase( self.parent )
	DatabaseConcatenate( self.data , database )

	local buildingComponent = EntityService:GetComponent(self.parent, "BuildingComponent")
	self.buildingType = buildingComponent:GetField("type"):GetValue()
	self.buildingName = buildingComponent:GetField("name"):GetValue()

	self.meshEnt = BuildingService:GetMeshEntity(self.parent);
	self.buildingTime = math.max( 0.1, self:CalculateBuildingBuildTime( self.data ) )
	self.materials = self:GetMaterials()
	self.buildingMultiplier =  math.max( 0.1,  ConsoleService:GetConfig("building_speed_multiplier") )

	self:CreateBuildingStateMachine()
	self.extendLength = 0.5
	self.lastProgress = 0
	self.currentLines = {}
	self.lines = {}
	self.currentCubes = {}
	self.cubes = {}
	self.buildingFinished = 0
	self.buildingSell = false
	self.printingLine1 = nil
	self.printingLine2 = nil
	self.printingCube  = nil
	self.dissolveCurrent = 0
	self.forwardTime = 0
	self.timeMachine = 0
	self.isFloor = self.buildingType == "floor"
	self.checkCollision = self.isFloor == false and  self.data:GetIntOrDefault("check_collison", 1 )
	self.nextState = ""
	self.owner = GetOwner( self.parent )

end

function building_creator:CreateBuildingStateMachine()
	if ( self.buildingSM) then
		return 
	end

	self.buildingSM = self:CreateStateMachine()
	self.buildingSM:AddState( "cube_fly", { from="*", enter="_OnCubeFlyEnter", exit="_OnCubeFlyExit", execute="_OnCubeFlyExecute" } )
	self.buildingSM:AddState( "building", { from="*", enter="_OnBuildingEnter", execute="_OnBuildingExecute", exit="_OnBuildingExit" } )
	self.buildingSM:AddState( "wait", { from="*", enter="_OnWaitEnter", exit="_OnWaitExit" } )
	self.buildingSM:AddState( "big_building_state1", { from="*", enter="_OnBigBuildingEnterState1", execute="_OnBigBuildingExecuteState1", exit="_OnBigBuildingExitState1" } )
	self.buildingSM:AddState( "big_building_state2", { from="*", enter="_OnBigBuildingEnterState2", execute="_OnBigBuildingExecuteState2", exit="_OnBigBuildingExitState2" } )
	self.buildingSM:AddState( "big_building_state3", { from="*", enter="_OnBigBuildingEnterState3", execute="_OnBigBuildingExecuteState3", exit="_OnBigBuildingExitState3" } )
	self.buildingSM:AddState( "big_building_state4", { from="*", enter="_OnBigBuildingEnterState4", execute="_OnBigBuildingExecuteState4", exit="_OnBigBuildingExitState4" } )
	self.buildingSM:AddState( "hide_scaffolding", { from="*", enter="_OnHideScafoldingEnter", execute="_OnHideScafoldingExecute", exit="_OnHideScafoldingExit" } )
	self.buildingSM:AddState( "wait_for_space", { from="*", execute="_OnWaitForSpace" } )
	
end

function building_creator:GetMaterials()
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

function building_creator:OnRelease()
	self:RemoveAllBuilidingEntities()
end

function building_creator:CreateBaseCubes()
	local createCubes = self.data:GetIntOrDefault("create_cubes", 1) == 1
	local cubes =  BuildingService:FlyCubesToBuilding(self.parent, self.owner , not self.isFloor and createCubes , not self.isFloor and createCubes)		
	self.cubeEnt = cubes.first
	self.endCubeEnt = cubes.second
end

function building_creator:_OnBuild(evt)
	self.buildingFinished = 2;
	self.upgrading = evt:GetUpgrading()
	self.data:SetInt( "owner", self.owner  )
	self.cubeEnt = evt:GetCubeEnt()
	self.endCubeEnt = evt:GetEndCubeEnt()
	self.cubeEffects = evt:GetEffects()
	if ( EntityService:IsAlive(self.cubeEnt) == false ) then
		self:CreateBaseCubes()
	end
	if ( self.upgrading ) then
		EffectService:AttachEffect(self.parent,  "effects/buildings_and_machines/building_upgrade")
	end
	
	local timer = self.buildingTime ;
	self.timerEnt = nil
	if ( timer > 10 ) then
		if ( self.upgrading ) then
			self.timerEnt = BuildingService:AttachGuiTimerWithMaterial( self.parent, timer, true,  "gui/hud/bars/upgrade_timer" )
		else
			self.timerEnt = BuildingService:AttachGuiTimer( self.parent, timer, true )
		end
	end	
	self.buildingSM:ChangeState("cube_fly")
end

function building_creator:_OnWaitEnter( state )
	state:SetDurationLimit( self.nextStateWaitDuration )
end

function building_creator:OnBuildingBuildEvent()
end

function building_creator:_OnWaitExit( state )
	if (self.buildingSell == true  ) then
		return
	end
	self.buildingSM:ChangeState(self.nextState)
	self.nextState = ""
end

function building_creator:_OnCubeFlyEnter( state )
	if ( AnimationService:HasAnim( self.cubeEnt, "fly_and_scale") ) then
		AnimationService:StartAnim( self.cubeEnt, "fly_and_scale", false, 4 )
	end
	EffectService:AttachEffects(self.cubeEnt, "fly")
	EntityService:SetMaterial( self.meshEnt, "selector/hologram_blue_depth", "default"  )

	Insert(self.cubes, self.cubeEnt )
	
	if (  BuildingService:IsFloor( self.parent ) ) then	
		state:Exit();
	elseif ( EntityService:IsAlive( self.cubeEnt ) == true ) then
		self:RegisterHandler( self.cubeEnt, "MoveEndEvent", "OnMoveEndEvent" )
	end
end

function building_creator:_OnCubeFlyExecute( state )
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_creator:_OnCubeFlyExit( state )
	if ( self.buildingSell == false ) then
		EffectService:DestroyEffectsByGroup(self.cubeEnt, "fly")

		local spaceOccupied = BuildingService:IsBuildingSpaceOccupied( self.parent )
		if ( spaceOccupied == false or self.checkCollision == false ) then

			if ( EntityService:IsAlive( self.endCubeEnt ) == true and self.forwardTime <= 0 and not BuildingService:IsFloor( self.parent )  ) then
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

function building_creator:OnMoveEndEvent( evt )
	if (self.buildingSM ~= nil and  evt:GetEntity() == self.cubeEnt) then
		self.buildingSM:Deactivate()
	end
end

function building_creator:_OnWaitForSpace( state )
	--LogService:Log("_OnWaitForSpace")
	if (self.buildingSell == true  ) then
		return
	end
		local spaceOccupied = BuildingService:IsBuildingSpaceOccupied( self.parent )
		if ( spaceOccupied == false ) then
			if ( self.timerEnt ~= nil ) then
				BuildingService:ResumeGuiTimer( self.timerEnt )
			end
			BuildingService:EnablePhysics( self.parent )
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

function building_creator:_OnBuildingEnter( state )
	
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
	local database = EntityService:GetDatabase( self.parent )	
	self.buildingTime = math.max( 0.1, self:CalculateBuildingBuildTime( database ) )
	
	state:SetDurationLimit( self.buildingTime )

	for i, material in ipairs(self:GetMaterials()) do
		EntityService:SetSubMeshMaterial( self.meshEnt, material .. "_dissolve", i - 1, "default" )
	end

	self.dissolveCurrent = 1;
    EntityService:SetGraphicsUniform( self.meshEnt, "cDissolveAmount", self.dissolveCurrent )
	EntityService:SetMaterial( self.meshEnt, "selector/hologram_blue_depth" , "dissolve" )

    if ( self.printingCube ~= nil ) then
		self.printingData1 = { EntityService:GetPositionX( self.printingCube ), EntityService:GetPositionY( self.printingCube ), EntityService:GetPositionZ( self.printingCube ) }
		self.printingData2 = { EntityService:GetPositionX( self.printingLine1 ), EntityService:GetPositionY( self.printingLine1 ), EntityService:GetPositionZ( self.printingLine1 ) }
		self.printingData3 = { EntityService:GetPositionX( self.printingLine2 ), EntityService:GetPositionY( self.printingLine2 ), EntityService:GetPositionZ( self.printingLine2 ) }
	end

end

function building_creator:_OnBuildingExecute( state )
	local currentDuration = state:GetDuration() + self.forwardTime

    local progress = currentDuration / state:GetDurationLimit()
	self.lastProgress = progress
	self.dissolveCurrent = 1 - progress
    EntityService:SetGraphicsUniform( self.meshEnt, "cDissolveAmount", self.dissolveCurrent )

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

function building_creator:_OnBuildingFastForwardEvent( evt )
	self.forwardTime = self.forwardTime + evt:GetDeltaTime()
end

function building_creator:_OnBuildingExit( state )
	self.forwardTime = 0
	self:UnregisterHandler( self.parent, "BuildingFastForwardEvent", "_OnBuildingFastForwardEvent" )
	if ( self.buildingSell == true ) then
		return
	end
	
	EntityService:RemoveMaterial( self.meshEnt, "dissolve" )
	for i, material in ipairs( self.materials ) do
		EntityService:SetSubMeshMaterial( self.meshEnt, material, i - 1, "default" )
	end

	EntityService:RemoveGraphicsUniform( self.meshEnt, "cDissolveAmount" )

	EffectService:DestroyEffectsByGroup(self.cubeEnt, "build_cone")
	if ( EntityService:IsAlive(self.endCubeEnt) == true ) then
		EntityService:RemoveEntity( self.endCubeEnt )
		self.endCubeEnt = nil
	end

	self.buildingSM:ChangeState("hide_scaffolding")
	self.buildingFinished = 0;

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

function building_creator:_CreateLine( ent1, ent2, dir, lengthMultiplier )
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

function building_creator:_OnBigBuildingEnterState1( state )
    state:SetDurationLimit( self.extendLength * self.buildingMultiplier )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 0, 1 )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 1, 1 )
	self:_CreateLine(self.cubeEnt, self.endCubeEnt, 2, 1 )
	
	EffectService:SpawnEffect( self.parent, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	--LogService:Log("_OnBigBuildingEnter1" )
end

function building_creator:_UpdateLines( progress, lines )
	progress = math.min( progress, 1)
	progress = math.max( progress, 0)
	progress = progress * progress
	for line in Iter( lines ) do
		local scale =  (line[2] / 2) * progress
		EntityService:SetScale( line[1], scale,1,1 )
		EntityService:SetScale( line[6], 1/scale,1,1 )
    end
end

function building_creator:_OnBigBuildingExecuteState1( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_creator:_OnBigBuildingExitState1( state )
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

function building_creator:_OnBigBuildingEnterState2( state )
    state:SetDurationLimit( self.extendLength * self.buildingMultiplier )
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
	
	EffectService:SpawnEffect( self.parent, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	--LogService:Log("_OnBigBuildingEnter2" )
end


function building_creator:_OnBigBuildingExecuteState2( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_creator:_OnBigBuildingExitState2( state )
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

function building_creator:_OnBigBuildingEnterState3( state )
    state:SetDurationLimit( self.extendLength * self.buildingMultiplier )
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
	
	EffectService:SpawnEffect( self.parent, "effects/buildings_and_machines/building_cube_line_expand_sound" )
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end


function building_creator:_OnBigBuildingExecuteState3( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_creator:_OnBigBuildingExitState3( state )
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


function building_creator:_OnBigBuildingEnterState4( state )
	--LogService:Log("_OnBigBuildingEnterState4")

	state:SetDurationLimit( (self.extendLength / 2.0) * self.buildingMultiplier )
	self.printingLine1 = self:_CreateLine(self.currentCubes[1], self.currentCubes[2], 2, 0.5 )
	self.printingLine2 = self:_CreateLine(self.currentCubes[2], self.currentCubes[1], 2, 0.5 )
	Insert(self.cubes, self.currentCubes[1] )
	Insert(self.cubes, self.currentCubes[2] )
	Clear( self.currentCubes )
	EffectService:SpawnEffect( self.parent, "effects/buildings_and_machines/building_cube_line_expand_sound" )
end


function building_creator:_OnBigBuildingExecuteState4( state )
	local progress = state:GetDuration() / state:GetDurationLimit()
	self:_UpdateLines(progress, self.currentLines)	
	if(self.forwardTime > 0 ) then
		state:Exit();
	end	
end

function building_creator:_OnBigBuildingExitState4( state )
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

function building_creator:_OnHideScafoldingEnter( state )
	state:SetDurationLimit( self.extendLength * 2 )
	--state:SetDurationLimit( 5 )
	self.startState = 0
	self.sizeState = #self.lines / 7
	--LogService:Log( "state.start: " .. tostring(self.startState) .. ", size: " .. tostring(self.sizeState) )
end

function building_creator:_OnHideScafoldingExecute( state )
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
				if ( EntityService:IsAlive( self.cubes[idx] ) ) then
					EntityService:CreateLifeTime( self.cubes[idx], 0.5, "" ) 
				end
				self.cubes[idx] = nil
			end
			i = i + 1
		end
		self.startState = self.startState + 1
	end
	
end

function building_creator:_OnHideScafoldingExit( state )
	for line in Iter( self.lines ) do
		EntityService:RemoveEntity( line[1]  )
    end
	Clear( self.lines )
	
	for cube in Iter( self.cubes ) do
		EffectService:AttachEffects( cube, "vanish")	
		if ( AnimationService:HasAnim( cube, "scale_down") ) then
			AnimationService:StartAnim( cube, "scale_down", false )
		end
		if ( EntityService:IsAlive( cube ) ) then
			EntityService:CreateLifeTime( cube, 0.5, "" ) 
		end
    end
	
	Clear( self.cubes )

	EntityService:RemoveEntity( self.entity )
end

function building_creator:RemoveAllBuilidingEntities()
	if ( self.printingOrigin ~= nil ) then
		EntityService:RemoveEntity( self.printingOrigin )
		self.printingOrigin = nil
	end
	EntityService:RemoveEntity(self.cubeEnt)
	if (#self.cubes > 0 ) then
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
			if ( EntityService:IsAlive( cube ) ) then
				EntityService:CreateLifeTime( cube, 0.5, "" ) 
			end
		end
		for cube in Iter( self.currentCubes) do
			AnimationService:StopAnims( cube )
			if ( AnimationService:HasAnim( cube, "scale_down") ) then
				AnimationService:StartAnim( cube, "scale_down", false )
			end
			if ( EntityService:IsAlive( cube ) ) then
				EntityService:CreateLifeTime( cube, 0.5, "" ) 
			end
		end
		
		Clear( self.cubes )
		Clear( self.currentCubes )
	end
end

function building_creator:OnLoad()
	self.buildingMultiplier =  math.max( 0.1, ConsoleService:GetConfig("building_speed_multiplier") )
end

return building_creator