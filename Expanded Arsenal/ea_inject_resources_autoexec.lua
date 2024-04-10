-- List all modded resources

local custom_resources =  {
    "voidinite_ore_vein",
    "supercoolant_vent",
    "magma_vent",
    "acid_vent",
    "morphium_vent"
}

local InjectIntoVector = function(resources)
    local result = false
    for _,resource_name in ipairs(custom_resources) do
        local has_resource_injected = false
        for i=0,resources:GetItemCount()-1 do
            has_resource_injected = has_resource_injected or resources:GetItem(i):GetValue() == resource_name
        end

        if not has_resource_injected then
            resources:CreateItem():SetValue(resource_name)
            result = true
        end
    end

    return result
end

local InjectIntoResourceVolumes = function( custom_resources, resources )
    local resources_injected = false
    for resource_name, resource_volume in pairs(custom_resources) do
        local has_resource_injected = false
        for i=0,resources:GetItemCount()-1 do
            has_resource_injected = has_resource_injected or resources:GetItem(i):GetField("resource"):GetValue() == resource_name
        end

        if not has_resource_injected then
            resources_injected = true

            local resource = resources:CreateItem()
            resource:GetField("resource"):SetValue(resource_name)
            resource:GetField("min_resources"):SetValue(resource_volume.min_resources or "0")
            resource:GetField("max_resources"):SetValue(resource_volume.max_resources or "0")
            resource:GetField("min_spawned_volumes"):SetValue(resource_volume.min_spawned_volumes or "1")
            resource:GetField("max_spawned_volumes"):SetValue(resource_volume.max_spawned_volumes or "1")
            resource:GetField("is_infinite"):SetValue(resource_volume.is_infinite or "0")
            resource:GetField("required_discovery_lvl"):SetValue(resource_volume.required_discovery_lvl or "0")
        end
    end

    return resources_injected;
end

-- inject resources into BiomeDef. Bypass biome folder

local supported_biomes =  { 
    "jungle",
    "acid",
    "desert",
    "magma",
    "metallic",
    "caverns",
    "swamp"
}

for _,biome_name in ipairs(supported_biomes) do
    local biome_def = ResourceManager:GetResource("BiomeDef", "biomes/" .. biome_name .. "/" .. biome_name .. ".biome" )
    if biome_def ~= nil then
        local biome_resources = biome_def:GetField("resources"):ToContainer()
        if InjectIntoVector( biome_resources ) then
            LogService:Log("Injected resources into: '" .. biome_name .. "'" )
        end
    end
end

-- inject resources into VolumeResourcesSpawnerComponent in EntityBlueprint. Bypass volume_random_resources.ent
local supported_blueprints = {
     "resources/volume_random_resources"
}

for _,blueprint_name in ipairs(supported_blueprints) do
    local blueprint = ResourceManager:GetBlueprint( blueprint_name )
    local volume_component = blueprint:GetComponent("VolumeResourcesSpawnerComponent")
    if volume_component ~= nil then
        local volume_resources = volume_component:GetField("resources"):ToContainer()
        if InjectIntoVector( volume_resources ) then
            LogService:Log("Injected resources into '" .. blueprint_name .. "'")
        end
    end
end

-- Campaign resource injection

local campaign_supported_missions = {

    -- campaign missions list
    "campaigns/story/acid_resource_outpost",
    "campaigns/story/desert_resource_outpost",
    "campaigns/story/headquarters",
    "campaigns/story/jungle_resource_outpost",
    "campaigns/story/magma_resource_outpost",
    
    -- DLC1 campaign missions list
    "campaigns/story/metallic_outpost",
    "campaigns/story/metallic_outpost_stage_2",
    "campaigns/story/metallic_outpost_stage_3",
    
    -- DLC2 campaign missions list
    "campaigns/story/caverns_outpost",
    "campaigns/story/caverns_outpost_stage_2",
}

local campaign_startup_resource_volumes = {
    ["voidinite_ore_vein"] = {
        min_resources = "1000",
        max_resources = "2000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "0"
    },
}

local campaign_random_resource_volumes = {
    ["voidinite_ore_vein"] = {
        min_resources = "2000",
        max_resources = "4000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "0",
        required_discovery_lvl = "1"
    },
    
    ["supercoolant_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "1",
        required_discovery_lvl = "1"
    }
}

for _,mission_name in ipairs(campaign_supported_missions) do
    local mission_def = ResourceManager:GetResource("MissionDef", "missions/" .. mission_name .. ".mission" )
    if mission_def ~= nil then
        local random_resources = mission_def:GetField("random_resources"):ToContainer()
        if InjectIntoResourceVolumes(campaign_random_resource_volumes, random_resources ) then
            LogService:Log("Injected campaign random resources into '" .. mission_name .. "'")
        end
        
        local starting_resources = mission_def:GetField("starting_resources"):ToContainer()
        if InjectIntoResourceVolumes(campaign_startup_resource_volumes, starting_resources ) then
            LogService:Log("Injected campaign starting resources into '" .. mission_name .. "'")
        end
    end
end

-- Survival resource injection

local survival_supported_missions = {

    -- survival missions list
    "survival/acid",
    "survival/caverns",
    "survival/desert",
    "survival/jungle",
    "survival/magma",
    "survival/metallic",
}

local survival_startup_resource_volumes = {
    ["voidinite_ore_vein"] = {
        min_resources = "1000",
        max_resources = "2000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "0"
    },
    
    ["acid_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "1",
        is_infinite = "1"
    },
    
    ["magma_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "1",
        is_infinite = "1"
    },
    
    ["morphium_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "1",
        is_infinite = "1"
    },
    
    ["supercoolant_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "1",
        is_infinite = "1"
    },
}

local survival_random_resource_volumes = {
    ["voidinite_ore_vein"] = {
        min_resources = "2000",
        max_resources = "4000",
        min_spawned_volumes = "2",
        max_spawned_volumes = "3",
        is_infinite = "0"
    },
    
    ["acid_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "1",
        required_discovery_lvl = "1"
    },
    
    ["magma_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "1",
        required_discovery_lvl = "1"
    },
    
    ["morphium_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "1",
        required_discovery_lvl = "1"
    },
    
    ["supercoolant_vent"] = {
        min_resources = "7500",
        max_resources = "12000",
        min_spawned_volumes = "1",
        max_spawned_volumes = "2",
        is_infinite = "1",
        required_discovery_lvl = "1"
    },
}

for _,mission_name in ipairs(survival_supported_missions) do
    local mission_def = ResourceManager:GetResource("MissionDef", "missions/" .. mission_name .. ".mission" )
    if mission_def ~= nil then
        local random_resources = mission_def:GetField("random_resources"):ToContainer()
        if InjectIntoResourceVolumes(survival_random_resource_volumes, random_resources ) then
            LogService:Log("Injected survival random resources into '" .. mission_name .. "'")
        end
        
        local starting_resources = mission_def:GetField("starting_resources"):ToContainer()
        if InjectIntoResourceVolumes(survival_startup_resource_volumes, starting_resources ) then
            LogService:Log("Injected survival starting resources into '" .. mission_name .. "'")
        end
    end
end

-- mini-miner resource_requirement injection

local modded_resources =  {
    "voidinite_ore_vein",
}

local InjectIntoVectorRequirement = function(resources)
    local result = false
    for _,resource_name in ipairs(modded_resources) do
        local has_resource_injected = false
        for i=0,resources:GetItemCount()-1 do
            has_resource_injected = has_resource_injected or resources:GetItem(i):GetValue() == resource_name
        end

        if not has_resource_injected then
            resources:CreateItem():SetValue(resource_name)
            result = true
        end
    end

    return result
end

-- item blueprint list

local supported_item_blueprints = {
     "items/consumables/mini_miner",
     "items/consumables/mini_miner_advanced",
     "items/consumables/mini_miner_superior",
     "items/consumables/mini_miner_extreme",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do
    local blueprint = ResourceManager:GetBlueprint( blueprint_name )
    local building_component = blueprint:GetComponent("BuildingDesc")
    if building_component ~= nil then
        local building_resources = building_component:GetField("resource_requirement"):ToContainer()
        if InjectIntoVectorRequirement( building_resources ) then
            LogService:Log("Injected resource_requirement into '" .. blueprint_name .. "'")
        end
    end
end