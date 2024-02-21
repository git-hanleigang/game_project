---
--xcyy
--2018年5月23日
--AChristmasCarolRespinBar.lua
local AChristmasCarolRespinBar = class("AChristmasCarolRespinBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "AChristmasCarolPublicConfig"

function AChristmasCarolRespinBar:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("AChristmasCarol_respin_spinnum.csb")
end

--[[
    刷新当前次数
]]
function AChristmasCarolRespinBar:updateRespinCount(curCount, totalCount, _isComeIn)
    if totalCount == 3 then
        for index = 1,3 do
            self:findChild("three_liang_"..index):setVisible(curCount == index)
        end
        if curCount == totalCount then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_respin_reset_nums)
            self:runCsbAction("reset", false)
        end
    else
        for index = 1,4 do
            self:findChild("four_liang_"..index):setVisible(curCount == index)
        end
        if curCount == totalCount then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_respin_reset_nums)
            self:runCsbAction("reset2", false)
        end
    end
end

--[[
    进入respin bar出现动画
]]
function AChristmasCarolRespinBar:playBarStartEffect(_isFour, _isNotPlaySound)
    self:setVisible(true)
    for index = 1,4 do
        self:findChild("four_liang_"..index):setVisible(false)
        if index < 4 then
            self:findChild("three_liang_"..index):setVisible(false)
        end
    end
    if _isFour then
        if not _isNotPlaySound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_respin_bar_start)
        end
        self:runCsbAction("show", false, function()
            performWithDelay(self, function()
                self:runCsbAction("switch", false)
            end, 10/30)
        end)
    else
        if not _isNotPlaySound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_respin_bar_start)
        end
        self:runCsbAction("show", false, function()
            self:runCsbAction("idle", false)
        end)
    end
end

--[[
    刷新当前次数
]]
function AChristmasCarolRespinBar:playBarOverEffect(totalCount)
    if totalCount == 3 then
        self:runCsbAction("over1", false)
    else
        self:runCsbAction("over2", false)
    end
end

return AChristmasCarolRespinBar