require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

class 'store_resources_script' ( LuaEntityObject )

function store_resources_script:__init()
    LuaEntityObject.__init(self, self)
end

function store_resources_script:init()

    EntityService:CreateOrSetLifetime( self.entity, 30.0, "normal" )



    self.playerId = self.data:GetInt("player_id")

    self.annoucement = self.data:GetString("annoucement")

    self.veinName = self.data:GetString("vein_name")
    self.resourceName = self.data:GetString("resource_name")

    self.currentValue = self.data:GetFloat("current_value")

    self.transform = EntityService:GetWorldTransform( self.entity )

    self.position = self.transform.position

    LogService:Log("store_resources_script:init self.currentValue " .. tostring(self.currentValue))
    LogService:Log("store_resources_script:init self.position " .. debug_serialize_utils:SerializeObject(self.position))


    self.existingVolumes = self:FindResourceVolume()



    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    if ( unlimitedMoney == false ) then

        local resourceCount = PlayerService:GetResourceAmount( self.resourceName )
        if ( resourceCount < self.currentValue ) then

            local playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 1.0, self.annoucement, playerEntity, false )

            self:DestroySelf()

            return
        end
    end




    self.entityEmptySpace = ResourceService:FindEmptySpace(0, 0)

    EntityService:CreateOrSetLifetime( self.entityEmptySpace, 30.0, "normal" )

    EntityService:SetPosition(self.entityEmptySpace, self.position.x, self.position.y, self.position.z)

    ResourceService:SpawnResources( self.entityEmptySpace, "resources/volume_template_resource", self.veinName, self.currentValue, self.currentValue + 1000 )

    EntityService:RemoveEntity(self.entityEmptySpace)



    self:RegisterHandler( self.entity, "TimerElapsedEvent", "OnTimerElapsedEvent")

    EntityService:CreateComponent( self.entity, "TimerComponent")

    QueueEvent( "SetTimerRequest", self.entity, "CheckNewResourceVolume", 0.5 )
end

function store_resources_script:OnLoad()

    self.playerId = self.data:GetInt("player_id")

    self.annoucement = self.data:GetString("annoucement")

    self.veinName = self.data:GetString("vein_name")
    self.resourceName = self.data:GetString("resource_name")

    self.currentValue = self.data:GetFloat("current_value")

    self.transform = EntityService:GetWorldTransform( self.entity )

    self.position = self.transform.position
end

function store_resources_script:OnTimerElapsedEvent(evt)

    if (evt:GetName() ~= "CheckNewResourceVolume") then
        return
    end

    local newVolumes = self:Except(self:FindResourceVolume(), self.existingVolumes) 

    if ( #newVolumes == 0 ) then
        self:DestroySelf()
        return
    end

    local createdVolume = newVolumes[1]
    if ( createdVolume == nil ) then
        self:DestroySelf()
        return
    end

    local resourceVolumeComponent = EntityService:GetComponent( createdVolume, "ResourceVolumeComponent" )
    if ( resourceVolumeComponent == nil ) then
        self:DestroySelf()
        return
    end

    local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

    LogService:Log("createdVolume " .. tostring(createdVolume) .. " resourceVolumeComponentRef " .. tostring(resourceVolumeComponentRef))

    local spawnedAmount = resourceVolumeComponentRef.spawned_amount

    local difference = self.currentValue - spawnedAmount

    LogService:Log("createdVolume " .. tostring(createdVolume) .. " self.currentValue " .. tostring(self.currentValue) .. " spawnedAmount " .. tostring(spawnedAmount) .. " difference " .. tostring(difference) )


    local childrenList = self:GetResourceChilds(createdVolume)

    LogService:Log("createdVolume " .. tostring(createdVolume) .. " #childrenList " .. tostring(#childrenList) )

    if ( #childrenList > 0 ) then

        local delta = difference / #childrenList

        LogService:Log("createdVolume " .. tostring(createdVolume) .. " #childrenList " .. tostring(#childrenList) .. " delta " .. tostring(delta) )

        for childResource in Iter( childrenList ) do

            local resource = EntityService:GetResourceAmount( childResource )

            LogService:Log("childResource " .. tostring(childResource) .. " resource " .. tostring(resource.first) .. " amount " .. tostring(resource.second))

            local amount = resource.second + delta

            if ( amount > 0 ) then

                EntityService:ChangeResourceAmount(childResource, amount)
            end
        end

        for childResource in Iter( childrenList ) do

            local resource = EntityService:GetResourceAmount( childResource )

            LogService:Log("changed childResource " .. tostring(childResource) .. " resource " .. tostring(resource.first) .. " amount " .. tostring(resource.second))
        end
    end

    if ( unlimitedMoney == false ) then
        PlayerService:AddResourceAmount( self.resourceName, -self.currentValue )
    end
end

function store_resources_script:Except(t1, t2)

    local result = {}

    for _,v in ipairs(t1) do

        if ( IndexOf( t2, v) == nil ) then

           Insert(result, v)
        end
    end

    return result
end

function store_resources_script:GetResourceChilds(createdVolume)

    local childrenList = EntityService:GetChildren( createdVolume, false )

    local result = {}

    for childResource in Iter( childrenList ) do

        if ( IndexOf( result, childResource ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
            goto continue
        end

        Insert( result, childResource )

        ::continue::
    end

    return result
end

function store_resources_script:FindResourceVolume()

    local predicate = {

        signature="ResourceVolumeComponent",

		filter = function( entity )

            local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
            if ( resourceVolumeComponent ~= nil ) then

                local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

                if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then

                    local resourceId = resourceVolumeComponentRef.type.resource.id or ""

                    if ( resourceId == self.veinName ) then
                        return true
                    end
                end
            end

			return false
		end
    }

    local boundsSize = { x=10.0, y=100.0, z=10.0 }

    local scaleVector = VectorMulByNumber(boundsSize, 1)

    local min = VectorSub(self.position, scaleVector)
    local max = VectorAdd(self.position, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    local result = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function store_resources_script:DestroySelf()

    if ( self.entityEmptySpace ~= nil) then
        EntityService:RemoveEntity(self.entityEmptySpace)
        self.entityEmptySpace = nil
    end

    EntityService:RemoveEntity( self.entity )
end

return store_resources_script