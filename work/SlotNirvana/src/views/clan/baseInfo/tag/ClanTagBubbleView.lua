--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-11-04 15:14:43
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-11-04 15:14:48
FilePath: /SlotNirvana/src/views/clan/baseInfo/tag/ClanTagBubbleView.lua
Description: 公会标签 气泡
--]]
local ClanTagBubbleView = class("ClanTagBubbleView", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanTagBubbleView:getCsbName()
    return "Club/csd/ClubEstablish/Club_Create_Info_bubble.csb"
end

function ClanTagBubbleView:initUI(_tagIdx)
    ClanTagBubbleView.super.initUI(self)
    local lbName = self:findChild("lb_bubble")
    local name = ClanManager:getStdTagName(_tagIdx)
    lbName:setString(name or "")
    util_scaleCoinLabGameLayerFromBgWidth(lbName, 150 ,1)

    self:setVisible(false)
end

function ClanTagBubbleView:showTip()
    if self:isVisible() then
        return
    end

    self:setVisible(true)
    self:runCsbAction("start", false, function()
        performWithDelay(self, function()
            self:hideTip()
        end, 3)
    end, 60)
end

function ClanTagBubbleView:hideTip()
    if not self:isVisible() then
        return
    end
    
    self:stopAllActions()
    self:setVisible(true)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end, 60)
end

return ClanTagBubbleView