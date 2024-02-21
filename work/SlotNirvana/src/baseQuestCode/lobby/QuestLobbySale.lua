--大地图上的促销节点
local QuestLobbySale = class("QuestLobbySale", util_require("base.BaseView"))

local STATE = {
    NONE = "NONE",
    NOBUFF = "NOBUFF",
    INBUFF = "INBUFF"
}

-- function QuestLobbySale:ctor()
--     QuestLobbySale.super.ctor(self)

--     self:mergePlistInfos(QUEST_PLIST_PATH.QuestLobbySale)
-- end

function QuestLobbySale:getCsbNodePath()
    return QUEST_RES_PATH.QuestLobbySale
end

function QuestLobbySale:initUI()
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:createCsbNode(self:getCsbNodePath())

    self.m_lb_num = self:findChild("m_lb_num")

    local touch = G_GetMgr(ACTIVITY_REF.Quest):makeTouch(cc.size(140, 140), "touch")
    self:addChild(touch, 1)
    self:addClick(touch)

    self:initView()
end

function QuestLobbySale:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Sale"
end

function QuestLobbySale:onEnter()
    --购买Quest活动促销成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_lb_num and not self.timer_schedule then
                self.timer_schedule = util_schedule(self, handler(self, self.refreshTimer), 1)
                self:refreshTimer()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_BUY_FINISH
    )
end

--促销
function QuestLobbySale:initView()
    self:changeState(STATE.NONE)
    if self.m_lb_num then
        self.timer_schedule = util_schedule(self, handler(self, self.refreshTimer), 1)
        self:refreshTimer()
    end
end

function QuestLobbySale:changeState(_state)
    if not _state then
        return
    end
    if self._state and self._state == _state then
        return
    end
    if _state == STATE.NONE then
        self:runCsbAction("idle", true)
    elseif _state == STATE.NOBUFF then
        self:runCsbAction("idle_none", true)
    elseif _state == STATE.INBUFF then
        self:runCsbAction("idle_buff", true)
    end
    self._state = _state
end

function QuestLobbySale:getState()
    return self._state
end

function QuestLobbySale:refreshTimer()
    --buff倒计时
    local buffExpire = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPY_QUEST_FAST)
    if buffExpire and buffExpire > 0 then
        self.m_lb_num:setString(util_count_down_str(buffExpire))
        if self:getState() == STATE.NOBUFF then
            self:changeState(STATE.INBUFF)
        end
    else
        self.m_lb_num:setString("00:00:00")
        self:stopAction(self.timer_schedule)
        self.timer_schedule = nil
        if self:getState() == STATE.INBUFF then
            self:changeState(STATE.NOBUFF)
        end
    end
end

function QuestLobbySale:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        G_GetMgr(ACTIVITY_REF.QuestSale):showMainLayer()
    end
end

function QuestLobbySale:runBuffEff()
    self:changeState(STATE.NOBUFF)
end

return QuestLobbySale
