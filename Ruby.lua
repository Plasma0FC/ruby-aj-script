--[[
    Ruby - Steal a Brainrots Script
    Criado por: Ruby Team
    Versão: 1.0
]]

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Variáveis
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- Variável global para armazenar a plot do jogador
local playerPlot = nil
local plotIdentified = false

-- Variável global para controle do auto join
_G.autoJoinEnabled = false
local blacklist = {}

-- Sistema de eventos para sincronizar GUI
_G.autoJoinStateChanged = Instance.new("BindableEvent")

-- Cores do tema Ruby (Roxa e Branco)
local COLORS = {
    PRIMARY = Color3.fromRGB(25, 25, 35),
    SECONDARY = Color3.fromRGB(45, 45, 65),
    ACCENT = Color3.fromRGB(138, 43, 226), -- Roxo
    ACCENT_LIGHT = Color3.fromRGB(155, 89, 182),
    TEXT_PRIMARY = Color3.fromRGB(255, 255, 255), -- Branco
    TEXT_SECONDARY = Color3.fromRGB(200, 200, 200),
    SUCCESS = Color3.fromRGB(76, 175, 80),
    ERROR = Color3.fromRGB(244, 67, 54),
    WARNING = Color3.fromRGB(255, 152, 0)
}

-- Função de notificação personalizada
local function ShowRubyNotification(title, message, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 5,
            Icon = "rbxassetid://140586746394105"
        })
    end)
end

-- Função utilitária para encontrar a plot do jogador pelo TextLabel (atualizada para uso global)
local function identifyPlayerPlot()
    local found = false
    if workspace:FindFirstChild("Plots") then
        for _, plot in pairs(workspace.Plots:GetChildren()) do
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("SurfaceGui") and plotSign.SurfaceGui:FindFirstChild("Frame") and plotSign.SurfaceGui.Frame:FindFirstChild("TextLabel") then
                local label = plotSign.SurfaceGui.Frame.TextLabel
                print("[Ruby] Plot encontrada: ", plot.Name, "| TextLabel: ", label.Text)
                -- Aceita se o TextLabel contém ou começa com o nome do jogador
                if string.find(label.Text, player.Name, 1, true) or label.Text:sub(1, #player.Name) == player.Name then
                    playerPlot = plot
                    found = true
                    break
                end
            end
        end
    end
    plotIdentified = found
    return found
end

-- Função para aguardar identificação da plot (timeout de 10s)
local function waitForPlotIdentification(timeout)
    timeout = timeout or 10
    local elapsed = 0
    while not identifyPlayerPlot() and elapsed < timeout do
        task.wait(0.5)
        elapsed = elapsed + 0.5
    end
    return plotIdentified
end

-- Iniciar identificação automática ao rodar o script
spawn(function()
    ShowRubyNotification("Ruby", "Aguardando identificação da sua base...", 4)
    if waitForPlotIdentification(15) then
        ShowRubyNotification("Ruby", "Sua base foi identificada!", 4)
    else
        ShowRubyNotification("Ruby", "Não foi possível identificar sua base automaticamente!", 4)
    end
end)

-- Função utilitária para encontrar a zona de coleta da plot do jogador
local function getCollectZone(plot)
    if plot and plot:FindFirstChild("Decorations") then
        for _, deco in pairs(plot.Decorations:GetChildren()) do
            if deco:FindFirstChild("SurfaceGui") and deco.SurfaceGui:FindFirstChild("Frame") and deco.SurfaceGui.Frame:FindFirstChild("TextLabel") then
                local label = deco.SurfaceGui.Frame.TextLabel
                if label.Text == "COLLECT ZONE" then
                    return deco
                end
            end
        end
    end
    return nil
end

-- Função utilitária para forçar teleporte seguro
local function forceTeleport(HRP, pos)
    local humanoid = HRP.Parent and HRP.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
    for i = 1, 10 do
        HRP.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
        HRP.Velocity = Vector3.new(0,0,0)
        task.wait(0.05)
    end
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

-- Função Steal Instant (Teleport para spawn)
local function stealInstant()
    if not plotIdentified or not playerPlot then
        ShowRubyNotification("Ruby", "Aguardando identificação da sua base!", 3)
        return
    end
    local HRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then 
        ShowRubyNotification("Ruby", "Personagem não encontrado!", 3)
        return 
    end
    -- 1. Tentar teleportar para o objeto Spawn da plot
    local spawnObj = playerPlot:FindFirstChild("Spawn")
    if spawnObj and spawnObj:IsA("BasePart") then
        local pos = spawnObj.Position + Vector3.new(0,3,0)
        forceTeleport(HRP, pos)
        ShowRubyNotification("Ruby", "Steal Instant ativado! Teleportado para o spawn da sua base.", 3)
        return
    end
    -- 2. Procurar pela zona de coleta
    local collectZone = getCollectZone(playerPlot)
    if collectZone then
        local pos = collectZone.Position + Vector3.new(0,3,0)
        forceTeleport(HRP, pos)
        ShowRubyNotification("Ruby", "Steal Instant ativado! Teleportado para a zona de coleta.", 3)
        return
    end
    -- 3. Fallback para coletador verde
    local collector = nil
    for _, obj in pairs(playerPlot:GetDescendants()) do
        if obj:IsA("Part") and obj.BrickColor.Name == "Bright green" then
            collector = obj
            break
        end
    end
    if collector then
        local pos = collector.Position + Vector3.new(0,3,0)
        forceTeleport(HRP, pos)
        ShowRubyNotification("Ruby", "Steal Instant ativado! Teleportado para o coletador.", 3)
        return
    end
    -- 4. Fallback para frente da base
    local basePos = playerPlot.Position
    local baseSize = playerPlot.Size
    local pos = Vector3.new(basePos.X, basePos.Y + 5, basePos.Z + baseSize.Z/2 + 10)
    forceTeleport(HRP, pos)
    ShowRubyNotification("Ruby", "Steal Instant ativado! Teleportado para sua base.", 3)
end

-- Função para coletar pet automaticamente (legítimo, rápido, seguro)
local function autoCollectPet()
    if not plotIdentified or not playerPlot then
        ShowRubyNotification("Ruby", "Aguardando identificação da sua base!", 3)
        return
    end
    local HRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then 
        ShowRubyNotification("Ruby", "Personagem não encontrado!", 3)
        return 
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        ShowRubyNotification("Ruby", "Humanoid não encontrado!", 3)
        return
    end
    -- Verificar se tem pet na mão (detecção aprimorada)
    local hasPet = false
    if char then
        for _, child in pairs(char:GetChildren()) do
            if not (child:IsA("BasePart") and (child.Name == "Head" or child.Name == "Torso" or child.Name:find("Leg") or child.Name:find("Arm") or child.Name:find("Hand") or child.Name:find("Foot"))) then
                if child:IsA("Tool") or child:IsA("Accessory") or child:FindFirstChildOfClass("Weld") or child:FindFirstChildOfClass("Attachment") or child.Name:lower():find("pet") or child.Name:lower():find("egg") or child.Name:lower():find("animal") then
                    hasPet = true
                    break
                end
            end
        end
    end
    if not hasPet then
        ShowRubyNotification("Ruby", "Você não tem um pet para coletar!", 3)
        return
    end
    -- ALERTA: verificar inimigos próximos na plot
    local enemies = {}
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - HRP.Position).Magnitude
            if dist < 40 then -- dentro da plot
                table.insert(enemies, plr.Name)
            end
        end
    end
    if #enemies > 0 then
        ShowRubyNotification("Ruby", "Atenção: Jogadores próximos! Use com cuidado!", 4)
    end
    -- Procurar pela zona de coleta
    local collectZone = getCollectZone(playerPlot)
    if collectZone then
        local pos = collectZone.Position + Vector3.new(0,3,0)
        local oldSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 28
        ShowRubyNotification("Ruby", "Indo coletar... Não mexa até aparecer a notificação de sucesso!", 3)
        -- Simular zig-zag e pulos
        local function zigzagMoveTo(targetPos)
            local start = HRP.Position
            local dir = (targetPos - start).Unit
            local right = Vector3.new(-dir.Z, 0, dir.X)
            for i=1,5 do
                local offset = (i%2==0) and right*4 or -right*4
                local mid = start + dir*((i/5)*(targetPos-start).Magnitude) + offset
                humanoid:MoveTo(mid)
                humanoid.Jump = true
                task.wait(0.25)
            end
            humanoid:MoveTo(targetPos)
        end
        zigzagMoveTo(pos)
        -- Espera chegar
        local arrived = false
        local start = tick()
        humanoid.MoveToFinished:Connect(function(reached)
            arrived = reached
        end)
        while not arrived and tick() - start < 5 do
            if (HRP.Position - pos).Magnitude < 4 then
                arrived = true
                break
            end
            humanoid.Jump = true
            task.wait(0.1)
        end
        humanoid:Move(Vector3.new(0,0,0), false)
        -- Aguarda coleta (pet sair da mão)
        local collected = false
        local waitCollect = tick()
        while tick() - waitCollect < 3 do
            local stillHasPet = false
            for _, child in pairs(char:GetChildren()) do
                if not (child:IsA("BasePart") and (child.Name == "Head" or child.Name == "Torso" or child.Name:find("Leg") or child.Name:find("Arm") or child.Name:find("Hand") or child.Name:find("Foot"))) then
                    if child:IsA("Tool") or child:IsA("Accessory") or child:FindFirstChildOfClass("Weld") or child:FindFirstChildOfClass("Attachment") or child.Name:lower():find("pet") or child.Name:lower():find("egg") or child.Name:lower():find("animal") then
                        stillHasPet = true
                        break
                    end
                end
            end
            if not stillHasPet then
                collected = true
                break
            end
            task.wait(0.1)
        end
        -- FUGA: MoveTo para fora da base (20 studs na direção Z)
        if collected then
            local basePos = playerPlot.Position
            local baseSize = playerPlot.Size
            local escapePos = Vector3.new(basePos.X, pos.Y, basePos.Z + baseSize.Z/2 + 20)
            humanoid:MoveTo(escapePos)
            ShowRubyNotification("Ruby", "Pet coletado! Fugindo da base...", 3)
            local escStart = tick()
            while (HRP.Position - escapePos).Magnitude > 5 and tick() - escStart < 4 do
                humanoid.Jump = true
                task.wait(0.1)
            end
            humanoid:Move(Vector3.new(0,0,0), false)
            ShowRubyNotification("Ruby", "Fuga concluída!", 3)
        else
            ShowRubyNotification("Ruby", "Não foi possível confirmar a coleta do pet.", 3)
        end
        humanoid.WalkSpeed = oldSpeed
        return
    end
    ShowRubyNotification("Ruby", "Coletador não encontrado na base!", 3)
end

-- Função para entrar em servidor específico
local function joinServerById(serverId)
    if not serverId or serverId == "" then
        ShowRubyNotification("Ruby", "Por favor, insira um Server ID válido!", 3)
        return
    end
    
    -- Limpar espaços em branco
    serverId = string.gsub(serverId, "%s+", "")
    
    -- Verificar se é um UUID válido (formato: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
    local uuidPattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    local isUUID = string.match(serverId, uuidPattern)
    
    -- Verificar se é um número
    local isNumber = tonumber(serverId)
    
    -- Aceitar tanto UUID quanto número
    if not isUUID and not isNumber then
        ShowRubyNotification("Ruby", "Server ID deve ser um número ou UUID válido!", 3)
        return
    end
    
    ShowRubyNotification("Ruby", "Conectando ao servidor " .. serverId .. "...", 3)
    
    -- Tentar teleportar para o servidor
    local success, error = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, serverId, player)
    end)
    
    if not success then
        ShowRubyNotification("Ruby", "Erro ao conectar: " .. tostring(error), 3)
    end
end

-- Função para criar botões estilizados
local function CreateStyledButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 40)
    button.BackgroundColor3 = COLORS.SECONDARY
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.TEXT_PRIMARY
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.ACCENT
    stroke.Thickness = 1
    stroke.Parent = button
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.ACCENT),
        ColorSequenceKeypoint.new(1, COLORS.ACCENT_LIGHT)
    })
    gradient.Parent = stroke
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {
            BackgroundColor3 = COLORS.ACCENT
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Thickness = 2
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {
            BackgroundColor3 = COLORS.SECONDARY
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Thickness = 1
        }):Play()
    end)
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    return button
end

-- Função para criar abas
local function CreateTab(parent, name, isActive)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 100, 0, 30)
    tab.BackgroundColor3 = isActive and COLORS.ACCENT or COLORS.SECONDARY
    tab.BorderSizePixel = 0
    tab.Text = name
    tab.TextColor3 = COLORS.TEXT_PRIMARY
    tab.TextScaled = false
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 20
    tab.TextWrapped = true
    tab.TextXAlignment = Enum.TextXAlignment.Center
    tab.TextYAlignment = Enum.TextYAlignment.Center
    tab.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tab
    return tab
end

-- Função para criar campo de texto
local function CreateTextBox(parent, placeholder)
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 35)
    textBox.BackgroundColor3 = COLORS.PRIMARY
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.TextColor3 = COLORS.TEXT_PRIMARY
    textBox.PlaceholderColor3 = COLORS.TEXT_SECONDARY
    textBox.TextScaled = true
    textBox.Font = Enum.Font.Gotham
    textBox.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = textBox
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.ACCENT
    stroke.Thickness = 1
    stroke.Parent = textBox
    return textBox
end

-- Criar GUI Principal
local function CreateMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Ruby_GUI"
    screenGui.Parent = playerGui
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = COLORS.PRIMARY
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.ACCENT
    stroke.Thickness = 3
    stroke.Parent = mainFrame
    
    -- Efeito de gradiente no stroke
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.ACCENT),
        ColorSequenceKeypoint.new(0.5, COLORS.ACCENT_LIGHT),
        ColorSequenceKeypoint.new(1, COLORS.ACCENT)
    })
    gradient.Parent = stroke
    
    -- Animação do gradiente
    RunService.Heartbeat:Connect(function()
        gradient.Offset = Vector2.new(tick() % 2 / 2, 0)
    end)
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = COLORS.SECONDARY
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ruby"
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Botão de fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 10)
    closeButton.BackgroundColor3 = COLORS.ERROR
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = COLORS.TEXT_PRIMARY
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        ShowRubyNotification("Ruby", "Script finalizado! Até logo!", 3)
        task.wait(1)
        -- Fechar todas as GUIs
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name:find("Ruby") then
                gui:Destroy()
            end
        end
        -- Parar todos os loops e conexões
        _G.autoJoinEnabled = false
        -- Finalizar o script completamente
        script:Destroy()
    end)
    
    -- Container das abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -20, 0, 40)
    tabContainer.Position = UDim2.new(0, 10, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    -- Layout das abas (centralizado)
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabContainer
    
    -- Container do conteúdo
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -110)
    contentContainer.Position = UDim2.new(0, 10, 0, 110)
    contentContainer.BackgroundColor3 = COLORS.SECONDARY
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentContainer
    
    -- ScrollFrame para o conteúdo
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = COLORS.ACCENT
    scrollFrame.Parent = contentContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    -- Variável para armazenar o TextBox do Server ID
    local serverIdTextBox = nil
    
    -- Função para mostrar conteúdo da aba
    local function ShowTabContent(tabName)
        -- Limpar conteúdo anterior (exceto UIListLayout)
        for _, child in pairs(scrollFrame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        if tabName == "Principal" then
            -- Conteúdo da aba Principal (movido da aba Info)
            local creditsFrame = Instance.new("Frame")
            creditsFrame.Size = UDim2.new(1, 0, 0, 200)
            creditsFrame.BackgroundTransparency = 1
            creditsFrame.Parent = scrollFrame
            
            local creditsTitle = Instance.new("TextLabel")
            creditsTitle.Size = UDim2.new(1, 0, 0, 40)
            creditsTitle.Position = UDim2.new(0, 0, 0, 0)
            creditsTitle.BackgroundTransparency = 1
            creditsTitle.Text = "Sobre o Ruby"
            creditsTitle.TextColor3 = COLORS.ACCENT
            creditsTitle.TextScaled = true
            creditsTitle.Font = Enum.Font.GothamBold
            creditsTitle.Parent = creditsFrame
            
            local creditsText = Instance.new("TextLabel")
            creditsText.Size = UDim2.new(1, 0, 0, 120)
            creditsText.Position = UDim2.new(0, 0, 0, 50)
            creditsText.BackgroundTransparency = 1
            creditsText.Text = "Ruby é um script premium desenvolvido especificamente para o jogo Steal a Brainrots.\n\nFuncionalidades:\n• Steal Instant - Teleporte rápido para o coletador\n• Auto Collect Pet - Coleta automática de pets\n• Server Hop - Entre em servidores específicos\n• Interface elegante em roxo e branco\n• Performance otimizada"
            creditsText.TextColor3 = COLORS.TEXT_SECONDARY
            creditsText.TextScaled = true
            creditsText.Font = Enum.Font.Gotham
            creditsText.TextWrapped = true
            creditsText.Parent = creditsFrame
            
            local versionFrame = Instance.new("Frame")
            versionFrame.Size = UDim2.new(1, 0, 0, 80)
            versionFrame.Position = UDim2.new(0, 0, 0, 220)
            versionFrame.BackgroundColor3 = COLORS.PRIMARY
            versionFrame.BorderSizePixel = 0
            versionFrame.Parent = scrollFrame
            
            local versionCorner = Instance.new("UICorner")
            versionCorner.CornerRadius = UDim.new(0, 8)
            versionCorner.Parent = versionFrame
            
            local versionTitle = Instance.new("TextLabel")
            versionTitle.Size = UDim2.new(1, 0, 0, 30)
            versionTitle.Position = UDim2.new(0, 10, 0, 5)
            versionTitle.BackgroundTransparency = 1
            versionTitle.Text = "Informações"
            versionTitle.TextColor3 = COLORS.ACCENT
            versionTitle.TextScaled = true
            versionTitle.Font = Enum.Font.GothamBold
            versionTitle.Parent = versionFrame
            
            local versionText = Instance.new("TextLabel")
            versionText.Size = UDim2.new(1, -20, 0, 40)
            versionText.Position = UDim2.new(0, 10, 0, 35)
            versionText.BackgroundTransparency = 1
            versionText.Text = "Versão: 1.0\nDesenvolvido por: GuiiX\nData: 16/07/2025"
            versionText.TextColor3 = COLORS.TEXT_SECONDARY
            versionText.TextScaled = true
            versionText.Font = Enum.Font.Gotham
            versionText.Parent = versionFrame
            
            -- Botão para verificar tempo da sessão
            CreateStyledButton(scrollFrame, "Verificar Tempo da Sessão", function()
                local userData = loadUserData()
                if userData then
                    local timeLeft = userData.expires_at - os.time()
                    if timeLeft > 0 then
                        local hoursLeft = math.floor(timeLeft / 3600)
                        local minutesLeft = math.floor((timeLeft % 3600) / 60)
                        ShowRubyNotification("Ruby", "Sessão válida por mais " .. hoursLeft .. "h " .. minutesLeft .. "m", 4)
                    else
                        ShowRubyNotification("Ruby", "Sessão expirada! Faça login novamente.", 4)
                    end
                else
                    ShowRubyNotification("Ruby", "Nenhuma sessão ativa encontrada.", 3)
                end
            end)
            
        elseif tabName == "Server Hop" then
            -- Conteúdo da aba Server Hop
            local infoFrame = Instance.new("Frame")
            infoFrame.Size = UDim2.new(1, 0, 0, 60)
            infoFrame.BackgroundTransparency = 1
            infoFrame.Parent = scrollFrame
            
            local infoText = Instance.new("TextLabel")
            infoText.Size = UDim2.new(1, 0, 1, 0)
            infoText.BackgroundTransparency = 1
            infoText.Text = "Cole o Server ID abaixo e clique em Join para entrar no servidor desejado."
            infoText.TextColor3 = COLORS.TEXT_SECONDARY
            infoText.TextScaled = true
            infoText.Font = Enum.Font.Gotham
            infoText.TextWrapped = true
            infoText.Parent = infoFrame
            
            -- Campo de texto para Server ID
            serverIdTextBox = CreateTextBox(scrollFrame, "Cole o Server ID aqui...")
            
            -- Botão: Join
            CreateStyledButton(scrollFrame, "Join", function()
                if serverIdTextBox and serverIdTextBox.Text then
                    joinServerById(serverIdTextBox.Text)
                else
                    ShowRubyNotification("Ruby", "Por favor, insira um Server ID primeiro!", 3)
                end
            end)

            -- Botão: Toggle Auto Join (criado manualmente para controle total)
            local autoJoinBtn = Instance.new("TextButton")
            autoJoinBtn.Size = UDim2.new(1, -20, 0, 40)
            autoJoinBtn.BackgroundColor3 = Color3.fromRGB(244, 67, 54) -- Vermelho (desligado)
            autoJoinBtn.BorderSizePixel = 0
            autoJoinBtn.Text = "Auto Join: Desativado"
            autoJoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            autoJoinBtn.TextScaled = true
            autoJoinBtn.Font = Enum.Font.GothamBold
            autoJoinBtn.Parent = scrollFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = autoJoinBtn
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = COLORS.ACCENT
            stroke.Thickness = 1
            stroke.Parent = autoJoinBtn
            
            -- Variável para controlar o estado atual
            local isAutoJoinEnabled = false
            
            -- Função para atualizar aparência do botão
            local function updateButtonAppearance()
                if _G.autoJoinEnabled then
                    autoJoinBtn.Text = "Auto Join: Ativado"
                    autoJoinBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
                else
                    autoJoinBtn.Text = "Auto Join: Desativado"
                    autoJoinBtn.BackgroundColor3 = Color3.fromRGB(244, 67, 54) -- Vermelho
                end
            end
            
            autoJoinBtn.MouseButton1Click:Connect(function()
                _G.autoJoinEnabled = not _G.autoJoinEnabled
                
                if _G.autoJoinEnabled then
                    ShowRubyNotification("Ruby", "Auto Join ativado!", 3)
                else
                    ShowRubyNotification("Ruby", "Auto Join desativado!", 3)
                end
                
                updateButtonAppearance()
                -- Disparar evento para sincronizar
                _G.autoJoinStateChanged:Fire(_G.autoJoinEnabled)
            end)
            
            -- Escutar mudanças de estado (para sincronizar com tecla J)
            _G.autoJoinStateChanged.Event:Connect(function(enabled)
                updateButtonAppearance()
            end)
            
            -- Atualizar aparência inicial
            updateButtonAppearance()
            
            -- Efeitos de hover (sem interferir na cor do estado)
            autoJoinBtn.MouseEnter:Connect(function()
                TweenService:Create(stroke, TweenInfo.new(0.3), {
                    Thickness = 2
                }):Play()
            end)
            
            autoJoinBtn.MouseLeave:Connect(function()
                TweenService:Create(stroke, TweenInfo.new(0.3), {
                    Thickness = 1
                }):Play()
            end)
            

        end
    end
    
    -- Criar abas
    local tabs = {"Principal", "Server Hop"}
    local tabButtons = {}

    for i, tabName in ipairs(tabs) do
        local tabButton = CreateTab(tabContainer, tabName, i == 1)
        tabButton.LayoutOrder = i
        tabButton.Parent = tabContainer
        tabButton.Size = UDim2.new(1/#tabs, -5, 1, 0)
        
        tabButton.MouseButton1Click:Connect(function()
            -- Atualizar aparência das abas
            for j, button in ipairs(tabButtons) do
                TweenService:Create(button, TweenInfo.new(0.3), {
                    BackgroundColor3 = j == i and COLORS.ACCENT or COLORS.SECONDARY
                }):Play()
            end
            ShowTabContent(tabName)
        end)
        table.insert(tabButtons, tabButton)
    end
    
    -- Mostrar conteúdo inicial (Principal)
    ShowTabContent("Principal")
    
    -- Sistema de arrastar
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Notificação de boas-vindas
    task.wait(1)
    ShowRubyNotification("Ruby", "Script carregado com sucesso! Bem-vindo!", 3)
end

-- Inicializar GUI
-- CreateMainGUI() -- REMOVIDO: A GUI agora é criada apenas após a validação da key

-- Toggle da GUI com tecla
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.H then
        local existingGui = playerGui:FindFirstChild("Ruby_GUI")
        if existingGui then
            existingGui:Destroy()
        else
            CreateMainGUI()
        end
    end
    
    -- Toggle do Auto Join com tecla J
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        _G.autoJoinEnabled = not _G.autoJoinEnabled
        if _G.autoJoinEnabled then
            ShowRubyNotification("Ruby", "Auto Join ativado! (Tecla J)", 3)
        else
            ShowRubyNotification("Ruby", "Auto Join desativado! (Tecla J)", 3)
        end
        
        -- Disparar evento para atualizar GUI
        _G.autoJoinStateChanged:Fire(_G.autoJoinEnabled)
    end
end)

-- Notificação inicial
ShowRubyNotification("Ruby", "Script carregado! Pressione H para abrir a GUI", 4) 
ShowRubyNotification("Ruby", "Pressione J para ativar/desativar Auto Join", 4) 

-- =============================
-- [INÍCIO] Validação de Key Discord com Sistema de Lembrar Usuário
-- =============================

local HttpService = game:GetService("HttpService")
local validated = false

-- Armazenamento local das keys usadas (simula um banco de dados)
local usedKeys = {}

-- Função para salvar dados do usuário localmente
local function saveUserData(discordId, key)
    local userData = {
        discord_id = discordId,
        key = key,
        login_time = os.time(),
        expires_at = os.time() + (24 * 60 * 60) -- 24 horas
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(userData)
    end)
    
    if success then
        writefile("ruby_user_data.json", encoded)
        return true
    end
    return false
end

-- Função para carregar dados do usuário salvos
local function loadUserData()
    local success, exists = pcall(function()
        return readfile("ruby_user_data.json")
    end)
    
    if success and exists then
        local decoded = HttpService:JSONDecode(exists)
        if decoded and decoded.expires_at and os.time() < decoded.expires_at then
            return decoded
        end
    end
    return nil
end

-- Função para limpar dados expirados
local function clearExpiredData()
    local userData = loadUserData()
    if userData and os.time() >= userData.expires_at then
        pcall(function()
            delfile("ruby_user_data.json")
        end)
        return true
    end
    return false
end

-- Função para validar formato da key
local function validateKeyFormat(key)
    -- Verifica se a key segue o formato RUBY-XGXX-UXXX-XXIX
    local pattern = "^RUBY%-%wG%w%w%-U%w%w%w%-%w%wI%w$"
    return string.match(key, pattern) ~= nil
end

-- Função para verificar se a key já foi usada
local function isKeyUsed(key)
    return usedKeys[key] == true
end

-- Função para marcar key como usada
local function markKeyAsUsed(key, discordId)
    usedKeys[key] = {
        used_by = discordId,
        used_at = os.time()
    }
end

-- Função de validação local
local function validateKey(discordId, key)
    -- Verificar formato
    if not validateKeyFormat(key) then
        return false, "Formato de key inválido. Use: RUBY-XGXX-UXXX-XXIX"
    end
    
    -- Verificar se já foi usada
    if isKeyUsed(key) then
        local usedInfo = usedKeys[key]
        return false, "Esta key já foi usada por outro usuário."
    end
    
    -- Se passou por todas as verificações, marcar como usada
    markKeyAsUsed(key, discordId)
    return true, "Key validada com sucesso!"
end

-- Função para auto-login se dados salvos existirem
local function attemptAutoLogin()
    local userData = loadUserData()
    if userData then
        local valid, msg = validateKey(userData.discord_id, userData.key)
        if valid then
            validated = true
            
            -- Calcular tempo restante
            local timeLeft = userData.expires_at - os.time()
            local hoursLeft = math.floor(timeLeft / 3600)
            local minutesLeft = math.floor((timeLeft % 3600) / 60)
            
            ShowRubyNotification("Ruby", "Login automático realizado! Bem-vindo de volta!", 4)
            task.wait(1)
            ShowRubyNotification("Ruby", "Sessão válida por mais " .. hoursLeft .. "h " .. minutesLeft .. "m", 4)
            return true
        else
            -- Se a key não for mais válida, limpar dados
            pcall(function()
                delfile("ruby_user_data.json")
            end)
        end
    end
    return false
end

-- Tela de validação
local function showValidationScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Ruby_Validation"
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 200)
    frame.Position = UDim2.new(0.5, -175, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.Parent = screenGui
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Validação de Key - Ruby"
    title.TextColor3 = Color3.fromRGB(138, 43, 226)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local idBox = Instance.new("TextBox")
    idBox.Size = UDim2.new(1, -40, 0, 30)
    idBox.Position = UDim2.new(0, 20, 0, 50)
    idBox.PlaceholderText = "Seu ID do Discord"
    idBox.Text = ""
    idBox.TextColor3 = Color3.fromRGB(255,255,255)
    idBox.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    idBox.Font = Enum.Font.Gotham
    idBox.TextScaled = true
    idBox.Parent = frame
    local idCorner = Instance.new("UICorner")
    idCorner.CornerRadius = UDim.new(0, 6)
    idCorner.Parent = idBox

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -40, 0, 30)
    keyBox.Position = UDim2.new(0, 20, 0, 90)
    keyBox.PlaceholderText = "Sua Key (RUBY-XGXX-UXXX-XXIX)"
    keyBox.Text = ""
    keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextScaled = true
    keyBox.Parent = frame
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyBox

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 20)
    statusLabel.Position = UDim2.new(0, 20, 0, 130)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(244, 67, 54)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = frame

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(1, -40, 0, 35)
    verifyBtn.Position = UDim2.new(0, 20, 0, 155)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    verifyBtn.Text = "Verificar Key"
    verifyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.TextScaled = true
    verifyBtn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = verifyBtn

    verifyBtn.MouseButton1Click:Connect(function()
        local discordId = idBox.Text
        local key = keyBox.Text
        
        if discordId == "" or key == "" then
            statusLabel.Text = "Preencha todos os campos!"
            return
        end
        
        statusLabel.Text = "Validando..."
        local valid, msg = validateKey(discordId, key)
        
        if valid then
            -- Salvar dados do usuário para login automático
            if saveUserData(discordId, key) then
                statusLabel.Text = "Login salvo! Próximo login será automático."
                task.wait(1)
            end
            
            validated = true
            screenGui:Destroy()
            ShowRubyNotification("Ruby", "Key validada com sucesso! Login salvo por 24h.", 4)
            CreateMainGUI()
        else
            statusLabel.Text = "Erro: " .. tostring(msg)
        end
    end)
end

-- Tentar auto-login primeiro
if not validated then
    if attemptAutoLogin() then
        -- Auto-login bem-sucedido, NÃO criar GUI automaticamente
        task.wait(1) -- Aguardar notificações terminarem
        -- GUI será criada apenas quando pressionar H
    else
        -- Limpar dados expirados se existirem
        clearExpiredData()
        
        -- Mostrar tela de login
        showValidationScreen()
        repeat task.wait(0.1) until validated
    end
end
-- =============================
-- [FIM] Validação de Key Discord (Local/Fake)
-- =============================

-- =============================
-- [INÍCIO] Integração Automática com Python (Job ID) - ULTRA RÁPIDO
-- =============================

local HttpService = game:GetService("HttpService")
local lastCheckedJobId = nil
local isJoining = false
local scriptStartTime = tick() -- Marca quando o script foi executado
local initialJobId = nil -- Job ID que estava no clipboard quando o script iniciou

-- Função para buscar o Job ID do Python (sem delay)
local function fetchJobIdFromPython()
    local success, response = pcall(function()
        return game:HttpGet("http://127.0.0.1:5000/jobid")
    end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.job_id and data.job_id ~= "" then
            return data.job_id
        end
    end
    return nil
end

-- Função para tentar entrar no servidor repetidamente
local function attemptJoinServer(jobId)
    if isJoining then return end
    if blacklist[jobId] then
        print("[Ruby] Job ID na blacklist, ignorando:", jobId)
        return
    end
    isJoining = true

    ShowRubyNotification("Ruby", "Tentando entrar no servidor " .. jobId .. "...", 2)

    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, jobId, player)
    end)

    if not success then
        ShowRubyNotification("Ruby", "Erro ao entrar: " .. tostring(errorMsg), 2)
        blacklist[jobId] = true
        print("[Ruby] Adicionado à blacklist:", jobId)
    else
        ShowRubyNotification("Ruby", "Teleporte iniciado!", 2)
    end

    isJoining = false
end

-- Loop ultra rápido para checar o clipboard
spawn(function()
    -- Aguardar um pouco para o Python inicializar
    task.wait(1)
    
    -- Capturar o Job ID inicial que estava no clipboard
    initialJobId = fetchJobIdFromPython()
    if initialJobId then
        print("[Ruby] Job ID inicial ignorado (já estava no clipboard):", initialJobId)
        lastCheckedJobId = initialJobId -- Marca como já processado
    end
    
    ShowRubyNotification("Ruby", "Sistema de Auto Join inicializado! Aguardando novos Job IDs...", 3)
    
    while true do
        if _G.autoJoinEnabled then
            local jobId = fetchJobIdFromPython()
            if jobId and jobId ~= lastCheckedJobId and not blacklist[jobId] then
                lastCheckedJobId = jobId
                ShowRubyNotification("Ruby", "Novo Job ID detectado! Entrando imediatamente...", 2)
                attemptJoinServer(jobId)
            end
        end
        task.wait(0.1)
    end
end)

-- =============================
-- [FIM] Integração Automática com Python (Job ID) - ULTRA RÁPIDO
-- ============================= 