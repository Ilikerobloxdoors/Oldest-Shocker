local G = getgenv()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [1] MODEL LOADER
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        return nil
    end

    local rawUrl = url
        :gsub("github.com", "raw.githubusercontent.com")
        :gsub("/blob/", "/")

    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0

        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end

        return "shocker_final_fix_" .. tostring(hash) .. ".rbxm"
    end

    local fileName = generateFileName(rawUrl)

    -- Try loading cached model
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)

    if success and exists then
        local assetId = getcustomasset(fileName)

        local loadSuccess, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)

        if loadSuccess and result then
            return result
        end
    end

    -- Download model
    local response = request({
        Url = rawUrl,
        Method = "GET"
    })

    if not response or response.StatusCode ~= 200 then
        warn("Failed to download Shocker model.")
        return nil
    end

    writefile(fileName, response.Body)

    local assetId = getcustomasset(fileName)

    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)

    return success and result or nil
end


-- [2] ENTITY: SHOCKER
local function SpawnShocker()

    local LP = game.Players.LocalPlayer
    local Char = LP.Character or LP.CharacterAdded:Wait()

    local Hum = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")

    local cam = workspace.CurrentCamera

    -- Camera shaker
    local cameraShaker = require(
        game.ReplicatedStorage.CameraShaker
    )

    local camShake = cameraShaker.new(
        Enum.RenderPriority.Camera.Value,
        function(cf)
            cam.CFrame = cam.CFrame * cf
        end
    )

    camShake:Start()


    -- NEW SHOCKER MODEL
    local modelUrl =
        "https://github.com/Ilikerobloxdoors/Oldest-Shocker/blob/main/Oldest%20Shocker.rbxm"

    local entity = G.LoadGithubModel(modelUrl)

    if not entity then
        warn("Could not load Oldest Shocker.")
        return
    end


    -- Find main part
    local mainPart =
        entity:FindFirstChild("OOGA BOOGAAAA", true)

    -- Fallback: use PrimaryPart
    if not mainPart then
        mainPart = entity.PrimaryPart
    end

    -- Fallback: find any BasePart
    if not mainPart then
        mainPart = entity:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    if not mainPart then
        warn("Could not find a BasePart inside Oldest Shocker.")
        entity:Destroy()
        return
    end


    -- Configure model
    entity.PrimaryPart = mainPart

    mainPart.Anchored = true
    mainPart.CanCollide = true

    -- Spawn in front of player
    entity:PivotTo(
        Root.CFrame * CFrame.new(0, 0, -12)
    )

    entity.Parent = workspace


    -- Spawn sound
    local spawnSound =
        entity:FindFirstChild("PlaySound", true)

    -- Attack sound
    local attackSound =
        entity:FindFirstChild("HORROR SCREAM 15", true)

    if spawnSound then
        spawnSound:Play()
    end


    -- Variables
    local lookingTime = 0
    local hasAttacked = false
    local isLookingAtSpawn = false


    -- Check whether player is looking at Shocker
    local function isPlayerLooking()

        if not entity
            or not entity.Parent
            or not mainPart
            or not mainPart.Parent then

            return false
        end

        local entityPos = mainPart.Position

        local vector, onScreen =
            cam:WorldToViewportPoint(entityPos)

        if not onScreen then
            return false
        end

        local direction =
            (entityPos - cam.CFrame.Position).Unit

        local dotProduct =
            direction:Dot(cam.CFrame.LookVector)

        -- Approximately 45-degree viewing angle
        return dotProduct > 0.7
    end


    -- Prevent PlaySound from triggering on removal
    for _, v in pairs(entity:GetDescendants()) do

        if v:IsA("Sound")
            and v.Name == "PlaySound" then

            v.PlayOnRemove = false
        end
    end


    -- Check initial state
    task.wait(0.1)

    if not isPlayerLooking() then

        mainPart.Anchored = false
        mainPart.CanCollide = false

        -- Achievement
        pcall(function()

            if not workspace:FindFirstChild(
                "ShockerAchievement"
            ) then

                if typeof(GiveAchievement) == "function" then
                    GiveAchievement("Shocker")
                end

                local obtained =
                    Instance.new("BoolValue")

                obtained.Name =
                    "ShockerAchievement"

                obtained.Value = true

                obtained.Parent = workspace
            end

        end)

        task.wait(6)

        if entity then
            entity:Destroy()
        end

        return
    end


    -- Main behavior
    task.spawn(function()

        local lastLookState =
            isPlayerLooking()

        local timeSinceLastLook = 0

        while entity
            and entity.Parent
            and not hasAttacked do

            task.wait(0.05)

            local currentLookState =
                isPlayerLooking()


            -- Player looking at entity
            if currentLookState then

                if not lastLookState then
                    lookingTime = 0
                end

                lookingTime =
                    lookingTime + 0.05

                timeSinceLastLook = 0


            -- Player looking away
            else

                timeSinceLastLook =
                    timeSinceLastLook + 0.05


                -- Looked long enough to trigger disappearance
                if lookingTime > 0.1
                    and lookingTime < 1.9
                    and timeSinceLastLook > 0.1 then

                    mainPart.Anchored = false
                    mainPart.CanCollide = false


                    pcall(function()

                        if not workspace:FindFirstChild(
                            "ShockerAchievement"
                        ) then

                            if typeof(GiveAchievement)
                                == "function" then

                                GiveAchievement("Shocker")
                            end

                            local obtained =
                                Instance.new("BoolValue")

                            obtained.Name =
                                "ShockerAchievement"

                            obtained.Value = true

                            obtained.Parent =
                                workspace
                        end

                    end)


                    task.wait(6)

                    if entity then
                        entity:Destroy()
                    end

                    break
                end


                -- Reset timer
                if timeSinceLastLook > 0.5 then
                    lookingTime = 0
                end
            end


            lastLookState =
                currentLookState


            -- =================================
            -- ATTACK
            -- =================================

            if lookingTime >= 1.9
                and not hasAttacked then

                hasAttacked = true


                -- Attack sound
                if attackSound then
                    attackSound:Play()
                end


                mainPart.Anchored = true
                mainPart.CanCollide = true


                -- Move Shocker toward player
                local attackTween =
                    game:GetService("TweenService"):Create(
                        mainPart,

                        TweenInfo.new(
                            0.5,
                            Enum.EasingStyle.Sine,
                            Enum.EasingDirection.In
                        ),

                        {
                            CFrame = Root.CFrame
                        }
                    )


                attackTween:Play()


                -- Damage
                task.delay(0.37, function()

                    if Hum
                        and Hum.Health > 0 then

                        Hum:TakeDamage(25)


                        -- Camera shake
                        pcall(function()
                            camShake:Shake(
                                cameraShaker.Presets.Explosion
                            )
                        end)


                        -- Death cause
                        pcall(function()

                            local statsFolder =
                                ReplicatedStorage:FindFirstChild(
                                    "GameStats"
                                )

                            if statsFolder then

                                local playerStat =
                                    statsFolder:FindFirstChild(
                                        "Player_" .. Char.Name
                                    )

                                if playerStat then

                                    local total =
                                        playerStat:FindFirstChild(
                                            "Total"
                                        )

                                    if total then

                                        local deathCause =
                                            total:FindFirstChild(
                                                "DeathCause"
                                            )

                                        if deathCause then
                                            deathCause.Value =
                                                "Shocker"
                                        end
                                    end
                                end
                            end

                        end)


                        -- Death hints
                        local hints = {
                            "You died to who you call Shocker...",
                            "Don't look at it or it stuns you!"
                        }


                        -- Send death hint
                        pcall(function()

                            local remotesFolder =
                                ReplicatedStorage:FindFirstChild(
                                    "RemotesFolder"
                                )

                            if remotesFolder then

                                local deathHint =
                                    remotesFolder:FindFirstChild(
                                        "DeathHint"
                                    )

                                if deathHint then
                                    firesignal(
                                        deathHint.OnClientEvent,
                                        hints,
                                        "Blue"
                                    )

                                    return
                                end
                            end


                            local bricks =
                                ReplicatedStorage:FindFirstChild(
                                    "Bricks"
                                )

                            if bricks then

                                local deathHint =
                                    bricks:FindFirstChild(
                                        "DeathHint"
                                    )

                                if deathHint then
                                    firesignal(
                                        deathHint.OnClientEvent,
                                        hints
                                    )
                                end
                            end

                        end)
                    end
                end)


                -- Wait for attack
                attackTween.Completed:Wait()

                task.wait(0.75)


                -- Cleanup
                if entity then
                    entity:Destroy()
                end

                break
            end
        end
    end)
end


-- Start Shocker
task.spawn(SpawnShocker)
