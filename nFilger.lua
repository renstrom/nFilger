--[[

Filger
Copyright (c) 2009, Nils Ruesch
All rights reserved.

]]

local _, addon = ...

local FilgerSettings = addon.FilgerSettings
local SpellList = addon.SpellList

local font_size = 14

local class = select(2, UnitClass('player'))
local classcolor = RAID_CLASS_COLORS[class]
local active, bars = {}, {}
local MyUnits = {
	player = true,
	vehicle = true,
	pet = true,
}

local Update
local function OnUpdate(self, elapsed)
	local time = self.filter == 'CD' and (self.expirationTime + self.duration - GetTime()) or (self.expirationTime - GetTime())

	if (self:GetParent().Mode == 'BAR') then
		self.statusbar:SetValue(time)

		if (time <= 60) then
			self.time:SetFormattedText('%.1f', time)
		else
			self.time:SetFormattedText('%d:%.2d', time / 60, time % 60)
		end
	end

	if (time < 0 and self.filter == 'CD') then
		local id = self:GetParent().Id

		for index, value in ipairs(active[id]) do
			if (self.spellName == value.data.spellName) then
				tremove(active[id], index)
				break
			end
		end

		self:SetScript('OnUpdate', nil)
		Update(self:GetParent())
	end
end

function Update(self)
	local id = self.Id

	if (not bars[id]) then
		bars[id] = {}
	end

	for index, value in ipairs(bars[id]) do
		value:Hide()
	end

	for index, value in ipairs(active[id]) do
		local bar = bars[id][index]

		if (not bar) then
			bar = CreateFrame('Frame', 'nFilgerAnchor'..id..'Frame'..index, self)
			bar:SetWidth(value.data.size)
			bar:SetHeight(value.data.size)
			bar:SetScale(1)

			if (index == 1) then
				bar:SetPoint(unpack(self.setPoint))
			else
				if (self.Direction == 'UP') then
					bar:SetPoint('BOTTOM', bars[id][index-1], 'TOP', 0, self.Interval)
				elseif (self.Direction == 'RIGHT') then
					bar:SetPoint('LEFT', bars[id][index-1], 'RIGHT', self.Mode == 'ICON' and self.Interval or value.data.barWidth+self.Interval, 0)
				elseif (self.Direction == 'LEFT') then
					bar:SetPoint('RIGHT', bars[id][index-1], 'LEFT', self.Mode == 'ICON' and -self.Interval or -(value.data.barWidth+self.Interval), 0)
				else
					bar:SetPoint('TOP', bars[id][index-1], 'BOTTOM', 0, -self.Interval)
				end
			end

			if (bar.icon) then
				bar.icon = _G[bar.icon:GetName()]
			else
				bar.icon = bar:CreateTexture('$parentIcon', 'ARTWORK')
				bar.icon:SetPoint('TOPLEFT', 2, -2)
				bar.icon:SetPoint('BOTTOMRIGHT', -2, 2)
				bar.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			end

			if (self.Mode == 'ICON') then
				if not bar.beautyBorder then
					bar:CreateBeautyBorder(12)
				end

				bar.cooldown = CreateFrame('Cooldown', '$parentCD', bar, 'CooldownFrameTemplate')
				bar.cooldown:SetAllPoints(bar.icon)
				bar.cooldown:SetReverse()

				if (bar.count) then
					bar.count = _G[bar.count:GetName()]
				else
					bar.count = bar:CreateFontString('$parentCount', 'OVERLAY')
					bar.count:SetFont('Fonts\\ARIALN.ttf', font_size, 'OUTLINE')
					bar.count:SetPoint('BOTTOMRIGHT', 1, -1)
					bar.count:SetJustifyH('CENTER')
				end
			else
				if (bar.statusbar) then
					bar.statusbar = _G[bar.statusbar:GetName()]
				else
					bar.statusbar = CreateFrame('StatusBar', '$parentStatusBar', bar)
					bar.statusbar:SetWidth(value.data.barWidth - 2)
					bar.statusbar:SetHeight(value.data.size - 10)
					bar.statusbar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar.blp')
					bar.statusbar:SetStatusBarColor(classcolor.r, classcolor.g, classcolor.b, 1)

					if ( self.IconSide == 'LEFT' ) then
						bar.statusbar:SetPoint('BOTTOMLEFT', bar, 'BOTTOMRIGHT', 6, 2)
					elseif ( self.IconSide == 'RIGHT' ) then
						bar.statusbar:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMLEFT', -6, 2)
					end
				end

				bar.statusbar:SetMinMaxValues(0, 1)
				bar.statusbar:SetValue(0)

				if (bar.bg) then
					bar.bg = _G[bar.bg:GetName()]
				else
					bar.bg = CreateFrame('Frame', '$parentBG', bar.statusbar)
					bar.bg:SetPoint('TOPLEFT', -2, 2)
					bar.bg:SetPoint('BOTTOMRIGHT', 2, -2)
					bar.bg:SetFrameStrata('BACKGROUND')
				end

				if (bar.background) then
					bar.background = _G[bar.background:GetName()]
				else
					bar.background = bar.statusbar:CreateTexture(nil, 'BACKGROUND')
					bar.background:SetAllPoints()
					bar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar.blp')
					bar.background:SetVertexColor(0, 0, 0, 0.5)
				end

				if (bar.time) then
					bar.time = _G[bar.time:GetName()]
				else			
					bar.time = bar.statusbar:CreateFontString('$parentTime', 'ARTWORK')
					bar.time:SetFont('Fonts\\ARIALN.ttf', font_size, 'OUTLINE')
					bar.time:SetPoint('RIGHT', bar.statusbar, 0, 0)
				end

				if (bar.count) then
					bar.count = _G[bar.count:GetName()]
				else
					bar.count = bar:CreateFontString('$parentCount', 'ARTWORK')
					bar.count:SetFont('Fonts\\ARIALN.ttf', font_size, 'OUTLINE')
					bar.count:SetPoint('BOTTOMRIGHT', 1, 1)
					bar.count:SetJustifyH('CENTER')
				end

				if (bar.spellname) then
					bar.spellname = _G[bar.spellname:GetName()]
				else
					bar.spellname = bar.statusbar:CreateFontString('$parentSpellName', 'ARTWORK')
					bar.spellname:SetFont('Fonts\\ARIALN.ttf', font_size, 'OUTLINE')
					bar.spellname:SetPoint('LEFT', bar.statusbar, 2, 0)
					bar.spellname:SetPoint('RIGHT', bar.time, 'LEFT')
					bar.spellname:SetJustifyH('LEFT')
				end
			end

			tinsert(bars[id], bar)
		end

		bar.spellName = value.data.spellName

		bar.icon:SetTexture(value.icon)
		bar.count:SetText(value.count > 1 and value.count or '')

		if (self.Mode == 'BAR') then
			bar.spellname:SetText(value.data.spellName)
		end

		if (value.duration > 0) then
			if (self.Mode == 'ICON') then
				CooldownFrame_SetTimer(bar.cooldown, value.data.filter == 'CD' and value.expirationTime or (value.expirationTime - value.duration), value.duration, 1)

				if (value.data.filter == 'CD') then
					bar.expirationTime = value.expirationTime
					bar.duration = value.duration
					bar.filter = value.data.filter
					bar:SetScript('OnUpdate', OnUpdate)
				end
			else
				bar.statusbar:SetMinMaxValues(0, value.duration)
				bar.expirationTime = value.expirationTime
				bar.duration = value.duration
				bar.filter = value.data.filter
				bar:SetScript('OnUpdate', OnUpdate)
			end
		else
			if (self.Mode == 'ICON') then
				bar.cooldown:Hide()
			else
				bar.statusbar:SetMinMaxValues(0, 1)
				bar.statusbar:SetValue(1)
				bar.time:SetText('')
				bar:SetScript('OnUpdate', nil)
			end
		end

		bar:Show()
	end
end

local function OnEvent(self, event, ...)
	local id = self.Id

	for i = 1, #SpellList[class][id], 1 do
		local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable, start, enabled, slotLink, spn
		local data = SpellList[class][id][i]

		if (data.filter == 'BUFF' or data.filter == 'DEBUFF') then
			spn = GetSpellInfo(data.spellID)
			if (spn) then
				name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitAura(data.unitId, spn, nil, data.filter == 'BUFF' and 'HELPFUL' or 'HARMFUL')
			end
		else
			if (data.spellID) then
				spn = GetSpellInfo(data.spellID)
				if (spn) then
					start, duration, enabled = GetSpellCooldown(spn)
					_, _, icon = GetSpellInfo(data.spellID)
				end
			else
				slotLink = GetInventoryItemLink('player', data.slotID)

				if (slotLink) then
					name, _, _, _, _, _, _, _, _, icon = GetItemInfo(slotLink)

					data.spellName = name
					start, duration, enabled = GetInventoryItemCooldown('player', data.slotID)
				end
			end

			count = 0
			caster = 'all'
		end

		if (not data.spellName) then
			data.spellName = spn
		end

		if (not active[id]) then
			active[id] = {}
		end

		for index, value in ipairs(active[id]) do
			if (data.spellName == value.data.spellName) then
				tremove(active[id], index)
				break
			end
		end

		if (( name and ( data.caster ~= 1 and ( caster == data.caster or data.caster == 'all' ) or MyUnits[caster] )) or ((enabled or 0) > 0 and (duration or 0 ) > 1.5 )) then
			table.insert(active[id], { data = data, icon = icon, count = count, duration = duration, expirationTime = expirationTime or start })
		end
	end

	Update(self)
end

if (SpellList and SpellList['ALL']) then
	if (not SpellList[class]) then
		SpellList[class] = {}
	end

	for i = 1, #SpellList['ALL'], 1 do
		table.insert(SpellList[class], SpellList['ALL'][i])
	end
end

if (SpellList and SpellList[class]) then
	for index in pairs(SpellList) do
		if (index ~= class) then
			SpellList[index] = nil
		end
	end

	for i = 1, #SpellList[class], 1 do
		local data = SpellList[class][i]

		local frame = CreateFrame('Frame', 'FilgerAnchor'..i, UIParent)
		frame.Id = i
		frame.Name = data.Name
		frame.Direction = data.Direction or 'DOWN'
		frame.IconSide = data.IconSide or 'LEFT'
		frame.Interval = data.Interval or 3
		frame.Mode = data.Mode or 'ICON'
		frame.setPoint = data.setPoint or 'CENTER'
		frame:SetWidth(SpellList[class][i][1] and SpellList[class][i][1].size or 100)
		frame:SetHeight(SpellList[class][i][1] and SpellList[class][i][1].size or 20)
		frame:SetPoint(unpack(data.setPoint))

		if (FilgerSettings.configmode) then
			for j = 1, #SpellList[class][i], 1 do
				data = SpellList[class][i][j]

				if (not active[i]) then
					active[i] = {}
				end

				if (data.spellID) then
					_, _, spellIcon = GetSpellInfo(data.spellID)
				else
					slotLink = GetInventoryItemLink('player', data.slotID)

					if (slotLink) then
						name, _, _, _, _, _, _, _, _, spellIcon = GetItemInfo(slotLink)
					end
				end

				table.insert(active[i], { data = data, icon = spellIcon, count = 9, duration = 0, expirationTime = 0 })
			end

			Update(frame)
		else
			for j = 1, #SpellList[class][i], 1 do
				data = SpellList[class][i][j]

				if (data.filter == 'CD') then
					frame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
					break
				end
			end

			frame:RegisterUnitEvent('UNIT_AURA', 'player', 'target', 'vehicle', 'pet', 'focus')
			frame:RegisterEvent('PLAYER_TARGET_CHANGED')
			frame:RegisterEvent('PLAYER_ENTERING_WORLD')
			frame:SetScript('OnEvent', OnEvent)
		end
	end
end
