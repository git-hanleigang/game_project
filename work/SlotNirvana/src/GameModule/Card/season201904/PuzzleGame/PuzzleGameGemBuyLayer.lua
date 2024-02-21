--[[
    购买次数界面
    author:{author}
    time:2020-09-04 15:53:04
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameGemBuyLayer = class("PuzzleGameGemBuyLayer", BaseView)
function PuzzleGameGemBuyLayer:initUI(mainClass)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self.m_mainClass = mainClass
        
    self:createCsbNode(CardResConfig.PuzzleGemBuyRes, isAutoScale)

    self.m_lbGemNum = self:findChild("lb_gemNum")
    self.m_lbGemBuy = self:findChild("lb_gemNumBuy")
    self.m_spCPR = self:findChild("sp_chaopiaoren")
    self.m_nodeAddGems = self:findChild("node_addGemsModule")
    self.m_btnBuy = self:findChild("btn_buy")

    self.m_spineFinger = util_spineCreate("CardRes/season201904/CashPuzzle/spine/MrCash_juese_1", true, true, 1)
    self.m_spCPR:addChild(self.m_spineFinger)
    util_spinePlay(self.m_spineFinger, "idleframe1", true)

    self:resetGemNodePosition()
    
    self:initGem()

    self:updateInfo()
    
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", false)
        end
    )    
end

function PuzzleGameGemBuyLayer:onEnter()
    -- 集卡小游戏引导：第6步开始
    local rootScale = self.m_csbNode:getChildByName("root"):getScale()
    CardSysManager:getPuzzleGameMgr():getPuzzleGuideMgr():startGuide(6, self.m_btnBuy, rootScale)
    
    gLobalNoticManager:addObserver(self, function(self,params)
        -- 刷新宝石
        self:updateInfo()        
    end,CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_BUY_MORE_UPDATE)

    gLobalNoticManager:addObserver(self, function(self,params)
        -- 刷新宝石
        if self and self.updateInfo then
            self:updateInfo()
        end
    end,ViewEventType.NOTIFY_PURCHASE_SUCCESS)    
end

function PuzzleGameGemBuyLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)

    -- 集卡小游戏引导：第7步开始
    if self.m_mainClass and self.m_mainClass.startGuide then
        self.m_mainClass:startGuide(7)
    end
end

function PuzzleGameGemBuyLayer:updateInfo()
    local puzzleData = CardSysRuntimeMgr:getPuzzleGameData()
    if puzzleData then
        self.m_lbGemBuy:setString(tostring(puzzleData.needCardRuby))
        if puzzleData.cardRuby < puzzleData.needCardRuby then
            self.m_lbGemBuy:setColor(cc.c3b(255, 0, 0))
        else
            self.m_lbGemBuy:setColor(cc.c3b(255, 255, 255))
        end
    end

    -- 创建时刷新一下UI
    self:updateGem()
end


function PuzzleGameGemBuyLayer:resetGemNodePosition()
    local node = self.m_mainClass:getGemNode()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local localPos = self.m_nodeAddGems:getParent():convertToNodeSpace(worldPos)
    self.m_nodeAddGems:setPosition(localPos)
end

function PuzzleGameGemBuyLayer:initGem()
    self.m_GemUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainGem")
    self.m_nodeAddGems:addChild(self.m_GemUI)
end

function PuzzleGameGemBuyLayer:updateGem()
    if self.m_GemUI and self.m_GemUI.updateUI then
        self.m_GemUI:updateUI()
    end
end

function PuzzleGameGemBuyLayer:canClick()
    if self.m_buyed then
        return false
    end
    if self.m_closed then
        return false
    end
    if self.m_showOutTip then
        return false 
    end
    return true
end

function PuzzleGameGemBuyLayer:clickFunc(sender)
    local name = sender:getName()

    if not self:canClick() then
        return
    end

    if name == "btn_buy" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:buyTimes()
    elseif name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:getPuzzleGameMgr():closeBuyMore()
    end
end

function PuzzleGameGemBuyLayer:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true

    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end
    )
end

function PuzzleGameGemBuyLayer:buyTimes()
    -- local gemWorldPos = self.m_lbGemNum:getParent():convertToWorldSpace(cc.p(self.m_lbGemNum:getPositionX(),self.m_lbGemNum:getPositionY()))
    -- gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PURCHASE, {startWorldPos = gemWorldPos})
    -- CardSysManager:getPuzzleGameMgr():closeBuyMore()
    local puzzleData = CardSysRuntimeMgr:getPuzzleGameData()
    if puzzleData then
        if puzzleData.cardRuby < puzzleData.needCardRuby then
            self.m_showOutTip = true
            local view = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameGemOutTip")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            view:setOverFunc(function()
                if self and self.m_showOutTip == true then
                    self.m_showOutTip = false
                end
            end)
        else        
            self.m_buyed = true
            local gemWorldPos = self.m_lbGemNum:getParent():convertToWorldSpace(cc.p(self.m_lbGemNum:getPositionX(),self.m_lbGemNum:getPositionY()))
            gLobalViewManager:addLoadingAnimaDelay()
            CardSysNetWorkMgr:sendPuzzleGameRequest(
                {status = 3},
                function()
                    self.m_buyed = false
                    gLobalViewManager:removeLoadingAnima()
                    -- 购买成功
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PURCHASE, {startWorldPos = gemWorldPos})

                    CardSysManager:getPuzzleGameMgr():closeBuyMore()
                end,
                function()
                    self.m_buyed = false
                    gLobalViewManager:removeLoadingAnima()
                    gLobalViewManager:showReConnect()
                end
            )
        end
    end
end

return PuzzleGameGemBuyLayer
