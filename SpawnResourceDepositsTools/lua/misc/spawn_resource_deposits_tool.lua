local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'spawn_resource_deposits_tool' ( tool )

function spawn_resource_deposits_tool:__init()
    tool.__init(self,self)
end

function spawn_resource_deposits_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.currentValue = 500
    self.stepValue = 100

    self.veinName = self.data:GetString("vein")
    self.resourceName = self.data:GetString("resource")

    --self.configName = "$spawn_resource_deposits_tool_config." .. self.veinName
    self.configName = "$spawn_resource_deposits_tool_config"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    if ( selectorDB ) then
        self.currentValue = selectorDB:GetIntOrDefault(self.configName, self.currentValue)
    end

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2)

    self.annoucement = self.data:GetString("annoucement")

    self:UpdateMarker()
end

function spawn_resource_deposits_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function spawn_resource_deposits_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function spawn_resource_deposits_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function spawn_resource_deposits_tool:UpdateMarker()

    self.buildCost = {}

    self.buildCost[self.resourceName] = self.currentValue

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -2, 0, 2)
    end

    self:OnUpdate()
end

function spawn_resource_deposits_tool:OnUpdate()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    self.buildCost = self.buildCost or {}

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function spawn_resource_deposits_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function spawn_resource_deposits_tool:AddedToSelection( entity )
end

function spawn_resource_deposits_tool:RemovedFromSelection( entity )
end

function spawn_resource_deposits_tool:OnActivateSelectorRequest()

    if ( self.currentValue <= 0 ) then
        return
    end

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    if ( unlimitedMoney == false ) then

        local resourceCount = PlayerService:GetResourceAmount( self.resourceName )
        if ( resourceCount < self.currentValue ) then

            local playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 1.0, self.annoucement, playerEntity, false )

            return
        end
    end

    local treasureSpotFind = FindService:FindEmptySpotInRadius( self.entity, 1.0, "", "" )
    if ( treasureSpotFind.first == false ) then
        return
    end

    local team = EntityService:GetTeam( self.entity )

    local position = treasureSpotFind.second




    local entityScript = EntityService:SpawnEntity( "misc/spawn_resource_deposits/script", position, team )

    local database = EntityService:GetOrCreateDatabase( entityScript )

    database:SetInt( "player_id", self.playerId )
    database:SetString( "annoucement", self.annoucement )
    database:SetString( "vein_name", self.veinName )
    database:SetString( "resource_name", self.resourceName )
    database:SetFloat( "current_value", self.currentValue )
end

function spawn_resource_deposits_tool:OnRotateSelectorRequest(evt)

    local maxDeltaTime = 1
    local maxCountToSwithTo1k = 14
    local maxCountToSwithTo2k = 24
    local maxCountToSwithTo10k = 49



    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -change
    end

    local delta = change * self.stepValue

    local trimValue = nil

    self.countToSpeedUp = self.countToSpeedUp or 0
    self.lastRotateTime = self.lastRotateTime or 0

    local currentTime = GetLogicTime()

    local deltaFromLast = currentTime - self.lastRotateTime

    if ( deltaFromLast < maxDeltaTime ) then

        if ( self.countToSpeedUp > maxCountToSwithTo10k ) then

            delta = delta * 100
            trimValue = 2000

        elseif ( self.countToSpeedUp > maxCountToSwithTo2k ) then

            delta = delta * 20
            trimValue = 2000

        elseif ( self.countToSpeedUp > maxCountToSwithTo1k ) then

            delta = delta * 10
            trimValue = 1000
        end

        self.countToSpeedUp = self.countToSpeedUp + 1
    else

        self.countToSpeedUp = 0
    end

    self.lastRotateTime = currentTime

    local newValue = self.currentValue + delta

    if ( trimValue ~= nil ) then

        newValue = newValue - ( newValue % trimValue)
    end

    if( newValue <= self.stepValue ) then
        newValue = self.stepValue
    end

    self.currentValue = newValue

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    if ( selectorDB ) then
        selectorDB:SetInt(self.configName, newValue)
    end

    self:UpdateMarker()
end

function spawn_resource_deposits_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return spawn_resource_deposits_tool
