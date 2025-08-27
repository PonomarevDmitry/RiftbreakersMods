require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeFloatingMinesWeaponItemDescValues = function(blueprintName, hashChanges)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeFloatingMinesWeaponItemDescValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local weaponItemDesc = blueprint:GetComponent("WeaponItemDesc")
    if ( weaponItemDesc == nil ) then
        LogService:Log("InjectChangeFloatingMinesWeaponItemDescValues Blueprint '" .. blueprintName .. "' WeaponItemDesc NOT EXISTS.")
        return
    end

    local stat_def_vecContainer = weaponItemDesc:GetField("stat_def_vec"):ToContainer()
    if ( stat_def_vecContainer == nil ) then
        LogService:Log("InjectChangeFloatingMinesWeaponItemDescValues Blueprint '" .. blueprintName .. "' weaponItemDesc:GetField('stat_def_vec'):ToContainer() NOT EXISTS.")
        return
    end

    for i=0,stat_def_vecContainer:GetItemCount()-1 do

        local weaponStatDef = stat_def_vecContainer:GetItem(i)

        if ( weaponStatDef == nil ) then
            LogService:Log("InjectChangeFloatingMinesWeaponItemDescValues Blueprint '" .. blueprintName .. "' weaponStatDef == nil")
            goto continue
        end

        local weaponStatDefRef = reflection_helper(weaponStatDef)
        if ( weaponStatDefRef.stat_type == nil ) then

            goto continue
        end

        local stat_typeValue = tostring(weaponStatDefRef.stat_type)

        if ( hashChanges[stat_typeValue] == nil ) then

            goto continue
        end

        local newValues = hashChanges[stat_typeValue]

        weaponStatDefRef.min_value = newValues.min_value
        weaponStatDefRef.max_value = newValues.max_value

        weaponStatDefRef.default_value = newValues.default_value

        weaponStatDefRef.stat_features = newValues.stat_features

        ::continue::
    end
end

local InjectChangeListFloatingMinesWeaponItemDescValues = function(blueprintStorageValues)

    for _, configObject in ipairs(blueprintStorageValues) do

        local list = configObject.list
        local hashChanges = configObject.changes

        for _, blueprintName in ipairs(list) do

            InjectChangeFloatingMinesWeaponItemDescValues(blueprintName, hashChanges)
        end
    end
end

local new_values = {

    {
        ["list"] = {

            "items/weapons/floating_mines_item",
            "items/weapons/floating_mines_acid_item",
            "items/weapons/floating_mines_cryo_item",
            "items/weapons/floating_mines_gravity_item",
            "items/weapons/floating_mines_incendiary_item",
        },

        ["changes"] = {

            -- stat_type "FIRE_PER_SHOT"
            ["3"] = {

                ["min_value"] = "1",
                ["max_value"] = "1",
                ["default_value"] = "1",

                ["stat_features"] = "1",
            },

            -- stat_type "AMMO_COST"
            ["15"] = {

                ["min_value"] = "1",
                ["max_value"] = "1",
                ["default_value"] = "1",

                ["stat_features"] = "37",
            },
        },
    },



    {
        ["list"] = {

            "items/weapons/floating_mines_advanced_item",
            "items/weapons/floating_mines_acid_advanced_item",
            "items/weapons/floating_mines_cryo_advanced_item",
            "items/weapons/floating_mines_gravity_advanced_item",
            "items/weapons/floating_mines_incendiary_advanced_item",
        },

        ["changes"] = {

            -- stat_type "FIRE_PER_SHOT"
            ["3"] = {

                ["min_value"] = "2",
                ["max_value"] = "2",
                ["default_value"] = "2",

                ["stat_features"] = "1",
            },

            -- stat_type "AMMO_COST"
            ["15"] = {

                ["min_value"] = "1.050",
                ["max_value"] = "1.200",
                ["default_value"] = "1.1",

                ["stat_features"] = "37",
            },
        },
    },



    {
        ["list"] = {

            "items/weapons/floating_mines_superior_item",
            "items/weapons/floating_mines_acid_superior_item",
            "items/weapons/floating_mines_cryo_superior_item",
            "items/weapons/floating_mines_gravity_superior_item",
            "items/weapons/floating_mines_incendiary_superior_item",
        },

        ["changes"] = {

            -- stat_type "FIRE_PER_SHOT"
            ["3"] = {

                ["min_value"] = "3",
                ["max_value"] = "3",
                ["default_value"] = "3",

                ["stat_features"] = "1",
            },

            -- stat_type "AMMO_COST"
            ["15"] = {

                ["min_value"] = "0.850",
                ["max_value"] = "0.950",
                ["default_value"] = "0.900",

                ["stat_features"] = "37",
            },
        },
    },



    {
        ["list"] = {

            "items/weapons/floating_mines_extreme_item",
            "items/weapons/floating_mines_acid_extreme_item",
            "items/weapons/floating_mines_cryo_extreme_item",
            "items/weapons/floating_mines_gravity_extreme_item",
            "items/weapons/floating_mines_incendiary_extreme_item",
        },

        ["changes"] = {

            -- stat_type "FIRE_PER_SHOT"
            ["3"] = {

                ["min_value"] = "4",
                ["max_value"] = "4",
                ["default_value"] = "4",

                ["stat_features"] = "1",
            },

            -- stat_type "AMMO_COST"
            ["15"] = {

                ["min_value"] = "0.775",
                ["max_value"] = "0.850",
                ["default_value"] = "0.800",

                ["stat_features"] = "37",
            },
        },
    },
}

InjectChangeListFloatingMinesWeaponItemDescValues(new_values)