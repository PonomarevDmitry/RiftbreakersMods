require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'auto_mines_placement' ( item )

function auto_mines_placement:__init()
    item.__init(self,self)
end

function auto_mines_placement:OnInit()

    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function auto_mines_placement:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
    
    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function auto_mines_placement:InitThrowStateMachine()

    if ( self.machine == nil ) then
        self.machine = self:CreateStateMachine()
        self.machine:AddState( "placemine", { execute="OnPlaceMineExecute", interval=1 } )
    end
end

function auto_mines_placement:OnActivate()

    self:InitThrowStateMachine()

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        self:OnPlaceMineExecute()

        self.machine:ChangeState("placemine")
    end
end

function auto_mines_placement:OnUnequipped()

    if ( self.isWorking ) then
        self:StopWorking()
    end
end

function auto_mines_placement:StopWorking()

    self.isWorking = false

    self.data:SetInt("auto_mines_placement_current_number", 1)

    self.machine:Deactivate()
end

function auto_mines_placement:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function auto_mines_placement:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("auto_mines_placement_MOD_" .. tostring(i), "") or ""

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

function auto_mines_placement:OnPlaceMineExecute( state )

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    local currentModNumber = self.data:GetIntOrDefault("auto_mines_placement_current_number", 1) or 1

    local emptySlots = 0

    while (true) do

        if ( emptySlots >= 6 ) then

            state:Exit()
            self:StopWorking()
            return
        end

        local modItemBlueprint = self.data:GetStringOrDefault("auto_mines_placement_MOD_" .. tostring(currentModNumber), "") or ""

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
            

            self.data:SetInt("auto_mines_placement_current_number", self:IncreaseModNumber(currentModNumber))
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

function auto_mines_placement:IncreaseModNumber(currentModNumber)

    local result = currentModNumber + 1

    if ( result > 6 ) then
        result = 1
    end

    return result
end

function auto_mines_placement:SpawnMine(mineBlueprintName)

    local spot = EntityService:GetPosition( self.owner )

    spot.y = EnvironmentService:GetTerrainHeight(spot)

    local spawned = EntityService:SpawnEntity( mineBlueprintName, spot, EntityService:GetTeam( self.owner ))

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, mineBlueprintName)



    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    local dissolveTime = database:GetFloatOrDefault( "dissolve", 0.5 )

    QueueEvent( "FadeEntityInRequest", spawned, dissolveTime )
end

return auto_mines_placement