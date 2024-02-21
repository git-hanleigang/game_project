--[[
    
]]

local SidekicksRankProgress = class("SidekicksRankProgress", BaseView)

function SidekicksRankProgress:getCsbName()
    return string.format("Sidekicks_%s/csd/rank/Sidekicks_Rank_progress.csb", self.m_seasonIdx)
end

function SidekicksRankProgress:initDatas(_seasonIdx, _mainLayer)
    self.m_seasonIdx = _seasonIdx
    self.m_mainLayer = _mainLayer
end

function SidekicksRankProgress:initCsbNodes()
    self.m_node_base = self:findChild("node_base")
    self.m_node_other = self:findChild("node_other")
    self.m_node_other2 = self:findChild("node_other_2")
    self.m_loadingBar = self:findChild("LoadingBar_1")
    self.m_lb_bar = self:findChild("lb_bar")
    self.m_lb_bar_desc = self:findChild("lb_bar_desc")
    self:setButtonLabelContent("btn_goback", "BACK TO BASE")
    self:setButtonLabelContent("btn_goback2", "BACK TO BASE")
end

function SidekicksRankProgress:updateUI(_curExp, _needExp, _curLevel, _level)
    self.m_node_base:setVisible(_curLevel == _level)
    self.m_node_other:setVisible(_level > _curLevel)
    self.m_node_other2:setVisible(_level < _curLevel)

    if _curLevel == _level then
        local percent = _curExp / _needExp * 100
        self.m_loadingBar:setPercent(percent)
        self.m_lb_bar:setString(util_formatCoins(_curExp, 4) .. "/" .. util_formatCoins(_needExp, 4))
        self:updateLabelSize({label = self.m_lb_bar, sx = 1, sy = 1}, 230)
    end
end

function SidekicksRankProgress:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_goback" or name == "btn_goback2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_mainLayer:toCurPage()
    end
end

return SidekicksRankProgress