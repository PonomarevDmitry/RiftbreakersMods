require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'grenades_pack' ( item )

function grenades_pack:__init()
    item.__init(self,self)
end

function grenades_pack:OnInit()

    self:InitThrowStateMachine()
end

function grenades_pack:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end
end

function grenades_pack:InitThrowStateMachine()

    self.machine = self:CreateStateMachine()
    self.machine:AddState( "throw", { execute="OnThrowExecute", interval=0.1 } )
end

function grenades_pack:OnActivate()

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end

    self.grenadesToThrow = {}

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("grenades_pack_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continueModList
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continueModList
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )
        if ( blueprintDatabase == nil ) then
            goto continueModList
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
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

            local grenadeBlueprint = itemBlueprintDatabase:GetString("bp")

            Insert( self.grenadesToThrow, grenadeBlueprint )

            if ( unlimitedMoney == false and unlimitedAmmo == false ) then
                inventoryItemComponentRef.use_count = inventoryItemComponentRef.use_count - 1
            end

            goto continueModList

            ::continueBlueprintList::
        end

        ::continueModList::
    end

    if ( #self.grenadesToThrow > 0 ) then

        local grenadeBlueprint = self.grenadesToThrow[1]

        table.remove( self.grenadesToThrow, 1 )

        local entity = WeaponService:ThrowGrenade( grenadeBlueprint, self.owner, "att_grenade" )
        ItemService:SetItemCreator( entity, self.entity_blueprint )
        EntityService:PropagateEntityOwner( entity, self.owner )

        if ( #self.grenadesToThrow > 0 ) then

            self.machine:ChangeState("throw")
        end
    end
end

function grenades_pack:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("grenades_pack_MOD_" .. tostring(i), "") or ""

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

function grenades_pack:OnThrowExecute( state )

    self.grenadesToThrow = self.grenadesToThrow or {}

    if ( #self.grenadesToThrow == 0 ) then

        state:Exit()
        return
    end

    local grenadeBlueprint = self.grenadesToThrow[1]

    table.remove( self.grenadesToThrow, 1 )

    local entity = WeaponService:ThrowGrenade( grenadeBlueprint, self.owner, "att_grenade" )
    ItemService:SetItemCreator( entity, self.entity_blueprint )
    EntityService:PropagateEntityOwner( entity, self.owner )
end

return grenades_pack