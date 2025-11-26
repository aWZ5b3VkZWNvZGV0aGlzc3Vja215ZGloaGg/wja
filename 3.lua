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
    ["method(enableWalk)"] = function()
        autoWalk = true
        print("Auto Walk enabled")
    end,

    ["method(disableWalk)"] = function()
        autoWalk = false
        print("Auto Walk disabled")
    end,

    ["method(enableJump)"] = function()
        autoJump = true
        print("Auto Jump enabled")
    end,

    ["method(disableJump)"] = function()
        autoJump = false
        print("Auto Jump disabled")
    end,

    ["help"] = function()
        print("Available commands:")
        print("method(enableWalk)")
        print("method(disableWalk)")
        print("method(enableJump)")
        print("method(disableJump)")
    end,
}

-- Chat listener
player.Chatted:Connect(function(msg)
    msg = msg:lower()
    if commands[msg] then
        commands[msg]({})
    end
end)

-- Function: find active training area (using BaseParts directly)
local function getActiveArea(hrp)
    local touching = hrp:GetTouchingParts()
    for _, part in ipairs(trainingAreas) do
        for _, t in ipairs(touching) do
            if t == part then
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
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local activeArea = getActiveArea(hrp)

            if activeArea and humanoid then
                -- inside a training area -> walk forward
                lastValidArea = activeArea
                humanoid:Move(Vector3.new(0,0,-1), true)
            else
                -- outside all areas -> teleport back to last valid area
                if lastValidArea then
                    hrp.CFrame = CFrame.new(lastValidArea.Position)
                    print("Teleported back to last valid training area:", lastValidArea.Name or "unknown")
                else
                    -- fallback: teleport to first area if none recorded yet
                    local fallback = trainingAreas[1]
                    if fallback then
                        hrp.CFrame = CFrame.new(fallback.Position)
                        print("Teleported back to fallback training area:", fallback.Name or "unknown")
                    end
                end
            end
        end
    end
end)

-- Auto Jump loop (hold jump continuously)
task.spawn(function()
    while true do
        task.wait(0.1) -- check every 0.1s
        if autoJump and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            humanoid.Jump = true -- keep jump held down
        else
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Jump = false
            end
        end
    end
end)

print("Script loaded successfully")
