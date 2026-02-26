local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()


local Window = Rayfield:CreateWindow({
    Name = "Elite HUB",
    Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
    LoadingTitle = "hello this is loading",
    LoadingSubtitle = "by Elite SNow",
    Theme = "Amethyst", -- Check https://docs.sirius.menu/rayfield/configuration/themes
 
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
 
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "Elite Hub", -- Create a custom folder for your hub/game
       FileName = "Elite Hub" -- Configuration file name
    },

 
    KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
       Title = "Elite keys",
       Subtitle = "Key System",
       Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
       FileName = "skibidi key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
       SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
       GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
       Key = {"Elite", "Elite2"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
 }) 


 local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()
 local chams = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/Roblox-Chams-Highlight/refs/heads/main/Highlight.lua"))()
 local targethud = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/Lua-TargetHud/refs/heads/main/targethud.lua"))()
 local speed = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/Lua-Speed/refs/heads/main/speed.lua"))()




 local aimbotTab = Window:CreateTab("aimbot", "crosshair")

 local Section = aimbotTab:CreateSection("Aimbot Settings")


 local Toggle = aimbotTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Toggle1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        Aimbot.Load()
    end,
 })

 local Toggle = aimbotTab:CreateToggle({
    Name = "fov",
    CurrentValue = false,
    Flag = "Toggle1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        getgenv().ExunysDeveloperAimbot.FOVSettings.Visible = Value
    end,
 })



 local Slider = aimbotTab:CreateSlider({
    Name = "fov",
    Range = {0, 500},
    Increment = 10,
    Suffix = "fov",
    CurrentValue = 50,
    Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        getgenv().ExunysDeveloperAimbot.FOVSettings.Radius = Value
    end,
 })


 local ColorPicker = aimbotTab:CreateColorPicker({
    Name = "Color fov",
    Color = Color3.fromRGB(255,255,255),
    Flag = "ColorPicker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        getgenv().ExunysDeveloperAimbot.FOVSettings.Color = Value
    end
})


 local Keybind = aimbotTab:CreateKeybind({
    Name = "aimbot bind",
    CurrentKeybind = "MB2",
    HoldToInteract = true,
    Flag = "Keybind1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Keybind)
        getgenv().ExunysDeveloperAimbot.Settings.TriggerKey = Value
    end,
 })



 local visualsTab = Window:CreateTab("Visuals", "crosshair")

 local Section = visualsTab:CreateSection("chams")


 local Toggle = visualsTab:CreateToggle({
    Name = "ESP ENABLE",
    CurrentValue = false,
    Flag = "Toggle1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
        getgenv().chams.enabled = Value
    end,
 })







 local playerTab = Window:CreateTab("Player", "crosshair")











 Rayfield:Notify({
    Title = "Elite Hub",
    Content = "Elite Hub Loaded",
    Duration = 6.5,
    Image = 4483362458,
 })
