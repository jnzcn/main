-- Script Join Server bằng JobId trong Roblox
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Lấy PlaceId của game hiện tại
local currentPlaceId = game.PlaceId

-- Tạo biến để theo dõi trạng thái UI
local uiVisible = true

-- Hàm để tham gia server bằng JobId
local function joinServerWithJobId(jobId)
    -- Hiển thị thông báo đang teleport
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Teleporting...",
        Text = "Đang kết nối đến server...",
        Duration = 3
    })
    
    -- Nếu game có Remote Function __ServerBrowser
    if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
        -- Sử dụng Remote Function có sẵn của game
        local success, errorMessage = pcall(function()
            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", jobId)
        end)
        
        if not success then
            -- Nếu không thành công, sử dụng phương thức thông thường
            TeleportService:TeleportToPlaceInstance(currentPlaceId, jobId, LocalPlayer)
        end
    else
        -- Sử dụng phương thức thông thường nếu không có Remote Function
        TeleportService:TeleportToPlaceInstance(currentPlaceId, jobId, LocalPlayer)
    end
end

-- Hàm để copy JobId vào clipboard
local function copyJobId()
    local jobId = game.JobId
    
    -- Kiểm tra nếu JobId tồn tại
    if jobId and jobId ~= "" then
        -- Copy JobId vào clipboard
        setclipboard(jobId)
        
        -- Thông báo cho người dùng
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "JobId Copied!",
            Text = "Server JobId đã được copy vào clipboard",
            Duration = 3
        })
    else
        -- Thông báo nếu không tìm thấy JobId
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể lấy JobId",
            Duration = 3
        })
    end
end

-- Tạo GUI đơn giản để join server bằng JobId
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JoinServerGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.BorderSizePixel = 0
title.Text = "Join Server by JobId"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Parent = mainFrame

-- Nút đóng
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Parent = mainFrame

-- Nút mở/đóng UI
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "UI"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 16
toggleButton.Visible = false
toggleButton.Parent = screenGui

-- Label JobId
local jobIdLabel = Instance.new("TextLabel")
jobIdLabel.Size = UDim2.new(0.3, 0, 0, 20)
jobIdLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
jobIdLabel.BackgroundTransparency = 1
jobIdLabel.Text = "JobId:"
jobIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
jobIdLabel.TextSize = 14
jobIdLabel.Parent = mainFrame

-- TextBox để nhập JobId
local jobIdBox = Instance.new("TextBox")
jobIdBox.Size = UDim2.new(0.6, 0, 0, 20)
jobIdBox.Position = UDim2.new(0.35, 0, 0.4, 0)
jobIdBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
jobIdBox.BorderSizePixel = 0
jobIdBox.Text = ""
jobIdBox.PlaceholderText = "Nhập JobId"
jobIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jobIdBox.TextSize = 14
jobIdBox.Parent = mainFrame

-- Nút Join Server
local joinButton = Instance.new("TextButton")
joinButton.Size = UDim2.new(0.4, 0, 0, 30)
joinButton.Position = UDim2.new(0.3, 0, 0.6, 0)
joinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
joinButton.BorderSizePixel = 0
joinButton.Text = "Join Server"
joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
joinButton.TextSize = 16
joinButton.Parent = mainFrame

-- Nút Copy JobId
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0.4, 0, 0, 30)
copyButton.Position = UDim2.new(0.3, 0, 0.8, 0)
copyButton.BackgroundColor3 = Color3.fromRGB(60, 170, 60)
copyButton.BorderSizePixel = 0
copyButton.Text = "Copy JobId"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 16
copyButton.Parent = mainFrame

-- Nút Paste JobId
local pasteButton = Instance.new("TextButton")
pasteButton.Size = UDim2.new(0.2, 0, 0, 20)
pasteButton.Position = UDim2.new(0.96, 0, 0.4, 0)
pasteButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
pasteButton.BorderSizePixel = 0
pasteButton.Text = "Paste"
pasteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
pasteButton.TextSize = 12
pasteButton.Parent = mainFrame

-- Kết nối sự kiện click vào nút đóng
closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    toggleButton.Visible = true
end)

-- Kết nối sự kiện click vào nút toggle
toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    toggleButton.Visible = false
end)

-- Kết nối sự kiện click vào nút join
joinButton.MouseButton1Click:Connect(function()
    local jobId = jobIdBox.Text
    
    if jobId and jobId ~= "" then
        joinServerWithJobId(jobId)
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = "Vui lòng nhập JobId hợp lệ",
            Duration = 3
        })
    end
end)

-- Kết nối sự kiện click vào nút copy
copyButton.MouseButton1Click:Connect(copyJobId)

-- Kết nối sự kiện click vào nút paste
pasteButton.MouseButton1Click:Connect(function()
    -- Lấy nội dung từ clipboard (nếu có thể)
    local success, clipboardContent = pcall(function()
        return getclipboard()
    end)
    
    if success and clipboardContent then
        jobIdBox.Text = clipboardContent
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể lấy nội dung từ clipboard",
            Duration = 3
        })
    end
end)

-- Phím tắt để đóng/mở UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        if mainFrame.Visible then
            mainFrame.Visible = false
            toggleButton.Visible = true
        else
            mainFrame.Visible = true
            toggleButton.Visible = false
        end
    end
end)
