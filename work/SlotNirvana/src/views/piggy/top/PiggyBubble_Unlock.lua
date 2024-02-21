local BasePiggyBubble = util_require("views.piggy.top.BasePiggyBubble")
local PiggyBubble_Unlock = class("PiggyBubble_Unlock", BasePiggyBubble)

function PiggyBubble_Unlock:initDatas()
    self:setName("PiggyBubble_Unlock")
end

function PiggyBubble_Unlock:getCsbName()
    return "GameNode/Piggy_UnlockTip.csb"
end

function PiggyBubble_Unlock:initCsbNodes()
    self.m_sp_bg = self:findChild("Image_1")
    self.m_sp_arrow = self:findChild("tishi_sanjiao_1")
end

function PiggyBubble_Unlock:initUI()
    PiggyBubble_Unlock.super.initUI(self)
    self:setPos()
end

function PiggyBubble_Unlock:setPos()
    if globalData.slotRunData.isPortrait == true then
        self.m_sp_bg:setPositionX(self.m_sp_bg:getPositionX() - 70)
    end
end

return PiggyBubble_Unlock
