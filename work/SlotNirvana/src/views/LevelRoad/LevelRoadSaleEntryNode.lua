-- 等级里程碑 促销右边条节点
local LevelRoadSaleEntryNode = class("LevelRoadSaleEntryNode", util_require("base.BaseView"))

function LevelRoadSaleEntryNode:initUI()
    LevelRoadSaleEntryNode.super.initUI(self)
    self:initView()
end

function LevelRoadSaleEntryNode:initDatas()
    self.m_data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    self.m_slaeData = self.m_data:getSaleData()
end

function LevelRoadSaleEntryNode:getCsbName()
    return "LevelRoad/csd/LevelRoad_entrance.csb"
end

function LevelRoadSaleEntryNode:initView()
    self:showDownTimer()
end

--显示倒计时
function LevelRoadSaleEntryNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LevelRoadSaleEntryNode:updateLeftTime()
    if self.m_data then
        local expireAt = self.m_data:getSaleExpireAt()
        local strLeftTime, isOver = util_daysdemaining(expireAt)
        if isOver then
            self:stopTimerAction()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_SALE_END)
        end
    else
        self:stopTimerAction()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_SALE_END)
    end
end

function LevelRoadSaleEntryNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function LevelRoadSaleEntryNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        G_GetMgr(G_REF.LevelRoad):showLevelRoadSaleLayer()
    end
end

function LevelRoadSaleEntryNode:getRightFrameSize()
    return {widht = 100, height = 100}
end

return LevelRoadSaleEntryNode
