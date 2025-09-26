require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local item = require("lua/items/item.lua")

class 'auto_mines_laying' ( item )

function auto_mines_laying:__init()
    item.__init(self,self)
end

function auto_mines_laying:OnInit()

    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function auto_mines_laying:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
    
    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function auto_mines_laying:InitThrowStateMachine()

    if ( self.machine == nil ) then
        self.machine = self:CreateStateMachine()
        self.machine:AddState( "placemine", { execute="OnPlaceMineExecute", interval=1 } )
        self.machine:AddState( "delay", { execute="OnDelayExecute", interval=0.4 } )
    end
end

function auto_mines_laying:OnActivate()

    self:InitThrowStateMachine()

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        self:OnPlaceMineExecute()

        self.machine:ChangeState("delay")

        if ( self.skillWorking ~= nil ) then
            EntityService:RemoveEntity( self.skillWorking )
            self.skillWorking = nil
        end

        self.skillWorking = EntityService:SpawnAndAttachEntity( "effects/items/mech_mine_beacon_activated", self.owner, "att_grenade", EntityService:GetTeam( self.owner ) )

        ItemService:SetItemCreator( self.skillWorking, "effects/items/mech_mine_beacon_activated" )
        EntityService:PropagateEntityOwner( self.skillWorking, self.owner )

        ItemService:SetItemReference( self.skillWorking, self.entity, EntityService:GetBlueprintName( self.entity ))
    end
end

function auto_mines_laying:OnUnequipped()

    self.lastSpawnedPosition = nil

    if ( self.isWorking ) then
        self:StopWorking()
    end
end

function auto_mines_laying:StopWorking()

    self.lastSpawnedPosition = nil

    self.isWorking = false

    self.data:SetInt("auto_mines_laying_current_number", 1)

    self.machine:Deactivate()

    if ( self.skillWorking ~= nil ) then

        EntityService:RemoveEntity( self.skillWorking )
        self.skillWorking = nil
    end
end

function auto_mines_laying:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function auto_mines_laying:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        self:SetCanActivate( false )
        return false
    end

    if ( self.isWorking ) then
        self:SetCanActivate( true )
        return true
    end

    local modsConfiguration = self:GetModsConfiguration()

    for i=1,6 do

        local modItemBlueprint = modsConfiguration[i]

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continue
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continue
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

        if ( blueprintDatabase == nil ) then
            goto continue
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continue
        end

        local blueprintListString = blueprintDatabase:GetString("blueprint_list")

        local blueprintListArray = Split( blueprintListString, "," )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem ~= INVALID_ID ) then

                local inventoryItemRuntimeDataComponentRef = reflection_helper(EntityService:GetComponent( playerItem, "InventoryItemRuntimeDataComponent" ))

                if ( inventoryItemRuntimeDataComponentRef.use_count > 0 ) then

                    self:SetCanActivate( true )
                    return true
                end
            end
        end

        ::continue::
    end

    self:SetCanActivate( false )
    return false
end

function auto_mines_laying:GetModsConfiguration()

    local result = {}

    local hasItems = false

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("auto_mines_laying_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continue
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continue
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

        if ( blueprintDatabase == nil ) then
            goto continue
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continue
        end

        hasItems = true

        result[i] = modItemBlueprint

        ::continue::
    end

    if ( hasItems == false )  then

        result[1] = "items/auto_mines_laying_mods/proximity_mine_standard_item"
    end

    return result
end

function auto_mines_laying:OnDelayExecute( state )

    local minDistanceBetweenLast = 5

    if ( self.lastSpawnedPosition ~= nil ) then

        local spot = EntityService:GetPosition( self.owner )
        spot.y = EnvironmentService:GetTerrainHeight(spot)

        local distance = Distance(self.lastSpawnedPosition, spot)

        if ( distance < minDistanceBetweenLast ) then
            return
        end
    end

    self.machine:ChangeState("placemine")
end

function auto_mines_laying:OnPlaceMineExecute( state )

    local minDistanceBetweenLast = 5

    if ( self.lastSpawnedPosition ~= nil ) then

        local spot = EntityService:GetPosition( self.owner )
        spot.y = EnvironmentService:GetTerrainHeight(spot)

        local distance = Distance(self.lastSpawnedPosition, spot)

        if ( distance < minDistanceBetweenLast ) then

            self.machine:ChangeState("delay")
            return
        end
    end

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    local currentModNumber = self.data:GetIntOrDefault("auto_mines_laying_current_number", 1) or 1

    local emptySlots = 0

    local modsConfiguration = self:GetModsConfiguration()

    while (true) do

        if ( emptySlots >= 6 ) then

            self.data:SetInt("auto_mines_laying_current_number", 1)

            return
        end

        local modItemBlueprint = modsConfiguration[currentModNumber]

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )
        if ( blueprintDatabase == nil ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        local blueprintListString = blueprintDatabase:GetString("blueprint_list")

        local blueprintListArray = Split( blueprintListString, "," )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem == INVALID_ID ) then
                goto continueBlueprintList
            end

            local inventoryItemRuntimeDataComponent = EntityService:GetComponent( playerItem, "InventoryItemRuntimeDataComponent" )
            if ( inventoryItemRuntimeDataComponent == INVALID_ID ) then
                goto continueBlueprintList
            end

            local inventoryItemRuntimeDataComponentRef = reflection_helper(inventoryItemRuntimeDataComponent)
            if ( inventoryItemRuntimeDataComponentRef.use_count <= 0 ) then
                goto continueBlueprintList
            end

            local itemBlueprintDatabase = EntityService:GetBlueprintDatabase( playerItem )

            if ( itemBlueprintDatabase == nil ) then
                goto continueBlueprintList
            end

            if ( not itemBlueprintDatabase:HasString("bp") ) then
                goto continueBlueprintList
            end

            local mineBlueprintName = itemBlueprintDatabase:GetString("bp")

            if ( unlimitedMoney == false and unlimitedAmmo == false ) then
                inventoryItemRuntimeDataComponentRef.use_count = inventoryItemRuntimeDataComponentRef.use_count - 1
            end
            

            self.data:SetInt("auto_mines_laying_current_number", self:IncreaseModNumber(currentModNumber))
            self:SpawnMine(mineBlueprintName)

            do
                return
            end

            ::continueBlueprintList::
        end

        emptySlots = emptySlots + 1
        currentModNumber = self:IncreaseModNumber(currentModNumber)

        ::continueModList::
    end
end

function auto_mines_laying:IncreaseModNumber(currentModNumber)

    local result = currentModNumber + 1

    if ( result > 6 ) then
        result = 1
    end

    return result
end

function auto_mines_laying:SpawnMine(mineBlueprintName)

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    local dissolveTime = database:GetFloatOrDefault( "dissolve", 0.3 )



    local spot = EntityService:GetPosition( self.owner )

    spot.y = EnvironmentService:GetTerrainHeight(spot)

    self.lastSpawnedPosition = spot

    local spawned = EntityService:SpawnEntity( mineBlueprintName, spot, EntityService:GetTeam( self.owner ))

    --EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    --QueueEvent( "FadeEntityInRequest", spawned, dissolveTime )
    EntityService:FadeEntity( spawned, DD_FADE_IN, dissolveTime )

    ItemService:SetItemCreator( spawned, mineBlueprintName )
    EntityService:PropagateEntityOwner( spawned, self.owner )
    
    EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", spawned, "" )
end

return auto_mines_laying