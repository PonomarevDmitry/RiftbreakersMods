require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'spawn_resource_deposits_script' ( LuaEntityObject )

function spawn_resource_deposits_script:__init()
    LuaEntityObject.__init(self, self)
end

function spawn_resource_deposits_script:init()

    EntityService:CreateOrSetLifetime( self.entity, 30.0, "normal" )



    self.playerId = self.data:GetInt("player_id")

    self.annoucement = self.data:GetString("annoucement")

    self.veinName = self.data:GetString("vein_name")
    self.resourceName = self.data:GetString("resource_name")

    self.currentValue = self.data:GetFloat("current_value")

    self.transform = EntityService:GetWorldTransform( self.entity )

    self.position = self.transform.position

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

    QueueEvent( "SetTimerRequest", self.entity, "CheckNewResourceVolume", 0.2 )
end

function spawn_resource_deposits_script:OnLoad()

    self.playerId = self.data:GetInt("player_id")

    self.annoucement = self.data:GetString("annoucement")

    self.veinName = self.data:GetString("vein_name")
    self.resourceName = self.data:GetString("resource_name")

    self.currentValue = self.data:GetFloat("current_value")

    self.transform = EntityService:GetWorldTransform( self.entity )

    self.position = self.transform.position
end

function spawn_resource_deposits_script:OnTimerElapsedEvent(evt)

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

    local spawnedAmount = resourceVolumeComponentRef.spawned_amount

    local coeff = self.currentValue / spawnedAmount 


    local childrenList = self:GetResourceChilds(createdVolume)
    if ( #childrenList > 0 ) then

        for childResource in Iter( childrenList ) do

            local resource = EntityService:GetResourceAmount( childResource )

            local amount = resource.second * coeff

            EntityService:ChangeResourceAmount(childResource, amount)
        end
    end

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    if ( unlimitedMoney == false ) then
        PlayerService:AddResourceAmount( self.resourceName, -self.currentValue )
    end
end

function spawn_resource_deposits_script:Except(t1, t2)

    local result = {}

    for _,v in ipairs(t1) do

        if ( IndexOf( t2, v) == nil ) then

           Insert(result, v)
        end
    end

    return result
end

function spawn_resource_deposits_script:GetResourceChilds(createdVolume)

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

function spawn_resource_deposits_script:FindResourceVolume()

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

function spawn_resource_deposits_script:DestroySelf()

    if ( self.entityEmptySpace ~= nil) then
        EntityService:RemoveEntity(self.entityEmptySpace)
        self.entityEmptySpace = nil
    end

    EntityService:RemoveEntity( self.entity )
end

return spawn_resource_deposits_script