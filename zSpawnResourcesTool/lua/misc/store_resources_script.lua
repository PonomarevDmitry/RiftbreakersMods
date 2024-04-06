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

    self.playerId = self.data:GetInt("player_id")

    self.annoucement = self.data:GetString("annoucement")

    self.veinName = self.data:GetString("vein_name")
    self.resourceName = self.data:GetString("resource_name")

    self.currentValue = self.data:GetFloat("current_value")

    self.transform = EntityService:GetWorldTransform( self.entity )

    self.position = self.transform.position

    LogService:Log("store_resources_script:init self.position " .. debug_serialize_utils:SerializeObject(self.position))

    

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

    if ( unlimitedMoney == false ) then
        PlayerService:AddResourceAmount( self.resourceName, -self.currentValue )
    end


end

function store_resources_script:OnLoad()

    self:DestroySelf()
end

function store_resources_script:DestroySelf()

    if ( self.entityEmptySpace ~= nil) then
        EntityService:RemoveEntity(self.entityEmptySpace)
        self.entityEmptySpace = nil
    end

    EntityService:RemoveEntity( self.entity )
end

return store_resources_script