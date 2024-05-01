require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'mine_trail' ( item )

function mine_trail:__init()
    item.__init(self,self)
end

function mine_trail:OnInit()

    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function mine_trail:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
    
    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function mine_trail:InitThrowStateMachine()

    if ( self.machine == nil ) then
        self.machine = self:CreateStateMachine()
        self.machine:AddState( "placemine", { execute="OnPlaceMineExecute", interval=1 } )
    end
end

function mine_trail:OnActivate()

    self:InitThrowStateMachine()

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        self:OnPlaceMineExecute()

        self.machine:ChangeState("placemine")
    end
end

function mine_trail:OnUnequipped()

    if ( self.isWorking ) then
        self:StopWorking()
    end
end

function mine_trail:StopWorking()

    self.isWorking = false

    self.data:SetInt("mine_trail_current_number", 1)

    self.machine:Deactivate()
end

function mine_trail:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function mine_trail:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("mine_trail_MOD_" .. tostring(i), "") or ""

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

                local inventoryItemComponentRef = reflection_helper(EntityService:GetComponent( playerItem, "InventoryItemComponent" ))

                if ( inventoryItemComponentRef.use_count > 0 ) then

                    return true
                end
            end
        end

        ::continue::
    end

    return false
end

function mine_trail:OnPlaceMineExecute( state )

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    local currentModNumber = self.data:GetIntOrDefault("mine_trail_current_number", 1) or 1

    local emptySlots = 0

    while (true) do

        if ( emptySlots >= 6 ) then

            state:Exit()
            self:StopWorking()
            return
        end

        local modItemBlueprint = self.data:GetStringOrDefault("mine_trail_MOD_" .. tostring(currentModNumber), "") or ""

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

            local inventoryItemComponent = EntityService:GetComponent( playerItem, "InventoryItemComponent" )
            if ( inventoryItemComponent == INVALID_ID ) then
                goto continueBlueprintList
            end

            local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)
            if ( inventoryItemComponentRef.use_count <= 0 ) then
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
                inventoryItemComponentRef.use_count = inventoryItemComponentRef.use_count - 1
            end
            

            self.data:SetInt("mine_trail_current_number", self:IncreaseModNumber(currentModNumber))
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

function mine_trail:IncreaseModNumber(currentModNumber)

    local result = currentModNumber + 1

    if ( result > 6 ) then
        result = 1
    end

    return result
end

function mine_trail:SpawnMine(mineBlueprintName)

    local spot = EntityService:GetPosition( self.owner )

    local spawned = EntityService:SpawnEntity( mineBlueprintName, spot, EntityService:GetTeam( self.owner ))

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, mineBlueprintName)



    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    local dissolveTime = database:GetFloatOrDefault( "dissolve", 0.5 )

    QueueEvent( "FadeEntityInRequest", spawned, dissolveTime )
end

return mine_trail