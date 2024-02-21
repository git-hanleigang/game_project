--大地图上的促销节点
local QuestNewLobbySaleNode = class("QuestNewLobbySaleNode", util_require("base.BaseView"))

function QuestNewLobbySaleNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewLobbySaleNode
end

function QuestNewLobbySaleNode:initUI()
    self.m_activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    self:createCsbNode(self:getCsbNodePath())

    self.m_lb_num = self:findChild("lb_spins")

    local touch = G_GetMgr(ACTIVITY_REF.Quest):makeTouch(cc.size(140, 140), "touch")
    self:addChild(touch, 1)
    self:addClick(touch)

    self:initView()
end

function QuestNewLobbySaleNode:getLanguageTableKeyPrefix()
    local theme = self.m_activityData:getThemeName()
    return theme .. "Sale"
end

function QuestNewLobbySaleNode:onEnter()
    --购买Quest活动促销成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshLeftSpins()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_BUY_FINISH
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.type == "success" then
                self:refreshLeftSpins()
            end
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_BUYSALE
    )
end

--促销
function QuestNewLobbySaleNode:initView()
    self:refreshLeftSpins()
end

function QuestNewLobbySaleNode:refreshLeftSpins()
    local leftSpin = self.m_activityData:getLeftSpins()
    if self.m_lb_num then
        self.m_lb_num:setString(""..leftSpin..(leftSpin>0 and " SPINS" or " SPIN"))
    end
    if leftSpin > 0 and self.m_useAct ~= "idle_buff" then
        self:runCsbAction("idle_buff", true)
        self.m_useAct = "idle_buff"
    else
        if leftSpin <= 0 and self.m_useAct ~= "idle" then
            self:runCsbAction("idle", true)
            self.m_useAct = "idle"
        end
    end
end

function QuestNewLobbySaleNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        G_GetMgr(ACTIVITY_REF.QuestNewSale):showMainLayer()
    end
end

return QuestNewLobbySaleNode
