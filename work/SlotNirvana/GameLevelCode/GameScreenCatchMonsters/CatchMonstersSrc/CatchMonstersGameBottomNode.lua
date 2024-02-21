-- 处理spin按钮点击跳过流程
local CatchMonstersGameBottomNode = class("CatchMonstersGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function CatchMonstersGameBottomNode:initUI(...)
    CatchMonstersGameBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_wheelSpinBtn = util_createView("CatchMonstersSrc.CatchMonstersSpin")
        spinParent:addChild(self.m_wheelSpinBtn, order)
        self.m_wheelSpinBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_wheelSpinBtn:setSelfMachine(self.m_machine)
        self:setWheelBtnVisible(false)
    end
end

function CatchMonstersGameBottomNode:setWheelBtnVisible(_vis)
    if nil ~= self.m_wheelSpinBtn then
        self.m_wheelSpinBtn:setVisible(_vis)
    end
end

function CatchMonstersGameBottomNode:postPiggy(type, lastBetIdx, _curBetValue)
    if type == "change" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            local curBetValue = _curBetValue
            local lastBetValue = globalData.slotRunData:getCurBetValueByIndex(lastBetIdx) * globalData.slotRunData.m_curBetMultiply
            if lastBetValue > curBetValue then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
            end
        end
    else
        CatchMonstersGameBottomNode.super.postPiggy(self,type, lastBetIdx, _curBetValue)
    end
end

--改变筹码
function CatchMonstersGameBottomNode:changeBetCoinNum(_betId,_curBetValue)
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    local betData = globalData.slotRunData:getBetDataByIdx(_betId , 0)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("change", lastBetIdx, _curBetValue)
    self:updateBetCoin()
end

return  CatchMonstersGameBottomNode