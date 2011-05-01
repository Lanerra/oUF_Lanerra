-- Copyright © 2010-2011 Lanerra. See LICENSE file for license terms.

-- Define some custom oUF tags
oUF.Tags['LanPvPTime'] = function(unit)
	return UnitIsPVP(unit) and not IsPVPTimerRunning() and '*' or IsPVPTimerRunning() and ('%d:%02d'):format((GetPVPTimer() / 1000) / 60, (GetPVPTimer() / 1000) % 60)
end

oUF.TagEvents['LanThreat'] = 'UNIT_THREAT_LIST_UPDATE'
oUF.Tags['LanThreat'] = function()
	local _, _, perc = UnitDetailedThreatSituation('player', 'target')
	return perc and ('%s%d%%|r'):format(hex(GetThreatStatusColor(UnitThreatSituation('player', 'target'))), perc)
end

oUF.Tags['LanLevel'] = function(unit)
    local level = UnitLevel(unit)
    local colorL = GetQuestDifficultyColor(level)
        
    if (level < 0) then 
        r, g, b = 1, 0, 0
        level = '??'
    elseif (level == 0) then
        r, g, b = colorL.r, colorL.g, colorL.b
        level = '?'
    else
        r, g, b = colorL.r, colorL.g, colorL.b
        level = level
    end

    return format('|cff%02x%02x%02x%s|r', r*255, g*255, b*255, level)
end

oUF.TagEvents['LanName'] = 'UNIT_NAME_UPDATE UNIT_HEALTH'
oUF.Tags['LanName'] = function(unit)
    local colorA
    local UnitName, UnitRealm =  UnitName(unit)
    local _, class = UnitClass(unit)
    
    if (UnitRealm) and (UnitRealm ~= '') then
        UnitName = UnitName
    end

    colorA = {1, 1, 1}

	r, g, b = colorA[1], colorA[2], colorA[3]
	    
    return format('|cff%02x%02x%02x%s|r', r*255, g*255, b*255, UnitName)
end

oUF.TagEvents['LanRaidName'] = 'UNIT_NAME_UPDATE UNIT_HEALTH'
oUF.Tags['LanRaidName'] = function(unit)
    local Name = string.sub(UnitName(unit), 1, 4)
	return Name
end

oUF.TagEvents['LanShortName'] = 'UNIT_NAME_UPDATE UNIT_HEALTH'
oUF.Tags['LanShortName'] = function(unit)
    local name = UnitName(unit)
    if strlen(name) > 8 then
        local NewName = string.sub(UnitName(unit), 1, 8)..'...'
        return NewName
    else
        return name
    end
end

oUF.TagEvents['LanPower'] = 'UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_MAXRUNIC_POWER UNIT_RUNIC_POWER'
oUF.Tags['LanPower'] = function(unit)
    local min = UnitPower(unit)
    return min
end

oUF.TagEvents['LanCombat'] = 'PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED'
oUF.Tags['LanCombat'] = function(unit)
	if unit == 'player' and UnitAffectingCombat('player') then
		return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:0:64:64:37:58:5:26|t]]
	end
end
oUF.UnitlessTagEvents['PLAYER_REGEN_DISABLED'] = true
oUF.UnitlessTagEvents['PLAYER_REGEN_ENABLED'] = true

oUF.TagEvents['LanLeader'] = 'PARTY_LEADER_CHANGED PARTY_MEMBERS_CHANGED'
oUF.Tags['LanLeader'] = function(unit)
	if UnitIsPartyLeader(unit) then
		return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]]
	elseif UnitInRaid(unit) and UnitIsRaidOfficer(unit) then
		return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0|t]]
	end
end

oUF.TagEvents['LanMaster'] = 'PARTY_LOOT_METHOD_CHANGED PARTY_MEMBERS_CHANGED'
oUF.Tags['LanMaster'] = function(unit)
	local method, pid, rid = GetLootMethod()
	if method ~= 'master' then return end
	local munit
	if pid then
		if pid == 0 then
			munit = 'player'
		else
			munit = 'party' .. pid
		end
	elseif rid then
		munit = 'raid' .. rid
	end
	if munit and UnitIsUnit(munit, unit) then
		return [[|TInterface\GroupFrame\UI-Group-MasterLooter:0:0:0:2|t]]
	end
end

oUF.TagEvents['LanResting'] = 'PLAYER_UPDATE_RESTING'
oUF.Tags['LanResting'] = function(unit)
	if unit == 'player' and IsResting() then
		return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:-6:64:64:28:6:6:28|t]]
	end
end


oUF.Tags['LanHolyPower'] = function(unit)
	local hp = UnitPower('player', SPELL_POWER_HOLY_POWER)

	if hp > 0 then
		return string.format('|c50f58cba%d|r', hp)
	end
end
oUF.TagEvents['LanHolyPower'] = 'UNIT_POWER'

oUF.Tags['LanShards'] = function(unit)
	local hp = UnitPower('player', SPELL_POWER_SOUL_SHARDS)

	if hp > 0 then
		return string.format('|c909482c9%d|r', hp)
	end
end
oUF.TagEvents['LanShards'] = 'UNIT_POWER'

oUF.Tags['LanCombo'] = function(unit)
    local cp = GetComboPoints('player', 'target')
    
    if cp > 0 then
        return string.format('|cffffff00%d|r', cp)
    end
end
oUF.TagEvents['LanCombo'] = 'UNIT_COMBO_POINTS'
