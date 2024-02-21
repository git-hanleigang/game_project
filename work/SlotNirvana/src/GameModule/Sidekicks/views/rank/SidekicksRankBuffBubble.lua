--[[
    
]]

local SidekicksRankBuffBubble = class("SidekicksRankBuffBubble", BaseView)

function SidekicksRankBuffBubble:getCsbName()
    return string.format("Sidekicks_%s/csd/rank/Sidekicks_Rank_buff_bubble.csb", self.m_seasonIdx, self.m_index)
end

function SidekicksRankBuffBubble:initDatas(_seasonIdx, _index)
    self.m_seasonIdx = _seasonIdx
end

function SidekicksRankBuffBubble:initCsbNodes()
    self.m_bonus_desc = self:findChild("lb_bubble_desc_1")
    self.m_wheel_desc = self:findChild("lb_bubble_desc_2")
    self.m_update_desc = self:findChild("lb_bubble_desc_3")
    self.m_update_unlock_desc = self:findChild("lb_bubble_desc_3_unlock")
end

function SidekicksRankBuffBubble:updateDecs(_index, _showNum, _honorLv)
    self.m_bonus_desc:setVisible(_index == 1)
    self.m_wheel_desc:setVisible(_index == 2)
    self.m_update_desc:setVisible(_index == 3 and _honorLv >= 3)
    self.m_update_unlock_desc:setVisible(_index == 3 and _honorLv < 3)
end

function SidekicksRankBuffBubble:playOpen(_index, _showNum, _honorLv)
    self:stopAllActions()
    self:setVisible(true)
    self:updateDecs(_index, _showNum, _honorLv)
    self:runCsbAction("start", false)

    performWithDelay(self, function ()
        self:runCsbAction("over", false)
    end, 2)
end

function SidekicksRankBuffBubble:hideSelf()
    self:stopAllActions()
    self:setVisible(false)
end

return SidekicksRankBuffBubble