-- 卡牌商店 上赛季卡牌结算引导

local CardStoreTimerTip = class("CardStoreTimerTip", BaseView)

function CardStoreTimerTip:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.GiftBubble then
        return p_config.GiftBubble
    end
end

function CardStoreTimerTip:initDatas()
    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
    self.bl_onshow = false
end

function CardStoreTimerTip:initCsbNodes()
    self.lb_time = self:findChild("lb_time")
end

function CardStoreTimerTip:refreshTimer()
    if not self.store_data then
        return
    end
    local timer = self.store_data:getTimeReset()
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
    end
end

function CardStoreTimerTip:onShow()
    if self.bl_onshow == true then
        return
    end

    self.bl_onshow = true
    self:refreshTimer()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
            self:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(2),
                    cc.CallFunc:create(
                        function()
                            self:runCsbAction(
                                "over",
                                false,
                                function()
                                    self.bl_onshow = false
                                end,
                                60
                            )
                        end
                    )
                )
            )
        end,
        60
    )
end

return CardStoreTimerTip
