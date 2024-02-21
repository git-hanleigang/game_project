--[[
]]
local LSGameRollEffect = class("LSGameRollEffect", BaseView)

function LSGameRollEffect:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_coinBox_select.csb"
end

function LSGameRollEffect:initCsbNodes()   
    self.m_nodeRollEffects = {} 
    for i = 1, 12 do
        self.m_nodeRollEffects[i] = self:findChild("ef_light" .. i) 
        self.m_nodeRollEffects[i]:setVisible(false) 
    end
end

function LSGameRollEffect:changeVisible(_index)
    for i = 1, 12 do
        self.m_nodeRollEffects[i]:setVisible(i == _index)
    end
end

function LSGameRollEffect:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function LSGameRollEffect:playIdle2()
    self:runCsbAction("idle2", true, nil, 60)
end
-- function LSGameRollEffect:playWinIdle()
--     self:runCsbAction("idle2", true, nil, 60)
-- end

function LSGameRollEffect:playWin(_over)
    self:runCsbAction("win", false, _over, 60)
end

return LSGameRollEffect
