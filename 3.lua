-- Training areas mapped (thresholds removed, last one commented)
local trainingAreas = {
    workspace.Main.TrainingAreasHitBoxes.BT["100"],
    workspace.Main.TrainingAreasHitBoxes.BT["10K"],
    workspace.Main.TrainingAreasHitBoxes.BT["100K"],
    workspace.Main.TrainingAreasHitBoxes.BT["1M"],
    workspace.Main.TrainingAreasHitBoxes.BT["10M"],
    workspace.Main.TrainingAreasHitBoxes.BT["1B"],
    workspace.Main.TrainingAreasHitBoxes.BT["100B"], -- corrected
    workspace.Main.TrainingAreasHitBoxes.BT["10T"],
    workspace.Main.TrainingAreasHitBoxes.BT["1Qa"],
    workspace.Main.TrainingAreasHitBoxes.BT["1Qi"],
    workspace.Main.TrainingAreasHitBoxes.BT["1Sx"],
    workspace.Main.TrainingAreasHitBoxes.BT["1Sp"],
    workspace.Main.TrainingAreasHitBoxes.BT["1Oc"],
    --workspace.Main.TrainingAreasHitBoxes.BT["1No"],
}

-- Toggle states
local autoWalk = false
local autoJump = false
local lastValidArea = nil -- track the last area HRP was inside

-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Command registry
local commands = {
    ["method(enablewalk)"] = function()
        autoWalk = true
        print("Auto Walk enabled")
    end,

    ["method(disablewalk)"] = function()
        autoWalk = false
        print("Auto Walk disabled")
    end,

    ["method(enablejump)"] = function()
        autoJump = true
        print("Auto Jump enabled")
    end,

    ["method(disablejump)"] = function()
        autoJump = false
        print("Auto Jump disabled")
    end,

    ["help"] = function()
        print("Available commands:")
        print("method(enablewalk)")
        print("method(disablewalk)")
        print("method(enablejump)")
        print("method(disablejump)")
    end,
}

-- Chat listener
player.Chatted:Connect(function(msg)
    msg = msg:lower()
    if commands[msg] then
        commands[msg]({})
    end
end)

-- Function: find active training area (bounding box check)
local function getActiveArea(hrp)
    for _, part in ipairs(trainingAreas) do
        if part then
            local size = part.Size
            local pos = part.Position
            local hrpPos = hrp.Position

            local withinX = hrpPos.X >= pos.X - size.X/2 and hrpPos.X <= pos.X + size.X/2
            local withinY = hrpPos.Y >= pos.Y - size.Y/2 and hrpPos.Y <= pos.Y + size.Y/2
            local withinZ = hrpPos.Z >= pos.Z - size.Z/2 and hrpPos.Z <= pos.Z + size.Z/2

            if withinX and withinY and withinZ then
                return part
            end
        end
    end
    return nil
end

-- Auto Walk loop (bounded by whichever training area HRP is in)
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoWalk and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local activeArea = getActiveArea(hrp)

            if activeArea then
                -- inside a training area -> simulate holding W
                lastValidArea = activeArea
                UserInputService:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            else
                -- only teleport if HRP is actually outside all zones
                if lastValidArea then
                    -- double‑check: are we outside lastValidArea bounds?
                    local size = lastValidArea.Size
                    local pos = lastValidArea.Position
                    local hrpPos = hrp.Position

                    local withinX = hrpPos.X >= pos.X - size.X/2 and hrpPos.X <= pos.X + size.X/2
                    local withinY = hrpPos.Y >= pos.Y - size.Y/2 and hrpPos.Y <= pos.Y + size.Y/2
                    local withinZ = hrpPos.Z >= pos.Z - size.Z/2 and hrpPos.Z <= pos.Z + size.Z/2

                    if not (withinX and withinY and withinZ) then
                        hrp.CFrame = CFrame.new(lastValidArea.Position)
                        UserInputService:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        print("Teleported back to last valid training area:", lastValidArea.Name or "unknown")
                    end
                else
                    -- fallback: teleport to first area if none recorded yet
                    local fallback = trainingAreas[1]
                    if fallback then
                        hrp.CFrame = CFrame.new(fallback.Position)
                        UserInputService:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        print("Teleported back to fallback training area:", fallback.Name or "unknown")
                    end
                end
            end
        else
            -- if autoWalk is off or character missing, release W
            UserInputService:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end
    end
end)

-- Auto Jump loop (simulate holding Space)
task.spawn(function()
    while true do
        task.wait(0.1) -- check every 0.1s
        if autoJump and player.Character and player.Character:FindFirstChild("Humanoid") then
            -- press Space (hold down)
            UserInputService:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        else
            -- release Space when autoJump is off
            UserInputService:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end)

print("Script loaded successfully")
