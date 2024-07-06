require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local building = require("lua/buildings/building.lua")
class 'drone_spawner_building' ( building )

local DRONE_SPAWNER_BUILDING_REMOVE_OPERATE_ACTION_MENU = 1
local DRONE_SPAWNER_BUILDING_CURRENT_VERSION = DRONE_SPAWNER_BUILDING_REMOVE_OPERATE_ACTION_MENU

local DRONE_FADE_TIME = 0.3

function drone_spawner_building:__init()
	building.__init(self,self)
end

function drone_spawner_building:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
	self.drone_search_radius = database:GetFloatOrDefault("drone_search_radius", database:GetFloatOrDefault("radius", 25.0));
	self.drone_attachments = database:GetStringOrDefault( "drone_attachments", "att_landing" )
	self.drone_per_attachment = database:GetIntOrDefault( "drone_per_spot", 2 )
	self.drones_visible = database:GetIntOrDefault( "drone_visible_on_spot", 1 ) == 1
	self.drone_blueprint = database:GetStringOrDefault( "drone_blueprint", "error" )
end

function drone_spawner_building:OnInit()
	self.drones = {}
	self.drones_visible = true
	self.version = DRONE_SPAWNER_BUILDING_CURRENT_VERSION
	self:FillInitialParams();

	self:AttachEventHandlersToLootCollector()
end

function drone_spawner_building:SpawnLandingSpots()
	if ( self.drone_landing_spots == nil or #self.drone_landing_spots == 0 ) then
		self.drone_landing_spots = {}

		local attachments = Split( self.drone_attachments, "," )
		for spot in Iter( attachments ) do
			local entity = EntityService:SpawnAndAttachEntity(self.entity, spot );
			Insert(self.drone_landing_spots, entity);
		end
	end
end

function drone_spawner_building:OnOperateActionMenuEvent()
end

function drone_spawner_building:OnLoad()
	--self.version = self.version or 0
	--if self.version < DRONE_SPAWNER_BUILDING_REMOVE_OPERATE_ACTION_MENU then
	--	self:UnregisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
--
	--	self.version = DRONE_SPAWNER_BUILDING_REMOVE_OPERATE_ACTION_MENU
	--end
	self:FillInitialParams();
	self:SpawnLandingSpots();
	self:SpawnDrones()

	building.OnLoad(self)

	self:AttachEventHandlersToLootCollector()
end

function drone_spawner_building:AttachEventHandlersToLootCollector()

	local blueprintName = EntityService:GetBlueprintName(self.entity)
	local lowName = BuildingService:FindLowUpgrade( blueprintName )
	if ( lowName ~= "loot_collector" ) then
		return
	end

	self:CreateCenterPoint()
	self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

	self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
	self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

	self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
	self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function drone_spawner_building:UpdateActiveDrones(drone, active)
	if active then
		QueueEvent( "EnableDroneRequest", drone )
	else
		QueueEvent( "DisableDroneRequest", drone )
	end

	local drones_achievement = _G["drones_achievement"] or { drones = {}, triggered = false }
	if active then
		drones_achievement.drones[ drone ] = true

		local drones_count = 0
		for drone,_ in pairs(drones_achievement.drones) do
			drones_count = drones_count + 1
		end

		if not drones_achievement.triggered and drones_count >= 50 then
			drones_achievement.triggered = true
			CampaignService:UnlockAchievement( ACHIEVEMENT_I_AM_THE_SWARM )
		end
	else
		drones_achievement.drones[ drone ] = nil
	end

	_G["drones_achievement"] = drones_achievement
end

function drone_spawner_building:OnBuildingEnd()
	self:SpawnLandingSpots()
	self:SpawnDrones()
end

function drone_spawner_building:OnActivate()
	for drone in Iter( self.drones ) do
		self:UpdateActiveDrones(drone, true)
	end
end

function drone_spawner_building:OnDeactivate()
	for drone in Iter( self.drones ) do
		self:UpdateActiveDrones(drone, false)
	end
end

function drone_spawner_building:SpawnDrones()
	self:CleanupDrones();

	local isActive = self.working;

	local blueprints = Split( self.drone_blueprint, ",")

	local droneIdx = 0;
	for attachment in Iter( self.drone_landing_spots ) do
		for i=1,self.drone_per_attachment do
			local drone_blueprint = blueprints[ (droneIdx % #blueprints) + 1 ]
			local drone = EntityService:SpawnEntity( drone_blueprint, attachment, EntityService:GetTeam(self.entity) )
			EntityService:SetScale( drone, 0.75,0.75,0.75 )

			UnitService:SetCurrentTarget( drone, "owner", attachment )
			if self.drones_visible then
				EntityService:FadeEntity( drone, DD_FADE_IN, DRONE_FADE_TIME )
			else
				--QueueEvent( "FadeEntityOutRequest", drone, 1 )
				EntityService:FadeEntity( drone, DD_FADE_OUT, 1 )
			end

			self:RegisterHandler( drone, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
			self:RegisterHandler( drone, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
			self:RegisterHandler( drone, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
			self:RegisterHandler( drone, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
			self:DroneSpawned( drone )

			local database = EntityService:GetDatabase( drone )
			database:SetInt("drone_id", droneIdx )
			database:SetFloat("drone_search_radius", self.drone_search_radius )
			droneIdx = droneIdx + 1
			Insert( self.drones, drone )

			self:UpdateActiveDrones( drone, isActive )
		end
	end
end

function drone_spawner_building:CleanupDrones( skipReleaseEvents )

	for drone in Iter( self.drones ) do
		self:UpdateActiveDrones(drone, false)

		if ( not skipReleaseEvents ) then
			self:UnregisterHandler( drone, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
			self:UnregisterHandler( drone, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
			self:UnregisterHandler( drone, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
			self:UnregisterHandler( drone, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
		end
		QueueEvent( "EmitStateMachineEventRequest", drone, "state_dead" )
		QueueEvent( "DissolveEntityRequest", drone, 0.5, 0.0 )
	end

	Clear(self.drones)
end

function drone_spawner_building:OnSellStart()
	self:CleanupDrones()
end

function drone_spawner_building:OnOverride()
	self:CleanupDrones()
end

function drone_spawner_building:OnRemove()
	self:CleanupDrones( true )
end

function drone_spawner_building:_OnDroneLiftingStartedEvent(evt)
	if not self.drones_visible then
		EntityService:FadeEntity( evt:GetEntity(), DD_FADE_IN, DRONE_FADE_TIME )
	end

	self:OnDroneLiftingStarted(evt:GetEntity())
end

function drone_spawner_building:_OnDroneLandingStartedEvent(evt)
	self:OnDroneLandingStarted(evt:GetEntity())
end

function drone_spawner_building:_OnDroneLiftingEndedEvent(evt)
	self:OnDroneLiftingEnded(evt:GetEntity())
end

function drone_spawner_building:_OnDroneLandingEndedEvent(evt)
	if not self.drones_visible then
		--QueueEvent( "FadeEntityOutRequest", evt:GetEntity(), 1.0 )
		EntityService:FadeEntity( evt:GetEntity(), DD_FADE_OUT, 1.0 )
	end

	self:OnDroneLandingEnded(evt:GetEntity())
end

function drone_spawner_building:OnDroneLiftingStarted( )
end

function drone_spawner_building:OnDroneLandingStarted( )
end

function drone_spawner_building:DroneSpawned( drone )
end

function drone_spawner_building:OnDroneLiftingEnded( )
end

function drone_spawner_building:OnDroneLandingEnded( )
end

-- #region Drone Point

function drone_spawner_building:CreateCenterPoint()

	local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

	local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

	local pointEntityBlueprintName = "misc/area_center_point"

	if ( self.pointEntity ~= nil and not EntityService:IsAlive(self.pointEntity) ) then
		self.pointEntity = nil
	end

	if ( self.pointEntity ~= nil ) then

		local pointEntityParent = EntityService:GetParent( self.pointEntity )

		if ( pointEntityParent == nil or pointEntityParent == INVALID_ID or pointEntityParent ~= self.entity ) then
			self.pointEntity = nil
		end
	end

	if ( self.pointEntity == nil ) then

		local children = EntityService:GetChildren( self.entity, true )
		for child in Iter(children) do
			local blueprintName = EntityService:GetBlueprintName( child )
			if ( blueprintName == pointEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

				self.pointEntity = child
				ItemService:SetInvisible(self.pointEntity, true)

				break
			end
		end
	end

	if ( self.pointEntity == nil ) then

		local newPositionX = 0
		local newPositionZ = 0

		if ( self.data:HasVector(selfLowName .. "_center_point_vector") ) then
			local vector = self.data:GetVector(selfLowName .. "_center_point_vector")

			newPositionX = vector.x
			newPositionZ = vector.z
		end

		local team = EntityService:GetTeam( self.entity )
		self.pointEntity = EntityService:SpawnAndAttachEntity( pointEntityBlueprintName, self.entity, team )

		ItemService:SetInvisible(self.pointEntity, true)

		self:SetCenterPointPosition( newPositionX, newPositionZ )
	end

	if ( self.pointEntity ~= nil ) then

		local children = EntityService:GetChildren( self.entity, true )
		for child in Iter(children) do
			local blueprintName = EntityService:GetBlueprintName( child )
			if ( blueprintName == pointEntityBlueprintName and child ~= self.pointEntity ) then
				EntityService:RemoveEntity( child )
			end
		end
	end

	EntityService:SetName( self.pointEntity, "center_point_entity" )

	self.data:SetInt("center_point_entity", self.pointEntity)
end

function drone_spawner_building:OnDronePointEvent(evt)

	local eventName = evt:GetEvent()
	local eventDatabase = evt:GetDatabase()
	local eventEntity = evt:GetEntity()

	if ( eventEntity ~= self.entity ) then
		return
	end

	if ( eventName == "AreaCenterPointChangeEvent" ) then

		local selfPosition = EntityService:GetPosition( self.entity )

		local newPositionX = eventDatabase:GetFloat("point_x") - selfPosition.x
		local newPositionZ = eventDatabase:GetFloat("point_z") - selfPosition.z

		self:SetCenterPointPosition( newPositionX, newPositionZ )

	elseif ( eventName == "AreaCenterPointSelectedEvent" ) then

		local selected = ( eventDatabase:GetStringOrDefault("isBuildingSelected", "0") == "1" )

		self.dronePointSelected = selected

		self:UpdateDronePointSkinMaterial()
	end
end

function drone_spawner_building:OnActivateEntityRequestDronePoint( evt )

	if ( evt:GetEntity() ~= self.entity) then
		return
	end

	self.dronePointSelected = true

	self:UpdateDronePointSkinMaterial()
end

function drone_spawner_building:OnDeactivateEntityRequestDronePoint( evt )

	if ( evt:GetEntity() ~= self.entity) then
		return
	end

	self.dronePointSelected = false

	self:UpdateDronePointSkinMaterial()
end

function drone_spawner_building:SetCenterPointPosition( newPositionX, newPositionZ )

	local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

	local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

	local newRelativePosition ={
		x = newPositionX,
		y = 0,
		z = newPositionZ
	}

	self.data:SetVector(selfLowName .. "_center_point_vector", newRelativePosition)

	local transform = EntityService:GetWorldTransform( self.entity )

	local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

	local pointX = SnapValue(inverteRotatedPosition.x, 1)
	local pointZ = SnapValue(inverteRotatedPosition.z, 1)

	EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

	self:RepositionLinkEntity()
end

function drone_spawner_building:UpdateDisplayRadiusVisibility( show, entity )

	local blueprintName = EntityService:GetBlueprintName(self.entity)
	local lowName = BuildingService:FindLowUpgrade( blueprintName )
	if ( lowName ~= "loot_collector" ) then

		building.UpdateDisplayRadiusVisibility(self, show, entity)

		return
	end

	self.display_radius_requesters = self.display_radius_requesters or {}

	if show then
		if self.display_radius_requesters[ entity ] then
			return
		end

		self.display_radius_requesters[ entity ] = true

		local count = 0
		for entityTemp,_ in pairs(self.display_radius_requesters) do
			if ( EntityService:IsAlive( entityTemp ) ) then
				count = count + 1
			end
		end

		if count == 1 then
			EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" );

			local displayRadiusComponent = EntityService:CreateComponent(self.pointEntity, "DisplayRadiusComponent")
			if ( displayRadiusComponent ~= nil ) then

				local displayRadiusComponentRef = reflection_helper( displayRadiusComponent )
				displayRadiusComponentRef.min_radius = self.display_radius_size.min
				displayRadiusComponentRef.max_radius = self.display_radius_size.max
				displayRadiusComponentRef.max_radius_blueprint = self.display_effect_blueprint
			end

			self:SetPointEntitySelectedSkin()

			self:CreateLinkEntity()

			self:RepositionLinkEntity()
		end
	else
		self.display_radius_requesters[ entity ] = nil

		local count = 0

		for entityTemp,_ in pairs(self.display_radius_requesters) do
			if ( EntityService:IsAlive( entityTemp ) ) then
				count = count + 1
			end
		end

		if count == 0 then
			EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )
			EntityService:RemoveMaterial( self.pointEntity, "selected" )

			self:RemoveLinkEntity()
		end
	end
end

function drone_spawner_building:SetPointEntitySelectedSkin()

	self.dronePointSelected = self.dronePointSelected or false

	local isSkinned = EntityService:IsSkinned(self.pointEntity)

	if ( self.dronePointSelected ) then
		if ( isSkinned ) then
			EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_pass", "selected" )
		else
			EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
		end
	else
		if ( isSkinned ) then
			EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_blue", "selected" )
		else
			EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
		end
	end
end

function drone_spawner_building:UpdateDronePointSkinMaterial()

	local count = 0
	for entityTemp,_ in pairs(self.display_radius_requesters) do
		if ( EntityService:IsAlive( entityTemp ) ) then
			count = count + 1
		end
	end

	self.dronePointSelected = self.dronePointSelected or false

	if count > 0 then
		self:SetPointEntitySelectedSkin()
	else
		EntityService:RemoveMaterial( self.pointEntity, "selected" )
	end

	self:RepositionLinkEntity()
end

function drone_spawner_building:CreateLinkEntity()

	local linkEntityBlueprintName = "effects/area_center_point_effects/area_center_point_link"

	if ( self.linkEntity == nil ) then

		local children = EntityService:GetChildren( self.entity, true )
		for child in Iter(children) do
			local blueprintName = EntityService:GetBlueprintName( child )
			if ( blueprintName == linkEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

				self.linkEntity = child
				ItemService:SetInvisible(self.linkEntity, true)

				break
			end
		end
	end

	if ( self.linkEntity == nil ) then

		local team = EntityService:GetTeam( self.entity )
		self.linkEntity = EntityService:SpawnAndAttachEntity( linkEntityBlueprintName, self.entity, team)
		ItemService:SetInvisible(self.linkEntity, true)
	end

	if ( self.linkEntity ~= nil ) then

		local children = EntityService:GetChildren( self.entity, true )
		for child in Iter(children) do
			local blueprintName = EntityService:GetBlueprintName( child )
			if ( blueprintName == linkEntityBlueprintName and child ~= self.linkEntity ) then
				EntityService:RemoveEntity( child )
			end
		end
	end
end

function drone_spawner_building:RemoveLinkEntity()

	if ( self.linkEntity == nil ) then
		return
	end

	EntityService:RemoveEntity(self.linkEntity)
	self.linkEntity = nil
end

function drone_spawner_building:RepositionLinkEntity()

	if ( self.linkEntity == nil or self.pointEntity == nil ) then
		return
	end

	local selfPosition = EntityService:GetPosition(self.entity)
	local pointPosition = EntityService:GetPosition(self.pointEntity)

	local direction = VectorMulByNumber( Normalize( VectorSub( pointPosition, selfPosition ) ), 2.0 )
	selfPosition = VectorAdd(selfPosition, direction)

	local lightningComponent = EntityService:GetComponent(self.linkEntity, "LightningComponent")
	if ( lightningComponent == nil ) then
		return
	end

	local lightningComponentRef = reflection_helper(lightningComponent)
	if ( lightningComponentRef == nil or lightningComponentRef.lighning_vec == nil ) then
		return
	end

	local container = rawget(lightningComponentRef.lighning_vec, "__ptr");

	local item = container:GetItem(0)
	if ( item == nil ) then
		item = container:CreateItem()
	end

	local instance =  reflection_helper(item)

	local sizeSelf = EntityService:GetBoundsSize( self.entity )
	local sizePoint = EntityService:GetBoundsSize( self.pointEntity )

	instance.start_point.x = selfPosition.x
	instance.start_point.y = selfPosition.y + sizeSelf.y
	instance.start_point.z = selfPosition.z

	instance.end_point.x = pointPosition.x
	instance.end_point.y = pointPosition.y + sizePoint.y + 2
	instance.end_point.z = pointPosition.z

	self.dronePointSelected = self.dronePointSelected or false

	if ( self.dronePointSelected ) then
		lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link_selected"
	else
		lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link"
	end
end

function drone_spawner_building:OnBuildingStartEventGettingInfo(evt)

	local eventEntity = evt:GetEntity()

	if (evt:GetUpgrading() == true) then

		self:GettingInfoFromBaseToUpgrade(eventEntity)
	else
		self:GettingInfoFromRuin()
	end
end

function drone_spawner_building:GettingInfoFromBaseToUpgrade(eventEntity)

	local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

	local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

	local position = EntityService:GetPosition(self.entity)

	local boundsSize = { x=1.0, y=100.0, z=1.0 }

	local vectorBounds = VectorMulByNumber(boundsSize , 2)

	local min = VectorSub(position, vectorBounds)
	local max = VectorAdd(position, vectorBounds)

	local entities = FindService:FindGridOwnersByBox( min, max )

	for entity in Iter( entities ) do

		if ( entity == eventEntity ) then
			goto continue
		end

		local blueprintName = EntityService:GetBlueprintName(entity)

		local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
		if ( buildingDesc == nil ) then
			goto continue
		end

		local buildingDescRef = reflection_helper(buildingDesc)
		if ( buildingDescRef.upgrade ~= selfBlueprintName ) then
			goto continue
		end

		local lowName = BuildingService:FindLowUpgrade( blueprintName )
		if ( lowName ~= selfLowName ) then
			goto continue
		end

		local baseDatabase = EntityService:GetDatabase( entity )
		if ( baseDatabase == nil ) then
			goto continue
		end

		local newPositionX = 0
		local newPositionZ = 0

		if ( baseDatabase and baseDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
			local vector = baseDatabase:GetVector(selfLowName .. "_center_point_vector")

			newPositionX = vector.x
			newPositionZ = vector.z
		end

		self:SetCenterPointPosition( newPositionX, newPositionZ )

		::continue::
	end
end

function drone_spawner_building:GettingInfoFromRuin()

	local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

	local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

	local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

	local position = EntityService:GetPosition(self.entity)

	local boundsSize = { x=1.0, y=100.0, z=1.0 }

	local vectorBounds = VectorMulByNumber(boundsSize , 2)

	local min = VectorSub(position, vectorBounds)
	local max = VectorAdd(position, vectorBounds)

	local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

	for ruinEntity in Iter( entities ) do

		local blueprintName = EntityService:GetBlueprintName(ruinEntity)
		if ( blueprintName ~= selfRuinsBlueprint ) then
			goto continue
		end

		local ruinPosition = EntityService:GetPosition(ruinEntity)
		if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
			goto continue
		end

		local ruinDatabase = EntityService:GetDatabase( ruinEntity )
		if ( ruinDatabase == nil ) then
			goto continue
		end

		local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
		if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
			goto continue
		end

		local newPositionX = 0
		local newPositionZ = 0

		if ( ruinDatabase and ruinDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
			local vector = ruinDatabase:GetVector(selfLowName .. "_center_point_vector")

			newPositionX = vector.x
			newPositionZ = vector.z
		end

		self:SetCenterPointPosition( newPositionX, newPositionZ )

		::continue::
	end
end

function drone_spawner_building:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

	local eventEntity = evt:GetEntity()

	if (evt:GetWasSold() == true) then
		return
	end

	local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

	local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

	local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

	local position = EntityService:GetPosition(self.entity)

	local boundsSize = { x=1.0, y=100.0, z=1.0 }

	local vectorBounds = VectorMulByNumber(boundsSize , 2)

	local min = VectorSub(position, vectorBounds)
	local max = VectorAdd(position, vectorBounds)

	local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

	for ruinEntity in Iter( entities ) do

		local blueprintName = EntityService:GetBlueprintName(ruinEntity)
		if ( blueprintName ~= selfRuinsBlueprint ) then
			goto continue
		end

		local ruinPosition = EntityService:GetPosition(ruinEntity)
		if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
			goto continue
		end

		local ruinDatabase = EntityService:GetDatabase( ruinEntity )
		if ( ruinDatabase == nil ) then
			goto continue
		end

		local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
		if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
			goto continue
		end

		local pointPosition = EntityService:GetPosition( self.pointEntity )
		local selfPosition = EntityService:GetPosition( self.entity )

		local pointPositionVector = {
			x = pointPosition.x - selfPosition.x,
			y = 0,
			z = pointPosition.z - selfPosition.z
		}

		ruinDatabase:SetVector(selfLowName .. "_center_point_vector", pointPositionVector)

		::continue::
	end
end

-- #endregion Drone Point

function drone_spawner_building:OnRelease()

	self:RemoveLinkEntity()

	if ( self.pointEntity ~= nil ) then

		EntityService:RemoveEntity( self.pointEntity )
		self.pointEntity = nil
	end

	if ( building.OnRelease ) then
		building.OnRelease(self)
	end
end

return drone_spawner_building
