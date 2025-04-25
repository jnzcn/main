-- Script Tổng Hợp Công Cụ Server Roblox
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Lấy PlaceId của game hiện tại
local currentPlaceId = game.PlaceId

-- Kiểm tra xem GUI đã tồn tại chưa và xóa nếu có
if CoreGui:FindFirstChild("ServerUtilityGUI") then
    CoreGui.ServerUtilityGUI:Destroy()
end

-- Tạo biến để theo dõi trạng thái UI
local activeTab = "JoinByJobId"
local guiElements = {}
local dragStartPosition = nil
local dragStartOffset = nil
local isDragging = false

-- Hàm để tham gia server bằng JobId
local function joinServerWithJobId(jobId)
    if not jobId or jobId == "" then return end
    
    -- Hiển thị thông báo đang teleport
    StarterGui:SetCore("SendNotification", {
        Title = "Teleporting...",
        Text = "Đang kết nối đến server...",
        Duration = 3
    })
    
    -- Sử dụng pcall để tránh lỗi
    local success, errorMessage = pcall(function()
        -- Nếu game có Remote Function __ServerBrowser
        if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", jobId)
        else
            -- Sử dụng phương thức thông thường
            TeleportService:TeleportToPlaceInstance(currentPlaceId, jobId, LocalPlayer)
        end
    end)
    
    if not success then
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể teleport: " .. tostring(errorMessage),
            Duration = 3
        })
    end
end

-- Hàm để copy JobId vào clipboard
local function copyJobId()
    local jobId = game.JobId
    
    -- Kiểm tra nếu JobId tồn tại
    if jobId and jobId ~= "" then
        -- Sử dụng pcall để tránh lỗi
        local success = pcall(function()
            setclipboard(jobId)
        end)
        
        -- Thông báo cho người dùng
        StarterGui:SetCore("SendNotification", {
            Title = success and "JobId Copied!" or "Error",
            Text = success and "Server JobId đã được copy vào clipboard" or "Không thể copy JobId",
            Duration = 3
        })
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể lấy JobId",
            Duration = 3
        })
    end
end

-- Hàm để paste từ clipboard
local function pasteFromClipboard()
    local success, clipboardContent = pcall(function()
        return getclipboard()
    end)
    
    if success and clipboardContent then
        return clipboardContent
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể lấy nội dung từ clipboard",
            Duration = 3
        })
        return ""
    end
end

-- Hàm để tìm server có ít người nhất
local function findLeastPopulatedServer()
    -- Hiển thị thông báo đang tìm kiếm
    StarterGui:SetCore("SendNotification", {
        Title = "Searching...",
        Text = "Đang tìm server có ít người nhất...",
        Duration = 3
    })
    
    -- Sử dụng pcall để tránh lỗi
    local success, result = pcall(function()
        local servers = {}
        local cursor = ""
        
        -- Lấy danh sách các server
        repeat
            local apiUrl = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                tostring(currentPlaceId),
                cursor
            )
            
            local response = HttpService:JSONDecode(game:HttpGet(apiUrl))
            
            if response and response.data then
                for _, server in ipairs(response.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server)
                    end
                end
            end
            
            cursor = response.nextPageCursor or ""
        until not cursor or #servers >= 50 -- Giới hạn số lượng server để tránh lag
        
        -- Sắp xếp server theo số lượng người chơi (tăng dần)
        table.sort(servers, function(a, b)
            return a.playing < b.playing
        end)
        
        return servers
    end)
    
    if success and result and #result > 0 then
        -- Cập nhật danh sách server
        updateServerList(result)
        
        -- Thông báo thành công
        StarterGui:SetCore("SendNotification", {
            Title = "Success",
            Text = "Đã tìm thấy " .. #result .. " server",
            Duration = 3
        })
    else
        -- Thông báo lỗi
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Không thể tìm thấy server phù hợp",
            Duration = 3
        })
    end
end

-- Hàm để tìm server có người chơi cụ thể
local function findPlayerServer(username)
    if not username or username == "" then
        StarterGui:SetCore("SendNotification", {
            Title = "Error",
            Text = "Vui lòng nhập tên người chơi",
            Duration = 3
        })
        return
    end
    
    -- Hiển thị thông báo đang tìm kiếm
    StarterGui:SetCore("SendNotification", {
        Title = "Searching...",
        Text = "Đang tìm server có người chơi " .. username,
        Duration = 3
    })
    
    -- Sử dụng pcall để tránh lỗi
    local success, result = pcall(function()
        local servers = {}
        local cursor = ""
        local foundServer = nil
        
        -- Lặp qua các trang kết quả
        local attempts = 0
        repeat
            attempts = attempts + 1
            local apiUrl = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                tostring(currentPlaceId),
                cursor
            )
            
            local response = HttpService:JSONDecode(game:HttpGet(apiUrl))
            
            if response and response.data then
                for _, server in ipairs(response.data) do
                    -- Kiểm tra danh sách người chơi trong server
                    for _, player in ipairs(server.playerIds) do
                        -- Lấy thông tin người chơi từ UserId
                        local playerInfoSuccess, playerInfo = pcall(function()
                            return Players:GetNameFromUserIdAsync(player)
                        end)
                        
                        if playerInfoSuccess and playerInfo then
                            -- So sánh tên người chơi (không phân biệt chữ hoa/thường)
                            if string.lower(playerInfo) == string.lower(username) then
                                foundServer = server
                                break
                            end
                        end
                    end
                    
                    if foundServer then
                        break
                    end
                end
            end
            
            cursor = response.nextPageCursor or ""
        until foundServer or not cursor or attempts >= 10 -- Giới hạn số lần lặp
        
        return foundServer
    end)
    
    if success and result then
        -- Tìm thấy server có người chơi
        StarterGui:SetCore("SendNotification", {
            Title = "Found!",
            Text = "Đã tìm thấy " .. username .. " trong server!",
            Duration = 3
        })
        
        -- Tham gia server
        joinServerWithJobId(result.id)
    else
        -- Không tìm thấy server
        StarterGui:SetCore("SendNotification", {
            Title = "Not Found",
            Text = "Không tìm thấy " .. username .. " trong bất kỳ server nào",
            Duration = 3
        })
    end
end

-- Hàm để tạo GUI element và lưu vào bảng để quản lý
local function createGuiElement(className, properties, parent)
    local element = Instance.new(className)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = parent
    table.insert(guiElements, element)
    return element
end

-- Hàm để cập nhật danh sách server
local function updateServerList(servers)
    -- Xóa danh sách cũ
    if serverListFrame then
        for _, child in pairs(serverListFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    -- Tạo danh sách mới
    for i, server in ipairs(servers) do
        if i <= 10 then -- Giới hạn hiển thị 10 server
            local serverFrame = createGuiElement("Frame", {
                Size = UDim2.new(1, -10, 0, 50),
                Position = UDim2.new(0, 5, 0, (i-1) * 55 + 5),
                BackgroundColor3 = Color3.fromRGB(50, 50, 55),
                BorderSizePixel = 0
            }, serverListFrame)
            
            local cornerFrame = createGuiElement("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }, serverFrame)
            
            local playerCount = createGuiElement("TextLabel", {
                Size = UDim2.new(0.2, 0, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = server.playing .. "/" .. server.maxPlayers,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Left
            }, serverFrame)
            
            local pingLabel = createGuiElement("TextLabel", {
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.2, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = "Ping: " .. server.ping .. "ms",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSans,
                TextXAlignment = Enum.TextXAlignment.Left
            }, serverFrame)
            
            local joinButton = createGuiElement("TextButton", {
                Size = UDim2.new(0.2, 0, 0.7, 0),
                Position = UDim2.new(0.8, -5, 0.15, 0),
                BackgroundColor3 = Color3.fromRGB(0, 120, 215),
                BorderSizePixel = 0,
                Text = "Join",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.SourceSansBold,
                AnchorPoint = Vector2.new(1, 0)
            }, serverFrame)
            
            local buttonCorner = createGuiElement("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }, joinButton)
            
            -- Kết nối sự kiện click vào nút join
            joinButton.MouseButton1Click:Connect(function()
                joinServerWithJobId(server.id)
            end)
            
            -- Hiệu ứng hover cho nút join
            createHoverEffect(joinButton, Color3.fromRGB(0, 120, 215), Color3.fromRGB(20, 140, 235))
        end
    end
end

-- Tạo hiệu ứng hover cho các nút
local function createHoverEffect(button, originalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
end

-- Tạo GUI
local screenGui = createGuiElement("ScreenGui", {
    Name = "ServerUtilityGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
}, CoreGui)

-- Tạo khung chính
local mainFrame = createGuiElement("Frame", {
    Size = UDim2.new(0, 350, 0, 400),
    Position = UDim2.new(0.5, -175, 0.5, -200),
    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true
}, screenGui)

-- Tạo hiệu ứng bo tròn góc
local uiCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, mainFrame)

-- Tạo thanh tiêu đề
local titleBar = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
    BorderSizePixel = 0
}, mainFrame)

-- Bo tròn góc cho thanh tiêu đề
local titleCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, titleBar)

-- Tạo clip frame để giới hạn bo tròn chỉ ở phía trên
local clipFrame = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 0.5, 0),
    Position = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
    BorderSizePixel = 0
}, titleBar)

-- Tiêu đề
local title = createGuiElement("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "Roblox Server Utility",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, titleBar)

-- Nút đóng
local closeButton = createGuiElement("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -30, 0, 0),
    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
    BorderSizePixel = 0,
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    Font = Enum.Font.SourceSansBold
}, titleBar)

-- Nút mở/đóng UI
local toggleButton = createGuiElement("TextButton", {
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Color3.fromRGB(45, 120, 200),
    BorderSizePixel = 0,
    Text = "SU",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    Visible = false,
    Font = Enum.Font.SourceSansBold
}, screenGui)

-- Bo tròn góc cho nút toggle
local toggleCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, toggleButton)

-- Tạo tab container
local tabContainer = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    BorderSizePixel = 0
}, mainFrame)

-- Tạo tab buttons
local tabButtons = {}

-- Tab Join by JobId
tabButtons.JoinByJobId = createGuiElement("TextButton", {
    Size = UDim2.new(0.33, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    BorderSizePixel = 0,
    Text = "Join by JobId",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, tabContainer)

-- Tab Find Server
tabButtons.FindServer = createGuiElement("TextButton", {
    Size = UDim2.new(0.33, 0, 1, 0),
    Position = UDim2.new(0.33, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    BorderSizePixel = 0,
    Text = "Find Server",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, tabContainer)

-- Tab Join by Username
tabButtons.JoinByUsername = createGuiElement("TextButton", {
    Size = UDim2.new(0.34, 0, 1, 0),
    Position = UDim2.new(0.66, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    BorderSizePixel = 0,
    Text = "Join by Username",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, tabContainer)

-- Tạo content frames
local contentFrames = {}

-- Content Join by JobId
contentFrames.JoinByJobId = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 1, -70),
    Position = UDim2.new(0, 0, 0, 70),
    BackgroundTransparency = 1,
    Visible = true
}, mainFrame)

-- Content Find Server
contentFrames.FindServer = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 1, -70),
    Position = UDim2.new(0, 0, 0, 70),
    BackgroundTransparency = 1,
    Visible = false
}, mainFrame)

-- Content Join by Username
contentFrames.JoinByUsername = createGuiElement("Frame", {
    Size = UDim2.new(1, 0, 1, -70),
    Position = UDim2.new(0, 0, 0, 70),
    BackgroundTransparency = 1,
    Visible = false
}, mainFrame)

-- Nội dung cho tab Join by JobId
local jobIdLabel = createGuiElement("TextLabel", {
    Size = UDim2.new(0.3, 0, 0, 25),
    Position = UDim2.new(0.1, 0, 0.1, 0),
    BackgroundTransparency = 1,
    Text = "JobId:",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left
}, contentFrames.JoinByJobId)

-- TextBox để nhập JobId
local jobIdBox = createGuiElement("TextBox", {
    Size = UDim2.new(0.6, -40, 0, 25),
    Position = UDim2.new(0.4, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(50, 50, 55),
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Nhập JobId",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    ClearTextOnFocus = false,
    Font = Enum.Font.SourceSans
}, contentFrames.JoinByJobId)

-- Bo tròn góc cho textbox
local boxCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, jobIdBox)

-- Nút Paste JobId
local pasteButton = createGuiElement("TextButton", {
    Size = UDim2.new(0, 35, 0, 25),
    Position = UDim2.new(0.9, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(60, 60, 65),
    BorderSizePixel = 0,
    Text = "📋",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSans
}, contentFrames.JoinByJobId)

-- Bo tròn góc cho nút paste
local pasteCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, pasteButton)

-- Nút Join Server
local joinButton = createGuiElement("TextButton", {
    Size = UDim2.new(0.8, 0, 0, 30),
    Position = UDim2.new(0.1, 0, 0.25, 0),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    BorderSizePixel = 0,
    Text = "Join Server",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, contentFrames.JoinByJobId)

-- Bo tròn góc cho nút join
local joinCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, joinButton)

-- Nút Copy JobId
local copyButton = createGuiElement("TextButton", {
    Size = UDim2.new(0.8, 0, 0, 30),
    Position = UDim2.new(0.1, 0, 0.4, 0),
    BackgroundColor3 = Color3.fromRGB(60, 170, 60),
    BorderSizePixel = 0,
    Text = "Copy Current JobId",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, contentFrames.JoinByJobId)

-- Bo tròn góc cho nút copy
local copyCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, copyButton)

-- Nội dung cho tab Find Server
local findButton = createGuiElement("TextButton", {
    Size = UDim2.new(0.8, 0, 0, 30),
    Position = UDim2.new(0.1, 0, 0.05, 0),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    BorderSizePixel = 0,
    Text = "Tìm Server Ít Người Nhất",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, contentFrames.FindServer)

-- Bo tròn góc cho nút find
local findButtonCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, findButton)

-- Khung chứa danh sách server
serverListFrame = createGuiElement("ScrollingFrame", {
    Size = UDim2.new(0.9, 0, 0.85, 0),
    Position = UDim2.new(0.05, 0, 0.15, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(0, 0, 0, 550),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, contentFrames.FindServer)

-- Nội dung cho tab Join by Username
local usernameLabel = createGuiElement("TextLabel", {
    Size = UDim2.new(0.3, 0, 0, 25),
    Position = UDim2.new(0.1, 0, 0.1, 0),
    BackgroundTransparency = 1,
    Text = "Username:",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left
}, contentFrames.JoinByUsername)

-- TextBox để nhập Username
local usernameBox = createGuiElement("TextBox", {
    Size = UDim2.new(0.6, 0, 0, 25),
    Position = UDim2.new(0.4, 0, 0.1, 0),
    BackgroundColor3 = Color3.fromRGB(50, 50, 55),
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Nhập tên người chơi",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    ClearTextOnFocus = false,
    Font = Enum.Font.SourceSans
}, contentFrames.JoinByUsername)

-- Bo tròn góc cho textbox
local usernameBoxCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, usernameBox)

-- Nút Find & Join
local findJoinButton = createGuiElement("TextButton", {
    Size = UDim2.new(0.8, 0, 0, 30),
    Position = UDim2.new(0.1, 0, 0.25, 0),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    BorderSizePixel = 0,
    Text = "Find & Join Player",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold
}, contentFrames.JoinByUsername)

-- Bo tròn góc cho nút find & join
local findJoinCorner = createGuiElement("UICorner", {
    CornerRadius = UDim.new(0, 4)
}, findJoinButton)

-- Tạo hiệu ứng hover cho các nút
createHoverEffect(closeButton, Color3.fromRGB(45, 45, 50), Color3.fromRGB(220, 70, 70))
createHoverEffect(toggleButton, Color3.fromRGB(45, 120, 200), Color3.fromRGB(65, 140, 220))
createHoverEffect(joinButton, Color3.fromRGB(0, 120, 215), Color3.fromRGB(20, 140, 235))
createHoverEffect(copyButton, Color3.fromRGB(60, 170, 60), Color3.fromRGB(80, 190, 80))
createHoverEffect(pasteButton, Color3.fromRGB(60, 60, 65), Color3.fromRGB(80, 80, 85))
createHoverEffect(findButton, Color3.fromRGB(0, 120, 215), Color3.fromRGB(20, 140, 235))
createHoverEffect(findJoinButton, Color3.fromRGB(0, 120, 215), Color3.fromRGB(20, 140, 235))

-- Hàm để chuyển đổi tab
local function switchTab(tabName)
    -- Cập nhật màu nút tab
    for name, button in pairs(tabButtons) do
        if name == tabName then
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        else
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        end
    end
    
    -- Hiển thị/ẩn nội dung tab
    for name, frame in pairs(contentFrames) do
        frame.Visible = (name == tabName)
    end
    
    activeTab = tabName
end

-- Kết nối sự kiện cho các nút tab
for name, button in pairs(tabButtons) do
    button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- Kết nối sự kiện drag cho thanh tiêu đề
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartPosition = input.Position
        dragStartOffset = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPosition
        mainFrame.Position = UDim2.new(
            dragStartOffset.X.Scale,
            dragStartOffset.X.Offset + delta.X,
            dragStartOffset.Y.Scale,
            dragStartOffset.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

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
        StarterGui:SetCore("SendNotification", {
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
    local clipboardContent = pasteFromClipboard()
    if clipboardContent and clipboardContent ~= "" then
        jobIdBox.Text = clipboardContent
    end
end)

-- Kết nối sự kiện click vào nút find
findButton.MouseButton1Click:Connect(findLeastPopulatedServer)

-- Kết nối sự kiện click vào nút find & join
findJoinButton.MouseButton1Click:Connect(function()
    local username = usernameBox.Text
    findPlayerServer(username)
end)

-- Phím tắt để đóng/mở UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.RightControl then
            if mainFrame.Visible then
                mainFrame.Visible = false
                toggleButton.Visible = true
            else
                mainFrame.Visible = true
                toggleButton.Visible = false
            end
        end
    end
end)

-- Tối ưu hiệu suất
local function optimizePerformance()
    -- Giảm số lượng cập nhật UI
    for _, element in ipairs(guiElements) do
        if element:IsA("GuiObject") then
            element.AutoLocalize = false
        end
    end
    
    -- Tắt các hiệu ứng không cần thiết
    mainFrame.ClipsDescendants = true
    screenGui.IgnoreGuiInset = true
    
    -- Sử dụng AnchorPoint để cải thiện hiệu suất khi thay đổi kích thước màn hình
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Giảm tải cho Rendering
    RunService:BindToRenderStep("ServerUtilityGUI_UpdateCheck", Enum.RenderPriority.Last.Value, function()
        -- Không làm gì cả, chỉ để kiểm soát việc cập nhật UI
    end)
end

-- Gọi hàm tối ưu hiệu suất
optimizePerformance()

-- Hàm dọn dẹp khi script bị hủy
local function cleanup()
    RunService:UnbindFromRenderStep("ServerUtilityGUI_UpdateCheck")
    for _, element in ipairs(guiElements) do
        if element and element.Parent then
            element:Destroy()
        end
    end
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end

-- Kết nối sự kiện khi game kết thúc
game.Close:Connect(cleanup)

-- Hiển thị thông báo khi script được tải
StarterGui:SetCore("SendNotification", {
    Title = "Server Utility Loaded",
    Text = "Nhấn RightControl để mở/đóng UI",
    Duration = 5
})
