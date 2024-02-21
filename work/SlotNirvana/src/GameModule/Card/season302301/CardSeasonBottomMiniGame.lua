--[[--
    小游戏入口
]]
local UI_STATE = {
    MagicGame = 1,
    CountDown = 2
}
local CardSeasonBottomMiniGame = class("CardSeasonBottomMiniGame", BaseView)

function CardSeasonBottomMiniGame:initDatas()
    self:setUIState(self:getUIState())
end

function CardSeasonBottomMiniGame:setUIState(_state)
    self.m_UIState = _state
end

function CardSeasonBottomMiniGame:getCsbName()
    return string.format("CardRes/season302301/cash_season_miniGame.csb")
end

function CardSeasonBottomMiniGame:getRedPointLua()
    return "GameModule.Card.season302301.CardRedPoint"
end

function CardSeasonBottomMiniGame:initCsbNodes()
    self.m_ndoeMagicGame = self:findChild("node_magicGame")
    self.m_nodeCountDown = self:findChild("node_countDown")

    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomMiniGame:initUI()
    CardSeasonBottomMiniGame.super.initUI(self)
    self:initRedPoint()
    self:initCountDown()
    self:updateUI()
end

function CardSeasonBottomMiniGame:initRedPoint()
    self.m_redPoint = util_createView(self:getRedPointLua())
    self.m_nodeRedPoint:addChild(self.m_redPoint)
    self.m_redPoint:updateNum(1)
end

function CardSeasonBottomMiniGame:initCountDown()
    self:stopCountDown()
    local miniGameData = G_GetMgr(G_REF.CardSeeker):getData()
    if miniGameData and self.m_UIState == UI_STATE.CountDown then
        local expireAt = miniGameData:getExpireAt()
        local function updateLabel()
            local timeStr = util_daysdemaining(expireAt, true)
            self.m_lbTime:setString(timeStr)        
        end
        updateLabel()
        self.m_countDown = util_schedule(self, updateLabel, 1)
    end
end

function CardSeasonBottomMiniGame:stopCountDown()
    if self.m_countDown then
        self:stopAction(self.m_countDown)
        self.m_countDown = nil
    end
end

function CardSeasonBottomMiniGame:updateUI()
    self.m_nodeCountDown:setVisible(self.m_UIState == UI_STATE.CountDown)
    self.m_ndoeMagicGame:setVisible(self.m_UIState == UI_STATE.MagicGame)
end

function CardSeasonBottomMiniGame:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        -- if self.m_UIState == UI_STATE.PICK_CLAN then
        --     G_GetMgr(G_REF.CardSpecialClan):showMainLayer(true)
        -- elseif self.m_UIState == UI_STATE.PICK_GAME then
        --     G_GetMgr(G_REF.CardSeeker):enterGame("CardSeasonBottomMiniGame")
        -- end
        if self.m_UIState == UI_STATE.MagicGame then
            G_GetMgr(G_REF.CardSeeker):enterGame("CardSeasonBottomMiniGame")
        end
    end
end

function CardSeasonBottomMiniGame:onEnter()
    CardSeasonBottomMiniGame.super.onEnter(self)

    -- pick小游戏cd结束
    -- 跨天数据更新后刷新
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setUIState(self:getUIState())
            self:updateUI()
            self:initCountDown()
        end,
        ViewEventType.CARD_SEEKER_DATA_REFRESH
    )

    -- -- pick玩完后进入cd
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         self:setUIState(self:getUIState())
    --         self:updateUI()
    --         self:initCountDown()
    --     end,
    --     ViewEventType.CARD_SEEKER_REQUEST_COLLECT
    -- )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         self:setUIState(self:getUIState())
    --         self:updateUI()
    --         self:initCountDown()
    --     end,
    --     ViewEventType.CARD_SEEKER_REQUEST_GIVEUP
    -- )
end

function CardSeasonBottomMiniGame:getUIState()
    local miniGameData = G_GetMgr(G_REF.CardSeeker):getData()
    if miniGameData and not miniGameData:isFinished() then -- 不需要判断时间戳是否过期
        return UI_STATE.MagicGame
    end
    return UI_STATE.CountDown
end

return CardSeasonBottomMiniGame
