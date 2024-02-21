---
--xcyy
--2018年5月23日
--LuxuryDiamondJackPotLock.lua

local LuxuryDiamondJackPotLock = class("LuxuryDiamondJackPotLock",util_require("Levels.BaseLevelDialog"))

local status = {
    idle = 1,
    dark = 2,
}

function LuxuryDiamondJackPotLock:initUI(index)
    self.m_index = index
    self.m_status = status.idle
    self.m_curLevel = 1
    local csbName = "LuxuryDiamond_Jackpot_an.csb"

    self:createCsbNode(csbName)

    local super = self:findChild("yaan_super")
    super:setVisible(false)
    local grand = self:findChild("yaan_grand")
    grand:setVisible(false)
    local major = self:findChild("yaan_major")
    major:setVisible(false)
    local minor = self:findChild("yaan_minor")
    minor:setVisible(false)
    if self.m_index == 1 then
    elseif self.m_index == 2 then
        minor:setVisible(true)
    elseif self.m_index == 3 then
        major:setVisible(true)
    elseif self.m_index == 4 then
        grand:setVisible(true)
    elseif self.m_index == 5 then
        super:setVisible(true)
    end
end

function LuxuryDiamondJackPotLock:onEnter()
 
    LuxuryDiamondJackPotLock.super.onEnter(self)
end

function LuxuryDiamondJackPotLock:onExit()
    LuxuryDiamondJackPotLock.super.onExit(self)
end

function LuxuryDiamondJackPotLock:playAni(name)
    self:runCsbAction(name) -- 播放时间线
end

function LuxuryDiamondJackPotLock:initCurLevel(level)
    self.m_curLevel = level 
    if self.m_curLevel >= self.m_index - 1 then
        self.m_status = status.idle
        self:playAni("idle")
    else
        self.m_status = status.dark
        self:playAni("anidle")
    end
end

function LuxuryDiamondJackPotLock:changeCurbetLevel(level)
    local temp_status = 0
    if level >= self.m_index - 1 then
        temp_status = status.idle
    else
        temp_status = status.dark
    end
    if temp_status ~= self.m_status then
        self.m_status = temp_status
        local play_name = self.m_status == status.idle and  "jiesuo" or "suoding"
        self:playAni(play_name)
    end
end

return LuxuryDiamondJackPotLock