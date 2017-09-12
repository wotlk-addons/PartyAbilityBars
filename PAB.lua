-- TODO
-- Capture cooldowns from combat log and player, then set them

local lower = string.lower
local match = string.match
local remove = table.remove
local GetSpellInfo = GetSpellInfo
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local UnitName = UnitName
local IsInInstance = IsInInstance  
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local CooldownFrame_SetTimer = CooldownFrame_SetTimer

local SPELLIDUPPER = 60000
local CommPrefix  = "PABx39dkes8xj" -- Receive ability and cooldown
local CommPrefix2 = "PAB935ndd8xid" -- Send GUID for syncing
local CommPrefix3 = "PABkd8cjnwuid" -- Receive GUID for syncing

local db
local pGUID
local pName

local PAB = CreateFrame("Frame","PAB",UIParent)
local PABIcons = CreateFrame("Frame",nil,UIParent)
local PABAnchor = CreateFrame("Frame",nil,UIParent)

local iconlist = {}
local anchors = {}
local activeGUIDS = {}

local function print(...)
	for i=1,select('#',...) do
		ChatFrame1:AddMessage("|cff33ff99 PAB|r: " .. select(i,...))
	end
end

local InArena = function() return (select(2,IsInInstance()) == "arena") end

local _iconPaths = {}
local iconPaths = {
		[42292] = 120, -- PvP Trinket
		[59752] = 120, -- Every Man for Himself
		[71607] = 120, -- Bauble of True Blood
		[29166] = 180, -- Innervate
		[22812] = 60, -- Barkskin
		[8983] = 60, -- Bash
		[53201] = 60, -- Starfall
		[50334] = 180, -- Berserk
		[61336] = 180, -- Survival Instincts
		[16979] = 15, -- Feral Charge - Bear
		[18562] = 13, -- Swiftmend
		[17116] = 180, -- Nature's Swiftness
		[19503] = 30, -- Scatter Shot
		[60192] = 28, -- Freezing Arrow
		[13809] = 28, -- Frost Trap
		[14311] = 28, -- Freezing Trap
		[19574] = 120, -- Bestial Wrath
		[34490] = 20, -- Silencing Shot
		[23989] = 180, -- Readiness
		[19263] = 90, -- Deterrence
		[67481] = 60, -- Roar of Sacrifice
		[53271] = 60, -- Master's Call
		[1953] = 15, -- Blink
		[2139] = 24, -- Counterspell
		[44572] = 30, -- Deep Freeze
		[12051] = 240, -- Evocation
		[45438] = 300, -- Ice Block
		[11958] = 384, -- Cold Snap
		[10308] = 40, -- Hammer of Justice
		[10308] = 60, -- Repentance
		[1044] = 25, -- Hand of Freedom
		[54428] = 60, -- Divine Plea
		[31821] = 120, -- Aura Mastery
		[64205] = 120, -- Divine Sacrifice
		[6940] = 120, -- Hand of Sacrifice
		[10278] = 180, -- Hand of Protection
		[642] = 300, -- Divine Shield
		[10890] = 24, -- Psychic Scream
		[34433] = 300, -- Shadowfiend
		[33206] = 144, -- Pain Suppression
		[64044] = 120, -- Psychic Horror
		[48158] = 12, -- Shadow World: Death
		[15487] = 45, -- Silence
		[47585] = 75, -- Dispersion
		[1766] = 10, -- Kick
		[8643] = 20, -- Kidney Shot
		[31224] = 60, -- Cloak of Shadows
		[51722] = 60, -- Dismantle
		[2094] = 120, -- Blind
		[26889] = 120, -- Vanish
		[14185] = 300, -- Preparation
		[51713] = 60, -- Shadow Dance
		[57994] = 6, -- Wind Shear
		[51514] = 45, -- Hex
		[16188] = 120, -- Nature's Swiftness
		[8177] = 15, -- Grounding Totem
		[19647] = 24, -- Spell Lock
		[17925] = 120, -- Death Coil
		[18708] = 180, -- Fel Domination
		[48011] = 8, -- Devour Magic
		[48020] = 30, -- Demonic Circle: Teleport
		[47847] = 20, -- Shadowfury
		[6552] = 10, -- Pummel
		[72] = 12, -- Shield Bash
		[11578] = 13, -- Charge
		[47996] = 15, -- Intercept
		[46924] = 90,  -- Bladestorm
		[871] = 300, -- Shield Wall
		[2565] = 60, -- Shield Block
		[2565] = 60, -- Shield Block
		[676] = 60, -- Disarm
		[47528] = 10, -- Mind Freeze
		[47481] = 20, -- Gnaw
		[48743] = 120, -- Death Pact
		[49206] = 180, -- Summon Gargoyle
		[51052] = 120, -- Anti-Magic Zone
		[49576] = 35, -- Death Grip
		[48707] = 45, -- Anti-Magic Shell
		[47476] = 120, -- Strangulate
		[49039] = 120, -- Lichborne
		[7744] = 120, -- Will of the Forsaken
}
for k in pairs(iconPaths) do _iconPaths[GetSpellInfo(k)] = select(3,GetSpellInfo(k)) end
iconPaths = _iconPaths
iconPaths[GetSpellInfo(71607)] = "Interface\\Icons\\inv_jewelcrafting_gem_28"

local specAbilities = {
	["ROGUE"] = {
		[14185] = { -- Preparation
			talentGroup = 3,
			index = 14,
		},
		[51713] = { -- Shadow Dance
			talentGroup = 3,
			index = 28,
		},
		[51690] = { -- Killing Spree
			talentGroup = 2,
			index = 28,
		},
		[14177] = { -- Cold Blood
			talentGroup = 1,
			index = 13,
		},
	},
	["PRIEST"] = {
		[47585] = { -- Dispersion
			talentGroup = 3,
			index = 27,
		},
		[33206] = { -- Pain Suppression
			talentGroup = 1,
			index = 25,
		},
		[15487] = { -- Silence
			talentGroup = 3,
			index = 13,
		},
		[64044] = { -- Psychic Horror
			talentGroup = 3,
			index = 23,
		},
	},
	["DRUID"] = {
		[53201] = {  -- Starfall
			talentGroup = 1,
			index = 28,
		},
		[61336] = { -- Survival Instincts
			talentGroup = 2,
			index = 7,
		},
		[16979] = {  -- Feral Charge - Bear
			talentGroup = 2,
			index = 14,
		},
		[50334] = { -- Berserk
			talentGroup = 2,
			index = 30,
		},
		[17116] = { -- Nature's Swiftness
			talentGroup = 3,
			index = 12,
		},
		[18562] = { -- Swiftmend
			talentGroup = 3,
			index = 18,
		},
	},
	["HUNTER"] = {
		[19574] = { -- Bestial Wrath
			talentGroup = 1,
			index = 18,
		},
		[23989] = { -- Readiness
			talentGroup = 2,
			index = 14,
		},
		[34490] = { -- Silencing Shot
			talentGroup = 2,
			index = 24,
		},
		[19503] = { -- Scatter Shot
			talentGroup = 3,
			index = 9,
		},
		[49012] = { -- Wyvern Sting
			talentGroup = 3,
			index = 20,
		},
	},
	["MAGE"] = 	{
		[12043] = { -- Presence of Mind
			talentGroup = 1,
			index = 16,
		},
		[11129] = { -- Combustion
			talentGroup = 2,
			index = 20,
		},
		[44572] = { -- Dragon's Breath
			talentGroup = 2,
			index = 25,
		},
		[11958] = { -- Cold Snap
			talentGroup = 3,
			index = 14,
		},
		[44572] = { -- Deep Freeze
			talentGroup = 3,
			index = 28,
		},
	},
	["PALADIN"] = {
		[31821] = { -- Aura Mastery
			talentGroup = 1,
			index = 6,
		},
		[48825] = { -- Holy Shock
			talentGroup = 1,
			index = 18,
		},
		[64205] = { -- Divine Sacrifice
			talentGroup = 2,
			index = 6,
		},
		[48827] = { -- Avenger's Shield
			talentGroup = 2,
			index = 22,
		},
		[66008] = { -- Repentance
			talentGroup = 3,
			index = 18,
		},
	},
	["SHAMAN"] = {
		[16188] = { -- Nature's Swiftness
			talentGroup = 3,
			index = 13,
		},
	},
	["WARLOCK"] = {
		[47847] = { -- Shadowfury
			talentGroup = 3,
			index = 23,
		},
	},
	["WARRIOR"] = {
		[46924] = { -- Bladestorm
			talentGroup = 1,
			index = 31,
		},
		[12809] = { -- Concussion Blow
			talentGroup = 3,
			index = 14,
		},
		[46968] = { -- Shockwave : cd -3 ?
			talentGroup = 3,
			index = 27,
		},
	},
	["DEATHKNIGHT"] = {
		[49039] = { -- Lichborne
			talentGroup = 2,
			index = 8,
		},
		[49203] = { -- Hungering Cold
			talentGroup = 2,
			index = 20,
		},
		[51271] = { -- Unbreakable Armor
			talentGroup = 2,
			index = 24,
		},
		[51052] = { -- Anti-Magic Zone
			talentGroup = 3,
			index = 22,
		},
		[49206] = { -- Summon Gargoyle
			talentGroup = 3,
			index = 31,
		},
	},
}

local defaultAbilities = {
	["DRUID"] = {
		[29166] = 180, -- Innervate
		[22812] = 60,  -- Barkskin
		[8983] = 60,   -- Bash
		[53201] = 60,  -- Starfall
		[50334] = 180, -- Berserk
		[61336] = 180, -- Survival Instincts
		[16979] = 15,  -- Feral Charge - Bear
		[18562] = 13,  -- Swiftmend
		[17116] = 180, -- Nature's Swiftness
		[71607] = 120, -- Bauble of True Blood
	},
	["HUNTER"] = {
		[19503] = 30,  -- Scatter Shot
		[60192] = 28,  -- Freezing Arrow
		[13809] = 28,  -- Frost Trap
		[14311] = 28,  -- Freezing Trap
		[19574] = 120, -- Bestial Wrath
		[34490] = 20,  -- Silencing Shot
		[23989] = 180, -- Readiness
		[19263] = 90,  -- Deterrence
		[67481] = 60,  -- Roar of Sacrifice
		[53271] = 60,  -- Master's Call
	},
	["MAGE"] = 	{
		[1953] = 15,   -- Blink
		[2139] = 24,   -- Counterspell
		[44572] = 30,  -- Deep Freeze
		[12051] = 240, -- Evocation
		[45438] = 300, -- Ice Block
		[11958] = 384, -- Cold Snap
	},
	["PALADIN"] = {
		[10308] = 40,  -- Hammer of Justice
		[1044] = 25,   -- Hand of Freedom
		[54428] = 60,  -- Divine Plea
		[6940] = 120,  -- Hand of Sacrifice
		[10278] = 180, -- Hand of Protection
		[642] = 300,   -- Divine Shield
		[71607] = 120, -- Bauble of True Blood
		[31821] = 120, -- Aura Mastery
		[66008] = 60, -- Repentance
		[64205] = 120, -- Divine Sacrifice
	},
	["PRIEST"] = {
		[10890] = 24,  -- Psychic Scream
		[48158] = 12,  -- Shadow World: Death
		[71607] = 120, -- Bauble of True Blood
		[47585] = 75, -- Dispersion
		[33206] = 144, -- Pain Suppression
		[15487] = 45, -- Silence 
		[64044] = 120, -- Psychic Horror
	},
	["ROGUE"] = {
		[1766] = 10,   -- Kick
		[8643] = 20,   -- Kidney Shot
		[31224] = 60,  -- Cloak of Shadows
		[51722] = 60,  -- Dismantle
		[2094] = 120,  -- Blind
		[26889] = 120, -- Vanish
		[14185] = 300, -- Preparation
		[51713] = 60, -- Shadow Dance
		[51690] = 120, -- Killing Spree
		[14177] = 180, -- Cold Blood
	},
	["SHAMAN"] = {
		[57994] = 6,   -- Wind Shear
		[51514] = 45,  -- Hex
		[16188] = 120, -- Nature's Swiftness
		[8177] = 15,   -- Grounding Totem
		[71607] = 120, -- Bauble of True Blood
	},
	["WARLOCK"] = {
		[19647] = 24,  -- Spell Lock
		[17925] = 120, -- Death Coil
		[18708] = 180, -- Fel Domination
		[48011] = 8,   -- Devour Magic
		[48020] = 30,  -- Demonic Circle: Teleport
		[47847] = 20,  -- Shadowfury
	},
	["WARRIOR"] = {
		[6552] = 10,   -- Pummel
		[72] = 12,     -- Shield Bash
		[11578] = 13,  -- Charge
		[47996] = 15,  -- Intercept
		[46924] = 90,  -- Bladestorm
		[871] = 300,   -- Shield Wall
		[2565] = 60,   -- Shield Block
		[676] = 60,    -- Disarm
	},
	["DEATHKNIGHT"] = {
		[47528] = 10,  -- Mind Freeze
		[47481] = 20,  -- Gnaw
		[48743] = 120, -- Death Pact
		[49206] = 180, -- Summon Gargoyle
		[51052] = 120, -- Anti-Magic Zone
		[49576] = 35,  -- Death Grip
		[48707] = 45,  -- Anti-Magic Shell
		[47476] = 120, -- Strangulate
		[49039] = 120, -- Lichborne
	},
	["Scourge"] = {
		[7744] = 120, -- Will of the Forsaken
		[42292] = 120, -- PvP Trinket
	},
	["BloodElf"] = {
		[28730] = 120, -- Arcane Torrent
		[42292] = 120, -- PvP Trinket
	},
	["Tauren"] = {
		[20549] = 120, -- War Stomp
		[42292] = 120, -- PvP Trinket
	},
	["Orc"] = {
		[42292] = 120, -- PvP Trinket
	},
	["Troll"] = {
		[42292] = 120, -- PvP Trinket
	},
	["NightElf"] = {
		[42292] = 120, -- PvP Trinket
	},
	["Draenei"] = {
		[42292] = 120, -- PvP Trinket
	},
	["Human"] = {
		[59752] = 120, -- Every Man for Himself
	},
	["Gnome"] = {
		[42292] = 120, -- PvP Trinket
	},
	["Dwarf"] = {
		[20594] = 120, -- Stoneform
		[42292] = 120, -- PvP Trinket
	}
}

-- V: added a "fillwith" parameter to fill the generated tables with a single value.
--    "not pretty, but it works"
local function convertspellids(t, fillwith)
	local temp = {}
	for class,table in pairs(t) do
		temp[class] = {}
		for k,v in pairs(table) do
			temp[class][GetSpellInfo(k)] = fillwith or v
		end
	end
	return temp
end

-- V: generate allCooldownIds before destructively convertign defaultAbilities
local allCooldownIds = convertspellids(defaultAbilities, true)

defaultAbilities = convertspellids(defaultAbilities)
specAbilities = convertspellids(specAbilities)


local groupedCooldowns = {
	["DRUID"] = {
		[16979] = 1, -- Feral Charge - Bear
		[49376] = 1, -- Feral Charge - Cat
	},
	["SHAMAN"] = {
		[49231] = 1, -- Earth Shock
		[49233] = 1, -- Flame Shock
		[49236] = 1, -- Frost Shock
	},
	["HUNTER"] = {
		[60192] = 1, -- Freezing Arrow
		[14311] = 1, -- Freezing Trap
		[13809] = 1, -- Frost Trap
		[49067] = 2, -- Explosive Trap
		[49056] = 2, -- Immolation Trap
		[34600] = 3, -- Snake Trap
	},
	["MAGE"] = {
		[43010] = 1,  -- Fire Ward
		[43012] = 1,  -- Frost Ward
	},
}

groupedCooldowns = convertspellids(groupedCooldowns)

local cooldownResetters = {
	[11958] = { -- Cold Snap
		[42931] = 1, -- Cone of Cold
		[42917] = 1, -- Frost Nova
		[43012] = 1, -- Frost Ward
		[43039] = 1, -- Ice Barrier
		[45438] = 1, -- Ice Block
		[31687] = 1, -- Summon Water Elemental
		[44572] = 1, -- Deep Freeze
		[44545] = 1, -- Fingers of Frost
		[12472] = 1, -- Icy Veins
	},
	[14185] = { -- Preparation
		[14177] = 1, -- Cold Blood
		[26669] = 1, -- Evasion
		[11305] = 1, -- Sprint
		[26889] = 1, -- Vanish
		[36554] = 1, -- Shadowstep
	},
	[23989] = { -- Readiness
		[19503] = 1, -- Scatter Shot
		[60192] = 1, -- Freezing Arrow
		[13809] = 1, -- Frost Trap
		[14311] = 1, -- Freezing Trap
		[19574] = 1, -- Bestial Wrath
		[34490] = 1, -- Silencing Shot
		[19263] = 1, -- Deterrence
		[53271] = 1, -- Master's Call
	},
}

local temp = {}
for k,v in pairs(cooldownResetters) do
	temp[GetSpellInfo(k)] = {}
	if type(v) == "table" then
		for id in pairs(v) do
			temp[GetSpellInfo(k)][GetSpellInfo(id)] = 1
		end
	else
		temp[GetSpellInfo(k)] = v
	end
end

cooldownResetters = temp
temp = nil
convertspellids = nil

function PAB:SavePositions()
	for k,anchor in ipairs(anchors) do
		local scale = anchor:GetEffectiveScale()
		local worldscale = UIParent:GetEffectiveScale()
		local x = anchor:GetLeft() * scale
		local y = (anchor:GetTop() * scale) - (UIParent:GetTop() * worldscale)
		
		if not db.positions[k] then
			db.positions[k] = {}
		end
		
		db.positions[k].x = x
		db.positions[k].y = y
	end
end

function PAB:LoadPositions()
	db.positions = db.positions or {}
	for k,anchor in ipairs(anchors) do
		if db.positions[k] then
			local x = db.positions[k].x
			local y = db.positions[k].y
			local scale = anchors[k]:GetEffectiveScale()
			anchors[k]:SetPoint("TOPLEFT", UIParent,"TOPLEFT", x/scale, y/scale)
		else
			anchors[k]:SetPoint("CENTER", UIParent, "CENTER")
		end
	end
end

local backdrop = {bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="", tile=false,}
function PAB:CreateAnchors()
	for i=1,4 do
		local anchor = CreateFrame("Frame","PABAnchor"..i ,PABAnchor)
		anchor:SetBackdrop(backdrop)
		anchor:SetHeight(15)
		anchor:SetWidth(15)
		anchor:SetBackdropColor(1,0,0,1)
		anchor:EnableMouse(true)
		anchor:SetMovable(true)
		anchor:Show()
		anchor.icons = {}
		anchor.HideIcons = function() for k,icon in ipairs(anchor.icons) do icon:Hide(); icon.shouldShow = nil end end
		anchor:SetScript("OnMouseDown",function(self,button) if button == "LeftButton" then self:StartMoving() end end)
		anchor:SetScript("OnMouseUp",function(self,button) if button == "LeftButton" then self:StopMovingOrSizing(); PAB:SavePositions() end end)
		anchors[i] = anchor
		
		local index = anchor:CreateFontString(nil,"ARTWORK","GameFontNormal")
		index:SetPoint("CENTER")
		index:SetText(i)
	end
end

local function CreateIcon(anchor)
	local icon = CreateFrame("Frame",anchor:GetName().."Icon".. (#anchor.icons+1),PABIcons)
	icon:SetHeight(30)
	icon:SetWidth(30)
		
	local cd = CreateFrame("Cooldown",icon:GetName().."Cooldown",icon,"CooldownFrameTemplate")
	icon.cd = cd
	
	icon.Start = function(sentCD)
		icon.cooldown = tonumber(sentCD);
		CooldownFrame_SetTimer(cd,GetTime(),icon.cooldown,1); 
		icon:Show(); 
		icon.active = true; 
		icon.starttime = GetTime()+0.4 
		activeGUIDS[icon.GUID][icon.ability] = activeGUIDS[icon.GUID][icon.ability] or {}
		activeGUIDS[icon.GUID][icon.ability].starttime = icon.starttime
		activeGUIDS[icon.GUID][icon.ability].cooldown =  icon.cooldown
	end
	
	icon.Stop = function() 
		CooldownFrame_SetTimer(cd,0,0,0); 
		icon.starttime = 0
	end
	
	icon.SetTimer = function(starttime,cooldown)
		CooldownFrame_SetTimer(cd,starttime,cooldown,1)
		icon.active = true
		icon.starttime = starttime
		icon.cooldown = cooldown
	end
	
	local texture = icon:CreateTexture(nil,"ARTWORK")
	texture:SetAllPoints(true)
	texture:SetTexCoord(0.07,0.9,0.07,0.90)
	icon.texture = texture

	return icon
end

function PAB:AppendIcon(icons,anchor)
	local newicon = CreateIcon(anchor)
	iconlist[#iconlist+1] = newicon
	if #icons == 0 then
		newicon:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT")
	elseif db.iconsperline ~= 0 and (#icons % db.iconsperline) == 0 then
		newicon:SetPoint("TOPLEFT",icons[#icons - db.iconsperline + 1],"BOTTOMLEFT", 0, -1)
	else
		newicon:SetPoint("LEFT",icons[#icons],"RIGHT", 1, 0)
	end
	icons[#icons+1] = newicon
	return newicon
end

function PAB:ShowUsedAnchors()
	for i=1,GetNumPartyMembers() do anchors[i]:Show() end
end

function PAB:HideUnusedAnchors()
	for k=GetNumPartyMembers()+1,#anchors do
		anchors[k]:Hide()
		anchors[k].HideIcons()
	end
end

function PAB:HideUnusedIcons(numIcons,icons)
	for j=numIcons,#icons do
		icons[j]:Hide()
		icons[j].shouldShow = nil
	end
end

function PAB:UpdateAnchors(updateIcons)
	for i=1,GetNumPartyMembers() do
		local _,class = UnitClass("party"..i)
		if not class then return end
		local anchor = anchors[i]
		anchor.GUID = UnitGUID("party"..i)
		anchor.class = select(2,UnitClass("party"..i))
		local abilities = db.abilities[class]
		-- uses races as well as classes, no unique combinations of class+race like "Nightelf Priest" possible
		anchor.race = select(2,UnitRace("party"..i))
		local boundTo = {}
		local abilities = { }
		for k, v in pairs(db.abilities) do
			if k == class or k == anchor.race then
				for ke, va in pairs(v) do
					abilities[ke]=va
					-- V: keep track of what is from what
					boundTo[ke] = k
				end
			end
		end
		if updateIcons then
			for i = 1, #anchor.icons do
				anchor.icons[i]:Hide()
				anchor.icons[i]:SetParent(nim)
				anchor.icons[i]:ClearAllPoints()
			end
			anchor.icons = {}
		end
		local numIcons = 1
		if not anchor.spec and not anchor.inspectFrame and CanInspect("party"..i) then
			local _self = self
			local f = CreateFrame("Frame")
			anchor.inspectFrame = f
			f:SetScript("OnEvent", function (self, event, ...)
				f:UnregisterEvent("INSPECT_TALENT_READY")
				local specSpells = specAbilities[anchor.class]
				if specSpells then
					anchor.spec = {}
					for ability, spell in pairs(specSpells) do
						local hasTalent = select(5,
							GetTalentInfo(spell.talentGroup, spell.index, true)
						) > 0
						anchor.spec[ability] = hasTalent
					end
					PAB:UpdateAnchors(true)
				end
				ClearInspectPlayer()
			end)
			f:RegisterEvent("INSPECT_TALENT_READY")
			NotifyInspect("party"..i)
		end
		local specSpells = specAbilities[anchor.class]
		for ability,cooldown in pairs(abilities) do
			-- if it's not a talent, or we have the talent
			local enabled = db.enabledCooldowns[boundTo[ability]][ability]
			if enabled and not specSpells[ability] or anchor.spec and anchor.spec[ability] then
				self:UpdateAnchorIcon(anchor, numIcons, ability, cooldown)
				numIcons = numIcons + 1
			end
		end
		self:HideUnusedIcons(numIcons,anchor.icons)
	end
	self:ShowUsedAnchors()
	self:HideUnusedAnchors()

	self:ApplyAnchorSettings()
end

function PAB:UpdateAnchorIcon(anchor, numIcons, ability, cooldown)
	local icons = anchor.icons
	local icon = icons[numIcons] or self:AppendIcon(icons,anchor)
	icon.texture:SetTexture(self:FindAbilityIcon(ability))
	icon.GUID = anchor.GUID
	icon.ability = ability
	icon.cooldown = cooldown
	icon.shouldShow = true
	activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
	if activeGUIDS[icon.GUID][icon.ability] then
		icon.SetTimer(activeGUIDS[icon.GUID][ability].starttime,activeGUIDS[icon.GUID][ability].cooldown)
	else
		icon.Stop()
	end
end

function PAB:ApplyAnchorSettings()
	PABIcons:SetScale(db.scale or 1)
	
	if db.arena then
		if InArena() then
			PABIcons:Show()
		else
			PABIcons:Hide()
		end
	else
		PABIcons:Show()
	end

	for k,v in ipairs(anchors) do
		for k,v in ipairs(v.icons) do
			if db.hidden and not v.active then
				v:Hide()
			elseif v.shouldShow then
				v:Show()
			end
		end
	end	
	
	if db.lock then PABAnchor:Hide() else PABAnchor:Show() end
end

function PAB:PARTY_MEMBERS_CHANGED()
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	self:UpdateAnchors(true)
end

function PAB:PLAYER_ENTERING_WORLD()
	if InArena() then
		-- Cooldowns reset when joining arena
		self:StopAllIcons()
		self:UpdateAnchors(true)
	end
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	self:UpdateAnchors(true)
end

function PAB:CheckAbility(anchor,ability,cooldown,pIndex)
	if not cooldown then return end
	for k,icon in ipairs(anchor.icons) do
		-- Direct cooldown
		if icon.ability == ability and icon.shouldShow then icon.Start(cooldown) end
		-- Grouped Cooldowns
		if groupedCooldowns[anchor.class] and groupedCooldowns[anchor.class][ability] then
			for k in pairs(groupedCooldowns[anchor.class]) do
				if k == icon.ability and icon.shouldShow then icon.Start(cooldown); break end
			end
		end
		-- Cooldown resetters
		if cooldownResetters[ability] then
			if type(cooldownResetters[ability]) == "table" then
				for k in pairs(cooldownResetters[ability]) do
					if k == icon.ability then icon.Stop(); break end
				end
			else
				icon.Stop()
			end
		end
	end
end

function PAB:UNIT_SPELLCAST_SUCCEEDED(unit,ability)
	if unit == "player" then return end
	local pIndex = match(unit,"party[pet]*([1-4])")
	if pIndex and ability then
		local _,class = UnitClass("party"..pIndex)
		self:CheckAbility(anchors[tonumber(pIndex)],ability,db.abilities[class][ability],pIndex) 
	end
end

local timers, timerfuncs, timerargs = {}, {}, {}
function PAB:Schedule(duration,func,...)
	timers[#timers+1] = duration
	timerfuncs[#timerfuncs+1] = func
	timerargs[#timerargs+1] = {...}
end

local time = 0

local function PAB_OnUpdate(self,elapsed)
	time = time + elapsed
	if time > 0.05 then
		--  Update Icons
		for k,icon in ipairs(iconlist) do
			if icon.active then
				icon.timeleft = icon.starttime + icon.cooldown - GetTime()
				if icon.timeleft <= 0 and icon.GUID and icon.ability then
					if db.hidden then icon:Hide() end
					activeGUIDS[icon.GUID][icon.ability] = nil
					icon.active = nil
				end
			end
		end
		
		-- Update Timers
		if #timers > 0 then
			for i=#timers,1,-1 do 
				timers[i] = timers[i] - 0.05
				if timers[i] <= 0 then
					remove(timers,i)
					remove(timerfuncs,i)(PAB,unpack(remove(timerargs,i)))
				end
			end
		end
		
		time = 0
	end
end

function PAB:StopAllIcons()
	for k,v in ipairs(iconlist) do v.Stop() end
	wipe(activeGUIDS)
end

local function PAB_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:SetScript("OnEvent",function(self,event,...) if self[event] then self[event](self,...) end end)
	
	PABDB = PABDB or {
		abilities = defaultAbilities,
		scale = 0.9,
		lock = true,
		arena = false,
		hidden = false,
		iconsperline = 0,
		positions = {
			{
				x = 1,
				y = -116,
			}, -- [1]
			{
				x = 1,
				y = -217,
			}, -- [2]
			{
				x = 1,
				y = -318,
			}, -- [3]
			{
				x = 1,
				y = -419,
			}, -- [4]
		},
		enabledCooldowns = allCooldownIds
	}
	db = PABDB

	self:CreateAnchors()
	self:UpdateAnchors(false)
	self:LoadPositions()
	self:CreateOptions()
	
	self:SetScript("OnUpdate",PAB_OnUpdate)
	
	print("Party Ability Bars by Kollektiv. enhancements by Lawz. Talent detection & configuration by Vendethiel. Type /pab to open options")
end

function PAB:FindAbilityIcon(ability)
	if iconPaths[ability] then return iconPaths[ability] end
	for id=SPELLIDUPPER,1,-1 do
		local _ability,_,_icon = GetSpellInfo(id)
		if _ability and _ability == ability then
			iconPaths[ability] = _icon
			return _icon
		end
	end
end

function PAB:FormatAbility(s)
	s = s:gsub("(%a)(%a*)('*)(%a*)", function (a,b,c,d) return a:upper()..b:lower()..c..d:lower() end)
	s = s:gsub("(The)", string.lower)
	s = s:gsub("(Of)", string.lower)
	return s
end

-------------------------------------------------------------
-- Options
-------------------------------------------------------------

local function CreateEditBox(name,parent,width,height)
	local editbox = CreateFrame("EditBox",parent:GetName()..name,parent,"InputBoxTemplate")
	editbox:SetHeight(height)
	editbox:SetWidth(width)
	editbox:SetAutoFocus(false)
	
	local label = editbox:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	label:SetText(name)
	label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT",-3,0)
	return editbox
end

local SO = LibStub("LibSimpleOptions-1.0")

function PAB:CreateOptions()
	local panel = SO.AddOptionsPanel("PAB", function() end)
	self.panel = panel
	SO.AddSlashCommand("PAB","/pab")
	local title, subText = panel:MakeTitleTextAndSubText("Party Ability Bars","General settings")
	
	local scale = panel:MakeSlider(
		'name', 'Scale',
		'description', 'Adjust the scale of icons',
		'minText', '0.1',
		'maxText', '5',
		'minValue', 0.1,
		'maxValue', 5,
		'step', 0.05,
		'default', 1,
		'current', db.scale,
		'setFunc', function(value) db.scale = value; PAB:ApplyAnchorSettings() end,
		'currentTextFunc', function(value) return string.format("%.2f",value) end)
	scale:SetPoint("TOPLEFT",subText,"TOPLEFT",16,-32)
--[[	
	local rows = panel:MakeSlider(
		'name', 'Row',
		'description', 'Set the number of icons per row',
		'minText', '1',
		'maxText', '10',
		'minValue', 1,
		'maxValue', 10,
		'step', 1,
		'default', 3,
		'current', db.rows,
		'setFunc', function(value) db.rows = value; PAB:ApplyAnchorSettings() end,
		'currentTextFunc', function(value) return value end)
	rows:SetPoint("TOPLEFT",subText,"TOPLEFT",100,-70)  
]]	
	local lock = panel:MakeToggle(
	     'name', 'Lock',
	     'description', 'Show/hide anchors',
	     'default', false,
	     'getFunc', function() return db.lock end,
	     'setFunc', function(value) db.lock = value; PAB:ApplyAnchorSettings() end)
	     
	lock:SetPoint("TOP",panel,"TOP",10,-36)
	
	local arena = panel:MakeToggle(
	     'name', 'Arena',
	     'description', 'Show in arena only',
	     'default', false,
	     'getFunc', function() return db.arena end,
	     'setFunc', function(value) db.arena = value; PAB:ApplyAnchorSettings() end)
	arena:SetPoint("TOP",lock,"BOTTOM",0,-5)
	
	local hidden = panel:MakeToggle(
	     'name', 'Hidden',
	     'description', 'Show icon only when on cooldown',
	     'default', false,
	     'getFunc', function() return db.hidden end,
	     'setFunc', function(value) db.hidden = value; PAB:ApplyAnchorSettings() end)
	hidden:SetPoint("LEFT",lock,"RIGHT",50,0)

	local iconsperline = CreateEditBox("Icons per line", panel, 50, 25)
	iconsperline:SetPoint("LEFT", arena, "RIGHT", 50, 0)
	iconsperline:SetMultiLine(false)
	iconsperline:SetNumber(db.iconsperline)
	iconsperline:SetCursorPosition(0)
	iconsperline:SetScript("OnTextChanged", function (self, isUserinput)
		if not isUserinput then return end
		local num = iconsperline:GetNumber()
		-- force numerical value. Does not infinite loop since we check for isUserinput
		iconsperline:SetNumber(num)
		if db.iconsperline ~= num then
			db.iconsperline = num
			PAB:UpdateAnchors(true)
		end
	end)


	local title2, subText2 = panel:MakeTitleTextAndSubText("Ability editor","Change what party member abilities are tracked")
	title2:ClearAllPoints()
	title2:SetPoint("LEFT",panel,"LEFT",16,80)
	subText2:ClearAllPoints()
	subText2:SetPoint("TOPLEFT",title2,"BOTTOMLEFT",0,-8)
	
	self:CreateAbilityEditor()

end

local function count(t) local i = 0 for k,v in pairs(t) do i = i + 1 end return i end

-- V: can't add it to LibSimpleOptions if other addons use it... zzzzz
local function GetToggleText(button)
	return _G[button:GetName().."Text"]
end

function PAB:UpdateScrollBar()
	local btns = self.btns
	-- V: the ability store helps us map which ability we want to enable/disable
	self.abilityStore = {}
	local checkboxes = self.abilityCheckboxes
	local scrollframe = self.scrollframe
	local classSelectedTable = db.abilities[db.classSelected]
	local classSelectedTableLength = count(db.abilities[db.classSelected])
	FauxScrollFrame_Update(scrollframe,classSelectedTableLength,10,16,nil,nil,nil,nil,nil,nil,true);
	local line = 1
	for ability,cooldown in pairs(classSelectedTable) do
		-- V: wtf is that... a global that's never used...
		--lineplusoffset = line + FauxScrollFrame_GetOffset(scrollframe)
		
		-- V: check if we have it enabled...
		local checked = db.enabledCooldowns[db.classSelected][ability]
		btns[line]:SetChecked(checked)

		local text = GetToggleText(btns[line])
		self.abilityStore[line] = ability
		text:SetText(ability)
		btns[line]:Show()
		line = line + 1
	end
	for i=line,20 do
		btns[i]:Hide()
	end
end

function PAB:OnVerticalScroll(offset,itemHeight)
	local scrollbar = _G[self.scrollframe:GetName().. "ScrollBar"]
	scrollbar:SetValue(offset);
	self.scrollframe.offset = floor((offset / itemHeight) + 0.5);
	self:UpdateScrollBar()
end

function PAB:CreateAbilityEditor()
	-- V: default out
	db.classSelected = db.classSelected or "WARRIOR"

	local panel = self.panel
	local btns = {}
	self.btns = btns
	local scrollframe = CreateFrame("ScrollFrame", "PABScrollFrame",panel,"FauxScrollFrameTemplate")
	--local abilityCheckboxes = {}
	--self.abilityCheckboxes = abilityCheckboxes
	-- V: the setter for the toggles. Using a local to close over i.
	local _self = self
	local function setterFunc(i)
		return function (value)
			local ability = _self.abilityStore[i]
			db.enabledCooldowns[db.classSelected][ability] = value
			-- redraw *everything*
			PAB:UpdateAnchors(true)
		end
	end
	-- V: let's say, 20, just 'cus I can.
	for i=1,20 do
		local button = panel:MakeToggle(
			'name', tostring(i),
			'description', "Enable or disable",
			'default', false,
			'current', false,
			'setFunc', setterFunc(i)
		)
		if i == 1 then -- first one
			button:SetPoint("TOPLEFT",scrollframe,"TOPLEFT",11,0)
		else
			button:SetPoint("TOPLEFT",btns[i-1],"BOTTOMLEFT")
		end
		btns[i] = button
	end
	
	scrollframe:SetWidth(150); 
	scrollframe:SetHeight(200)
	scrollframe:SetPoint('LEFT',16,-45)
	scrollframe:SetBackdrop(backdrop)
	scrollframe:SetBackdropColor(.6,.6,.6,0.25)
	scrollframe:SetScript("OnVerticalScroll", function(self,offset) PAB:OnVerticalScroll(offset,16) end)
	scrollframe:SetScript("OnShow",function(self) if not db.classSelected then db.classSelected = "WARRIOR" end; PAB:UpdateScrollBar();  end)
	
	self.scrollframe = scrollframe
	
	local dropdown = panel:MakeDropDown(
		'name', 'Class',
		'description', 'Pick a class to edit the ability list',
		'values', {
			-- TODO should use the keys of defaultAbilities
			"WARRIOR", "Warrior",
			"DEATHKNIGHT", "Deathknight",
			"PALADIN", "Paladin",
			"PRIEST", "Priest",
			"SHAMAN", "Shaman",
			"DRUID", "Druid",
			"ROGUE", "Rogue",
			"MAGE", "Mage",
			"WARLOCK", "Warlock",
			"HUNTER", "Hunter",
			"Dwarf", "Dwarf",
			"BloodElf", "Bloodelf",
			"Scourge", "Undead",
			"Tauren", "Tauren",
			"NightElf", "Nightelf",
			"Draenei", "Draenei",
			"Human", "Human",
			"Gnome", "Gnome",
			"Orc", "Orc",
			"Troll", "Troll",
		},
		'default', 'WARRIOR',
		'getFunc', function()
			return db.classSelected
		end,
		'setFunc', function(value)
			db.classSelected = value
			PAB:UpdateScrollBar()
		end
	)
	dropdown:SetPoint("TOPLEFT",scrollframe,"TOPRIGHT",20, -20)
end

PAB:RegisterEvent("VARIABLES_LOADED")
PAB:SetScript("OnEvent",PAB_OnLoad)