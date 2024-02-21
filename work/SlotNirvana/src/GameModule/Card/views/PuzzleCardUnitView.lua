local BaseView = util_require("base.BaseView")
local PuzzleCardUnitView = class("PuzzleCardUnitView", BaseView)
function PuzzleCardUnitView:ctor()
    PuzzleCardUnitView.super.ctor(self)
end

-- 初始化UI --
function PuzzleCardUnitView:initUI(cardData, actionName, newFlag)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.puzzle)
    if cardData then
        self:reloadUI(cardData, actionName, newFlag)
    end
end

function PuzzleCardUnitView:setCardData(cardData)
    self.m_lastCardData = self.m_cardData
    self.m_cardData = cardData
end

function PuzzleCardUnitView:getCardData()
    return self.m_cardData
end

-- 重新加载 --
function PuzzleCardUnitView:reloadUI(cardData, actionName, newFlag)
    self:initData(cardData, actionName, newFlag)
    self:updateUI()
end

function PuzzleCardUnitView:initData(cardData, actionName, newFlag)
    self.m_cardData = cardData
    self.m_actionName = actionName
    self.m_newFlag = newFlag
    if self.m_lastCardData and self.m_cardData then
        if self.m_lastCardData.cardId == self.m_cardData.cardId then
            return
        end
    end
    if self.m_actionName == "idle" then
        self:runCsbAction("idle", true)
    elseif self.m_actionName == "show" then
        self:runCsbAction(
            "show",
            nil,
            function()
                self:runCsbAction("idle", true)
            end
        )
    elseif self.m_actionName == "start" then
        self:runCsbAction(
            "start",
            nil,
            function()
                self:runCsbAction("idle", true)
            end
        )
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:findChild("Node_flag"):setVisible(self.m_newFlag == true)
end

function PuzzleCardUnitView:initView()
    local cardData = self:getCardData()
    self.m_card_icon = self:findChild("card_icon")
    local sp = CardResConfig.getCardIcon(cardData.cardId, true)
    util_changeTexture(self.m_card_icon, sp)
end

function PuzzleCardUnitView:updateUI()
    if self.m_lastCardData and self.m_cardData then
        if self.m_lastCardData.cardId == self.m_cardData.cardId then
            return
        end
    end
    self:initView()
end

return PuzzleCardUnitView
