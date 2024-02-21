-- 集卡 排行榜按钮控件

local CardRankConfig = require("views.Card.CardRank202303.CardRankConfig")
local CardRankItem = class("CardRankItem", BaseView)

function CardRankItem:getCsbName()
    return CardRankConfig.RankItemUI
end

function CardRankItem:initUI()
    CardRankItem.super.initUI(self)

    self:doIdle()
    self:onTick()
end

function CardRankItem:initCsbNodes()
    self.lbRank = self:findChild("lb_RankNum")
    self.lbRank:setVisible(false)
end

function CardRankItem:doIdle()
    self:updateRankUI()
    self:setTouchEnabled(true)
end

function CardRankItem:clickFunc(sender)
    if not self.bl_enable then
        return
    end
    local name = sender:getName()
    if name == "btn_Rank" then
        self:openRankUI()
    end
end

function CardRankItem:setTouchEnabled(bl_enable)
    self.bl_enable = bl_enable
end

function CardRankItem:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param and param.refName == G_REF.CardRank then
                self:updateRankUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

function CardRankItem:onTick()
    local function tick()
        local act_ata = G_GetMgr(G_REF.CardRank):getRunningData()
        if not act_ata then
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            if not tolua.isnull(self) then
                self:removeSelf()
            end
            return
        end
        local left_time = act_ata:getLeftTime()
        if not left_time or left_time <= 0 then
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            if not tolua.isnull(self) then
                self:removeSelf()
            end
        end
    end

    if not self.schedule_timer then
        self.schedule_timer = util_schedule(self, tick, 1)
    end

    tick()
end

function CardRankItem:openRankUI()
    local function callFunc()
        if not tolua.isnull(self) then
            G_GetMgr(G_REF.CardRank):showMainLayer()
        end
    end
    G_GetMgr(G_REF.CardRank):sendActionRank(1, callFunc)
end

function CardRankItem:updateRankUI()
    local act_data = G_GetMgr(G_REF.CardRank):getData()
    if act_data ~= nil then
        -- 排名上升或下降
        local rankUpDown = act_data:getRankUp()
        if not rankUpDown then
            self:runCsbAction("idle", true, nil, 60)
            return
        end
        if rankUpDown > 0 then
            self:runCsbAction("up", true, nil, 60)
            self:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(5),
                    cc.CallFunc:create(
                        function()
                            self:runCsbAction("idle", true, nil, 60)
                        end
                    )
                )
            )
        elseif rankUpDown < 0 then
            self:runCsbAction("down", true, nil, 60)
            self:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(5),
                    cc.CallFunc:create(
                        function()
                            self:runCsbAction("idle", true, nil, 60)
                        end
                    )
                )
            )
        else
            self:runCsbAction("idle", true, nil, 60)
        end
        -- 名次
        local rank = act_data:getRank()
        self.lbRank:setVisible(rank > 0)
        self.lbRank:setString(rank)
    end
end

return CardRankItem
