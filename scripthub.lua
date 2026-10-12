-- X1 Games Hub v4 | paginas + autoload + sombra fixa + CTRL + fluidez | EN/PT
-- Fonte: https://scriptblox.com API | Powered by ScriptBlox.com
-- CTRL (ou RightShift) abre/fecha. Se a janela sumir, ela volta sozinha.

local Http = game:GetService("HttpService")
local Tween = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local OKG, GENVS = pcall(function() return getgenv() end)
local GV = (OKG and GENVS) or {}
GV.X1GH = GV.X1GH or {games = {}, scripts = {}, builds = 0, minimized = true, selPid = nil, autoLoaded = false}
local CACHE = GV.X1GH
if CACHE.v ~= 6 then -- rescan amplo (50 pgs) + retoma de onde parou
   CACHE.games, CACHE.scripts, CACHE.selPid, CACHE.autoLoaded = {}, {}, nil, false
   CACHE.scanPage, CACHE.curatedDone, CACHE.searchMode, CACHE.fullBackup = 0, nil, nil, nil
   CACHE.v = 6
end

local LANG = "EN"
local MIN_VIEWS = 0 -- todos os jogos do catalogo (sem corte)
local SCAN_PAGES = 50 -- 50 pgs x 20 scripts = ~1000 scripts varridos p/ montar a lista
local PAGE_SIZE = 15
local T = {
   EN = {
      title = "X1 GAMES HUB", searchPh = "  Search games...", games = "GAMES", scripts = "SCRIPTS",
      thisGame = "This Game", loading = "Loading", found = "scripts", exec = "EXECUTE", copy = "COPY",
      views = "views", likes = "likes", keyY = "KEY", keyN = "keyless", patched = "PATCHED",
      sel = "Pick a game on the left.", pickScript = "Pick a script above.", attr = "Powered by ScriptBlox.com",
      noGame = "No games over 5k views. Try another term.", noScript = "No scripts for this game.",
      hub = "hubs & universal", page = "Page", prev = "<", next = ">",
   },
   PT = {
      title = "X1 HUB DE JOGOS", searchPh = "  Buscar jogos...", games = "JOGOS", scripts = "SCRIPTS",
      thisGame = "Este jogo", loading = "Carregando", found = "scripts", exec = "EXECUTAR", copy = "COPIAR",
      views = "views", likes = "likes", keyY = "COM KEY", keyN = "sem key", patched = "PATCHED",
      sel = "Escolha um jogo na esquerda.", pickScript = "Escolha um script acima.", attr = "Powered by ScriptBlox.com",
      noGame = "Sem jogos acima de 5k views. Tente outro termo.", noScript = "Sem scripts p/ este jogo.",
      hub = "hubs & universal", page = "Pag.", prev = "<", next = ">",
   },
}
local function L(k) return T[LANG][k] or k end

local CURATED = {
   {"Blox Fruits", 2753915549}, {"Blade Ball", 13772394625}, {"Doors", 6516141723},
   {"Grow a Garden", 126884695634066}, {"Fisch", 16732694052},
   {"The Strongest Battlegrounds", 10449761463}, {"Brookhaven RP", 4924922222},
   {"Pet Simulator 99", 8737899170}, {"Murder Mystery 2", 142823291}, {"BedWars", 6872265039},
   {"Arsenal", 286090429}, {"Tower of Hell", 1962086868}, {"Adopt Me", 920587237},
   {"Rivals", 17625359962}, {"Da Hood", 2788229376}, {"Steal An Egg", 107778070777162},
   {"Volleyball Legends", 73956553001240}, {"Steal a Brainrot", 109983668079237},
   {"Universal / Hubs", -1},
}

local C = {
   bg = Color3.fromRGB(13, 15, 23), panel = Color3.fromRGB(20, 23, 34),
   side = Color3.fromRGB(16, 19, 29), accent = Color3.fromRGB(99, 102, 241),
   accent2 = Color3.fromRGB(34, 211, 238), txt = Color3.fromRGB(236, 239, 246),
   dim = Color3.fromRGB(148, 156, 176), btn = Color3.fromRGB(28, 32, 46),
   btnh = Color3.fromRGB(40, 46, 66), good = Color3.fromRGB(34, 197, 94),
   good2 = Color3.fromRGB(16, 185, 129), red = Color3.fromRGB(239, 68, 68),
}

local function tw(o, t, props, style, dir)
   pcall(function()
      Tween:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
   end)
end
local function corner(o, r) local u = Instance.new("UICorner") u.CornerRadius = UDim.new(0, r or 8) u.Parent = o return u end
local function stroke(o, col, tr)
   local s = Instance.new("UIStroke") s.Color = col or Color3.fromRGB(255, 255, 255)
   s.Transparency = tr or 0.88 s.Thickness = 1 s.Parent = o return s
end
local function grad(o, c1, c2, rot)
   local g = Instance.new("UIGradient")
   g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}
   g.Rotation = rot or 90 g.Parent = o return g
end
local function urlEncode(s)
   return (s:gsub("[^%w%-%.%_%~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end
local function apiGet(path)
   local ok, body = pcall(function() return game:HttpGet("https://scriptblox.com" .. path) end)
   if not ok or not body or body == "" then return nil end
   local ok2, data = pcall(function() return Http:JSONDecode(body) end)
   if not ok2 then return nil end
   return data
end
local function fmt(n)
   n = tonumber(n) or 0
   if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
   if n >= 1000 then return string.format("%.1fk", n / 1000) end
   return tostring(n)
end
local function uiParent()
   if gethui then local ok, h = pcall(function() return gethui() end) if ok and h then return h end end
   return PG
end
local function wipeOld()
   pcall(function()
      local roots = {PG}
      if gethui then local ok, h = pcall(function() return gethui() end) if ok and h then table.insert(roots, h) end end
      for _, root in pairs(roots) do
         local old = root:FindFirstChild("X1GamesHub") if old then old:Destroy() end
         local fl = root:FindFirstChild("X1FloatBtn") if fl then fl:Destroy() end
      end
   end)
end
local function findHub()
   local roots = {PG}
   if gethui then local ok, h = pcall(function() return gethui() end) if ok and h then table.insert(roots, 1, h) end end
   for _, root in pairs(roots) do
      local g = root:FindFirstChild("X1GamesHub")
      if g then return g end
   end
   return nil
end

local SelGame, SelScript = nil, nil

local function buildUI(startHidden)
   wipeOld()
   CACHE.builds = CACHE.builds + 1
   local myBuild = CACHE.builds

   local UIROOT = uiParent()
   local gui = Instance.new("ScreenGui")
   gui.Name = "X1GamesHub"
   gui.ResetOnSpawn = false
   gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   gui.Parent = UIROOT

   local main = Instance.new("Frame")
   main.Name = "Main"
   main.Size = UDim2.new(0, 860, 0, 540)
   main.Position = UDim2.new(0.5, -430, 0.5, -270)
   main.BackgroundColor3 = C.bg
   main.BorderSizePixel = 0
   main.ClipsDescendants = false
   main.Active = true
   main.Draggable = true
   main.Parent = gui
   corner(main, 12)
   stroke(main, Color3.fromRGB(99, 102, 241), 0.75)

   -- sombra DENTRO do main: anda junto, sem lag
   local shadow = Instance.new("ImageLabel")
   shadow.Name = "Shadow"
   shadow.Size = UDim2.new(1, 28, 1, 28)
   shadow.Position = UDim2.new(0, -14, 0, -14)
   shadow.BackgroundTransparency = 1
   shadow.Image = "rbxassetid://6014261993"
   shadow.ImageColor3 = Color3.new(0, 0, 0)
   shadow.ImageTransparency = 0.5
   shadow.ScaleType = Enum.ScaleType.Slice
   shadow.SliceCenter = Rect.new(49, 49, 450, 450)
   shadow.ZIndex = 0
   shadow.Parent = main

   local head = Instance.new("Frame")
   head.Size = UDim2.new(1, 0, 0, 44)
   head.BackgroundColor3 = Color3.fromRGB(30, 27, 75)
   head.BorderSizePixel = 0
   head.Parent = main
   grad(head, Color3.fromRGB(76, 29, 149), Color3.fromRGB(12, 74, 110), 0)
   local hRound = Instance.new("UICorner", head) hRound.CornerRadius = UDim.new(0, 12)
   local hFix = Instance.new("Frame")
   hFix.Size = UDim2.new(1, 0, 0, 12)
   hFix.Position = UDim2.new(0, 0, 1, -12)
   hFix.BackgroundColor3 = Color3.fromRGB(21, 42, 92)
   hFix.BorderSizePixel = 0
   hFix.Parent = head

   local title = Instance.new("TextLabel")
   title.Size = UDim2.new(1, -170, 1, 0)
   title.Position = UDim2.new(0, 14, 0, 0)
   title.BackgroundTransparency = 1
   title.Font = Enum.Font.GothamBlack
   title.TextSize = 17
   title.TextXAlignment = Enum.TextXAlignment.Left
   title.TextColor3 = Color3.new(1, 1, 1)
   title.Text = L("title")
   title.Parent = head

   local function hBtn(x, txt, col)
      local b = Instance.new("TextButton")
      b.Size = UDim2.new(0, 34, 0, 28)
      b.Position = UDim2.new(1, x, 0, 8)
      b.BackgroundColor3 = col or Color3.fromRGB(255, 255, 255)
      b.BackgroundTransparency = 0.85
      b.Font = Enum.Font.GothamBold
      b.TextSize = 14
      b.TextColor3 = Color3.new(1, 1, 1)
      b.Text = txt
      b.AutoButtonColor = true
      b.Parent = head
      corner(b, 7)
      return b
   end
   local langBtn = hBtn(-146, LANG)
   local minBtn = hBtn(-106, "_")
   local closeBtn = hBtn(-66, "X", C.red)
   closeBtn.BackgroundTransparency = 0.15

   local body = Instance.new("Frame")
   body.Name = "Body"
   body.Size = UDim2.new(1, -16, 1, -52)
   body.Position = UDim2.new(0, 8, 0, 48)
   body.BackgroundTransparency = 1
   body.Parent = main

   local left = Instance.new("Frame")
   left.Size = UDim2.new(0, 272, 1, 0)
   left.BackgroundColor3 = C.side
   left.BorderSizePixel = 0
   left.Parent = body
   corner(left, 10)
   stroke(left, nil, 0.9)

   local search = Instance.new("TextBox")
   search.Size = UDim2.new(1, -16, 0, 34)
   search.Position = UDim2.new(0, 8, 0, 8)
   search.BackgroundColor3 = C.btn
   search.Font = Enum.Font.Gotham
   search.TextSize = 13
   search.TextColor3 = C.txt
   search.PlaceholderColor3 = C.dim
   search.PlaceholderText = L("searchPh")
   search.Text = ""
   search.ClearTextOnFocus = false
   search.Parent = left
   corner(search, 8)
   stroke(search, C.accent, 0.7)

   local gCount = Instance.new("TextLabel")
   gCount.Size = UDim2.new(1, -16, 0, 20)
   gCount.Position = UDim2.new(0, 10, 0, 46)
   gCount.BackgroundTransparency = 1
   gCount.Font = Enum.Font.GothamBold
   gCount.TextSize = 12
   gCount.TextXAlignment = Enum.TextXAlignment.Left
   gCount.TextColor3 = C.accent2
   gCount.Parent = left

   local gScroll = Instance.new("ScrollingFrame")
   gScroll.Size = UDim2.new(1, -16, 1, -74)
   gScroll.Position = UDim2.new(0, 8, 0, 68)
   gScroll.BackgroundTransparency = 1
   gScroll.ScrollBarThickness = 4
   gScroll.ScrollBarImageColor3 = C.accent
   gScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
   gScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
   gScroll.Parent = left
   local gLay = Instance.new("UIListLayout", gScroll)
   gLay.Padding = UDim.new(0, 6)
   gLay.SortOrder = Enum.SortOrder.LayoutOrder

   local right = Instance.new("Frame")
   right.Size = UDim2.new(1, -288, 1, 0)
   right.Position = UDim2.new(0, 280, 0, 0)
   right.BackgroundColor3 = C.panel
   right.BorderSizePixel = 0
   right.Parent = body
   corner(right, 10)
   stroke(right, nil, 0.9)

   local rHead = Instance.new("TextLabel")
   rHead.Size = UDim2.new(1, -16, 0, 26)
   rHead.Position = UDim2.new(0, 10, 0, 8)
   rHead.BackgroundTransparency = 1
   rHead.Font = Enum.Font.GothamBlack
   rHead.TextSize = 16
   rHead.TextXAlignment = Enum.TextXAlignment.Left
   rHead.TextColor3 = C.txt
   rHead.TextTruncate = Enum.TextTruncate.AtEnd
   rHead.Text = L("scripts")
   rHead.Parent = right

   local rStatus = Instance.new("TextLabel")
   rStatus.Size = UDim2.new(1, -16, 0, 18)
   rStatus.Position = UDim2.new(0, 10, 0, 34)
   rStatus.BackgroundTransparency = 1
   rStatus.Font = Enum.Font.Gotham
   rStatus.TextSize = 12
   rStatus.TextXAlignment = Enum.TextXAlignment.Left
   rStatus.TextColor3 = C.accent2
   rStatus.Parent = right

   local sScroll = Instance.new("ScrollingFrame")
   sScroll.Size = UDim2.new(1, -16, 1, -206)
   sScroll.Position = UDim2.new(0, 8, 0, 56)
   sScroll.BackgroundTransparency = 1
   sScroll.ScrollBarThickness = 4
   sScroll.ScrollBarImageColor3 = C.accent
   sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
   sScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
   sScroll.Parent = right
   local sLay = Instance.new("UIListLayout", sScroll)
   sLay.Padding = UDim.new(0, 6)
   sLay.SortOrder = Enum.SortOrder.LayoutOrder

   -- linha de paginacao
   local prevBtn = Instance.new("TextButton")
   prevBtn.Size = UDim2.new(0, 44, 0, 26)
   prevBtn.Position = UDim2.new(0, 8, 1, -146)
   prevBtn.BackgroundColor3 = C.btn
   prevBtn.Font = Enum.Font.GothamBlack
   prevBtn.TextSize = 14
   prevBtn.TextColor3 = C.txt
   prevBtn.Text = L("prev")
   prevBtn.AutoButtonColor = true
   prevBtn.Parent = right
   corner(prevBtn, 6)

   local pageLbl = Instance.new("TextLabel")
   pageLbl.Size = UDim2.new(1, -112, 0, 26)
   pageLbl.Position = UDim2.new(0, 56, 1, -146)
   pageLbl.BackgroundTransparency = 1
   pageLbl.Font = Enum.Font.GothamBold
   pageLbl.TextSize = 12
   pageLbl.TextColor3 = C.dim
   pageLbl.Parent = right

   local nextBtn = Instance.new("TextButton")
   nextBtn.Size = UDim2.new(0, 44, 0, 26)
   nextBtn.Position = UDim2.new(1, -52, 1, -146)
   nextBtn.BackgroundColor3 = C.btn
   nextBtn.Font = Enum.Font.GothamBlack
   nextBtn.TextSize = 14
   nextBtn.TextColor3 = C.txt
   nextBtn.Text = L("next")
   nextBtn.AutoButtonColor = true
   nextBtn.Parent = right
   corner(nextBtn, 6)

   local detail = Instance.new("TextLabel")
   detail.Size = UDim2.new(1, -16, 0, 44)
   detail.Position = UDim2.new(0, 8, 1, -114)
   detail.BackgroundTransparency = 1
   detail.Font = Enum.Font.Gotham
   detail.TextSize = 12
   detail.TextXAlignment = Enum.TextXAlignment.Left
   detail.TextYAlignment = Enum.TextYAlignment.Top
   detail.TextColor3 = C.dim
   detail.TextWrapped = true
   detail.Text = L("sel")
   detail.Parent = right

   local execBtn = Instance.new("TextButton")
   execBtn.Size = UDim2.new(0.5, -12, 0, 36)
   execBtn.Position = UDim2.new(0, 8, 1, -44)
   execBtn.BackgroundColor3 = C.good
   execBtn.Font = Enum.Font.GothamBlack
   execBtn.TextSize = 14
   execBtn.TextColor3 = Color3.new(1, 1, 1)
   execBtn.Text = L("exec")
   execBtn.AutoButtonColor = true
   execBtn.Parent = right
   corner(execBtn, 8)
   grad(execBtn, C.good, C.good2, 0)

   local copyBtn = Instance.new("TextButton")
   copyBtn.Size = UDim2.new(0.5, -12, 0, 36)
   copyBtn.Position = UDim2.new(0.5, 4, 1, -44)
   copyBtn.BackgroundColor3 = C.accent
   copyBtn.Font = Enum.Font.GothamBlack
   copyBtn.TextSize = 14
   copyBtn.TextColor3 = Color3.new(1, 1, 1)
   copyBtn.Text = L("copy")
   copyBtn.AutoButtonColor = true
   copyBtn.Parent = right
   corner(copyBtn, 8)
   grad(copyBtn, C.accent, C.accent2, 0)

   local attr = Instance.new("TextLabel")
   attr.Size = UDim2.new(1, 0, 0, 14)
   attr.Position = UDim2.new(0, 0, 1, -14)
   attr.BackgroundTransparency = 1
   attr.Font = Enum.Font.Gotham
   attr.TextSize = 10
   attr.TextColor3 = C.dim
   attr.Text = L("attr")
   attr.Parent = main

   local floatGui = Instance.new("ScreenGui")
   floatGui.Name = "X1FloatBtn"
   floatGui.ResetOnSpawn = false
   floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   floatGui.Enabled = false
   floatGui.Parent = UIROOT

   local float = Instance.new("TextButton")
   float.Size = UDim2.new(0, 58, 0, 58)
   float.Position = UDim2.new(0, 24, 0.5, -29)
   float.BackgroundColor3 = Color3.fromRGB(30, 27, 75)
   float.Font = Enum.Font.GothamBlack
   float.TextSize = 18
   float.TextColor3 = Color3.new(1, 1, 1)
   float.Text = "X1"
   float.Active = true
   float.Draggable = true
   float.Parent = floatGui
   corner(float, 29)
   stroke(float, C.accent2, 0.4)
   grad(float, Color3.fromRGB(76, 29, 149), Color3.fromRGB(12, 74, 110), 45)

   local LoadingDots = false
   local function dots(base)
      LoadingDots = true
      local tk = myBuild
      task.spawn(function()
         local n = 0
         while LoadingDots and gui.Parent and tk == CACHE.builds do
            n = (n % 3) + 1
            pcall(function() rStatus.Text = base .. string.rep(".", n) end)
            task.wait(0.35)
         end
      end)
   end

   local function hoverFx(b, base)
      b.MouseEnter:Connect(function() tw(b, 0.15, {BackgroundColor3 = C.btnh}) end)
      b.MouseLeave:Connect(function()
         if not (SelGame and b:GetAttribute("pid") == SelGame.placeId) then
            tw(b, 0.2, {BackgroundColor3 = base})
         end
      end)
   end
   local function clearScroll(sc)
      for _, v in pairs(sc:GetChildren()) do
         if v:IsA("TextButton") then v:Destroy() end
      end
   end

   local selectGame -- fwd
   local lastRender = 0
   local function gameBtn(g, i)
      local b = Instance.new("TextButton")
      b.Size = UDim2.new(1, -4, 0, 54)
      b.BackgroundColor3 = (SelGame and SelGame.placeId == g.placeId) and C.btnh or C.btn
      b.Text = ""
      b.AutoButtonColor = false
      b.LayoutOrder = i
      b:SetAttribute("pid", g.placeId)
      b.Parent = gScroll
      corner(b, 8)
      if SelGame and SelGame.placeId == g.placeId then stroke(b, C.accent2, 0.3) end
      hoverFx(b, C.btn)

      local rank = Instance.new("TextLabel")
      rank.Size = UDim2.new(0, 30, 0, 30)
      rank.Position = UDim2.new(0, 7, 0, 12)
      rank.BackgroundColor3 = (i <= 3) and C.accent or C.btnh
      rank.Font = Enum.Font.GothamBlack
      rank.TextSize = 13
      rank.TextColor3 = Color3.new(1, 1, 1)
      rank.Text = tostring(i)
      rank.Parent = b
      corner(rank, 15)

      local t = Instance.new("TextLabel")
      t.Size = UDim2.new(1, -52, 0, 22)
      t.Position = UDim2.new(0, 44, 0, 5)
      t.BackgroundTransparency = 1
      t.Font = Enum.Font.GothamBold
      t.TextSize = 13
      t.TextXAlignment = Enum.TextXAlignment.Left
      t.TextColor3 = C.txt
      t.TextTruncate = Enum.TextTruncate.AtEnd
      t.Text = g.name
      t.Parent = b

      local s = Instance.new("TextLabel")
      s.Size = UDim2.new(1, -52, 0, 15)
      s.Position = UDim2.new(0, 44, 1, -19)
      s.BackgroundTransparency = 1
      s.Font = Enum.Font.Gotham
      s.TextSize = 11
      s.TextXAlignment = Enum.TextXAlignment.Left
      s.TextColor3 = (i <= 3) and C.accent2 or C.dim
      s.Text = g.placeId == -1 and L("hub") or ((g.n and (g.n .. " scripts | ") or "") .. fmt(g.views or 0) .. " " .. L("views"))
      s.Parent = b
      b.MouseButton1Click:Connect(function() selectGame(g, 1) end)
      return b
   end

   local function renderGames()
      if not gui.Parent or myBuild ~= CACHE.builds then return end
      clearScroll(gScroll)
      table.sort(CACHE.games, function(a, b) return (a.views or 0) > (b.views or 0) end)
      local shown = 0
      for _, g in ipairs(CACHE.games) do
         if g.placeId == -1 or (g.views or 0) >= MIN_VIEWS then
            shown = shown + 1
            gameBtn(g, shown)
         end
      end
      if shown == 0 then
         local l = Instance.new("TextLabel")
         l.Size = UDim2.new(1, -4, 0, 40)
         l.BackgroundTransparency = 1
         l.Font = Enum.Font.Gotham
         l.TextSize = 12
         l.TextColor3 = C.dim
         l.TextWrapped = true
         l.Text = L("noGame")
         l.Parent = gScroll
      end
      gCount.Text = L("games") .. ": " .. shown .. "  (all)"
   end
   local function requestRender(force)
      if force or (tick() - lastRender > 1.5) then
         lastRender = tick()
         renderGames()
      end
   end

   local function scriptBtn(s, i)
      local b = Instance.new("TextButton")
      b.Size = UDim2.new(1, -4, 0, 54)
      b.BackgroundColor3 = C.btn
      b.Text = ""
      b.AutoButtonColor = false
      b.LayoutOrder = i
      b.Parent = sScroll
      corner(b, 8)
      hoverFx(b, C.btn)

      local tags = {}
      if s.verified then table.insert(tags, "v") end
      table.insert(tags, s.key and L("keyY") or L("keyN"))
      if s.isPatched then table.insert(tags, L("patched")) end

      local medal = (i == 1 and " 1st") or (i == 2 and " 2nd") or (i == 3 and " 3rd") or (" #" .. i)
      local ttl = tostring(s.title or "?")
      if #ttl > 50 then ttl = ttl:sub(1, 50) .. "..." end

      local t1 = Instance.new("TextLabel")
      t1.Size = UDim2.new(1, -12, 0, 22)
      t1.Position = UDim2.new(0, 8, 0, 4)
      t1.BackgroundTransparency = 1
      t1.Font = Enum.Font.GothamBold
      t1.TextSize = 12
      t1.TextXAlignment = Enum.TextXAlignment.Left
      t1.TextColor3 = (i <= 3) and Color3.new(1, 1, 1) or C.txt
      t1.TextTruncate = Enum.TextTruncate.AtEnd
      t1.Text = medal .. "  " .. ttl
      t1.Parent = b

      local t2 = Instance.new("TextLabel")
      t2.Size = UDim2.new(1, -12, 0, 15)
      t2.Position = UDim2.new(0, 8, 1, -18)
      t2.BackgroundTransparency = 1
      t2.Font = Enum.Font.Gotham
      t2.TextSize = 11
      t2.TextXAlignment = Enum.TextXAlignment.Left
      t2.TextColor3 = (i <= 3) and C.accent2 or C.dim
      t2.Text = fmt(s.views) .. " " .. L("views") .. (s.likeCount and (" | " .. fmt(s.likeCount) .. " " .. L("likes")) or "") .. " | " .. table.concat(tags, " | ")
      t2.Parent = b
      return b, table.concat(tags, " | ")
   end

   local function rec()
      if not SelGame then return nil end
      local r = CACHE.scripts[SelGame.placeId]
      if not r then
         r = {pages = {}, total = 1, page = 1}
         CACHE.scripts[SelGame.placeId] = r
      end
      return r
   end

   local function renderScripts()
      if not gui.Parent or myBuild ~= CACHE.builds then return end
      clearScroll(sScroll)
      SelScript = nil
      if not SelGame then
         pageLbl.Text = ""
         detail.Text = L("sel")
         return
      end
      local r = rec()
      local list = (r and r.pages[r.page]) or {}
      local startIdx = (r.page - 1) * PAGE_SIZE
      for i, s in ipairs(list) do
         local b, tags = scriptBtn(s, startIdx + i)
         b.MouseButton1Click:Connect(function()
            SelScript = s
            local g = (s.game and s.game.name) or ""
            detail.Text = tostring(s.title) .. "\n" .. g .. " | " .. fmt(s.views) .. " " .. L("views") .. " | " .. tags
         end)
      end
      pageLbl.Text = L("page") .. " " .. r.page .. "/" .. math.max(r.total, 1)
      detail.Text = (#list == 0) and L("noScript") or L("pickScript")
   end

   local function showPage(p)
      local g = SelGame
      if not g or not gui.Parent or myBuild ~= CACHE.builds then return end
      local r = rec()
      if p == "next" then p = r.page + 1 elseif p == "prev" then p = r.page - 1 end
      p = math.max(1, p)
      if r.total and p > r.total then p = r.total end
      r.page = p
      if r.pages[p] then renderScripts() return end
      dots(L("loading") .. " " .. L("page") .. " " .. p)
      task.spawn(function()
         local url = (g.placeId == -1)
            and ("/api/script/fetch?universal=1&sortBy=views&order=desc&max=" .. PAGE_SIZE .. "&page=" .. p)
            or ("/api/script/fetch?placeId=" .. tostring(g.placeId) .. "&sortBy=views&order=desc&max=" .. PAGE_SIZE .. "&page=" .. p)
         local data = apiGet(url)
         if SelGame ~= g or not gui.Parent or myBuild ~= CACHE.builds then LoadingDots = false return end
         LoadingDots = false
         if data and data.result and data.result.scripts then
            r.pages[p] = data.result.scripts
            r.total = tonumber(data.result.totalPages) or 1
            local v, n = 0, 0
            for _, pg in pairs(r.pages) do for _, s in ipairs(pg) do v = v + (tonumber(s.views) or 0) n = n + 1 end end
            g.views = math.max(g.views or 0, v)
            if n > 0 and not g.n then g.n = "~" .. n end
            renderScripts()
         else
            rStatus.Text = ""
            renderScripts()
         end
      end)
   end

   selectGame = function(g, page)
      SelGame = g
      CACHE.selPid = g.placeId
      renderGames()
      rHead.Text = g.name
      local r = rec()
      r.page = page or 1
      showPage(r.page)
   end

   local function addGame(name, placeId, views, n)
      for _, g in ipairs(CACHE.games) do if g.placeId == placeId then
         g.views = math.max(g.views or 0, views or 0)
         if n then g.n = n end
         return g
      end end
      local g = {name = name, placeId = placeId, views = views or 0, n = n}
      table.insert(CACHE.games, g)
      return g
   end

   local function loadTopGames()
      if #CACHE.games > 0 then
         renderGames()
         detail.Text = L("sel")
         if not CACHE.autoLoaded then
            CACHE.autoLoaded = true
            for _, g in ipairs(CACHE.games) do
               if g.placeId == game.PlaceId then selectGame(g, 1) break end
            end
         elseif CACHE.selPid then
            for _, g in ipairs(CACHE.games) do
               if g.placeId == CACHE.selPid then SelGame = g renderGames() renderScripts() break end
            end
         end
      end
      if CACHE.searchMode then return end
      if (CACHE.scanPage or 0) >= SCAN_PAGES and CACHE.curatedDone then
         LoadingDots = false
         return
      end
      dots(L("loading") .. " " .. L("games"))
      task.spawn(function()
         local function alive() return gui.Parent and myBuild == CACHE.builds end
         for page = (CACHE.scanPage or 0) + 1, SCAN_PAGES do
            if not alive() or CACHE.searchMode then LoadingDots = false return end
            local data = apiGet("/api/script/fetch?sortBy=views&order=desc&max=20&page=" .. page)
            if not data or not data.result or not data.result.scripts then break end
            CACHE.scanPage = page
            local seen = {}
            for _, s in ipairs(data.result.scripts) do
               local gm = s.game
               if gm and tonumber(gm.gameId) and tonumber(gm.gameId) > 0 then
                  local gname = tostring(gm.name or "")
                  local low = gname:lower()
                  -- fora hubs genericos (categoria propria "Universal / Hubs")
                  if low ~= "" and low ~= "script hub" and not low:find("universal script") then
                     local pid = tonumber(gm.gameId)
                     seen[pid] = seen[pid] or {name = (gname ~= "" and gname or tostring(pid)), views = 0}
                     if #gname > #seen[pid].name then seen[pid].name = gname end
                     seen[pid].views = seen[pid].views + (tonumber(s.views) or 0)
                  end
               end
            end
            for pid, gg in pairs(seen) do addGame(gg.name, pid, gg.views, nil) end
            if alive() then requestRender() end
         end
         if not CACHE.curatedDone then
            CACHE.curatedDone = true
            for _, c in ipairs(CURATED) do
               if not alive() or CACHE.searchMode then LoadingDots = false return end
               local g = addGame(c[1], c[2], 0, nil)
               task.spawn(function()
                  local url = (c[2] == -1)
                     and "/api/script/fetch?universal=1&max=20&page=1"
                     or ("/api/script/fetch?placeId=" .. tostring(c[2]) .. "&sortBy=views&order=desc&max=20&page=1")
                  local data = apiGet(url)
                  if data and data.result and data.result.scripts and alive() and #data.result.scripts > 0 then
                     local v = 0
                     for _, s in ipairs(data.result.scripts) do v = v + (tonumber(s.views) or 0) end
                     -- NUNCA renomeia: a API devolve game.name generico ("Script hub")
                     -- em scripts arquivados sob placeId real; nosso nome curado esta certo
                     g.views = v
                     requestRender()
                  end
               end)
            end
         end
         local curName = L("thisGame")
         pcall(function() curName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
         local g = addGame(tostring(curName), game.PlaceId, 0, nil)
         g.views = (g.views or 0) + 999999999
         if alive() then
            LoadingDots = false
            requestRender(true)
            detail.Text = L("sel")
            rStatus.Text = ""
            if not CACHE.autoLoaded then
               CACHE.autoLoaded = true
               selectGame(g, 1)
            end
         else
            LoadingDots = false
         end
      end)
   end

   search.FocusLost:Connect(function()
      local q = search.Text:gsub("^%s+", ""):gsub("%s+$", "")
      if q == "" then
         if CACHE.searchMode then
            CACHE.games = CACHE.fullBackup or {}
            CACHE.fullBackup = nil
            CACHE.searchMode = nil
         end
         SelGame = nil
         CACHE.selPid = nil
         loadTopGames()
         return
      end
      dots(L("loading"))
      task.spawn(function()
         local data = apiGet("/api/script/search?q=" .. urlEncode(q) .. "&strict=false&max=20&page=1")
         local fresh = {}
         if data and data.result and data.result.scripts then
            local seen = {}
            for _, s in ipairs(data.result.scripts) do
               local gm = s.game
               if gm and tonumber(gm.gameId) and tonumber(gm.gameId) > 0 then
                  local gname = tostring(gm.name or "")
                  local low = gname:lower()
                  if low ~= "" and low ~= "script hub" and not low:find("universal script") then
                     local pid = tonumber(gm.gameId)
                     seen[pid] = seen[pid] or {name = gname, views = 0}
                     seen[pid].views = seen[pid].views + (tonumber(s.views) or 0)
                  end
               end
            end
            for pid, gg in pairs(seen) do table.insert(fresh, {name = gg.name, placeId = pid, views = gg.views}) end
         end
         if gui.Parent and myBuild == CACHE.builds then
            if not CACHE.searchMode then
               CACHE.fullBackup = CACHE.games
               CACHE.searchMode = true
            end
            CACHE.games = fresh
            SelGame = nil
            CACHE.selPid = nil
            LoadingDots = false
            renderGames()
         end
      end)
   end)

   execBtn.MouseButton1Click:Connect(function()
      if not SelScript then return end
      local s = SelScript
      local src = nil
      if s.slug then
         local ok, raw = pcall(function() return game:HttpGet("https://scriptblox.com/raw/" .. tostring(s.slug)) end)
         if ok and raw and #raw > 0 then src = raw end
      end
      if not src and s.script and #s.script > 0 then src = s.script end
      if not src then detail.Text = "HTTP fail (F9)" return end
      local fn, err = loadstring(src)
      if not fn then detail.Text = "load fail (F9)" print("[X1-GH] " .. tostring(err)) return end
      local ok, rerr = pcall(fn)
      if not ok then print("[X1-GH] " .. tostring(rerr)) end
   end)

   copyBtn.MouseButton1Click:Connect(function()
      if SelScript and SelScript.slug then
         pcall(function() setclipboard("loadstring(game:HttpGet(\"https://scriptblox.com/raw/" .. SelScript.slug .. "\"))()") end)
      end
   end)

   langBtn.MouseButton1Click:Connect(function()
      LANG = (LANG == "EN") and "PT" or "EN"
      langBtn.Text = LANG
      title.Text = L("title")
      search.PlaceholderText = L("searchPh")
      execBtn.Text = L("exec")
      copyBtn.Text = L("copy")
      prevBtn.Text = L("prev")
      nextBtn.Text = L("next")
      attr.Text = L("attr")
      renderGames()
      renderScripts()
      if not SelGame then rHead.Text = L("scripts") detail.Text = L("sel") end
   end)

   prevBtn.MouseButton1Click:Connect(function()
      if SelGame then showPage("prev") end
   end)
   nextBtn.MouseButton1Click:Connect(function()
      if SelGame then showPage("next") end
   end)

   local function setMinimized(mini, instant)
      CACHE.minimized = mini
      if mini then
         local function hide()
            if gui.Parent then main.Visible = false floatGui.Enabled = true end
         end
         if instant then hide()
         else
            tw(main, 0.22, {Size = UDim2.new(0, 860, 0, 44), Position = UDim2.new(0.5, -430, 0.5, -22)})
            task.delay(0.24, hide)
         end
      else
         floatGui.Enabled = false
         main.Visible = true
         tw(main, 0.28, {Size = UDim2.new(0, 860, 0, 540), Position = UDim2.new(0.5, -430, 0.5, -270)}, Enum.EasingStyle.Back)
      end
   end

   minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
   closeBtn.MouseButton1Click:Connect(function()
      tw(main, 0.2, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
      task.delay(0.21, function() pcall(function() gui:Destroy() floatGui:Destroy() end) end)
   end)
   float.MouseButton1Click:Connect(function() setMinimized(false) end)

   -- CTRL / RightShift abre e fecha (ignora quando digitando)
   UIS.InputBegan:Connect(function(inp, gpe)
      if gpe then return end
      local kc = inp.KeyCode
      if kc == Enum.KeyCode.LeftControl or kc == Enum.KeyCode.RightControl or kc == Enum.KeyCode.RightShift then
         if UIS:GetFocusedTextBox() then return end
         if not gui.Parent then return end
         setMinimized(main.Visible)
      end
   end)

   loadTopGames()
   if CACHE.minimized == false then
      setMinimized(false, true)
   else
      setMinimized(true, true)
   end
   return gui
end

buildUI(CACHE.minimized ~= false)
print("[X1-GH] games hub v4 loaded (build #" .. CACHE.builds .. ", cached games: " .. #CACHE.games .. ")")

task.spawn(function()
   local heals = 0
   while heals < 25 do
      task.wait(6)
      if not findHub() then
         heals = heals + 1
         print("[X1-GH] janela ausente, reconstruindo (" .. heals .. ") com cache")
         local ok, err = pcall(function() buildUI(true) end)
         if not ok then print("[X1-GH] rebuild falhou: " .. tostring(err)) break end
      end
   end
end)
