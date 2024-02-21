--[[
Author: your name
Date: 2021-01-13 20:59:08
LastEditTime: 2021-01-15 17:07:20
LastEditors: Please set LastEditors
Description: In User Settings Edit
FilePath: /SlotNirvana/src/views/ChooseLevel/ChooseLevelHighTip.lua
--]]

local ChooseLevelHighTip = class("ChooseLevelHighTip", util_require("base.BaseView"))

function ChooseLevelHighTip:initUI()
    self:createCsbNode("BetChoice/BetChoice_Mainlayer_bubble.csb")

    self.m_spBubble = self:findChild("sp_bubble")
    self.m_spBubble:setVisible(false)

    self.m_canTouch = true
    self.m_bHide = true
end

function ChooseLevelHighTip:changeShowState()
    if self.m_bHide then
        self:showTip()
    else
        self:hideTip()
    end
end

function ChooseLevelHighTip:showTip()
    if not self.m_canTouch then
        return
    end

    self.m_canTouch = false
    self.m_spBubble:setVisible(true)
    self:runCsbAction("satart", false, function()
        self.m_canTouch = true
        self:runCsbAction("idle")
        self.m_bHide = false
        performWithDelay(self, function()
            self:hideTip()
        end, 3)
    end, 60)
end

function ChooseLevelHighTip:hideTip()
    if not self.m_canTouch then
        return
    end
    
    self:stopAllActions()
    self.m_canTouch = false
    self.m_spBubble:setVisible(true)
    self:runCsbAction("over", false, function()
        self.m_canTouch = true
        self.m_spBubble:setVisible(false)
        self.m_bHide = true
    end, 60)
end


return ChooseLevelHighTip