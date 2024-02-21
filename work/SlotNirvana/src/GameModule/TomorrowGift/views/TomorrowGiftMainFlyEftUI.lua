--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:27:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:19:34
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftMainFlyEftUI.lua
Description: 次日礼物主界面 飞粒子
--]]
local TomorrowGiftMainFlyEftUI = class("TomorrowGiftMainFlyEftUI", BaseView)

function TomorrowGiftMainFlyEftUI:getCsbName()
    return "Activity/TomorrowGift/csb/TomorrowGift_tuowei.csb"
end

function TomorrowGiftMainFlyEftUI:initUI()
    TomorrowGiftMainFlyEftUI.super.initUI(self)
    
    -- 粒子
    local particle = self:findChild("ef_tuowei")
    -- particle:resetSystem()
    particle:setPositionType(0) 
    particle:setTotalParticles(300)
end

function TomorrowGiftMainFlyEftUI:fly(_startPosW, _endPosW, _cb)
    local startPos = self:convertToNodeSpace(_startPosW)
    local endPos = self:convertToNodeSpace(_endPosW)

    self:setPosition(startPos)
    local moveTo = cc.EaseIn:create(cc.MoveTo:create(0.7, endPos), 0.7)
    local actList = {
        moveTo,
        cc.CallFunc:create(_cb),
        cc.RemoveSelf:create()
    }
    self:runAction(cc.Sequence:create(actList))
end

return TomorrowGiftMainFlyEftUI