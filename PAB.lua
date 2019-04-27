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
		[36554] = { -- Shadow Step
			talentGroup = 3,
			index = 25,
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
		[42950] = { -- Dragon's Breath
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
		[16166] = { -- Elemental Mastery
			talentGroup = 1,
			index = 16
		},
		[51490] = { -- Thunderstorm
			talentGroup = 1,
			index = 25,
		},
		[30823] = { -- Shamanistic Rage
			talentGroup = 2,
			index = 26
		},
	},
	["WARLOCK"] = {
		[47847] = { -- Shadowfury
			talentGroup = 3,
			index = 23,
		},
		[18708] = { -- Fel Domination
			talentGroup = 2,
			index = 10,
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
		[46968] = { -- Shockwave
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
		[49012] = 30,  -- Wyvern Sting
	},
	["MAGE"] = 	{
		[1953] = 15,   -- Blink
		[2139] = 24,   -- Counterspell
		[44572] = 30,  -- Deep Freeze
		[12051] = 240, -- Evocation
		[45438] = 300, -- Ice Block
		[11958] = 384, -- Cold Snap
		[12043] = 60, -- Presence of Mind
		[11129] = 120, -- Combustion
		[42950] = 20, -- Dragon's Breath
	},
	["PALADIN"] = {
		[10308] = 40,  -- Hammer of Justice
		[1044] = 25,   -- Hand of Freedom
		[54428] = 60,  -- Divine Plea
		[6940] = 120,  -- Hand of Sacrifice
		[10278] = 180, -- Hand of Protection
		[642] = 300,   -- Divine Shield
		[31821] = 120, -- Aura Mastery
		[66008] = 60,  -- Repentance
		[64205] = 120, -- Divine Sacrifice
		[48825] = 5,   -- Holy Shock
		[48827] = 30,  -- Avenger's Shield
	},
	["PRIEST"] = {
		[10890] = 27,  -- Psychic Scream
		[48158] = 12,  -- Shadow World: Death
		[47585] = 75, -- Dispersion
		[33206] = 144, -- Pain Suppression
		[15487] = 45, -- Silence 
		[64044] = 120, -- Psychic Horror
		[34433] = 300, -- Shadowfiend
		[6346] = 180, -- Fear Ward
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
		[36554] = 20, -- Shadowstep
	},
	["SHAMAN"] = {
		[57994] = 6,   -- Wind Shear
		[51514] = 45,  -- Hex
		[16188] = 120, -- Nature's Swiftness
		[8177] = 15,   -- Grounding Totem
		[51490] = 35, -- Thunderstorm (45s - 10s glyph)
		[30823] = 60, -- Shamanistic Rage
		[16166] = 180, -- Elemental Mastery
	},
	["WARLOCK"] = {
		[19647] = 24,  -- Spell Lock
		[17925] = 120, -- Death Coil
		[18708] = 180, -- Fel Domination
		[48011] = 8,   -- Devour Magic
		[48020] = 30,  -- Demonic Circle: Teleport
		[47847] = 20,  -- Shadowfury
		[18708] = 180, -- Fel Domination
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
		[12809] = 30,  -- Concussion Blow
		[46968] = 17,  -- Shockwave
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
		[49203] = 60,  -- Hungering Cold
		[51271] = 60,  -- Unbreakable Armor
		[48792] = 120, -- Icebound Fortitude
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
	},
	["Items"] = {
		[71607] = 120, -- Release of Light (Bauble)
	}
}

local itemForSpell = {
	[GetSpellInfo(71607)] = GetItemInfo(50354), -- Bauble of True Blood
}

local iconPaths = {}
for k in pairs(iconPaths) do _iconPaths[GetSpellInfo(k)] = select(3,GetSpellInfo(k)) end
iconPaths[GetSpellInfo(71607)] = "Interface\\Icons\\inv_jewelcrafting_gem_28"
iconPaths[GetSpellInfo(42292)] = "Interface\\Icons\\Inv_jewelry_trinketpvp_02"


-- V: added a "fillwith" parameter to fill the generated tables with a single value.
--    "not pretty, but it works"
local function convertspellids(t, fillwith)
	local temp = {}
	for class,table in pairs(t) do
		temp[class] = {}
		for k,v in pairs(table) do
			local spellName, _, spellIcon = GetSpellInfo(k)
			if not iconPaths[spellName] then
				iconPaths[spellName] = spellIcon
			end
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
		[1766] = 10, -- Kick
		[51722] = 60,-- Dismantle
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
		[49012] = 1, -- Wyvern Sting
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
			if db.movable then
				anchors[k]:SetPoint("TOPLEFT", UIParent,"TOPLEFT", x/scale, y/scale)
			else
				anchors[k]:SetPoint("TOPLEFT", "PartyMemberFrame"..k,"TOPLEFT", db.xanchor, db.yanchor)
			end
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

function PAB:ResetAnchorsSpecAndItems()
	for i = 1, #anchors do
		anchors[i].spec = nil
		anchors[i].items = nil
	end
end

-- Utils
local function array_contains(tab, val)
	-- V: no value given
	if not tab then return false end

    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function PAB:UpdateAnchors(updateIcons)
	for i=1,GetNumPartyMembers() do
		local unitName = "party"..i
		local _,class = UnitClass(unitName)
		if not class then return end
		local anchor = anchors[i]
		anchor.GUID = UnitGUID(unitName)
		anchor.class = select(2,UnitClass(unitName))
		-- uses races as well as classes, no unique combinations of class+race like "Nightelf Priest" possible tho
		anchor.race = select(2,UnitRace(unitName))
		if updateIcons then
			for i = 1, #anchor.icons do
				anchor.icons[i]:Hide()
				anchor.icons[i]:SetParent(nim)
				anchor.icons[i]:ClearAllPoints()
			end
			anchor.icons = {}
		end
		local numIcons = 1
		for ability,cooldown in pairs(db.abilities[anchor.race]) do
			local enabled = db.enabledCooldowns[anchor.race]
			if enabled then
				self:UpdateAnchorIcon(anchor, numIcons, ability, cooldown)
				numIcons = numIcons + 1
			end
		end
		if anchor.items then
			for ability,cooldown in pairs(db.abilities["Items"]) do
				local itemName = itemForSpell[ability]
				local enabled = db.enabledCooldowns["Items"][ability]
				if enabled and array_contains(anchor.items, itemName) then
					self:UpdateAnchorIcon(anchor, numIcons, ability, cooldown)
					numIcons = numIcons + 1
				end
			end
		end
		local specSpells = specAbilities[anchor.class]
		for ability,cooldown in pairs(db.abilities[class]) do
			-- if it's not a talent, or we have the talent
			local enabled = db.enabledCooldowns[class][ability]
			if enabled and (not specSpells[ability] or anchor.spec and anchor.spec[ability]) then
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
	
	if db.lock or not db.movable then PABAnchor:Hide() else PABAnchor:Show() end
end

function PAB:UPDATE_BATTLEFIELD_STATUS(idx)
	if idx ~= 1 then return end -- only for arenas

	local status = GetBattlefieldStatus(idx)
	if status == "active" then
		self:UpdateAnchors(false)
		self:ResetAnchorsSpecAndItems()
	end
end

function PAB:PARTY_MEMBERS_CHANGED()
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	inspectData = {}
	self:UpdateAnchors(false)
	self:ResetAnchorsSpecAndItems()
end

function PAB:PLAYER_ENTERING_WORLD()
	if InArena() then
		-- Cooldowns reset when joining arena
		self:StopAllIcons()
		-- V: reset spec info
		inspectData = {}
	end
	if not pGUID then pGUID = UnitGUID("player") end
	if not pName then pName = UnitName("player") end
	self:UpdateAnchors(false)
	self:ResetAnchorsSpecAndItems()
end

function PAB:CheckAbility(anchor,ability,cooldown,pIndex)
	if not cooldown then return end
	for k,icon in ipairs(anchor.icons) do
		-- Direct cooldown
		if icon.ability == ability and icon.shouldShow then icon.Start(cooldown) end
		-- Grouped Cooldowns
		if groupedCooldowns[anchor.class] and groupedCooldowns[anchor.class][ability] then
			for k in pairs(groupedCooldowns[anchor.class]) do
				if k == icon.ability and icon.shouldShow then icon.Start(cooldown) break end
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
                if icon.timeleft <= 0 then
                    if db.hidden then icon:Hide() end
                    if icon.GUID and icon.ability and activeGUIDS[icon.GUID] then
                      activeGUIDS[icon.GUID][icon.ability] = nil
                    end
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

	-- Maybe query spec info (throttled)
	PAB:QuerySpecInfo(elapsed)
end

local inspectData = {
	frame = nil,
	current = nil,
	throttle = 0,
	lastQuery = nil
}

-- V: function called every tick that tries to query spec info
function PAB:QuerySpecInfo(elapsed)
	inspectData.throttle = inspectData.throttle + elapsed

	-- timeout check
	if inspectData.lastQuery then
		inspectData.lastQuery = inspectData.lastQuery + elapsed
		if inspectData.lastQuery > 10 then -- we've been waiting for 10s... give up
			inspectData.current = nil
			inspectData.lastQuery = nil
		end
	end

	-- throttle
	if inspectData.throttle < 0.5 then return end
	inspectData.throttle = 0

	-- are we fighting
	if InCombatLockdown() then return end
	-- if we're currently awaiting an INSPECT_TALENT_READY
	if inspectData.current then return end
	-- are we dead
	if UnitIsDead("player") then return end
	-- is the player inspecting
	if InspectFrame and InspectFrame:IsShown() then return end

	if not inspectData.frame then
		inspectData.frame = CreateFrame("Frame")
		inspectData.frame:SetScript("OnEvent", function (self, event, ...)
			-- are we fighting
			if InCombatLockdown() then return end
			-- is the player inspecting
			if InspectFrame and InspectFrame:IsShown() then return end

			if not inspectData.current then return end
			local anchor = anchors[inspectData.current]
			if not anchor or not anchor.class then
				-- anchor not yet created
				inspectData.current = nil
				return
			end

			local specSpells = specAbilities[anchor.class]
			if specSpells then
				anchor.spec = {}
				-- V: foundATalent is useful to circumvent a bug where we inspect
				--    someone before their talents loaded
				local foundATalent = false
				for ability, spell in pairs(specSpells) do
					local hasTalent = select(5,
						GetTalentInfo(spell.talentGroup, spell.index, true, false, GetActiveTalentGroup(true))
					) > 0
					foundATalent = foundATalent or hasTalent
					anchor.spec[ability] = hasTalent
				end
				-- V: we found no talent, that's weird. Let's remove anchor.spec so we inspect them again
				if not foundATalent then
					anchor.spec = nil
				end
			end

			anchor.items = {}
--			for itemSlot = 1, 18 do -- ignore tabard + bags
			for itemSlot = 13, 14 do -- ignore tabard + bags
				local itemID = GetInventoryItemLink("party"..inspectData.current, itemSlot)
				if itemID then
					anchor.items[itemSlot] = GetItemInfo(itemID)
				end
			end

			PAB:UpdateAnchors(true)
			ClearInspectPlayer()
			inspectData.current = nil
		end)
		inspectData.frame:RegisterEvent("INSPECT_TALENT_READY")
	end

	for i=1, GetNumPartyMembers() do
		local anchor = anchors[i]
		if not anchor then return end
		if (not anchor.spec or not anchor.items) and (CanInspect("party"..i) and UnitIsConnected("party"..i)) then
			inspectData.current = i
			inspectData.lastQuery = 0
			NotifyInspect("party"..i)
			break
		end
	end
end

function PAB:UNIT_INVENTORY_CHANGED(unit)
	if unit == "player" then return end
	local pIndex = match(unit,"party[pet]*([1-4])")

	if pIndex then
		pIndex = tonumber(pIndex)
		if not anchors[pIndex] then return end -- Should not happen
		local anchor = anchors[pIndex]

		anchor.items = nil
	end
end

function PAB:UNIT_SPELLCAST_SUCCEEDED(unit,ability)
	if unit == "player" then return end
	local pIndex = match(unit,"party[pet]*([1-4])")

	-- XXX this only supports the english client (supposedly)
	if pIndex then
		pIndex = tonumber(pIndex)
		local actualUnit = "party"..pIndex -- don't query pet
		if ability == "Activate Primary Spec" or ability == "Activate Secondary Spec" then
			if not anchors[pIndex] then return end -- Should not happen
			local anchor = anchors[pIndex]

			anchor.spec = nil
			return
		end

		if ability then
			local _,class = UnitClass(actualUnit)
			local _,race = UnitRace(actualUnit)
			local cooldown = db.abilities[class][ability] or db.abilities[race][ability] or db.abilities["Items"][ability]
			self:CheckAbility(anchors[pIndex],ability,cooldown,pIndex) 
		end
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
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:SetScript("OnEvent",function(self,event,...) if self[event] then self[event](self,...) end end)
	
	PABDB = PABDB or {
		scale = 0.9,
		lock = true,
		arena = false,
		hidden = true,
		iconsperline = 0,
		xanchor = -88,
		yanchor = 17,
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
	PABDB.abilities = defaultAbilities -- V: always keep ALL the abilities
	
	-- V: upgrade path #1
	if not PABDB.enabledCooldowns["Items"] then
		PABDB.enabledCooldowns["Items"] = enabledCooldowns["Items"]
	end
	

	PABDB.xanchor = PABDB.xanchor or -88
	PABDB.yanchor = PABDB.yanchor or 17
	db = PABDB

	self:CreateAnchors()
	self:UpdateAnchors(false)
	self:LoadPositions()
	self:CreateOptions()
	
	self:SetScript("OnUpdate",PAB_OnUpdate)
	
	--print("Party Ability Bars by Kollektiv. Enhancements by Lawz and Vendethiel. Type /pab to open options")
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
		'minText', '0.5',
		'maxText', '2',
		'minValue', 0.5,
		'maxValue', 2,
		'step', 0.01,
		'default', 1,
		'current', db.scale,
		'setFunc', function(value) db.scale = value; PAB:ApplyAnchorSettings() end,
		'currentTextFunc', function(value) return string.format("%.2f",value) end)
	scale:SetPoint("TOPLEFT",subText,"TOPLEFT",16,-32)

	local arena = panel:MakeToggle(
	     'name', 'Arena',
	     'description', 'Show in arena only',
	     'default', false,
	     'getFunc', function() return db.arena end,
	     'setFunc', function(value) db.arena = value; PAB:ApplyAnchorSettings() end)
	arena:SetPoint("TOP",panel,"TOP",10,-36)
	
	local hidden = panel:MakeToggle(
	    'name', 'Hidden',
	    'description', 'Show icon only when on cooldown',
	    'default', false,
	    'getFunc', function() return db.hidden end,
	    'setFunc', function(value) db.hidden = value; PAB:ApplyAnchorSettings() end)
	hidden:SetPoint("LEFT",arena,"RIGHT",50,0)

	local ApplyMovableFunction
	local movable = panel:MakeToggle(
	    'name', 'Movable',
	    'description', 'Movable anchors',
	    'default', false,
	    'getFunc', function() return db.movable end,
	    'setFunc', function(value)
	    	db.movable = value
	    	ApplyMovableFunction()
	    	PAB:ApplyAnchorSettings()
	    	PAB:LoadPositions()
	    end)
	movable:SetPoint("TOPLEFT",arena,"BOTTOMLEFT",0,-5)

	local lock = panel:MakeToggle(
	     'name', 'Lock',
	     'description', 'Show/hide anchors',
	     'default', false,
	     'getFunc', function() return db.lock end,
	     'setFunc', function(value) db.lock = value; PAB:ApplyAnchorSettings() end)	     
	lock:SetPoint("LEFT",movable,"RIGHT",50,0)

	local iconsperline = panel:MakeSlider(
		'name', 'Icons per line (0 = all)',
		'description', 'Adjust x anchor',
		'minText', '0',
		'maxText', '10',
		'minValue', 0,
		'maxValue', 10,
		'step', 	1,
		'default', 	0,
		'current', db.iconsperline,
		'setFunc', function(value) db.iconsperline = value; PAB:UpdateAnchors(true) end,
		'currentTextFunc', function(value) return string.format("%d",value) end)
	iconsperline:SetPoint("TOPLEFT", movable, "BOTTOMLEFT", 0, -20)
		
	local xanchor = panel:MakeSlider(
		'name', 'x anchor',
		'description', 'Adjust x anchor',
		'minText', '-100',
		'maxText', '100',
		'minValue', -100,
		'maxValue', 100,
		'step', 	1,
		'default', 	0,
		'current', db.xanchor,
		'setFunc', function(value) db.xanchor = value; PAB:LoadPositions(true) end,
		'currentTextFunc', function(value) return string.format("%d",value) end)
	xanchor:SetPoint("TOPLEFT", iconsperline, "BOTTOMLEFT", 0, -30)
	
	local yanchor = panel:MakeSlider(
		'name', 'y anchor',
		'description', 'Adjust x anchor',
		'minText', '-100',
		'maxText', '100',
		'minValue', -100,
		'maxValue', 100,
		'step', 	1,
		'default', 	0,
		'current', db.yanchor,
		'setFunc', function(value) db.yanchor = value; PAB:LoadPositions(true) end,
		'currentTextFunc', function(value) return string.format("%d",value) end)
	yanchor:SetPoint("TOPLEFT", xanchor, "BOTTOMLEFT", 0, -30)

	-- V: when "movable gets toggled"
	ApplyMovableFunction = function()
		if db.movable then
			lock:Show()

			xanchor:Hide()
			yanchor:Hide()
		else
			lock:Hide()

			xanchor:Show()
			yanchor:Show()
		end
	end

	ApplyMovableFunction()

	local title2, subText2 = panel:MakeTitleTextAndSubText("Ability editor","Abilities tracked :")
	title2:ClearAllPoints()
	title2:SetPoint("LEFT",panel,"LEFT",16,100)
	subText2:ClearAllPoints()
	subText2:SetPoint("TOPLEFT",title2,"BOTTOMLEFT",25,-8)
	
	self:CreateAbilityEditor()

end

local function count(t) local i = 0 for k,v in pairs(t) do i = i + 1 end return i end

-- V: can't add it to LibSimpleOptions if other addons use it... zzzzz
local function GetToggleText(button)
	return _G[button:GetName().."Text"]
end

local SHOW_BUTTONS = 8
local BUTTON_HEIGHT = 16
function PAB:UpdateScrollBar()
	local btns = self.btns
	-- V: the ability store helps us map which ability we want to enable/disable
	self.abilityStore = {}
	local checkboxes = self.abilityCheckboxes
	local scrollframe = self.scrollframe
	local classSelectedTable = db.abilities[db.classSelected]
	local classSelectedTableLength = count(db.abilities[db.classSelected])
	-- V: PAB never *actually* implemented the FauxScrollFrame. Let's do it...
	FauxScrollFrame_Update(scrollframe,classSelectedTableLength,SHOW_BUTTONS,BUTTON_HEIGHT,nil,nil,nil,nil,nil,nil,true)
	local offset = FauxScrollFrame_GetOffset(scrollframe)
	local i = 1 -- track where we are
	for ability,cooldown in pairs(classSelectedTable) do
		if i > offset and (i - offset) <= SHOW_BUTTONS then
			btns[i - offset]:Show()
			
			-- V: check if we have it enabled...
			if not db.enabledCooldowns[db.classSelected] then
				db.enabledCooldowns[db.classSelected] = {}
			end

			local checked = db.enabledCooldowns[db.classSelected][ability]
			btns[i - offset]:SetChecked(checked)

			local text = GetToggleText(btns[i - offset])
			self.abilityStore[i - offset] = ability
			text:SetText(itemForSpell[ability]or ability)
		end
		i = i + 1
	end
	-- V: hide the other buttons
	for hideI = i - offset, SHOW_BUTTONS do
		btns[hideI]:Hide()
	end
end

function PAB:CreateAbilityEditor()
	-- V: default out
	db.classSelected = db.classSelected or "WARRIOR"

	local panel = self.panel
	local btns = {}
	self.btns = btns
	local scrollframe = CreateFrame("ScrollFrame", "PABScrollFrame",panel,"FauxScrollFrameTemplate")
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
	-- V: use a constant
	for i=1,SHOW_BUTTONS do
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
	scrollframe:SetPoint('LEFT',5,-60)
	scrollframe:SetBackdrop(backdrop)
	scrollframe:SetBackdropColor(.6,.6,.6,0.25)
	scrollframe:SetScript("OnVerticalScroll", function(self,offset)
		FauxScrollFrame_OnVerticalScroll(scrollframe, offset, BUTTON_HEIGHT, function (_) -- ignore self argument
			PAB:UpdateScrollBar()
		end)
	end)
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
			"Items","Items"
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
	dropdown:SetPoint("LEFT",scrollframe,"RIGHT",20, 0)
end

PAB:RegisterEvent("VARIABLES_LOADED")
PAB:SetScript("OnEvent",PAB_OnLoad)
