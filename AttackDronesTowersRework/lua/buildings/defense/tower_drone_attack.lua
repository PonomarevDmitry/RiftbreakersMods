require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_drone_attack' ( drone_spawner_building )

function tower_drone_attack:__init()
    drone_spawner_building.__init(self,self)
end

function tower_drone_attack:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self:CreateDronePoint()
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "_onDronePointChange" )
end

function tower_drone_attack:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateDronePoint()
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "_onDronePointChange" )
end

function tower_drone_attack:CreateDronePoint()

	if ( self.pointEntity == nil ) then

		local team = EntityService:GetTeam(self.entity)

		local transform = EntityService:GetWorldTransform( self.entity )

		self.pointEntity = EntityService:SpawnEntity( "buildings/defense/tower_drone_point", transform.position, team )
	end	
	
	LogService:Log("drone_point_entity " .. tostring(self.pointEntity))

	self.data:SetInt("drone_point_entity", self.pointEntity)
end

function tower_drone_attack:_onDronePointChange(evt)

	local eventName = evt:GetEvent()
	local eventDatabase = evt:GetDatabase()
	local eventEntity = evt:GetEntity()

	if ( eventEntity ~= self.entity ) then
		return
	end

	if ( eventName ~= "DronePointChangeEvent" ) then
		return
	end

	local pointX = eventDatabase:GetFloat("point_x")
	local pointZ = eventDatabase:GetFloat("point_z")

	local transform = EntityService:GetWorldTransform( self.entity )

	self:CreateDronePoint()

	EntityService:SetPosition( self.pointEntity, pointX, transform.position.y, pointZ )

	self:SpawnDrones()
end

function tower_drone_attack:UpdateDisplayRadiusVisibility( show, entity )

	self.display_radius_requesters = self.display_radius_requesters or {}

	self:CreateDronePoint()

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
			EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" );

			local component = reflection_helper( EntityService:CreateComponent(self.pointEntity,"DisplayRadiusComponent") )
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
			EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )
		end
	end
end

function tower_drone_attack:OnRelease()

    if ( self.pointEntity ~= nil ) then

        EntityService:RemoveEntity( self.pointEntity )
		self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease(self)
    end
end

return tower_drone_attack
