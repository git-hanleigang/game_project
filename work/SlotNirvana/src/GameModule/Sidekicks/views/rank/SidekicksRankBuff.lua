--[[
    
]]

local SidekicksRankBuff = class("SidekicksRankBuff", BaseView)

function SidekicksRankBuff:getCsbName()
    return string.format("Sidekicks_%s/csd/rank/Sidekicks_Rank_buff_%s.csb", self.m_seasonIdx, self.m_index)
end

function SidekicksRankBuff:initDatas(_seasonIdx, _index, _mainLayer)
    self.m_seasonIdx = _seasonIdx
    self.m_index = _index
    self.m_mainLayer = _mainLayer
    self.m_showNum = 0
end

function SidekicksRankBuff:initCsbNodes()
    self.m_node_bubble = self:findChild("node_bubble")
end

function SidekicksRankBuff:updateNum(_num, _honorLv)
    self.m_showNum = _num
    local lb_num = self:findChild("lb_buff_num")
    if lb_num then
        lb_num:setString("x" .. _num)
    end
    
    local sp_unlock = self:findChild("sp_unlock")
    if sp_unlock then
        local sp_buff_name = self:findChild("sp_buff_name")
        sp_unlock:setVisible(_honorLv < 3)
        sp_buff_name:setVisible(_honorLv >= 3)
    end
end

function SidekicksRankBuff:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_check" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_mainLayer:showBubble(self.m_index, self.m_showNum)
    end
end

return SidekicksRankBuff