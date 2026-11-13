-- One column per physical key, in QWERTY order, then the character that
-- keyboard sends. Colemak-DH here is the matrix layout: Z X C stay put.
-- Add a layout by appending one string to every row, in this same order.
-- Top, home, bottom, then ' - = [ ]
local ORDER = { "qwerty", "colemak_dh", "colemak", "dvorak" }

local LETTERS = {
	qwerty = {
		"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
		"A", "S", "D", "F", "G", "H", "J", "K", "L", ";",
		"Z", "X", "C", "V", "B", "N", "M", ",", ".", "/",
		"'", "-", "=", "[", "]",
	},
	colemak_dh = {
		"Q", "W", "F", "P", "B", "J", "L", "U", "Y", ";",
		"A", "R", "S", "T", "G", "M", "N", "E", "I", "O",
		"Z", "X", "C", "D", "V", "K", "H", ",", ".", "/",
		"'", "-", "=", "[", "]",
	},
	colemak = {
		"Q", "W", "F", "P", "G", "J", "L", "U", "Y", ";",
		"A", "R", "S", "T", "D", "H", "N", "E", "I", "O",
		"Z", "X", "C", "V", "B", "K", "M", ",", ".", "/",
		"'", "-", "=", "[", "]",
	},
	dvorak = {
		"'", ",", ".", "P", "Y", "F", "G", "C", "R", "L",
		"A", "O", "E", "U", "I", "D", "H", "T", "N", "S",
		";", "Q", "J", "K", "X", "B", "M", "W", "V", "Z",
		"-", "[", "]", "/", "=",
	},
}

local INDEX = {}
local width
for orderIndex = 1, #ORDER do
	local id = ORDER[orderIndex]
	local row = LETTERS[id]
	if not width then
		width = #row
	elseif #row ~= width then
		error("KeyboardLayoutSwapper: " .. id .. " does not match the QWERTY key count")
	end
	INDEX[id] = {}
	for pos = 1, #row do
		local letter = row[pos]
		if INDEX[id][letter] then
			error("KeyboardLayoutSwapper: " .. id .. " uses " .. letter .. " twice")
		end
		INDEX[id][letter] = pos
	end
end

-- ESDF on QWERTY: E forward, S left, D back, F right.
local MOVE = {
	forward = INDEX.qwerty.E,
	left = INDEX.qwerty.S,
	back = INDEX.qwerty.D,
	right = INDEX.qwerty.F,
}

local MARKER_KEY = "CTRL-ALT-SHIFT-F12"
local COMMAND_FOR = {
	qwerty = "KEYBOARDLAYOUTSWAPPER_QWERTY",
	colemak_dh = "KEYBOARDLAYOUTSWAPPER_COLEMAK_DH",
	colemak = "KEYBOARDLAYOUTSWAPPER_COLEMAK",
	dvorak = "KEYBOARDLAYOUTSWAPPER_DVORAK",
}
-- colemak and c stay Colemak-DH so the old /kls colemak command does not
-- jump to classic Colemak. Classic Colemak is colemak-classic.
local ALIAS = {
	q = "qwerty",
	qwerty = "qwerty",
	dh = "colemak_dh",
	["colemak-dh"] = "colemak_dh",
	colemakdh = "colemak_dh",
	c = "colemak_dh",
	colemak = "colemak_dh",
	["colemak-classic"] = "colemak",
	dv = "dvorak",
	dvorak = "dvorak",
}
local MARKER_OF = {
	KEYBOARDLAYOUTSWAPPER_QWERTY = "qwerty",
	KEYBOARDLAYOUTSWAPPER_COLEMAK_DH = "colemak_dh",
	KEYBOARDLAYOUTSWAPPER_COLEMAK = "colemak",
	KEYBOARDLAYOUTSWAPPER_DVORAK = "dvorak",
	LAYOUTBINDS_QWERTY = "qwerty",
	LAYOUTBINDS_COLEMAK_DH = "colemak_dh",
	LAYOUTBINDS_COLEMAK = "colemak",
	LAYOUTBINDS_DVORAK = "dvorak",
	LAYOUTSWAP_QWERTY = "qwerty",
	LAYOUTSWAP_COLEMAK = "colemak_dh",
}
local LABEL = {
	qwerty = "QWERTY",
	colemak_dh = "Colemak-DH",
	colemak = "Colemak",
	dvorak = "Dvorak",
}
local TOKEN = {
	qwerty = "qwerty",
	colemak_dh = "colemak-dh",
	colemak = "colemak-classic",
	dvorak = "dvorak",
}
local LETTER = {
	qwerty = "Q",
	colemak_dh = "DH",
	colemak = "C",
	dvorak = "Dv",
}
local COLOR = {
	qwerty = { 1, 0.86, 0.4 },
	colemak_dh = { 0.35, 0.9, 0.75 },
	colemak = { 0.45, 0.75, 1 },
	dvorak = { 0.95, 0.55, 0.85 },
}
local MODIFIERS = { "ALT-", "CTRL-", "SHIFT-", "META-" }
local DEFAULT_USE = { "qwerty", "colemak_dh" }

BINDING_HEADER_KEYBOARDLAYOUTSWAPPER = "KeyboardLayoutSwapper"
BINDING_NAME_KEYBOARDLAYOUTSWAPPER_QWERTY = "Layout marker (QWERTY)"
BINDING_NAME_KEYBOARDLAYOUTSWAPPER_COLEMAK_DH = "Layout marker (Colemak-DH)"
BINDING_NAME_KEYBOARDLAYOUTSWAPPER_COLEMAK = "Layout marker (Colemak)"
BINDING_NAME_KEYBOARDLAYOUTSWAPPER_DVORAK = "Layout marker (Dvorak)"

KeyboardLayoutSwapperDB = KeyboardLayoutSwapperDB or {}
local db = KeyboardLayoutSwapperDB

local button
local reconcileTries = 0

local MINIMAP_SHAPES = {
	ROUND = { true, true, true, true },
	SQUARE = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function Say(message)
	print("|cff7ec8ffKeyboardLayoutSwapper|r: " .. message)
end

local function Resolve(name)
	if type(name) ~= "string" then
		return nil
	end
	return ALIAS[name:lower()]
end

local function Contains(list, value)
	for i = 1, #list do
		if list[i] == value then
			return true
		end
	end
	return false
end

local function UseIsValid(list)
	if type(list) ~= "table" or #list < 2 then
		return false
	end
	local seen = {}
	for i = 1, #list do
		local id = list[i]
		if not LETTERS[id] or seen[id] then
			return false
		end
		seen[id] = true
	end
	return true
end

local function CycleText()
	local parts = {}
	for i = 1, #db.use do
		parts[i] = LABEL[db.use[i]]
	end
	return table.concat(parts, ", ")
end

local function LayoutHelp()
	local parts = {}
	for i = 1, #ORDER do
		local id = ORDER[i]
		parts[i] = LABEL[id] .. " (" .. TOKEN[id] .. ")"
	end
	return table.concat(parts, ", ")
end

local function NormalizeDB()
	KeyboardLayoutSwapperDB = KeyboardLayoutSwapperDB or {}
	db = KeyboardLayoutSwapperDB
	if not db.tookLayoutBindsSettings and type(LayoutBindsDB) == "table" then
		for k, v in pairs(LayoutBindsDB) do
			if db[k] == nil then
				db[k] = v
			end
		end
		db.tookLayoutBindsSettings = true
	end
	if not db.tookSwapSettings and type(LayoutSwapDB) == "table" then
		if type(db.minimapPos) ~= "number" and type(LayoutSwapDB.minimapPos) == "number" then
			db.minimapPos = LayoutSwapDB.minimapPos
		end
		if db.auto == nil and LayoutSwapDB.auto then
			local prefer = LayoutSwapDB.prefer
			if prefer == "colemak" then
				prefer = "colemak_dh"
			end
			prefer = LETTERS[prefer] and prefer or Resolve(prefer)
			if prefer then
				db.auto = true
				db.prefer = prefer
			end
		end
		if not LETTERS[db.layout] and LayoutSwapDB.layout then
			local layout = LayoutSwapDB.layout == "colemak" and "colemak_dh" or LayoutSwapDB.layout
			if LETTERS[layout] then
				db.layout = layout
			end
		end
		db.tookSwapSettings = true
	end
	if not UseIsValid(db.use) then
		db.use = { DEFAULT_USE[1], DEFAULT_USE[2] }
	end
	if db.layout and not LETTERS[db.layout] then
		db.layout = Resolve(db.layout)
	end
	if db.prefer and not LETTERS[db.prefer] then
		db.prefer = Resolve(db.prefer)
		if not db.prefer then
			db.auto = false
		end
	end
end

local function IsCategory(value)
	return type(value) == "string" and (value:find("^BINDING_") ~= nil or value:find("%l") ~= nil or value:find(" ") ~= nil)
end

local function IsKeyName(value)
	return type(value) == "string" and value ~= "" and not IsCategory(value)
end

local function SplitKey(key)
	local prefixes = {}
	local rest = key
	local found = true
	while found and rest ~= "" do
		found = false
		for i = 1, #MODIFIERS do
			local prefix = MODIFIERS[i]
			if rest:sub(1, #prefix) == prefix then
				prefixes[#prefixes + 1] = prefix
				rest = rest:sub(#prefix + 1)
				found = true
				break
			end
		end
	end
	return table.concat(prefixes), rest
end

local function TranslateKey(key, fromId, toId)
	local prefixes, base = SplitKey(key)
	local pos = INDEX[fromId][base]
	if not pos then
		return key
	end
	local moved = LETTERS[toId][pos]
	if not moved or moved == base then
		return key
	end
	return prefixes .. moved
end

local function Capture()
	local byKey = {}
	local total = GetNumBindings()
	for index = 1, total do
		local command, first, second, third = GetBinding(index)
		if command and command ~= "" then
			local key1, key2
			if IsCategory(first) then
				key1, key2 = second, third
			else
				key1, key2 = first, second
			end
			if IsKeyName(key1) then
				byKey[key1] = command
			end
			if IsKeyName(key2) then
				byKey[key2] = command
			end
		end
	end
	return byKey
end

local function Signature(byKey)
	local keys = {}
	for key in pairs(byKey) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local parts = {}
	for i = 1, #keys do
		parts[i] = keys[i] .. "=" .. byKey[keys[i]]
	end
	return table.concat(parts, "\n")
end

local function DetectLayout()
	local action = GetBindingAction and GetBindingAction(MARKER_KEY)
	if MARKER_OF[action] then
		return MARKER_OF[action]
	end
	local found
	for command, id in pairs(MARKER_OF) do
		if GetBindingKey(command) then
			if found and found ~= id then
				return nil
			end
			found = id
		end
	end
	return found
end

local function UnbindKeys(keySet)
	for key in pairs(keySet) do
		SetBinding(key)
	end
end

local function WriteBindings(byKey)
	for key, command in pairs(byKey) do
		if not SetBinding(key, command) then
			return false, key, command
		end
	end
	return true
end

local function KeyForCommand(byKey, command)
	local modified
	for key, bound in pairs(byKey) do
		if bound == command then
			local _, base = SplitKey(key)
			if key == base then
				return base
			end
			modified = base
		end
	end
	return modified
end

local function MovementMatches(byKey)
	local forward = KeyForCommand(byKey, "MOVEFORWARD")
	local back = KeyForCommand(byKey, "MOVEBACKWARD")
	local left = KeyForCommand(byKey, "STRAFELEFT")
	local right = KeyForCommand(byKey, "STRAFERIGHT")
	local matches = {}
	if not forward or not back or not left or not right then
		return matches
	end
	for i = 1, #ORDER do
		local id = ORDER[i]
		local row = LETTERS[id]
		if forward == row[MOVE.forward] and left == row[MOVE.left] and back == row[MOVE.back] and right == row[MOVE.right] then
			matches[#matches + 1] = id
		end
	end
	return matches
end

local function MovementLine(byKey)
	return "Forward "
		.. (KeyForCommand(byKey, "MOVEFORWARD") or "-")
		.. ", Back "
		.. (KeyForCommand(byKey, "MOVEBACKWARD") or "-")
		.. ", Left "
		.. (KeyForCommand(byKey, "STRAFELEFT") or "-")
		.. ", Right "
		.. (KeyForCommand(byKey, "STRAFERIGHT") or "-")
end

local function ChooseLayout(matches, marked)
	if #matches == 1 then
		return matches[1]
	end
	if #matches > 1 then
		if marked and Contains(matches, marked) then
			return marked
		end
		local preferred = {}
		for i = 1, #db.use do
			if Contains(matches, db.use[i]) then
				preferred[#preferred + 1] = db.use[i]
			end
		end
		if #preferred >= 1 then
			if db.layout and Contains(preferred, db.layout) then
				return db.layout
			end
			return preferred[1]
		end
		if db.layout and Contains(matches, db.layout) then
			return db.layout
		end
		return matches[1]
	end
	if marked and LETTERS[marked] then
		return marked
	end
	if db.layout and LETTERS[db.layout] then
		return db.layout
	end
	return nil
end

local function CurrentLayout()
	local captured = Capture()
	return ChooseLayout(MovementMatches(captured), DetectLayout())
end

local function NextInCycle(current)
	for i = 1, #db.use do
		if db.use[i] == current then
			return db.use[(i % #db.use) + 1]
		end
	end
	return db.use[1]
end

local function StampHint()
	local parts = {}
	local seenRight = {}
	local ambiguous = false
	for i = 1, #db.use do
		local id = db.use[i]
		local right = LETTERS[id][MOVE.right]
		parts[#parts + 1] = LABEL[id] .. " if Strafe Right is " .. right
		if seenRight[right] then
			ambiguous = true
		end
		seenRight[right] = true
	end
	local hint = "I can't tell which keyboard these keys are for. " .. table.concat(parts, ". ") .. "."
	if ambiguous then
		hint = hint .. " Those share Strafe Right, so name the layout: /kls stamp " .. TOKEN[db.use[1]]
	end
	return hint
end

local function UpdateButton()
	if not button then
		return
	end
	local layout = CurrentLayout()
	local text = LETTER[layout] or "?"
	local font, _, flags = GameFontNormal:GetFont()
	button.label:SetFont(font, #text > 1 and 10 or 13, flags or "OUTLINE")
	button.label:SetText(text)
	local color = COLOR[layout] or { 1, 1, 1 }
	button.label:SetTextColor(color[1], color[2], color[3])
end

local function UpdatePosition(position)
	if not button or not Minimap then
		return
	end
	local angle = math.rad(position or 225)
	local x, y = math.cos(angle), math.sin(angle)
	local quadrant = 1
	if x < 0 then
		quadrant = quadrant + 1
	end
	if y > 0 then
		quadrant = quadrant + 2
	end
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local quad = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES.ROUND
	local mapWidth = (Minimap:GetWidth() / 2) + 5
	local mapHeight = (Minimap:GetHeight() / 2) + 5
	if quad[quadrant] then
		x, y = x * mapWidth, y * mapHeight
	else
		local diagW = math.sqrt(2 * mapWidth * mapWidth) - 10
		local diagH = math.sqrt(2 * mapHeight * mapHeight) - 10
		x = math.max(-mapWidth, math.min(x * diagW, mapWidth))
		y = math.max(-mapHeight, math.min(y * diagH, mapHeight))
	end
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function Restamp(target)
	local command = COMMAND_FOR[target]
	if not command or GetBindingAction(MARKER_KEY) == command or InCombatLockdown() then
		return false
	end
	if not SetBinding(MARKER_KEY, command) then
		return false
	end
	local which = GetCurrentBindingSet()
	if which ~= 1 and which ~= 2 then
		return false
	end
	SaveBindings(which)
	return true
end

local function Apply(target)
	NormalizeDB()
	if not LETTERS[target] then
		Say("Unknown layout. " .. LayoutHelp() .. ".")
		return false
	end
	if InCombatLockdown() then
		Say("Cannot swap in combat.")
		return false
	end

	local current = Capture()
	local bound = 0
	for _ in pairs(current) do
		bound = bound + 1
	end
	if bound < 8 then
		Say("Keybinds are not loaded yet.")
		return false
	end

	local source = ChooseLayout(MovementMatches(current), DetectLayout())
	if not source then
		Say(StampHint())
		return false
	end

	if source == target then
		Restamp(target)
		Say("Already " .. LABEL[target] .. ". " .. MovementLine(current))
		db.layout = target
		db.signature = Signature(Capture())
		UpdateButton()
		return true
	end

	local nextBindings = {}
	local clear = {}
	for key, command in pairs(current) do
		if MARKER_OF[command] then
			clear[key] = true
		else
			local newKey = TranslateKey(key, source, target)
			if newKey ~= key then
				if nextBindings[newKey] and nextBindings[newKey] ~= command then
					Say("Stopped. " .. newKey .. " would be used by two actions.")
					return false
				end
				clear[key] = true
				clear[newKey] = true
				nextBindings[newKey] = command
			end
		end
	end
	clear[MARKER_KEY] = true
	nextBindings[MARKER_KEY] = COMMAND_FOR[target]

	local function Restore()
		UnbindKeys(clear)
		WriteBindings(current)
	end

	UnbindKeys(clear)
	local ok, badKey, badCommand = WriteBindings(nextBindings)
	if not ok then
		Restore()
		Say("Did not change binds. The game rejected " .. tostring(badKey) .. " for " .. tostring(badCommand) .. ".")
		return false
	end

	local which = GetCurrentBindingSet()
	if which ~= 1 and which ~= 2 then
		Restore()
		Say("Did not save, so the swap was reverted.")
		return false
	end
	SaveBindings(which)

	local written = Capture()
	db.layout = target
	db.signature = Signature(written)
	UpdateButton()
	Say(LABEL[target] .. ". " .. MovementLine(written))
	return true
end

local function Toggle()
	NormalizeDB()
	local layout = CurrentLayout()
	if not layout then
		Say(StampHint())
		return
	end
	Apply(NextInCycle(layout))
end

local function EnsureButton()
	NormalizeDB()
	if button or not Minimap then
		return
	end

	button = CreateFrame("Button", "KeyboardLayoutSwapperMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(22, 22)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("CENTER")

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.label:SetPoint("CENTER", 0, 1)

	button:SetScript("OnEnter", function(self)
		local layout = CurrentLayout()
		local nxt = NextInCycle(layout)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("KeyboardLayoutSwapper")
		GameTooltip:AddLine("Now: " .. (LABEL[layout] or "unknown"), 1, 1, 1)
		GameTooltip:AddLine("Click to switch to " .. (LABEL[nxt] or "the next layout"), 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Cycle: " .. CycleText(), 0.7, 0.7, 0.7)
		if db.auto and db.prefer then
			GameTooltip:AddLine("This computer prefers " .. LABEL[db.prefer], 0.6, 0.8, 0.6)
		end
		GameTooltip:AddLine("Drag to move.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:SetScript("OnClick", function(self)
		if self.dragged then
			self.dragged = nil
			return
		end
		Toggle()
	end)
	button:SetScript("OnDragStart", function(self)
		self.dragged = true
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale
			db.minimapPos = math.deg(math.atan2(py - my, px - mx)) % 360
			UpdatePosition(db.minimapPos)
		end)
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	if type(db.minimapPos) ~= "number" then
		db.minimapPos = 225
	end
	UpdatePosition(db.minimapPos)
	UpdateButton()
end

local function Reconcile()
	NormalizeDB()
	if InCombatLockdown() then
		local waiter = CreateFrame("Frame")
		waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
		waiter:SetScript("OnEvent", function(self)
			self:UnregisterAllEvents()
			Reconcile()
		end)
		return
	end

	EnsureButton()
	local captured = Capture()
	local bound = 0
	for _ in pairs(captured) do
		bound = bound + 1
	end
	if bound < 8 and reconcileTries < 5 then
		reconcileTries = reconcileTries + 1
		C_Timer.After(1, Reconcile)
		return
	end

	local layout = ChooseLayout(MovementMatches(captured), DetectLayout())
	local sig = Signature(captured)
	if db.auto and db.prefer and layout and layout ~= db.prefer and sig ~= db.signature then
		db.layout = layout
		Apply(db.prefer)
		return
	end

	if layout then
		db.layout = layout
		if bound >= 8 then
			Restamp(layout)
		end
	end
	local foreign = db.auto and db.prefer and layout and layout ~= db.prefer
	if not foreign then
		db.signature = Signature(Capture())
	end
	UpdateButton()

	if not db.seenIntro then
		db.seenIntro = true
		if layout then
			Say(LABEL[layout] .. ". " .. MovementLine(captured))
		else
			Say(StampHint())
		end
		Say("Click cycles " .. CycleText() .. ". /kls use qwerty dvorak changes the list.")
	end
end

local function SetAuto(prefer)
	NormalizeDB()
	if prefer == "off" or prefer == "" then
		db.auto = false
		Say("This computer will no longer swap on its own.")
		UpdateButton()
		return
	end
	local id = Resolve(prefer)
	if not id then
		Say("Usage: /kls auto qwerty, /kls auto colemak-dh, /kls auto dvorak, or /kls auto off.")
		return
	end
	db.auto = true
	db.prefer = id
	if CurrentLayout() ~= id then
		Say("Switching to " .. LABEL[id] .. ".")
		Apply(id)
	else
		UpdateButton()
		Say("Already " .. LABEL[id] .. ". This computer will keep it that way at login.")
	end
end

local function SetUse(words)
	NormalizeDB()
	if #words < 2 then
		Say("Click cycles " .. CycleText() .. ". Example: /kls use qwerty dvorak")
		return
	end
	local clean = {}
	local seen = {}
	for i = 1, #words do
		local id = Resolve(words[i])
		if not id then
			Say("Unknown layout " .. words[i] .. ". " .. LayoutHelp() .. ".")
			return
		end
		if not seen[id] then
			seen[id] = true
			clean[#clean + 1] = id
		end
	end
	if #clean < 2 then
		Say("Name two different layouts. Example: /kls use qwerty dvorak")
		return
	end
	db.use = clean
	UpdateButton()
	Say("Click cycles " .. CycleText() .. ".")
end

SLASH_KEYBOARDLAYOUTSWAPPER1 = "/keyboardlayoutswapper"
SLASH_KEYBOARDLAYOUTSWAPPER2 = "/kls"
SlashCmdList.KEYBOARDLAYOUTSWAPPER = function(message)
	NormalizeDB()
	local words = {}
	for word in (message or ""):gmatch("%S+") do
		words[#words + 1] = word:lower()
	end
	local command = words[1] or ""
	local direct = Resolve(command)
	if command == "" then
		Toggle()
	elseif direct then
		Apply(direct)
	elseif command == "use" then
		local names = {}
		for i = 2, #words do
			names[#names + 1] = words[i]
		end
		SetUse(names)
	elseif command == "layouts" or command == "list" then
		Say(LayoutHelp() .. ". Click cycles " .. CycleText() .. ".")
	elseif command == "auto" then
		SetAuto(words[2] or "off")
	elseif command == "stamp" then
		local id = Resolve(words[2] or "")
		if not id then
			Say("Usage: /kls stamp qwerty, /kls stamp colemak-dh, /kls stamp colemak-classic, or /kls stamp dvorak.")
		elseif InCombatLockdown() then
			Say("Cannot swap in combat.")
		else
			SetBinding(MARKER_KEY, COMMAND_FOR[id])
			local which = GetCurrentBindingSet()
			if which == 1 or which == 2 then
				SaveBindings(which)
			end
			db.layout = id
			db.signature = Signature(Capture())
			UpdateButton()
			Say("Marked as " .. LABEL[id] .. " without moving keys. " .. MovementLine(Capture()))
		end
	else
		local layout = CurrentLayout()
		Say("Now " .. (LABEL[layout] or "unknown") .. ". Click cycles " .. CycleText() .. ". /kls use qwerty dvorak. " .. LayoutHelp() .. ".")
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event)
	NormalizeDB()
	if event == "PLAYER_LOGIN" then
		EnsureButton()
	else
		C_Timer.After(1, Reconcile)
	end
end)
