local weapon = require("lua/items/weapon.lua")
-- ClusterProjectile.lua

class 'cluster_weapon' ( weapon )

-- Define the projectile's properties
local cluster_weapon:projectile = {
    name = "ClusterProjectile",
    speed = 1000, -- speed of the projectile
    damage = 10, -- damage dealt by the projectile
    explosionRadius = 5, -- radius of the explosion
    clusterCount = 5, -- number of cluster projectiles
    clusterSpread = 10, -- spread of the cluster projectiles
}

-- Function to create the cluster projectiles
local function cluster_weapon:createClusterProjectiles(projectile, position, direction)
    for i = 1, projectile.clusterCount do
        local clusterDirection = direction + (math.random() * projectile.clusterSpread - projectile.clusterSpread / 2)
        local clusterProjectile = {
            name = "ClusterProjectile",
            speed = projectile.speed,
            damage = projectile.damage / projectile.clusterCount,
            explosionRadius = projectile.explosionRadius,
        }
        -- Create the cluster projectile
        createProjectile(clusterProjectile, position, clusterDirection)
    end
end

-- Function to update the projectile
local function cluster_weapon:update(projectile, dt)
    -- Move the projectile
    projectile.position = projectile.position + projectile.direction * projectile.speed * dt

    -- Check if the projectile has hit something
    if checkCollision(projectile.position, projectile.explosionRadius) then
        -- Create the cluster projectiles
        createClusterProjectiles(projectile, projectile.position, projectile.direction)

        -- Remove the original projectile
        removeProjectile(projectile)
    end
end

-- Register the projectile
registerProjectile(projectile, update)

return cluster_weapon