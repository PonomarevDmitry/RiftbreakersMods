require("lua/utils/table_utils.lua")

local InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown = function(blueprintsList, cooldownValue)

    for _,blueprintName in ipairs(blueprintsList) do

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint == nil ) then

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " NOT EXISTS.")
            goto continue
        end

        local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
        if ( inventoryItemComponent ~= nil ) then

            inventoryItemComponent:GetField("cooldown"):SetValue(cooldownValue)
        else

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " InventoryItemComponent NOT EXISTS.")
        end

        local inventoryItemRuntimeDataComponent = blueprint:GetComponent("InventoryItemRuntimeDataComponent")
        if ( inventoryItemRuntimeDataComponent ~= nil ) then

            inventoryItemRuntimeDataComponent:GetField("cooldown"):SetValue(cooldownValue)
        else

            LogService:Log("InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown Blueprint " .. blueprintName .. " InventoryItemRuntimeDataComponent NOT EXISTS.")
        end

        ::continue::
    end
end

local supported_item_blueprints = {

    "items/skills/time_warp_item",

    "items/skills/invisibility_item",
    "items/skills/invisibility_short_item",

    "items/skills/teleport_item",
    "items/skills/teleport_advanced_item",
    "items/skills/teleport_superior_item",
    "items/skills/teleport_extreme_item",

    "items/skills/teleport_short_item",

    "items/skills/dash",

    "items/skills/dodge_roll_item",
    "items/skills/dodge_roll_advanced_item",
    "items/skills/dodge_roll_superior_item",
    "items/skills/dodge_roll_extreme_item",

    "items/skills/dash_acid_item",
    "items/skills/dash_acid_advanced_item",
    "items/skills/dash_acid_superior_item",
    "items/skills/dash_acid_extreme_item",

    "items/skills/dash_energy_item",
    "items/skills/dash_energy_advanced_item",
    "items/skills/dash_energy_superior_item",
    "items/skills/dash_energy_extreme_item",

    "items/skills/dash_fire_item",
    "items/skills/dash_fire_advanced_item",
    "items/skills/dash_fire_superior_item",
    "items/skills/dash_fire_extreme_item",

    "items/skills/dash_cryo_item",
    "items/skills/dash_cryo_advanced_item",
    "items/skills/dash_cryo_superior_item",
    "items/skills/dash_cryo_extreme_item",

    

    "items/skills/jump_splash_standard_item",
    "items/skills/jump_splash_advanced_item",
    "items/skills/jump_splash_superior_item",
    "items/skills/jump_splash_extreme_item",

    "items/skills/jump_acid_item",
    "items/skills/jump_acid_advanced_item",
    "items/skills/jump_acid_superior_item",
    "items/skills/jump_acid_extreme_item",

    "items/skills/jump_energy_item",
    "items/skills/jump_energy_advanced_item",
    "items/skills/jump_energy_superior_item",
    "items/skills/jump_energy_extreme_item",

    "items/skills/jump_fire_item",
    "items/skills/jump_fire_advanced_item",
    "items/skills/jump_fire_superior_item",
    "items/skills/jump_fire_extreme_item",

    "items/skills/jump_cryo_item",
    "items/skills/jump_cryo_advanced_item",
    "items/skills/jump_cryo_superior_item",
    "items/skills/jump_cryo_extreme_item",



    "items/skills/teleport_attack_acid_standard_item",
    "items/skills/teleport_attack_acid_advanced_item",
    "items/skills/teleport_attack_acid_superior_item",
    "items/skills/teleport_attack_acid_extreme_item",

    "items/skills/teleport_attack_area_standard_item",
    "items/skills/teleport_attack_area_advanced_item",
    "items/skills/teleport_attack_area_superior_item",
    "items/skills/teleport_attack_area_extreme_item",

    "items/skills/teleport_attack_energy_standard_item",
    "items/skills/teleport_attack_energy_advanced_item",
    "items/skills/teleport_attack_energy_superior_item",
    "items/skills/teleport_attack_energy_extreme_item",

    "items/skills/teleport_attack_fire_standard_item",
    "items/skills/teleport_attack_fire_advanced_item",
    "items/skills/teleport_attack_fire_superior_item",
    "items/skills/teleport_attack_fire_extreme_item",

    "items/skills/teleport_attack_ice_standard_item",
    "items/skills/teleport_attack_ice_advanced_item",
    "items/skills/teleport_attack_ice_superior_item",
    "items/skills/teleport_attack_ice_extreme_item",



    "items/skills/teleport_combined_acid_standard_item",
    "items/skills/teleport_combined_acid_advanced_item",
    "items/skills/teleport_combined_acid_superior_item",
    "items/skills/teleport_combined_acid_extreme_item",

    "items/skills/teleport_combined_area_standard_item",
    "items/skills/teleport_combined_area_advanced_item",
    "items/skills/teleport_combined_area_superior_item",
    "items/skills/teleport_combined_area_extreme_item",

    "items/skills/teleport_combined_energy_standard_item",
    "items/skills/teleport_combined_energy_advanced_item",
    "items/skills/teleport_combined_energy_superior_item",
    "items/skills/teleport_combined_energy_extreme_item",

    "items/skills/teleport_combined_fire_standard_item",
    "items/skills/teleport_combined_fire_advanced_item",
    "items/skills/teleport_combined_fire_superior_item",
    "items/skills/teleport_combined_fire_extreme_item",

    "items/skills/teleport_combined_ice_standard_item",
    "items/skills/teleport_combined_ice_advanced_item",
    "items/skills/teleport_combined_ice_superior_item",
    "items/skills/teleport_combined_ice_extreme_item",



    "items/skills/teleport_emergency_acid_standard_item",
    "items/skills/teleport_emergency_acid_advanced_item",
    "items/skills/teleport_emergency_acid_superior_item",
    "items/skills/teleport_emergency_acid_extreme_item",

    "items/skills/teleport_emergency_area_standard_item",
    "items/skills/teleport_emergency_area_advanced_item",
    "items/skills/teleport_emergency_area_superior_item",
    "items/skills/teleport_emergency_area_extreme_item",

    "items/skills/teleport_emergency_energy_standard_item",
    "items/skills/teleport_emergency_energy_advanced_item",
    "items/skills/teleport_emergency_energy_superior_item",
    "items/skills/teleport_emergency_energy_extreme_item",

    "items/skills/teleport_emergency_fire_standard_item",
    "items/skills/teleport_emergency_fire_advanced_item",
    "items/skills/teleport_emergency_fire_superior_item",
    "items/skills/teleport_emergency_fire_extreme_item",

    "items/skills/teleport_emergency_ice_standard_item",
    "items/skills/teleport_emergency_ice_advanced_item",
    "items/skills/teleport_emergency_ice_superior_item",
    "items/skills/teleport_emergency_ice_extreme_item",

    "items/skills/customizable_movement_skill_1_item",
    "items/skills/customizable_movement_skill_2_item",
    "items/skills/customizable_movement_skill_3_item",
}

InjectChangeMovingSkillBlueprintInventoryItemComponentCooldown(supported_item_blueprints, "0.5")

local supported_item_hash = {}

for _,blueprintName in ipairs(supported_item_blueprints) do

    supported_item_hash[blueprintName] = 1
end

RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID) then
        return
    end

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local itemType = ItemService:GetItemType(entity)

    if ( itemType ~= "dash_skill" and itemType ~= "movement_skill" ) then
        return
    end

    local entityBlueprintName = EntityService:GetBlueprintName(entity)

    if ( supported_item_hash[entityBlueprintName] == 1 ) then
        return
    end

    local inventoryItemComponent = EntityService:GetConstComponent( entity, "InventoryItemComponent" )
    if ( inventoryItemComponent ~= nil ) then

        inventoryItemComponent:GetField("cooldown"):SetValue("0.5")
    end

    local inventoryItemRuntimeDataComponent = EntityService:GetComponent(entity, "InventoryItemRuntimeDataComponent")
    if ( inventoryItemRuntimeDataComponent ~= nil ) then

        inventoryItemRuntimeDataComponent:GetField("cooldown"):SetValue("0.5")
    end

end)
