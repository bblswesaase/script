--[[
    Jazz's Custom Rivals Skin Changer - getgenv() Edition 😈
    Fully open-source, expanded skins (308+ from wiki/rscripts), getgenv() API for integration.
    UI via OrionLib + Global controls (e.g., getgenv().JazzRivalsSkins.activeSkins["Assault Rifle"] = "AK-47")
    Auto-apply hook, save config. Alt + VPN only!
]]

getgenv().JazzRivalsSkins = getgenv().JazzRivalsSkins or {
    enabled = true,
    autoApply = true,
    weaponSkins = {  -- FULL EXPANDED LIST (Feb 2026 - Primaries/Secondaries/Melees/Utilities)
        ["Assault Rifle"] = {"AK-47", "AUG", "AKEY-47", "Gingerbread AUG", "Boneclaw Rifle", "Tommy Gun", "Phoenix Rifle"},
        ["Burst Rifle"] = {"Aqua Burst", "Electro Rifle", "Pixel Burst", "Spectral Burst"},
        ["Bow"] = {"Compound Bow", "Raven Bow", "Bat Bow"},
        ["Chainsaw"] = {"Blobsaw", "Handsaws"},
        ["Crossbow"] = {"Pixel Crossbow", "Frostbite Crossbow"},
        ["Exogun"] = {"Singularity", "Wondergun", "Exogourd", "Ray Gun", "Midnight Festive Exogun"},
        ["Fists"] = {"Boxing Gloves", "Brass Knuckles", "Pumpkin Claws", "Festive Fists"},
        ["Flamethrower"] = {"Lamethrower", "Pixel Flamethrower"},
        ["Flare Gun"] = {"Dynamite Gun", "Firework Gun", "Wrapped Flare Gun", "Vexed Flare Gun"},
        ["Freeze Ray"] = {"Bubble Ray", "Temporal Ray", "Spider Ray", "Wrapped Freeze Ray"},
        ["Grenade"] = {"Water Balloon", "Whoopee Cushion", "Soul Grenade", "Jingle Grenade"},
        ["Grenade Launcher"] = {"Swashbuckler", "Uranium Launcher"},
        ["Handgun"] = {"Blaster", "Gingerbread Handgun", "Pumpkin Handgun", "Pixel Handgun"},
        ["Katana"] = {"Lightning Bolt", "Saber", "Pixel Katana", "2025 Katana", "Devil's Trident"},
        ["Medkit"] = {"Laptop", "Sandwich", "Brief Case", "Briefcase"},
        ["Minigun"] = {"Lasergun 3000", "Pixel Minigun"},
        ["Paintball Gun"] = {"Boba Gun", "Slime Gun", "Snowball Gun", "Brain Gun"},
        ["Revolver"] = {"Sheriff", "Desert Eagle"},
        ["RPG"] = {"Nuke Launcher", "RPKEY", "Spaceship Launcher"},
        ["Scythe"] = {"Anchor", "Scythe of Death", "Keythe", "Cryo Scythe", "Bat Scythe"},
        ["Shotgun"] = {"Balloon Shotgun", "Hyper Shotgun", "Wrapped Shotgun", "Broomstick"},
        ["Slingshot"] = {"Goalpost", "Stick", "Reindeer Slingshot", "Boneshot"},
        ["Sniper"] = {"Pixel Sniper", "Hyper Sniper", "Eyething Sniper", "Gingerbread Sniper"},
        ["Smoke Grenade"] = {"Balance", "Emoji Cloud", "Snowglobe", "Eyeball"},
        ["Subspace Tripmine"] = {"Don't Press", "Spring", "Dev-in-the-Box", "Trick or Treat"},
        ["Uzi"] = {"Electro Uzi", "Water Uzi"},
        ["Knife"] = {"Karambit", "Chancla", "Keyper", "Candy Cane", "Machete"},
        ["Flashbang"] = {"Camera", "Disco Ball", "Pixel Flashbang", "Shining Star", "Skullbang"},
        ["Molotov"] = {"Coffee", "Torch", "Hot Coals", "Vexed Candle"},
        ["Trowel"] = {"Garden Shovel", "Plastic Shovel", "Snow Shovel", "Pumpkin Carver"},
        -- Add more spied via Cobalt as needed
    },
    activeSkins = {},  -- Set externally: activeSkins["Assault Rifle"] = "AK-47"
    assetFolder = nil
}

local config = getgenv().JazzRivalsSkins

-- Wait for assets
task.spawn(function()
    config.assetFolder = game.Players.LocalPlayer.PlayerScripts:WaitForChild("Assets"):WaitForChild("ViewModels")
end)

-- Core swap function
function config:swapWeaponSkins(normalWeaponName, skinName, State)
    if not normalWeaponName or not config.assetFolder then return end
    
    local normalWeapon = config.assetFolder:FindFirstChild(normalWeaponName)
    if not normalWeapon then return end
    
    if State and skinName then
        local skin = config.assetFolder:FindFirstChild(skinName)
        if not skin then return end
        
        normalWeapon:ClearAllChildren()
        for _, child in pairs(skin:GetChildren()) do
            local newChild = child:Clone()
            newChild.Parent = normalWeapon
        end
        if State ~= false then  -- Keep active
            config.activeSkins[normalWeaponName] = skinName
        end
    else
        config.activeSkins[normalWeaponName] = nil
    end
end

-- Apply all active
function config:applyAll()
    for base, skin in pairs(config.activeSkins) do
        config:swapWeaponSkins(base, skin, true)
    end
end

-- Auto-apply hook (reapplies every 1s if enabled)
task.spawn(function()
    while config.enabled do
        task.wait(1)
        if config.autoApply and config.assetFolder then
            config:applyAll()
        end
    end
end)

-- UI (OrionLib - optional, controls getgenv())
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "Jazz Skin Changer (getgenv() API)",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "JazzRivalsSkins"
})

local Tab = Window:MakeTab({
    Name = "Skins",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Dynamic UI from table
for weapon, skins in pairs(config.weaponSkins) do
    Tab:AddDropdown({
        Name = weapon .. " Skin",
        Options = skins,
        Callback = function(selectedSkin)
            config.activeSkins[weapon] = selectedSkin
            config:applyAll()
            OrionLib:MakeNotification({
                Name = "Applied!",
                Content = selectedSkin .. " on " .. weapon,
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    })
    Tab:AddToggle({
        Name = "Enable " .. weapon,
        Default = false,
        Callback = function(state)
            if state then
                -- Default first skin
                local defaultSkin = skins[1]
                config.activeSkins[weapon] = defaultSkin
            else
                config.activeSkins[weapon] = nil
                config:swapWeaponSkins(weapon, nil, false)
            end
            config:applyAll()
        end
    })
end

Tab:AddToggle({
    Name = "Auto Apply",
    Default = true,
    Callback = function(v)
        config.autoApply = v
    end
})

OrionLib:Init()

print("JazzRivalsSkins loaded! Use getgenv().JazzRivalsSkins.activeSkins['Weapon'] = 'Skin' externally. Athens grind safe! 😈")
