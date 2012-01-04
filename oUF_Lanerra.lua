--[[
    Copyright © 2010-2011 Lanerra. See LICENSE file for license terms.
    
	Special thanks to P3lim for inspiration, Neav for textures and inspiration,
    Game92 for inspiration, and Phanx for inspiration and an inline border method
--]]

---- Lazy Stuff Goes Here!

-- Disable Blizzard options that are rendered useless by having a unit frame addon

for _, button in pairs({
    'UnitFramePanelPartyBackground',
    'UnitFramePanelPartyPets',
	'UnitFramePanelFullSizeFocusFrame',

    'CombatPanelTargetOfTarget',
    'CombatPanelTOTDropDown',
    'CombatPanelTOTDropDownButton',
    'CombatPanelEnemyCastBarsOnPortrait',

    'DisplayPanelShowAggroPercentage',

    'FrameCategoriesButton9',
}) do
    _G['InterfaceOptions'..button]:SetAlpha(0.35)
    _G['InterfaceOptions'..button]:Disable()
    _G['InterfaceOptions'..button]:EnableMouse(false)
end

do 
    for k, v in pairs(UnitPopupMenus) do
        for x, i in pairs(UnitPopupMenus[k]) do
            if (i == 'SET_FOCUS' or i == 'CLEAR_FOCUS') then
                table.remove(UnitPopupMenus[k],x)
            end
        end
    end
end

-------------------------------------------------
-- Variables for defining colors and appearance
-------------------------------------------------


local colors = oUF.colors

local playerClass = select(2, UnitClass('player'))
local isHealer = (playerClass == 'DRUID' or playerClass == 'PALADIN' or playerClass == 'PRIEST' or playerClass == 'SHAMAN')

-- A little backdrop local to save us some typing...because I'm lazy
local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local PlayerUnits = { player = true, pet = true, vehicle = true }

-- Dummy function
local noop = function() return end

fontstrings = { }

-- Custom power colors
local PowerBarColor = PowerBarColor

PowerBarColor['MANA'] = { r = 0/255, g = 0.55, b = 1 }
PowerBarColor['RAGE'] = { r = 240/255, g = 45/255, b = 75/255 }
PowerBarColor['FOCUS'] = { r = 255/255, g = 175/255, b = 0 }
PowerBarColor['ENERGY'] = { r = 1, g = 1, b = 35/255 }
PowerBarColor['RUNIC_POWER'] = { r = 0.45, g = 0.85, b = 1 }

-- Threat color handling
oUF.colors.threat = { }
for i = 1, 3 do
	local r, g, b = GetThreatStatusColor(i)
	oUF.colors.threat[i] = { r, g, b }
end

-- Debuff color handling
colors.Debuff = { }
for type, color in pairs(DebuffTypeColor) do
	if (type ~= 'none') then
		colors.Debuff[type] = { color.r, color.g, color.b }
	end
end

-- Color conversion function
function hex(r, g, b)
	if(type(r) == 'table') then
		if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

---- No More Lazy Stuff!

-- Border update function
local function UpdateBorder(self)
	local Threat, Debuff, Dispellable = self.threatLevel, self.debuffType, self.debuffDispellable

	local color
	if Debuff and Dispellable then
		color = colors.Debuff[Debuff]
    elseif Debuff and Threat then
        color = colors.Debuff[Debuff]
    elseif Threat and Threat > 1 then
        color = colors.threat[Threat]
	elseif Debuff then
		color = colors.Debuff[Debuff]
    elseif Threat and Threat > 0 then
        color = colors.threat[Threat]
    end
    
    
	if color then
		self:SetBackdropBorderColor(color[1], color[2], color[3], 1)
	else
		self:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

-- Formatting function for the display of health and power text
local function ShortValue(value)
	if value >= 1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e5 then
		return ('%.0fk'):format(value / 1e3)
	elseif value >= 1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

------------------------------------------
-- Functions used to build Unit Frames
------------------------------------------


-- Build dropdown menus
local dropdown = CreateFrame('Frame', 'oUF_LanerraDropDown', UIParent, 'UIDropDownMenuTemplate')

UIDropDownMenu_Initialize(dropdown, function(self)
	local unit = self:GetParent().unit
	if not unit then return end

	local menu, name, id
	if UnitIsUnit(unit, 'player') then
		menu = 'SELF'
	elseif UnitIsUnit(unit, 'vehicle') then
		menu = 'VEHICLE'
	elseif UnitIsUnit(unit, 'pet') then
		menu = 'PET'
	elseif UnitIsPlayer(unit) then
		id = UnitInRaid(unit)
		if id then
			menu = 'RAID_PLAYER'
			name = GetRaidRosterInfo(id)
		elseif UnitInParty(unit) then
			menu = 'PARTY'
		else
			menu = 'PLAYER'
		end
	else
		menu = 'TARGET'
		name = RAID_TARGET_ICON
	end
	if menu then
		UnitPopup_ShowMenu(self, menu, unit, name, id)
	end
end, 'MENU')

local function CreateDropDown(self)
	dropdown:SetParent(self)
    ToggleDropDownMenu(1, nil, dropdown, 'cursor', 15, -15)
end

local Interrupt = 'Interface\\Addons\\oUF_Lanerra\\Media\\BorderInterrupt'
local Normal = 'Interface\\Addons\\oUF_Lanerra\\Media\\BorderNormal'

local function PostCastStart(Castbar, unit)
    self.Castbar.SafeZone:SetDrawLayer('BORDER')
    self.Castbar.SafeZone:ClearAllPoints()
    self.Castbar.SafeZone:SetPoint('TOPRIGHT', self.Castbar)
    self.Castbar.SafeZone:SetPoint('BOTTOMRIGHT', self.Castbar)
    
    if (unit == 'target') then
        if (self.Castbar.interrupt) then
            self.Castbar.Border:SetBorderTexture(Interrupt)
            print('Changed the border, chief!')
            self.Castbar.Border:SetBorderColor(1, 0, 1)
            self.Castbar.Border:SetBorderShadowColor(1, 0, 1)
        else
            self.Castbar.Border:SetBorderTexture(Normal)
            self.Castbar.Border:SetBorderColor(1, 1, 1)
            self.Castbar.Border:SetBorderShadowColor(0, 0, 0)
        end
    end
end

local function PostChannelStart(Castbar, unit)
    self.Castbar.SafeZone:SetDrawLayer('ARTWORK')
    self.Castbar.SafeZone:ClearAllPoints()
    self.Castbar.SafeZone:SetPoint('TOPLEFT', self.Castbar)
    self.Castbar.SafeZone:SetPoint('BOTTOMLEFT', self.Castbar)
    
    if (unit == 'target') then
        if (self.interrupt) then
            self.Castbar.Border:SetBorderTexture(Interrupt)
            self.Castbar.Border:SetBorderColor(1, 0, 1)
            self.Castbar.Border:SetBorderShadowColor(1, 0, 1)
        else
            self.Castbar.Border:SetBorderTexture(Normal)
            self.Castbar.Border:SetBorderColor(1, 1, 1)
            self.Castbar.Border:SetBorderShadowColor(0, 0, 0)
        end
    end
end

-- Health update function of doom!
local UpdateHealth = function(Health, unit, min, max)
    if (Health:GetParent().unit ~= unit) then
        return
	end
    
	if (not unit == 'pet' or unit == 'focus' or unit == 'targettarget' or unit == 'player') then
		if (UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit)) then
            Health:SetValue(0)
            Health:SetStatusBarColor(.5, .5, .5)
        end
	end
	
	if (unit == 'player') then
		if (Settings.Units.Player.Health.Percent) then
			Health.Value:SetText((min / max * 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.Player.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.Player.Health.Current) then
			Health.Value:SetText((min ~= max) and format('%d', min) or '')
		else
			Health.Value:SetText()
		end
	elseif (unit == 'target') then
		if (Settings.Units.Target.Health.Percent) then
			Health.Value:SetText((min / max * 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.Target.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.Target.Health.Current) then
			Health.Value:SetText(ShortValue(min))
		elseif (Settings.Units.Target.Health.PerCur) then
            Health.Value:SetText((min/max * 100 and format('%s - %d%%', ShortValue(min), min/max * 100)))
        else
			Health.Value:SetText()
		end
	elseif (unit == 'targettarget') then
		if (Settings.Units.ToT.Health.Percent) then
			Health.Value:SetText((min / max * 100 < 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.ToT.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.ToT.Health.Current) then
			Health.Value:SetText((min ~= max) and format('%d', min) or '')
		else
			Health.Value:SetText()
		end
	elseif (unit == 'pet') then
		if (Settings.Units.Pet.Health.Percent) then
			Health.Value:SetText((min / max * 100 < 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.Pet.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.Pet.Health.Current) then
			Health.Value:SetText((min ~= max) and format('%d', min) or '')
		else
			Health.Value:SetText()
		end
	elseif (unit == 'focus') then
		if (Settings.Units.Focus.Health.Percent) then
			Health.Value:SetText((min / max * 100 < 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.Focus.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.Focus.Health.Current) then
			Health.Value:SetText((min ~= max) and format('%d', min) or '')
		else
			Health.Value:SetText()
		end
	end
	
	-- Bar Color Stuff
	Health:SetStatusBarColor(.25, .25, .25)
end

-- Group update health function
local function UpdateGroupHealth(Health, unit, min, max)
	if (Health:GetParent().unit ~= unit) then
		return
	end
	
	if (UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit)) then
        Health:SetValue(0)
        Health:SetStatusBarColor(.5, .5, .5)
    end

    if (Settings.Units.Party.Health.Percent) then
        Health.Value:SetText((min / max * 100 < 100 and format('%d%%', min / max * 100)) or '')
    elseif (Settings.Units.Party.Health.Deficit) then
        Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
    elseif (Settings.Units.Party.Health.Current) then
        Health.Value:SetText((min ~= max) and format('%d', min) or '')
    else
        Health.Value:SetText()
    end
    
    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
    if (Settings.Units.Party.Health.ClassColor) then
        Health.colorClass = true
    else
        Health:SetStatusBarColor(.25, .25, .25)
    end
end

-- Raid update health function
local function UpdateRaidHealth(Health, unit, min, max)
	if (Health:GetParent().unit ~= unit) then
		return
	end
	
	if (UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit)) then
		Health:SetValue(0)
        Health:SetStatusBarColor(.5, .5, .5)
	else
		if (Settings.Units.Raid.Health.Percent) then
			Health.Value:SetText((min / max * 100 and format('%d%%', min / max * 100)) or '')
		elseif (Settings.Units.Raid.Health.Deficit) then
			Health.Value:SetText((min ~= max) and format('%d', min - max) or '')
		elseif (Settings.Units.Raid.Health.Current) then
			Health.Value:SetText((min ~= max) and format('%d', min) or '')
		else
			Health.Value:SetText()
		end
		
		local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
		if (Settings.Units.Raid.Health.ClassColor) then
			Health.colorClass = true
		else
			Health:SetStatusBarColor(.25, .25, .25)
		end
	end
end

-- Custom Power Updating Function
local function UpdatePower(Power, unit, min, max)
    local self = Power:GetParent()

	local _, PowerType, altR, altG, altB = UnitPowerType(unit)
	local UnitPower = PowerBarColor[PowerType]

    if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
        Power:SetValue(0)
        Power.Value:SetText('')
    elseif (unit == 'player' and Settings.Units.Player.ShowPowerText or unit == 'target' and Settings.Units.Target.ShowPowerText) then
        if (unit == 'target' and max == 0) then
            Power.Value:SetText('')
        else
            Power.Value:SetText((min/max * 100 and format('%d%%', min/max * 100)))
        end
    else
        Power.Value:SetText()
    end

    if (UnitPower) then
        Power.Value:SetTextColor(UnitPower.r, UnitPower.g, UnitPower.b)
	else
        Power.Value:SetTextColor(altR, altG, altB)
	end
end

-- Add DruidPower support
local function UpdateDruidPower(self, event, unit)
    if (unit and unit ~= self.unit) then 
        return 
    end
    
	local unitPower = PowerBarColor['MANA']
    local mana = UnitPowerType('player') == 0
    local index = GetShapeshiftForm()

    if (index == 1 or index == 3) then
        if (unitPower) then
            self.Druid.Power:SetStatusBarColor(unitPower.r, unitPower.g, unitPower.b)
        end
        
        self.Druid.Power:SetAlpha(1)

        local min, max = UnitPower('player', 0), UnitPowerMax('player', 0)

        self.Druid.Power:SetMinMaxValues(0, max)
        self.Druid.Power:SetValue(min)
    else
        self.Druid.Power:SetAlpha(0)
    end
end

-- Aura Icons for our unit frames
-- Aura Icon Show
local AuraIconCD_OnShow = function(cd)
	local button = cd:GetParent()
	button:SetBorderParent(cd)
	button.count:SetParent(cd)
end

-- Aura Icon Hide
local AuraIconCD_OnHide = function(cd)
	local button = cd:GetParent()
	button:SetBorderParent(button)
	button.count:SetParent(button)
end
-- Aura Icon Overlay
local AuraIconOverlay_SetBorderColor = function(overlay, r, g, b)
	if not r or not g or not b then
		r, g, b = unpack(Settings.Media.BorderColor)
	end
	overlay:GetParent():SetBorderColor(r, g, b)
end

-- Aura Icon Creation Function
local function PostCreateAuraIcon(iconframe, button)
	AddBorder(button, Settings.Media.BorderSize, Settings.Media.BorderPadding)

	button.cd:SetReverse(true)
	button.cd:SetScript('OnHide', AuraIconCD_OnHide)
	button.cd:SetScript('OnShow', AuraIconCD_OnShow)
	if button.cd:IsShown() then
        AuraIconCD_OnShow(button.cd)
    end
    
	button.icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)

	button.overlay:Hide()
	button.overlay.Hide = AuraIconOverlay_SetBorderColor
	button.overlay.SetVertexColor = AuraIconOverlay_SetBorderColor
	button.overlay.Show = noop
end

-- Aura Icon Update Function
local function PostUpdateAuraIcon(iconframe, unit, button, index, offset)
	local name, _, texture, count, type, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, button.filter)

	if PlayerUnits[caster] then
		button.icon:SetDesaturated(false)
	else
		button.icon:SetDesaturated(true)
	end

	if button.timer then return end

	if OmniCC then
		for i = 1, button:GetNumChildren() do
			local child = select(i, button:GetChildren())
			if child.text and (child.icon == button.icon or child.cooldown == button.cd) then
				-- found it!
				child.SetAlpha = noop
				child.SetScale = noop

				child.text:ClearAllPoints()
				child.text:SetPoint('CENTER', button, 'TOP', 0, 2)

				child.text:SetFont(Settings.Media.Font, unit:match('^party') and 14 or 18)
				child.text.SetFont = noop

				child.text:SetTextColor(1, 0.8, 0)
                child.text:SetShadowOffset(1, -1)
				child.text.SetTextColor = noop
				child.text.SetVertexColor = noop

				tinsert(fontstrings, child.text)

				button.timer = child.text

				return
			end
		end
	else
		button.timer = true
	end
end

-- Dispel highlighting function
local function UpdateDispelHighlight(self, event, unit, debuffType, canDispel)
	if (self.unit ~= unit) then
        return
    end
    
	if (self.debuffType == debuffType) then
        return
    end

	self.debuffType = debuffType
	self.debuffDispellable = canDispel
    
    self:UpdateBorder()
end

-- Threat highlighting function
local function UpdateThreatHighlight(self, unit, status)
	if self.threatLevel == status then return end

	self.threatLevel = status
	self:UpdateBorder()
end

-- Time to give our solo unit frames some style!
local Stylish = function(self, unit, isSingle)
	self.menu = CreateDropDown
    
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    
	self.ignoreHealComm = true
	
	self:EnableMouse(true)
	self:RegisterForClicks('AnyUp')
	
    -- Health Bar-specific stylings
	self.Health = CreateFrame('StatusBar', '$parentHealthBar', self)
	self.Health:SetHeight(Settings.Units.Player.Height * .75)
	self.Health:SetStatusBarTexture(Settings.Media.StatusBar)
	
	-- Turn on the smoothness
	self.Health.Smooth = true
	
	self.Health.frequentUpdates = 0.2
	
	self.Health:SetParent(self)
	self.Health:SetPoint('TOP')
	self.Health:SetPoint('LEFT')
	self.Health:SetPoint('RIGHT')
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(unpack(Settings.Media.BackdropColor))
	
	if (unit == 'player') then
		local info = self.Health:CreateFontString('$parentInfo', 'OVERLAY', 'GameFontHighlightSmall')
		info:SetPoint('CENTER', self.Health)
		info.frequentUpdates = .25
		self:Tag(info, '[LanThreat] |cffff0000[LanPvPTime]|r')
	end
	
	-- Setup our health text
	self.Health.Value = self.Health:CreateFontString('$parentHealthValue', 'OVERLAY')
	self.Health.Value:SetFont(Settings.Media.Font, Settings.Media.FontSize)
	self.Health.Value:SetShadowOffset(1, -1)
	self.Health.Value:SetTextColor(1, 1, 1)
	
	self.Health.PostUpdate = UpdateHealth
	
	-- And now for the power bar and text stuff
	self.Power = CreateFrame('StatusBar', '$parentPowerBar', self)
	self.Power:SetHeight(Settings.Units.Player.Height * .22)
	self.Power:SetStatusBarTexture(Settings.Media.StatusBar)
    
	self.Power.colorClass = true
	self.Power.colorTapping = true
    self.Power.colorReaction = true
    	
	-- We like to keep things smooth around here
    self.Power.frequentUpdates = 0.2
    self.Power.Smooth = true
    	
	self.Power:SetParent(self)
	self.Power:SetPoint('BOTTOM')
	self.Power:SetPoint('LEFT', .2, 0)
	self.Power:SetPoint('RIGHT', -.2, 0)
	
	-- Now, the power bar's text
	self.Power.Value = self.Power:CreateFontString('$parentPowerValue', 'OVERLAY')
	self.Power.Value:SetFont(Settings.Media.Font, Settings.Media.FontSize)
	self.Power.Value:SetShadowOffset(1, -1)
    if (unit == 'target') then
        self.Power.Value:SetPoint('TOPRIGHT', self.Power, 'BOTTOMRIGHT', 0, -5)
    elseif (unit == 'player') then
        self.Power.Value:SetPoint('LEFT', self.Health.Value, 'RIGHT', -195, 0)
    end
	
	self.Power.Value:SetTextColor(1, 1, 1)
    self.Power.Value:SetJustifyH('LEFT')
    self.Power.Value.frequentUpdates = 0.1
    
	if (unit == 'targettarget') then
		self.Power:Hide()
		self.Power.Show = self.Power.Hide
		self.Health:SetAllPoints(self)
	end
    
    if (unit == 'focus' and Settings.Units.Focus.VerticalHealth) then
		self.Power:Hide()
		self.Power.Show = self.Power.Hide
		self.Health:SetAllPoints(self)
		self.Health:SetOrientation('VERTICAL')
	else
		self.Health:SetOrientation('HORIZONTAL')
	end
	
    self.Power.PostUpdate = UpdatePower
    
    -- Improve border drawing
    self.Overlay = CreateFrame('Frame', nil, self)
	self.Overlay:SetAllPoints(self)
	self.Overlay:SetFrameLevel(self.Health:GetFrameLevel() + (self.Power and 3 or 2))
    
	-- Now, to hammer out our castbars
	if (Settings.Show.CastBars) then
        if (unit == 'player') then
			self.Castbar = CreateFrame('StatusBar', '$parentCastBar', self)
            self.Castbar:SetStatusBarTexture(Settings.Media.StatusBar)
			self.Castbar:SetScale(Settings.CastBars.Player.Scale)
			self.Castbar:SetStatusBarColor(unpack(Settings.CastBars.Player.Color))
            
            self.Castbar.Border = CreateFrame('Frame', nil, self.Castbar)
            self.Castbar.Border:SetAllPoints(self.Castbar)
            self.Castbar.Border:SetFrameLevel(self.Castbar:GetFrameLevel() + 2)
            
			AddBorder(self.Castbar.Border, Settings.Media.BorderSize, Settings.Media.BorderPadding)
			
			self.Castbar:SetHeight(Settings.CastBars.Player.Height)
			self.Castbar:SetWidth(Settings.CastBars.Player.Width)
			self.Castbar:SetParent(self)
			self.Castbar:SetPoint(unpack(Settings.CastBars.Player.Position))
			
			self.Castbar.Bg = self.Castbar:CreateTexture('$parentCastBarBackground', 'BACKGROUND')
			self.Castbar.Bg:SetAllPoints(self.Castbar)
			self.Castbar.Bg:SetTexture(Settings.Media.StatusBar)
			self.Castbar.Bg:SetVertexColor(.1, .1, .1, .7)
			
			self.Castbar.Text = self.Castbar:CreateFontString('$parentCastBarText', 'OVERLAY')
			self.Castbar.Text:SetFont(Settings.Media.Font, 13)
			self.Castbar.Text:SetShadowOffset(1, -1)
			self.Castbar.Text:SetPoint('LEFT', self.Castbar, 'LEFT', 2, 0)
			self.Castbar.Text:SetHeight(Settings.Media.FontSize)
			self.Castbar.Text:SetWidth(130)
			self.Castbar.Text:SetJustifyH('LEFT')
			self.Castbar.Text:SetParent(self.Castbar)
			self.Castbar.CustomTimeText = function(self, duration)
				self.Time:SetFormattedText('%.1f/%.1f', duration, self.max)
			end
			
			self.Castbar.Time = self.Castbar:CreateFontString('$parentCastBarTime', 'OVERLAY')
			self.Castbar.Time:SetFont(Settings.Media.Font, 13)
			self.Castbar.Time:SetShadowOffset(1, -1)
			self.Castbar.Time:SetPoint('RIGHT', self.Castbar, 'RIGHT', -2, 0)
			self.Castbar.Time:SetParent(self.Castbar)
			self.Castbar.Time:SetJustifyH('RIGHT')
			self.Castbar.CustomDelayText = function(self, duration)
				self.Time:SetFormattedText('[|cffff0000-%.1f|r] %.1f/%.1f', self.delay, duration, self.max)
			end
			
			self.Castbar.SafeZone = self.Castbar:CreateTexture('$parentCastBarSafeZone', 'OVERLAY')
			self.Castbar.SafeZone:SetTexture('Interface\\Buttons\\WHITE8x8')
			self.Castbar.SafeZone:SetVertexColor(1, .5, 0, .25)
            
			self.PostChannelStart = UpdateChannelStart
			self.PostCastStart = UpdateCastStart
		elseif (unit == 'target') then
			self.Castbar = CreateFrame('StatusBar', '$parentCastBar', self)
			self.Castbar:SetStatusBarTexture(Settings.Media.StatusBar)
			self.Castbar:SetStatusBarColor(unpack(Settings.CastBars.Target.Color))
			self.Castbar:SetWidth(Settings.CastBars.Target.Width)
			self.Castbar:SetScale(Settings.CastBars.Target.Scale)
			
            self.Castbar.Border = CreateFrame('Frame', nil, self.Castbar)
            self.Castbar.Border:SetAllPoints(self.Castbar)
            self.Castbar.Border:SetFrameLevel(self.Castbar:GetFrameLevel() + 2)
            
			AddBorder(self.Castbar.Border, Settings.Media.BorderSize, Settings.Media.BorderPadding)
			
			self.Castbar:SetHeight(Settings.CastBars.Target.Height)
			self.Castbar:SetParent(self)
			self.Castbar:SetPoint(unpack(Settings.CastBars.Target.Position))
			
			self.Castbar.Bg = self.Castbar:CreateTexture('$parentCastBarBackground', 'BORDER')
			self.Castbar.Bg:SetAllPoints(self.Castbar)
			self.Castbar.Bg:SetTexture(.1, .1, .1, .7)
			
			self.Castbar.Text = self.Castbar:CreateFontString('$parentCastBarText', 'OVERLAY')
			self.Castbar.Text:SetFont(Settings.Media.Font, 13)
			self.Castbar.Text:SetShadowOffset(1, -1)
			self.Castbar.Text:SetPoint('LEFT', self.Castbar, 'LEFT', 2, 0)
			self.Castbar.Text:SetHeight(Settings.Media.FontSize)
			self.Castbar.Text:SetWidth(130)
			self.Castbar.Text:SetJustifyH('LEFT')
			
			self.Castbar.Time = self.Castbar:CreateFontString('$parentCastBarTime', 'OVERLAY')
			self.Castbar.Time:SetFont(Settings.Media.Font, 13)
			self.Castbar.Time:SetShadowOffset(1, -1)
			self.Castbar.Time:SetPoint('RIGHT', self.Castbar, 'RIGHT', -2, 0)
			self.Castbar.CustomTimeText = function(self, duration)
				if (self.casting) then
					self.Time:SetFormattedText('%.1f', self.max - duration)
				elseif (self.channeling) then
					self.Time:SetFormattedText('%.1f', duration)
				end
			end
			
			self.PostChannelStart = PostChannelStart
			self.PostCastStart = PostCastStart
		end
	end
	
	-- Now to skin and setup our Mirror Timers
	for _, bar in pairs({
		'MirrorTimer1',
		'MirrorTimer2',
		'MirrorTimer3',
	}) do
		for i, region in pairs({_G[bar]:GetRegions()}) do
			if (region.GetTexture and region:GetTexture() == 'SolidTexture') then
				region:Hide()
			end
		end
		
        MirrorBorder = CreateFrame('Frame', nil, _G[bar])
        MirrorBorder:SetAllPoints(_G[bar])
        MirrorBorder:SetFrameLevel(_G[bar]:GetFrameLevel() + 2)
		AddBorder(MirrorBorder, Settings.Media.BorderSize, Settings.Media.BorderPadding)
		
		_G[bar..'Border']:Hide()
		
		_G[bar]:SetParent(UIParent)
		_G[bar]:SetScale(1.135)
		_G[bar]:SetHeight(18)
		_G[bar]:SetWidth(200)
		
		_G[bar..'Background'] = _G[bar]:CreateTexture(bar..'Background', 'BACKGROUND', _G[bar])
		_G[bar..'Background']:SetTexture('Interface\\Buttons\\WHITE8x8')
		_G[bar..'Background']:SetAllPoints(bar)
		_G[bar..'Background']:SetVertexColor(0, 0, 0, .5)
		
		_G[bar..'Text']:SetFont(CastingBarFrameText:GetFont(), 13)
		_G[bar..'Text']:ClearAllPoints()
		_G[bar..'Text']:SetPoint('CENTER', MirrorTimer1StatusBar, 0, 1)
		
		_G[bar..'StatusBar']:SetAllPoints(_G[bar])
	end
	
	-- Display the names
	if (unit ~= 'player') then
		local name = self.Health:CreateFontString('$parentName', 'OVERLAY')
		name:SetFont(Settings.Media.Font, Settings.Media.FontSize)
		name:SetShadowOffset(1, -1)
		name:SetTextColor(1, 1, 1)
		name:SetWidth(130)
        name:SetParent(self.Overlay)
		name:SetHeight(Settings.Media.FontSize)
        name.frequentUpdates = 0.2
        
        self.Health.Value:SetParent(self.Overlay)
        
        self.Info = name
        self:Tag(self.Info, '[LanShortName]')
        
        if (unit == 'targettarget') then
            self.Health.Value:SetPoint('BOTTOM', self.Health, 0, 1)
            self.Health.Value:Hide()
            
            if (Settings.Units.ToT.Health.Percent or Settings.Units.ToT.Health.Deficit or Settings.Units.ToT.Health.Current) then
                name:SetPoint('TOP', self.Health, 0, -1)
                self.Health.Value:Show()
            else
                name:SetPoint('CENTER', self.Health)
                name:Show()
                self.Health.Value:Hide()
            end
		elseif (unit == 'pet' and Settings.Units.Pet.ShowPowerText) then
            name:Hide()
            
            if (Settings.Units.Pet.Health.Percent or Settings.Units.Pet.Health.Deficit or Settings.Units.Pet.Health.Current) then
                self.Power.Value:SetPoint('RIGHT', self.Health, -2, 0)
                self.Health.Value:SetPoint('LEFT', self.Health, 2, -1)
            end
        elseif (unit == 'pet' and not Settings.Units.Pet.ShowPowerText) then
            name:SetPoint('CENTER', self.Health)
            self:Tag(self.Info, '[LanName]')
        elseif (unit == 'focus') then
            name:SetText()
        elseif (unit == 'target') then
            name:SetPoint('LEFT', self.Health, 'LEFT', 1, 0)
			name:SetJustifyH('LEFT')
            self:Tag(self.Info, '[LanLevel][LanClassification] [LanName]')
            self.Health.Value:SetPoint('RIGHT', self.Health, -2, -1)
        else
			name:SetPoint('LEFT', self.Health, 'LEFT', 1, 0)
			name:SetJustifyH('LEFT')
            self:Tag(self.Info, '[LanName]')
		end
    else
        self.Health.Value:SetPoint('RIGHT', self.Health, -2, -1)
    end
    
    if (Settings.Show.HealerOverride == true) then
        if (unit == 'target') then
            local MHPB = CreateFrame('StatusBar', nil, self.Health)
            MHPB:SetOrientation('HORIZONTAL')
            MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
            MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            MHPB:SetWidth(200)
            MHPB:SetHeight(22)
            MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

            local OHPB = CreateFrame('StatusBar', nil, self.Health)
            OHPB:SetOrientation('HORIZONTAL')
            OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
            OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            OHPB:SetWidth(200)
            OHPB:SetHeight(22)
            OHPB:SetStatusBarColor(0, 1, 0, 0.25)

            self.HealPrediction = {
                myBar = MHPB,
                otherBar = OHPB,
                maxOverflow = 1,
            }
        end
    else
        if (isHealer) then
            if (unit == 'target') then
                local MHPB = CreateFrame('StatusBar', nil, self.Health)
                MHPB:SetOrientation('HORIZONTAL')
                MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
                MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
                MHPB:SetWidth(200)
                MHPB:SetHeight(22)
                MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

                local OHPB = CreateFrame('StatusBar', nil, self.Health)
                OHPB:SetOrientation('HORIZONTAL')
                OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
                OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
                OHPB:SetWidth(200)
                OHPB:SetHeight(22)
                OHPB:SetStatusBarColor(0, 1, 0, 0.25)

                self.HealPrediction = {
                    myBar = MHPB,
                    otherBar = OHPB,
                    maxOverflow = 1,
                }
            end
        end
    end
    
	-- Display icons
	if (unit == 'player') then
		self.Status = self.Health:CreateFontString(nil, 'OVERLAY')
        self.Status:SetParent(self.Overlay)
        self.Status:SetFont(Settings.Media.Font, Settings.Media.FontSize)
		self.Status:SetPoint('LEFT', self.Health, 'TOPLEFT', 2, 2)

		self:Tag(self.Status, '[LanLeader][LanMaster]')
        
        self.Resting = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.Resting:SetParent(self.Overlay)
		self.Resting:SetPoint('CENTER', self.Health, 'BOTTOMLEFT', 0, -4)
		self.Resting:SetSize(20, 20)

		self.Combat = self.Health:CreateTexture(nil, 'OVERLAY')
        self.Combat:SetParent(self.Overlay)
		self.Combat:SetPoint('CENTER', self.Health, 'BOTTOMRIGHT', 0, -4)
		self.Combat:SetSize(24, 24)
    end
    
    -- Aura/buff/debuff handling, update those suckers!
    if (unit == 'player' and Settings.Units.Player.ShowBuffs) then
		local GAP = 6

		self.Buffs = CreateFrame('Frame', nil, self)
		self.Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 10)
		self.Buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 10)
		self.Buffs:SetHeight(30)

		self.Buffs['growth-x'] = 'LEFT'
		self.Buffs['growth-y'] = 'UP'
		self.Buffs['initialAnchor'] = 'BOTTOMRIGHT'
		self.Buffs['num'] = math.floor((Settings.Units.Player.Width - 4 + GAP) / (30 + GAP))
		self.Buffs['size'] = Settings.Units.Player.Height
		self.Buffs['spacing-x'] = GAP
		self.Buffs['spacing-y'] = GAP

		self.Buffs.CustomFilter   = CustomAuraFilter
		self.Buffs.PostCreateIcon = PostCreateAuraIcon
		self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

		self.Buffs.parent = self
	elseif (unit == 'target') then
		local GAP = 6

        local MAX_ICONS = math.floor((Settings.Units.Target.Width + GAP) / (Settings.Units.Target.Height + GAP)) - 1
        local NUM_BUFFS = math.max(1, math.floor(MAX_ICONS * 0.2))
        local NUM_DEBUFFS = math.min(MAX_ICONS - 1, math.floor(MAX_ICONS * 0.8))

		if (isHealer) then
            local debuff = NUM_DEBUFFS - 1
            local buff = NUM_BUFFS + 1
        else
            local debuff = NUM_DEBUFFS - 1
            local buff = NUM_BUFFS + 1
        end
        
        self.Debuffs = CreateFrame('Frame', nil, self)
        self.Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 24)
		self.Debuffs:SetWidth((Settings.Units.Target.Height * NUM_DEBUFFS - 1) + (GAP * (NUM_DEBUFFS - 1)))
		self.Debuffs:SetHeight((Settings.Units.Target.Height * 2) + (GAP * 2))

		self.Debuffs['growth-x'] = 'RIGHT'
		self.Debuffs['growth-y'] = 'UP'
		self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
		self.Debuffs['num'] = debuffs
		self.Debuffs['showType'] = false
		self.Debuffs['size'] = Settings.Units.Target.Height
		self.Debuffs['spacing-x'] = GAP
		self.Debuffs['spacing-y'] = GAP * 2

		self.Debuffs.CustomFilter   = CustomAuraFilter
		self.Debuffs.PostCreateIcon = PostCreateAuraIcon
		self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon

		self.Debuffs.parent = self

		self.Buffs = CreateFrame('Frame', nil, self)
        self.Buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 2, 24)
		self.Buffs:SetWidth((Settings.Units.Target.Height * NUM_BUFFS + 1) + (GAP * (NUM_BUFFS - 1)))
		self.Buffs:SetHeight((Settings.Units.Target.Height * 2) + (GAP * 2))

		self.Buffs['growth-x'] = 'LEFT'
		self.Buffs['growth-y'] = 'UP'
		self.Buffs['initialAnchor'] = 'BOTTOMRIGHT'
		self.Buffs['num'] = buffs
		self.Buffs['showType'] = false
		self.Buffs['size'] = Settings.Units.Target.Height
		self.Buffs['spacing-x'] = GAP
		self.Buffs['spacing-y'] = GAP * 2

		

		self.Buffs.CustomFilter   = CustomAuraFilter
		self.Buffs.PostCreateIcon = PostCreateAuraIcon
		self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

		self.Buffs.parent = self
	end
	
	-- DebuffHighlight Support
	self.DebuffHighlightBackdrop = false
	self.DebuffHighlightFilter = true
	
	-- Various oUF plugins support
	if (unit == 'player') then
		-- oUF_RuneBar support
		if (IsAddOnLoaded('oUF_RuneBar') and class == 'DEATHKNIGHT') then
			self.RuneBar = {}
			for i = 1, 6 do
				self.RuneBar[i] = CreateFrame('StatusBar', '$parentRuneBar', self)
				if(i == 1) then
					self.RuneBar[i]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
				else
					self.RuneBar[i]:SetPoint('TOPLEFT', self.RuneBar[i-1], 'TOPRIGHT', 1, 0)
				end
				self.RuneBar[i]:SetStatusBarTexture(Settings.Media.StatusBar)
				self.RuneBar[i]:SetHeight(5)
				self.RuneBar[i]:SetWidth(200/6 - .85)
				self.RuneBar[i]:SetBackdrop(backdrop)
				self.RuneBar[i]:SetBackdropColor(0, 0, 0, .5)
				self.RuneBar[i]:SetMinMaxValues(0, 1)

				self.RuneBar[i].bg = self.RuneBar[i]:CreateTexture('$parentRuneBackground', 'BORDER')
				self.RuneBar[i].bg:SetAllPoints(self.RuneBar[i])
				self.RuneBar[i].bg:SetTexture(.1, .1, .1)			
			end
		end
    end

    -- DruidPower Support
    if (unit == 'player' and select(2, UnitClass('player')) == 'DRUID') then    
        self.Druid = CreateFrame('Frame')
        self.Druid:SetParent(self) 
        self.Druid:SetFrameStrata('LOW')

        self.Druid.Power = CreateFrame('StatusBar', nil, self)
        self.Druid.Power:SetPoint('TOP', self.Power, 'BOTTOM', 0, -7)
        self.Druid.Power:SetStatusBarTexture(Settings.Media.StatusBar)
        self.Druid.Power:SetFrameStrata('LOW')
        self.Druid.Power:SetFrameLevel(self.Druid:GetFrameLevel() - 1)
        self.Druid.Power:SetHeight(10)
        self.Druid.Power:SetWidth(200)
        self.Druid.Power:SetBackdrop(backdrop)
        self.Druid.Power:SetBackdropColor(0, 0, 0, 0.5)
        
        self.DruidBorder = CreateFrame('Frame', nil, self.Druid.Power)
        self.DruidBorder:SetAllPoints(self.Druid.Power)
        self.DruidBorder:SetFrameLevel(self.Druid.Power:GetFrameLevel() + 2)
        
        AddBorder(self.DruidBorder, Settings.Media.BorderSize, 5)
        
        table.insert(self.__elements, UpdateDruidPower)
        self:RegisterEvent('UNIT_MANA', UpdateDruidPower)
        self:RegisterEvent('UNIT_RAGE', UpdateDruidPower)
        self:RegisterEvent('UNIT_ENERGY', UpdateDruidPower)
        self:RegisterEvent('UPDATE_SHAPESHIFT_FORM', UpdateDruidPower)
    end
    
    -- Eclipse Bar Support
    if (select(2, UnitClass('player')) == 'DRUID') then
        local EclipseBar = CreateFrame('Frame', nil, self)
        EclipseBar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
        EclipseBar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -10)
        EclipseBar:SetSize(200, 10)
        EclipseBar:SetBackdrop(backdrop)
        EclipseBar:SetBackdropColor(0, 0, 0, 0.6)
        
        local EclipseBarBorder = CreateFrame('Frame', nil, EclipseBar)
        EclipseBarBorder:SetAllPoints(EclipseBar)
        EclipseBarBorder:SetFrameLevel(EclipseBar:GetFrameLevel() + 2)
      
        AddBorder(EclipseBarBorder, Settings.Media.BorderSize, Settings.Media.BorderPadding)

        local LunarBar = CreateFrame('StatusBar', nil, EclipseBar)
        LunarBar:SetPoint('LEFT', EclipseBar, 'LEFT', 0, 0)
        LunarBar:SetSize(200, 10)
        LunarBar:SetStatusBarTexture(Settings.Media.StatusBar)
        LunarBar:SetStatusBarColor(1, 1, 1)
        EclipseBar.LunarBar = LunarBar

        local SolarBar = CreateFrame('StatusBar', nil, EclipseBar)
        SolarBar:SetPoint('LEFT', LunarBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
        SolarBar:SetSize(200, 10)
        SolarBar:SetStatusBarTexture(Settings.Media.StatusBar)
        SolarBar:SetStatusBarColor(1, 3/5, 0)
        EclipseBar.SolarBar = SolarBar

        local EclipseBarText = EclipseBarBorder:CreateFontString(nil, 'OVERLAY')
        EclipseBarText:SetPoint('CENTER', EclipseBarBorder, 'CENTER', 0, 0)
        EclipseBarText:SetFont(Settings.Media.Font, Settings.Media.FontSize, 'OUTLINE')
        self:Tag(EclipseBarText, '[pereclipse]%')

        self.EclipseBar = EclipseBar
    end
    
    -- Soul Shard Support
	if (select(2, UnitClass('player')) == 'WARLOCK') then
        local Shards = self:CreateFontString(nil, 'OVERLAY')
        Shards:SetPoint('CENTER', self, 'RIGHT', 17, -2)
        Shards:SetFont(Settings.Media.Font, 24, 'OUTLINE')
        Shards:SetJustifyH('CENTER')
        self:Tag(Shards, '[LanShards]')
    end

    -- Holy Power Support
    if (select(2, UnitClass('player')) == 'PALADIN') then
        local HolyPower = self:CreateFontString(nil, 'OVERLAY')
        HolyPower:SetPoint('CENTER', self, 'RIGHT', 17, -2)
        HolyPower:SetFont(Settings.Media.Font, 24, 'OUTLINE')
        HolyPower:SetJustifyH('CENTER')
        self:Tag(HolyPower, '[LanHolyPower]')
    end
    
    -- Combo points display
	if (select(2, UnitClass('player')) == 'ROGUE') or (select(2, UnitClass('player')) == 'DRUID') then
        local ComboPoints = self:CreateFontString(nil, 'OVERLAY')
        ComboPoints:SetPoint('CENTER', self, 'RIGHT', 17, -2)
        ComboPoints:SetFont(Settings.Media.Font, 24, 'OUTLINE')
        ComboPoints:SetJustifyH('CENTER')
        self:Tag(ComboPoints, '[LanCombo]')
    
    end
	
    -- Raid Icons
    if (unit == 'target') then
        self.RaidIcon = self.Overlay:CreateTexture('$parentRaidIcon', 'ARTWORK')
        self.RaidIcon:SetHeight(18)
        self.RaidIcon:SetWidth(18)
        self.RaidIcon:SetPoint('CENTER', self.Overlay, 'TOP')
        self.RaidIcon:SetTexture('Interface\\TargettingFrame\\UI-RaidTargetingIcons')
    end
    
	-- Custom sizes for our frames
    if (isSingle) then
        if (unit == 'player') then
            self:SetSize(Settings.Units.Player.Width, Settings.Units.Player.Height)
        elseif (unit == 'target') then
            self:SetSize(Settings.Units.Target.Width, Settings.Units.Target.Height)
        elseif (unit == 'pet') then
            self:SetSize(Settings.Units.Pet.Width, Settings.Units.Pet.Height)
        end
        
        if (Settings.Show.ToT) then
            if (unit == 'targettarget') then
                self:SetSize(Settings.Units.ToT.Width, Settings.Units.ToT.Height)
            end
        end
        
        if (Settings.Show.Focus) then
            if (unit == 'focus') then
                self:SetSize(Settings.Units.Focus.Width, Settings.Units.Focus.Height)
            end
        end
    end
	
    -- Hardcore border action!
    AddBorder(self, Settings.Media.BorderSize, Settings.Media.BorderPadding + 2)
    self:SetBorderParent(self.Overlay)
    
    self.UpdateBorder = UpdateBorder

    -- Dispel highlight support
    self.DispelHighlight = UpdateDispelHighlight
    
    -- Threat highlight support
    self.threatLevel = 0
	self.ThreatHighlight = UpdateThreatHighlight
       
    return self
end

-- First build the group style
local function StylishGroup(self, unit)
	self.menu = CreateDropDown
    
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    
	self.ignoreHealComm = true
	
	self:EnableMouse(true)
	self:RegisterForClicks('AnyUp')
	
	if (Settings.Show.Party) then
		if (Settings.Units.Party.Healer) then
			self:SetSize(100, 35)
		else
			self:SetSize(Settings.Units.Party.Width, Settings.Units.Party.Height)
		end
    else
        return
	end
	
	-- Health bar display for group frames
	self.Health = CreateFrame('StatusBar', '$parentHealthBar', self)
	self.Health:SetStatusBarTexture(Settings.Media.StatusBar, 'ARTWORK')
	
	self.Health:SetParent(self)
	self.Health:SetPoint('TOPRIGHT')
	self.Health:SetPoint('BOTTOMLEFT', 0, -1)
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, .5)
	
	self.Health.PostUpdate = UpdateGroupHealth
	
	if (Settings.Units.Party.Health.ClassColor) then
		self.Health.colorClass = true
	end
	
	self.Health.Smooth = true
    self.Health.frequentUpdates = 0.3
	
	-- Health bar background display for group frames
	self.Health.Background = self.Health:CreateTexture('$parentHealthBackground', 'BORDER')
	self.Health.Background:SetAllPoints(self.Health)
	
	-- Background Color
	self.Health.Background:SetTexture(.08, .08, .08)
	
	-- Health value settings
	self.Health.Value = self.Health:CreateFontString('$parentHealthValue', 'OVERLAY')
	self.Health.Value:SetFont(Settings.Media.Font, Settings.Media.FontSize)
    
    -- Improve border drawing
    self.Overlay = CreateFrame('Frame', nil, self)
	self.Overlay:SetAllPoints(self)
	self.Overlay:SetFrameLevel(self.Health:GetFrameLevel() + (self.Power and 3 or 2))
	
	-- Display group names
	self.Name = self.Health:CreateFontString('$parentName', 'OVERLAY')
	self.Name:SetPoint('LEFT', self.Health, 5, 1)
	self.Name:SetFont(Settings.Media.Font, 13)
	self.Name:SetShadowOffset(1, -1)
    self.Name.frequentUpdates = 0.3
    
    self:Tag(self.Name, '|cffffffff[LanName]|r')
    	
	if (Settings.Units.Party.Healer) then
		self.Name:SetPoint('CENTER', self.Health)
	end
    
    if (Settings.Show.HealerOverride == true) then
        local MHPB = CreateFrame('StatusBar', nil, self.Health)
		MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
		MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
		MHPB:SetWidth(100)
		MHPB:SetHeight(35)
		MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

		local OHPB = CreateFrame('StatusBar', nil, self.Health)
		OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
		OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
		OHPB:SetWidth(100)
		OHPB:SetHeight(35)
		OHPB:SetStatusBarColor(0, 1, 0, 0.25)

		self.HealPrediction = {
			myBar = MHPB,
			otherBar = OHPB,
			maxOverflow = 1,
		}
    else
        if (isHealer) then
            local MHPB = CreateFrame('StatusBar', nil, self.Health)
            MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
            MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            MHPB:SetWidth(100)
            MHPB:SetHeight(35)
            MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

            local OHPB = CreateFrame('StatusBar', nil, self.Health)
            OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
            OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            OHPB:SetWidth(100)
            OHPB:SetHeight(35)
            OHPB:SetStatusBarColor(0, 1, 0, 0.25)

            self.HealPrediction = {
                myBar = MHPB,
                otherBar = OHPB,
                maxOverflow = 1,
            }
        end
    end
	
	if unit == 'party' or unit == 'target' then
		self.Status = self.Overlay:CreateFontString(nil, 'OVERLAY')
        self.Status:SetFont(Settings.Media.Font, Settings.Media.FontSize)
		self.Status:SetPoint('RIGHT', self.Health, 'BOTTOMRIGHT', -2, 0)

		self:Tag(self.Status, '[LanMaster][LanLeader]')
	end
	
	-- Raid Icons
	self.RaidIcon = self.Overlay:CreateTexture('$parentRaidIcon', 'ARTWORK')
	self.RaidIcon:SetHeight(18)
	self.RaidIcon:SetWidth(18)
	self.RaidIcon:SetPoint('CENTER', self.Overlay, 'TOP')
	self.RaidIcon:SetTexture('Interface\\TargettingFrame\\UI-RaidTargetingIcons')
	
    -- LFD Role
    self.LFDRole = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.LFDRole:SetPoint('CENTER', self, 'RIGHT', 2, 0)
    self.LFDRole:SetSize(16, 16)
    
    -- Buffs
    local GAP = 6

    self.Buffs = CreateFrame('Frame', nil, self)
    self.Buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 10)
    self.Buffs:SetHeight(Settings.Units.Party.Height)
    self.Buffs:SetWidth((Settings.Units.Party.Height * 4) + (GAP * 3))

    self.Buffs['growth-x'] = 'LEFT'
    self.Buffs['growth-y'] = 'DOWN'
    self.Buffs['initialAnchor'] = 'TOPRIGHT'
    self.Buffs['num'] = 4
    self.Buffs['size'] = Settings.Units.Party.Height
    self.Buffs['spacing-x'] = GAP
    self.Buffs['spacing-y'] = GAP

    self.Buffs.CustomFilter   = CustomAuraFilter
    self.Buffs.PostCreateIcon = PostCreateAuraIcon
    self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

    self.Buffs.parent = self
    
	-- Range-finding support
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = .3,
	}
	
	self.SpellRange = true
    
    -- Hardcore border action!
    AddBorder(self, Settings.Media.BorderSize, Settings.Media.BorderPadding + 2)
    self:SetBorderParent(self.Overlay)
    
    self.UpdateBorder = UpdateBorder

    -- Dispel highlight support
    self.DispelHighlight = UpdateDispelHighlight
    
    -- Threat highlight support
    self.threatLevel = 0
	self.ThreatHighlight = UpdateThreatHighlight
    
    return self
end

-- Now the raid style
local function StylishRaid(self, unit)
	self.menu = CreateDropDown
    
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    
	self.ignoreHealComm = true
	
	self:EnableMouse(true)
	self:RegisterForClicks('AnyUp')
	
	if (Settings.Show.Raid) then
		if (Settings.Units.Raid.Healer) then
			self:SetSize(75, 35)
		else
			self:SetSize(Settings.Units.Raid.Width, Settings.Units.Raid.Height)
		end
    else
        return
	end
	
	-- Health bar display for group frames
	self.Health = CreateFrame('StatusBar', '$parentHealthBar', self)
	self.Health:SetStatusBarTexture(Settings.Media.StatusBar, 'ARTWORK')
	
	self.Health:SetParent(self)
	self.Health:SetPoint('TOPRIGHT')
	self.Health:SetPoint('BOTTOMLEFT', 0, -1)
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, .5)
	
	self.Health.PostUpdate = UpdateRaidHealth
	
	if (Settings.Units.Raid.Health.ClassColor) then
		self.Health.colorClass = true
	end
	
	self.Health.Smooth = true
    self.Health.frequentUpdates = 0.3
	
	-- Health bar background display for group frames
	self.Health.Background = self.Health:CreateTexture('$parentHealthBackground', 'BORDER')
	self.Health.Background:SetAllPoints(self.Health)
	
	-- Background Color
	self.Health.Background:SetTexture(.08, .08, .08)
	
	-- Health value settings
	self.Health.Value = self.Health:CreateFontString('$parentHealthValue', 'OVERLAY')
	self.Health.Value:SetFont(Settings.Media.Font, Settings.Media.FontSize)
    
    -- Improve border drawing
    self.Overlay = CreateFrame('Frame', nil, self)
	self.Overlay:SetAllPoints(self)
	self.Overlay:SetFrameLevel(self.Health:GetFrameLevel() + (self.Power and 3 or 2))
		
	-- Display group names
    if (Settings.Units.Raid.Healer) then
		self.Name = self.Health:CreateFontString('$parentName', 'OVERLAY')
		self.Name:SetPoint('TOP', 0, -2)
		self.Name:SetFont(Settings.Media.Font, 13)
		self.Name:SetShadowOffset(1, -1)
		self.Name:SetJustifyH('CENTER')
		self:Tag(self.Name, '|cffffffff[LanRaidName]|r')
	else
		self.Name = self.Health:CreateFontString('$parentName', 'OVERLAY')
		self.Name:SetPoint('LEFT', self.Health, 5, 1)
		self.Name:SetFont(Settings.Media.Font, 13)
		self.Name:SetShadowOffset(1, -1)
		self:Tag(self.Name, '|cffffffff[LanName]|r')
		self.Health:SetOrientation('HORIZONTAL')
	end
    
    self.Name.frequentUpdates = 0.3
    
    if (Settings.Show.HealerOverride == true) then
        local MHPB = CreateFrame('StatusBar', nil, self.Health)
		MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
		MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
		MHPB:SetWidth(75)
		MHPB:SetHeight(35)
		MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

		local OHPB = CreateFrame('StatusBar', nil, self.Health)
		OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
		OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
		OHPB:SetWidth(75)
		OHPB:SetHeight(35)
		OHPB:SetStatusBarColor(0, 1, 0, 0.25)

		self.HealPrediction = {
			myBar = MHPB,
			otherBar = OHPB,
			maxOverflow = 1,
		}
    else
        if (isHealer) then
            local MHPB = CreateFrame('StatusBar', nil, self.Health)
            MHPB:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
            MHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            MHPB:SetWidth(75)
            MHPB:SetHeight(35)
            MHPB:SetStatusBarColor(0, 1, 0.5, 0.25)

            local OHPB = CreateFrame('StatusBar', nil, self.Health)
            OHPB:SetPoint('LEFT', MHPB:GetStatusBarTexture(), 'RIGHT', 0, 0)
            OHPB:SetStatusBarTexture(Settings.Media.StatusBar)
            OHPB:SetWidth(75)
            OHPB:SetHeight(35)
            OHPB:SetStatusBarColor(0, 1, 0, 0.25)

            self.HealPrediction = {
                myBar = MHPB,
                otherBar = OHPB,
                maxOverflow = 1,
            }
        end
    end
	
	-- Status Icons Display
    self.Status = self.Overlay:CreateFontString(nil, 'OVERLAY')
    self.Status:SetFont(Settings.Media.Font, Settings.Media.FontSize)
    self.Status:SetPoint('RIGHT', self.Health, 'BOTTOMRIGHT', -2, 0)

    self:Tag(self.Status, '[LanMaster][LanLeader]')
	
	-- Raid Icons
	self.RaidIcon = self.Overlay:CreateTexture('$parentRaidIcon', 'ARTWORK')
	self.RaidIcon:SetHeight(18)
	self.RaidIcon:SetWidth(18)
	self.RaidIcon:SetPoint('CENTER', self.Overlay, 'TOP')
	self.RaidIcon:SetTexture('Interface\\TargettingFrame\\UI-RaidTargetingIcons')
	
    -- Range-finding support
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = .3,
	}
	
	self.SpellRange = true
	
    -- Hardcore border action!
    AddBorder(self, Settings.Media.BorderSize, Settings.Media.BorderPadding + 2)
    self:SetBorderParent(self.Overlay)
    
    self.UpdateBorder = UpdateBorder

    -- Dispel highlight support
    self.DispelHighlight = UpdateDispelHighlight
    
    -- Threat highlight support
    self.threatLevel = 0
	self.ThreatHighlight = UpdateThreatHighlight
    
    return self
end

-- Now, actually bring it all together by actually spawning the frames
-- First spawn the group and raid stuff
oUF:RegisterStyle('oUF_Lanerra_Group', StylishGroup)
oUF:RegisterStyle('oUF_Lanerra_Raid', StylishRaid)

-- First up are the group frames
oUF:Factory(function(self)
	if (Settings.Units.Party.Healer) then
		local group = oUF:SpawnHeader('oUF_Lanerra_Group', nil, nil, 'showParty', true, 'showFocus', true, 'columnSpacing', 10, 'unitsPerColumn', 1, 'maxColumns', 5, 'columnAnchorPoint', 'LEFT', 'groupFilter', i)
		group:SetPoint('CENTER', UIParent, 0, -240)
	else
		local group = oUF:SpawnHeader('oUF_Lanerra_Group', nil, nil, 'showParty', true, 'showPlayer', true, 'showFocus', true, 'yOffset', -10)
		if (IsAddOnLoaded('Skada')) then
			group:SetPoint(unpack(Settings.Units.Party.TinyPosition))
		else
			group:SetPoint(unpack(Settings.Units.Party.Position))
		end
	end
end)

-- Now for the raid frames
oUF:Factory(function(self)
    self:SetActiveStyle('oUF_Lanerra_Raid')
        
    if (Settings.Units.Raid.Healer) then
        raid = oUF:SpawnHeader('oUF_Lanerra_Raid', nil, nil, 'showPlayer', true, 'showRaid', true, 'xOffset', 10, 'yOffset', -5, 'point', 'LEFT', 'groupFilter', '1,2,3,4,5', 'groupingOrder', '1,2,3,4,5', 'groupBy', 'GROUP', 'maxColumns', 10, 'unitsPerColumn', 5, 'columnSpacing', 10, 'columnAnchorPoint', 'TOP')
        raid:SetPoint('CENTER', UIParent, 0, -310)

        if (Settings.Units.Raid.Healer) then
            local RaidShift, raid = false
            do
                local UpdateRaid = CreateFrame('Frame')
                UpdateRaid:RegisterEvent('RAID_ROSTER_UPDATE')
                UpdateRaid:SetScript('OnEvent', function(self)
                    if RaidShift == false then return end
                    if(InCombatLockdown()) then
                        self:RegisterEvent('PLAYER_REGEN_ENABLED')
                    else
                        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
                        if (GetNumRaidMembers() < 26 and GetNumRaidMembers() > 10) then
                            raid:SetPoint('CENTER', UIParent, -105, -200)
                        elseif (GetNumRaidMembers() < 11) then
                            raid:SetPoint('CENTER', UIParent, -21, -200)
                        end
                    end
                end)
            end
        end
    else
        raid = {}
        for i = 1, 5 do
            raid[i] = oUF:SpawnHeader('oUF_Lanerra_Raid'..i, nil, nil, 'groupFilter', i, 'showRaid', true, 'showParty', true, 'showFocus', true, 'yOffset', -10)
            table.insert(raid, raid[i])
            if (i == 1) then
                if (IsAddOnLoaded('TinyDPS')) then
                    raid[i]:SetPoint(unpack(Settings.Units.Raid.TinyPosition))
                else
                    raid[i]:SetPoint(unpack(Settings.Units.Raid.Position))
                end
            else
                raid[i]:SetPoint('TOP', raid[i-1], 'BOTTOM', 0, -10)
            end
            raid[i]:Show()
        end
    end
end)

-- Killin' those pesky raid frames
for _, frame in pairs({
	CompactPartyFrame,
	CompactRaidFrameManager,
	CompactRaidFrameContainer,
}) do
	frame:UnregisterAllEvents()
    
    hooksecurefunc(frame, 'Show', function(self)
        self:Hide()
    end)
end

for _, button in pairs({
	'OptionsButton',

    'LockedModeToggle',
	'HiddenModeToggle',
}) do
    _G['CompactRaidFrameManagerDisplayFrame'..button]:Hide()
    _G['CompactRaidFrameManagerDisplayFrame'..button]:Disable()
    _G['CompactRaidFrameManagerDisplayFrame'..button]:EnableMouse(false)
end

-- Now all the solo stuff
oUF:RegisterStyle('oUF_Lanerra', Stylish)
oUF:Factory(function(self)
	self:SetActiveStyle('oUF_Lanerra')
	self:Spawn('player', 'oUF_Lanerra_Player'):SetPoint(unpack(Settings.Units.Player.Position))
	self:Spawn('target', 'oUF_Lanerra_Target'):SetPoint(unpack(Settings.Units.Target.Position))
	self:Spawn('targettarget', 'oUF_Lanerra_ToT'):SetPoint(unpack(Settings.Units.ToT.Position))
	self:Spawn('pet', 'oUF_Lanerra_Pet'):SetPoint(unpack(Settings.Units.Pet.Position))
	self:Spawn('focus', 'oUF_Lanerra_Focus'):SetPoint(unpack(Settings.Units.Focus.Position))
end)

-- Handling, whether the Raid- or the Party-frame is shown
-- FIX: Quick'n'dirty fix until the oUF-conditions work again
local partyToggle = CreateFrame('Frame')        
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBERS_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
    if(InCombatLockdown()) then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
    else
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        
        --[[ This results in the following behavior: If you're in a raid, the party frame will be hidden, no matter how many members
        your raid already has. This means, the party will be hidden if the party leader clicks the button to create a raid.
        If you want to switch to raid view later (meaning, if the members no longer fit into the party frame), you may change the following line accordingly.--]]
        
        if (Settings.Units.Raid.Healer) and (Settings.Units.Party.Healer) then
	        if(GetNumRaidMembers() > 0) then
	            _G['oUF_Lanerra_Group']:Hide()
	            _G['oUF_Lanerra_Raid']:Show()
	        else
	            _G['oUF_Lanerra_Group']:Show()
	            _G['oUF_Lanerra_Raid']:Hide()
	        end
	     else
	        if(GetNumRaidMembers() > 0) then
	            _G['oUF_Lanerra_Group']:Hide()
	            _G['oUF_Lanerra_Raid1']:Show()
	            _G['oUF_Lanerra_Raid2']:Show()
	            _G['oUF_Lanerra_Raid3']:Show()
	            _G['oUF_Lanerra_Raid4']:Show()
	            _G['oUF_Lanerra_Raid5']:Show()
	        else
	            _G['oUF_Lanerra_Group']:Show()
	            _G['oUF_Lanerra_Raid1']:Hide()
	            _G['oUF_Lanerra_Raid2']:Hide()
	            _G['oUF_Lanerra_Raid3']:Hide()
	            _G['oUF_Lanerra_Raid4']:Hide()
	            _G['oUF_Lanerra_Raid5']:Hide()
	        end
	     end
    end
end)