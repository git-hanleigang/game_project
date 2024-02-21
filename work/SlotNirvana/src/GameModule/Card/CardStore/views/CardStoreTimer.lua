-- 卡牌商城 商品道具

local CardStoreTimer = class("CardStoreTimer", BaseView)

function CardStoreTimer:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.TimerUI then
        return p_config.TimerUI
    end
end

function CardStoreTimer:initDatas()
    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
end

function CardStoreTimer:initUI()
    CardStoreTimer.super.initUI(self)
    self:initView()
end

function CardStoreTimer:initCsbNodes()
    self.lb_time = self:findChild("lb_time")
    self.btn_gems = self:findChild("btn_gems")
end

function CardStoreTimer:initView()
    if not self.store_data then
        return
    end
    local gems = self.store_data:getResetGems()
    if gems and gems > 0 then
        self:setButtonLabelContent("btn_gems", gems)
    end

    self:refreshTimer()
end

function CardStoreTimer:refreshTimer()
    if not self.store_data then
        return
    end
    local timer = self.store_data:getTimeReset()
    if not timer then
        return
    end
    local timeStr, isOver = util_daysdemaining(timer, true)
    self.lb_time:setString(timeStr)
    if not isOver then
        if not self.timer_schedule then
            self.timer_schedule =
                util_schedule(
                self,
                function()
                    if not self.store_data then
                        if self.timer_schedule then
                            self:stopAction(self.timer_schedule)
                            self.timer_schedule = nil
                        end
                        return
                    end
                    local timer = self.store_data:getTimeReset()
                    local timeStr, isOver = util_daysdemaining(timer, true)
                    self.lb_time:setString(timeStr)
                    if isOver then
                        if self.timer_schedule then
                            self:stopAction(self.timer_schedule)
                            self.timer_schedule = nil
                        end
                        G_GetMgr(G_REF.CardStore):sendToReset("auto")
                    end
                end,
                1
            )
        end
    else
        if self.timer_schedule then
            self:stopAction(self.timer_schedule)
            self.timer_schedule = nil
        end
        G_GetMgr(G_REF.CardStore):sendToReset("auto")
    end
end

function CardStoreTimer:onRefresh()
    if not self.store_data then
        return
    end
    local gems = self.store_data:getResetGems()
    self:setButtonLabelContent("btn_gems", gems)

    self:refreshTimer()
end

function CardStoreTimer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_gems" then
        self:showReset()
    end
end

-- 显示重置面板
function CardStoreTimer:showReset()
    if gLobalViewManager:getViewByExtendData("CardStoreResetLayer") then
        return
    end

    local resetUI = util_createView("GameModule.Card.CardStore.views.CardStoreResetLayer")
    if resetUI then
        gLobalViewManager:showUI(resetUI, ViewZorder.ZORDER_UI)
    end
end

return CardStoreTimer
