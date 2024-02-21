--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-05 10:24:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-05 16:20:44
FilePath: /SlotNirvana/src/views/levelup/LVUpCashMoneyUpAniUI.lua
Description: 升级弹板 cashMoney 详情动画
--]]
local LVUpCashMoneyUpAniUI = class("LVUpCashMoneyUpAniUI", BaseView)

function LVUpCashMoneyUpAniUI:getCsbName()
    return "LevelUp_new/LevelUpLayer_cashmoney.csb"
end

function LVUpCashMoneyUpAniUI:initUI(_cashMoenyValue)
    LVUpCashMoneyUpAniUI.super.initUI(self)

    -- 值
    local lbValue = self:findChild("lb_maxbet_title")
    local value = util_formatCoins(tonumber(_cashMoenyValue) or 0, 3)
    local str = "CASH MONEY\nUP TO " .. value
    lbValue:setString(str)
    self:setVisible(false)
end

function LVUpCashMoneyUpAniUI:playShowAct()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:setVisible(false)
    end, 60)
end

function LVUpCashMoneyUpAniUI:getShowActTime()
    if not self.m_csbAct then
        return  0
    end
    local time = util_csbGetAnimTimes(self.m_csbAct, "start", 60)
    return time or 70 / 60
end

return LVUpCashMoneyUpAniUI