require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'grenades_pack' ( item )

function grenades_pack:__init()
    item.__init(self,self)
end

function grenades_pack:OnActivate()

    for i=1,3 do

        local modItemBlueprint = self.data:GetStringOrDefault("grenades_pack_MOD_" .. tostring(i), "") or ""

        LogService:Log("OnActivate modItemBlueprint " .. tostring(modItemBlueprint))

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

        local blueprintListArray = Split( blueprintListString, "|" )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem == INVALID_ID ) then
                goto continue2
            end

            local inventoryItemComponent = EntityService:GetComponent( playerItem, "InventoryItemComponent" )
            if ( inventoryItemComponent == INVALID_ID ) then
                goto continue2
            end

            local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)
            if ( inventoryItemComponentRef.use_count <= 0 ) then
                goto continue2
            end

            local itemBlueprintDatabase = EntityService:GetBlueprintDatabase( playerItem )

            if ( itemBlueprintDatabase == nil ) then
                goto continue2
            end

            if ( not itemBlueprintDatabase:HasString("bp") ) then
                goto continue2
            end

            local grenadeBlueprint = itemBlueprintDatabase:GetString("bp")
            local grenadeAtt = itemBlueprintDatabase:GetString("att")

            local entity = WeaponService:ThrowGrenade( grenadeBlueprint , self.owner, grenadeAtt )
            ItemService:SetItemCreator( entity, self.entity_blueprint )

            local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
            local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

            if ( unlimitedMoney == false and unlimitedAmmo == false ) then
                inventoryItemComponentRef.use_count = inventoryItemComponentRef.use_count - 1
            end

            goto continue

            ::continue2::
        end

        ::continue::
    end
end

function grenades_pack:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    for i=1,3 do

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

        local blueprintListArray = Split( blueprintListString, "|" )

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

return grenades_pack