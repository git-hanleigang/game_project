--[[--
    小游戏入口
]]
local UI_STATE = {
    PICK_CLAN = 1,
    PICK_GAME = 2
}
local CardSeasonBottomMiniGame = class("CardSeasonBottomMiniGame", BaseView)

function CardSeasonBottomMiniGame:initDatas()
    self:setUIState(self:getUIState())
end

function CardSeasonBottomMiniGame:setUIState(_state)
    self.m_UIState = _state
end

function CardSeasonBottomMiniGame:getCsbName()
    return string.format("CardRes/season202304/cash_season_miniGame.csb")
end

function CardSeasonBottomMiniGame:getRedPointLua()
    return "GameModule.Card.season202304.CardRedPoint"
end

function CardSeasonBottomMiniGame:initCsbNodes()
    self.m_spPickGame = self:findChild("sp_pickGame")
    self.m_spPickClan = self:findChild("sp_pickClan")
    self.m_nodeRedPoint = self:findChild("node_redPoint")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomMiniGame:initUI()
    CardSeasonBottomMiniGame.super.initUI(self)
    self:initRedPoint()
    self:updateUI()
end

function CardSeasonBottomMiniGame:initRedPoint()
    self.m_redPoint = util_createView(self:getRedPointLua())
    self.m_nodeRedPoint:addChild(self.m_redPoint)
end

function CardSeasonBottomMiniGame:updateUI()
    self.m_spPickClan:setVisible(self.m_UIState == UI_STATE.PICK_CLAN)
    self.m_spPickGame:setVisible(self.m_UIState == UI_STATE.PICK_GAME)
    if self.m_UIState == UI_STATE.PICK_GAME then
        self.m_redPoint:setVisible(true)
        self.m_redPoint:updateNum(1)
    else
        self.m_redPoint:setVisible(false)
    end
end

function CardSeasonBottomMiniGame:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        if self.m_UIState == UI_STATE.PICK_CLAN then
            G_GetMgr(G_REF.CardSpecialClan):showMainLayer(true)
        elseif self.m_UIState == UI_STATE.PICK_GAME then
            G_GetMgr(G_REF.CardSeeker):enterGame("CardSeasonBottomMiniGame")
        end
    end
end

function CardSeasonBottomMiniGame:onEnter()
    CardSeasonBottomMiniGame.super.onEnter(self)

    -- pick小游戏cd结束
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setUIState(self:getUIState())
            self:updateUI()
        end,
        ViewEventType.CARD_SEEKER_PICKGAME_ENTER_CD
    )

    -- pick玩完后进入cd
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setUIState(self:getUIState())
            self:updateUI()
        end,
        ViewEventType.CARD_SEEKER_REQUEST_COLLECT
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setUIState(self:getUIState())
            self:updateUI()
        end,
        ViewEventType.CARD_SEEKER_REQUEST_GIVEUP
    )
end

function CardSeasonBottomMiniGame:getUIState()
    local miniGameData = G_GetMgr(G_REF.CardSeeker):getData()
    if miniGameData and not miniGameData:isFinished() then -- 不需要判断时间戳是否过期
        return UI_STATE.PICK_GAME
    end
    return UI_STATE.PICK_CLAN
end

return CardSeasonBottomMiniGame
