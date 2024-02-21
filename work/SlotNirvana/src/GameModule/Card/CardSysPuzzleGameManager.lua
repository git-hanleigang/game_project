--[[
    集卡小游戏管理器
]]
local CardSysPuzzleGuideManager = util_require("GameModule.Card.CardSysPuzzleGuideManager")
local CardSysPuzzleGameManager = class("CardSysPuzzleGameManager")

-- 章节类型
local PUZZLE_TYPE = {
    normal = "NORMAL",
    golden = "GOLDEN",
    naod = "NADO"
}

function CardSysPuzzleGameManager:ctor()
    self.m_isInPuzzleGame = nil

    self.m_puzzlGuideMgr = CardSysPuzzleGuideManager.new()
end

function CardSysPuzzleGameManager:getPuzzleGuideMgr()
    return self.m_puzzlGuideMgr
end

function CardSysPuzzleGameManager:getPuzzleType(puzzleType)
    return PUZZLE_TYPE[puzzleType]
end

function CardSysPuzzleGameManager:isInPuzzleGame()
    return self.m_isInPuzzleGame
end

function CardSysPuzzleGameManager:enterPuzzlePage()
    self:showPageMainUI()
end

function CardSysPuzzleGameManager:exitPuzzlePage()
end

-- 开始
-- completePageIndex:外部掉落时集齐某一页碎片
function CardSysPuzzleGameManager:enterPuzzleGame(completePageIndex)
    -- 购买埋点
    self.m_preEntryType = gLobalSendDataManager:getLogIap():getEntryType()
    gLobalSendDataManager:getLogIap():setEntryType("CardPuzzle")

    self.m_isInPuzzleGame = true
    if self.m_PageMainUI and self.m_PageMainUI:isVisibleEx() then
        self.m_PageMainUI:setVisible(false)
    end
    self:showGameMainUI(completePageIndex)
end

-- 结束
function CardSysPuzzleGameManager:exitPuzzleGame()
    gLobalSendDataManager:getLogIap():setEntryType(self.m_preEntryType)
    self.m_isInPuzzleGame = false
    if self.m_PageMainUI and self.m_PageMainUI:isVisibleEx() == false then
        self.m_PageMainUI:setVisible(true)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUZZLE_GAME_END)
end

function CardSysPuzzleGameManager:showPageMainUI()
    if self.m_PageMainUI then
        return
    end
    local _curAlbumID = CardSysRuntimeMgr:getCurAlbumID()
    local _logic = CardSysRuntimeMgr:getSeasonLogic(_curAlbumID)
    if _logic and _logic.getPuzzlePageLuaName and _logic:getPuzzlePageLuaName() ~= nil then
        self.m_PageMainUI = util_createView(_logic:getPuzzlePageLuaName())
        if self.m_PageMainUI then
            gLobalViewManager:showUI(self.m_PageMainUI, ViewZorder.ZORDER_UI)
            CardSysManager:hideCardAlbumView()
        end
    end
end

function CardSysPuzzleGameManager:closePageMainUI(callBack)
    if self.m_PageMainUI ~= nil then
        if self.m_PageMainUI.closeUI then
            self.m_PageMainUI:closeUI(callBack)
        end
        self.m_PageMainUI = nil

        CardSysManager:redisplayCardAlbumView()
    end
end

function CardSysPuzzleGameManager:showGameMainUI(completePageIndex)
    if self.m_GameMainUI then
        return
    end
    local _curAlbumID = CardSysRuntimeMgr:getCurAlbumID()
    local _logic = CardSysRuntimeMgr:getSeasonLogic(_curAlbumID)
    if _logic and _logic.getPuzzlePageLuaName and _logic:getPuzzleGameLuaName() ~= nil then
        self.m_GameMainUI = util_createView(_logic:getPuzzleGameLuaName(), completePageIndex)
        if self.m_GameMainUI then
            gLobalViewManager:showUI(self.m_GameMainUI, ViewZorder.ZORDER_UI)
        else
            -- 没有找到资源时，直接发消息通知，结束了集卡小游戏，不影响外部功能逻辑
            release_print("---- cannot find CardCode/season201904/PuzzleGame/PuzzleGameMainUI ----")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUZZLE_GAME_END)
        end
    end
end

function CardSysPuzzleGameManager:closeGameMainUI(callBack)
    if self.m_GameMainUI ~= nil then
        if self.m_GameMainUI.closeUI then
            self.m_GameMainUI:closeUI(callBack)
        end
        self.m_GameMainUI = nil

        -- 退出集卡小游戏
        self:exitPuzzleGame()
    end
end

function CardSysPuzzleGameManager:isOverShowing()
    if self.m_GameOverUI == nil then
        return false
    end
    return true
end

function CardSysPuzzleGameManager:showGameOverUI(callBack)
    if self.m_GameOverUI then
        return
    end
    gLobalViewManager:addLoadingAnimaDelay()
    CardSysNetWorkMgr:sendPuzzleGameRequest(
        {status = 2},
        function()
            gLobalViewManager:removeLoadingAnima()
            if callBack then
                callBack()
            end
            -- 刷新小游戏主界面上的按钮状态
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_UPDATE_PICK)

            -- 判断是否有奖励
            local data = CardSysRuntimeMgr:getPuzzleGameData()
            if data and data.reward[1] then
                local puzzleReward = data and data.reward[1]
                if puzzleReward.coins > 0 or #puzzleReward.cardDrops > 0 or #puzzleReward.rewards > 0 then
                    self.m_GameOverUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameOverUI")
                    gLobalViewManager:showUI(self.m_GameOverUI, ViewZorder.ZORDER_UI)
                else
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_CHANGE_BOX)
                end
            else
                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_CHECK_CHANGE_BOX)
            end
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
            if callBack then
                callBack()
            end
            gLobalViewManager:showReConnect()
        end
    )
end

function CardSysPuzzleGameManager:closeGameOverUI(callBack)
    if self.m_GameOverUI ~= nil then
        if self.m_GameOverUI.closeUI then
            self.m_GameOverUI:closeUI(callBack)
        end
        self.m_GameOverUI = nil
    end
end

function CardSysPuzzleGameManager:showBuyMore(gemNode)
    if self.m_buyMoreUI then
        return
    end
    -- 断线重连用
    globalData.isPuzzleGameBuyMore = true
    self:sendExtraRequest({{"isPuzzleGameBuyMore", true}})
    self.m_buyMoreUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameGemBuyLayer", gemNode)
    gLobalViewManager:showUI(self.m_buyMoreUI, ViewZorder.ZORDER_UI)
end

function CardSysPuzzleGameManager:closeBuyMore(callBack)
    if self.m_buyMoreUI ~= nil then
        if self.m_buyMoreUI.closeUI then
            -- 断线重连用
            globalData.isPuzzleGameBuyMore = false
            self:sendExtraRequest({{"isPuzzleGameBuyMore", false}})
            self.m_buyMoreUI:closeUI(callBack)
        end
        self.m_buyMoreUI = nil
    end
end

function CardSysPuzzleGameManager:showPageCompleteUI()
    self.m_pageCompleteUI = util_createView("GameModule.Card.season201904.PuzzlePage.PageCompleteUI")
    gLobalViewManager:showUI(self.m_pageCompleteUI, ViewZorder.ZORDER_UI)
    return self.m_pageCompleteUI
end

function CardSysPuzzleGameManager:closePageCompleteUI(callBack)
    if self.m_pageCompleteUI ~= nil then
        if self.m_pageCompleteUI.closeUI then
            self.m_pageCompleteUI:closeUI(callBack)
        end
        self.m_pageCompleteUI = nil
    end
end

function CardSysPuzzleGameManager:showPageCompleteRewardUI(pageIndex, overCall, isOuterComplete)
    self.m_pageCompleteRewardUI = util_createView("GameModule.Card.season201904.PuzzlePage.PageCompleteRewardUI", pageIndex, overCall, isOuterComplete)
    gLobalViewManager:showUI(self.m_pageCompleteRewardUI, ViewZorder.ZORDER_UI)
end

function CardSysPuzzleGameManager:closePageCompleteRewardUI(callBack)
    if self.m_pageCompleteRewardUI ~= nil then
        if self.m_pageCompleteRewardUI.closeUI then
            self.m_pageCompleteRewardUI:closeUI(callBack)
        end
        self.m_pageCompleteRewardUI = nil
    end
end

function CardSysPuzzleGameManager:sendExtraRequest(extraKV)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    if extraKV and #extraKV > 0 then
        for i = 1, #extraKV do
            extraData[extraKV[i][1]] = extraKV[i][2]
        end
    end
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

return CardSysPuzzleGameManager
