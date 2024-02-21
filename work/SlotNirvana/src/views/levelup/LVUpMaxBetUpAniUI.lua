--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-05 10:24:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-05 14:40:50
FilePath: /SlotNirvana/src/views/levelup/LVUpMaxBetUpAniUI.lua
Description: 升级弹板 最大bet值 变化
--]]
local LVUpMaxBetUpAniUI = class("LVUpMaxBetUpAniUI", BaseView)

function LVUpMaxBetUpAniUI:getCsbName()
    return "LevelUp_new/LevelUpLayer_maxbet.csb"
end

function LVUpMaxBetUpAniUI:initUI(_maxBetValueList)
    LVUpMaxBetUpAniUI.super.initUI(self)

    _maxBetValueList = _maxBetValueList or {}
    -- 值
    local lbValuePre = self:findChild("lb_num_old")
    local lbValueCur = self:findChild("lb_num_new")
    lbValuePre:setString(util_formatCoins(tonumber(_maxBetValueList[1]) or 0, 3))
    lbValueCur:setString(util_formatCoins(tonumber(_maxBetValueList[2]) or 0, 3))

    self:setVisible(false)
end

function LVUpMaxBetUpAniUI:playShowAct()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:setVisible(false)
    end, 60)
end

function LVUpMaxBetUpAniUI:getShowActTime()
    if not self.m_csbAct then
        return  0
    end
    local time = util_csbGetAnimTimes(self.m_csbAct, "start", 60)
    return time or 70 / 60
end

return LVUpMaxBetUpAniUI