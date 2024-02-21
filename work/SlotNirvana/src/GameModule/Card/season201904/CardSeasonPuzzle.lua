--[[--
    小游戏入口
]]
local CardSeasonPuzzle = class("CardSeasonPuzzle", util_require("base.BaseView"))
function CardSeasonPuzzle:initUI()
    self:createCsbNode(CardResConfig.season201904.CardSeasonPuzzleRes)

    self.m_numLB = self:findChild("BitmapFontLabel_1")
    self.m_touch = self:findChild("Panel_wheel")
    self.m_spLock = self:findChild("sp_lock")
    self.m_spLock:setVisible(false)
    self.m_nodeNum = self:findChild("Node_Num")
    self:addClick(self.m_touch)
    self:runCsbAction("idle")
    self:initRedPoint()
    self:updateUI()
end

function CardSeasonPuzzle:initRedPoint( )
    if self.m_nodeNum ~= nil then
        self.m_redPoint = util_createView("GameModule.Card.season201904.CardRedPoint")
        self.m_nodeNum:addChild(self.m_redPoint)
    end
end

function CardSeasonPuzzle:updateUI()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if self.m_redPoint then
        if data and data.pickLeft > 0 then
            self.m_redPoint:updateNum(data.pickLeft)
            self.m_redPoint:setVisible(true)
        else
            self.m_redPoint:setVisible(false)
        end
    end
    -- 临时修改
    -- self:runCsbAction("idle")
    -- self.m_spLock:setVisible(true)
end

function CardSeasonPuzzle:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_wheel" then
        if self.m_spLock:isVisibleEx() then
            self:showTip()
        else
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)

            CardSysManager:getPuzzleGameMgr():showPageMainUI()
        end
    end
end

function CardSeasonPuzzle:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateUI()
        end,
        CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PURCHASE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateUI()
        end,
        CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PICK
    )
end

function CardSeasonPuzzle:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function CardSeasonPuzzle:showTip()
    local view = self:getChildByName("PuzzleTip")
    if view then
        return
    end

    view = util_createView("GameModule.Card.season201904.CardSeasonPuzzleTip")
    view:setName("PuzzleTip")
    view:setPosition(cc.p(0, 75))
    self:addChild(view)
end

return CardSeasonPuzzle
