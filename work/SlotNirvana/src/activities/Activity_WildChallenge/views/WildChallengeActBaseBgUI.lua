--[[
Author: cxc
Date: 2022-03-23 17:19:46
LastEditTime: 2022-03-23 17:19:48
LastEditors: cxc
Description: 3日行为付费聚合活动   base  背景UI
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/WildChallengeActBaseBgUI.lua
--]]
local WildChallengeActBaseBgUI = class("WildChallengeActBaseBgUI", BaseView)

function WildChallengeActBaseBgUI:initCsbNodes()
    self.m_bg = self:findChild("sp_bg")
end

function WildChallengeActBaseBgUI:getContentSize()
    local posX = self.m_bg:getPositionX()
    local size = self.m_bg:getContentSize()
    local width = size.width - math.abs(posX)
    return cc.size(width, display.height)
end

return WildChallengeActBaseBgUI