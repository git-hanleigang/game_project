local FlamingPompeiiRespinTips = class("FlamingPompeiiRespinTips",util_require("Levels.BaseLevelDialog"))

FlamingPompeiiRespinTips.TipState = {
    NotShow = 0,            --隐藏
    Idle    = 1,            --播idle
    Over    = 2,            --播over
}
function FlamingPompeiiRespinTips:initDatas(_data)
    self.m_curState = self.TipState.NotShow
end
function FlamingPompeiiRespinTips:initUI()
    self:createCsbNode("FlamingPompeii_reSpintishi.csb")
    self:addClick(self:findChild("Panel_click"))
end
--没有点击回调就无法点击关闭
function FlamingPompeiiRespinTips:clickFunc(sender)
    if "function" ~= type(self.m_fnOver) then
        return
    end
    self:playOverAnim()
end

--[[
    关闭回调
]]
function FlamingPompeiiRespinTips:setOverCallBack(_fn)
    self.m_fnOver = _fn
end
function FlamingPompeiiRespinTips:runOverCallBack()
    if "function" == type(self.m_fnOver) then
        self.m_fnOver()
        self.m_fnOver = nil
    end
end
--[[
    idle -> over
]]
function FlamingPompeiiRespinTips:playIdleAnim()
    self:setVisible(true)
    self.m_curState = self.TipState.Idle
    self:runCsbAction("idle", false)
end

function FlamingPompeiiRespinTips:startCountDown()
    performWithDelay(self,function()
        self:playOverAnim()
    end, 3)
end
function FlamingPompeiiRespinTips:playOverAnim()
    if self.m_curState ~= self.TipState.Idle then
        return
    end
    self:stopAllActions()
    self.m_curState = self.TipState.Over
    self:runCsbAction("over", false, function()
        self.m_curState = self.TipState.NotShow
        self:setVisible(false)
        self.m_fnOver()
    end)
end

return FlamingPompeiiRespinTips