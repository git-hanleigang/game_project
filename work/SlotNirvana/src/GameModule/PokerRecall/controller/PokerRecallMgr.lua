local PokerRecallMgr = class("PokerRecallMgr", BaseGameControl)
local PokerRecallNet = util_require("GameModule.PokerRecall.net.PokerRecallNet")
function PokerRecallMgr:ctor()
    PokerRecallMgr.super.ctor(self)
    self:setRefName(G_REF.PokerRecall)
    self.m_isFirst = false
    self.m_touchCount = 0
    -- 控制当前界面按钮能否点击
    self.m_canTouch = nil
end
function PokerRecallMgr:parseData(data)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.PokerRecall.model.PokerRecallData"):create()
        _data:parseData(data)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

--玩家带付费项且为FALSE可以额外获得一次重新翻牌的机会
function PokerRecallMgr:getPokerRecallStatus()
    local gameData = self:getData()
    if gameData then
        return gameData:getPokerRecallStatus()
    end
    return nil
end

function PokerRecallMgr:startRecall(_status, _over)
    self.m_over = _over
    local call = function ()
        self:overRecall()
    end
    local ui = self:dropRecallTipsLayer(call)
    if not ui then
        if self.m_over then
            self.m_over()
            self.m_over = nil
        end
    end
end

function PokerRecallMgr:overRecall(_isStopBgMusic)
    if self.m_over then
        self.m_over()
        self.m_over = nil
    end

    if _isStopBgMusic then
        self:stopPokerRecallBgMusic()
    end
end

function PokerRecallMgr:isQuestLobby()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    --串一行
    if questConfig and questConfig.m_isQuestLobby then
        return true
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
        return true
    end
    return false
end

function PokerRecallMgr:isInPoker()
    if gLobalViewManager:getViewByName("PokerUI_Main") ~= nil then
        return true
    end
    return false
end

function PokerRecallMgr:stopPokerRecallBgMusic()
    -- if gLobalViewManager:isLobbyView() then
    --     if self:isQuestLobby() then
    --         gLobalSoundManager:playBgMusic("Activity/QuestSounds/Quest_bg.mp3")
    --     elseif self:isInPoker() then
    --         gLobalSoundManager:playBgMusic("Activity/Activity_Poker/other/music/bg_main.mp3")
    --     else
    --         --上线兼容使用方式
    --         local lobbyBgmPath = "Sounds/bkg_lobby_new.mp3"
    --         if gLobalActivityManager.getLobbyMusicPath then
    --             lobbyBgmPath = gLobalActivityManager:getLobbyMusicPath()
    --         end
    --         gLobalSoundManager:playBgMusic(lobbyBgmPath)
    --     end
    -- else
    --     --关卡中
    --     if self.m_preMusicName then
    --         gLobalSoundManager:playBgMusic(self.m_preMusicName)
    --         self.m_preMusicName = nil
    --     end
    -- end
end

--外部需要掉落这个弹窗界面
function PokerRecallMgr:dropRecallTipsLayer(_call)
    if not self:isCanShowLayer() then
        if _call then
            _call()
        end
        return nil
    end

    if gLobalViewManager:getViewByName("PokerRecallDropLayer") ~= nil then
        return nil
    end

    local view = util_createView("PokerRecallDropLayer", _call)
    view:setName("PokerRecallDropLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

--外部需要弹出PokerRecall界面的接口
function PokerRecallMgr:showMainLayer(_gameId)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByName("PokerRecallMainLayer") ~= nil then
        return nil
    end

    self:setCurPokerGameId(_gameId)
    local gameData = self:getCurPokerGameData()
    if not gameData then
        release_print("--------获取游戏数据失败-------")
        return nil
    end

    local view = util_createView("PokerRecallMainLayer")
    view:setName("PokerRecallMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

--外部弹出奖励界面的接口
function PokerRecallMgr:showRewardLayer()
    local view = util_createView("PokerRecallRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

--外部弹出二次确认弹板
function PokerRecallMgr:showRewardTipsLayer()
    local view = util_createView("PokerRecallTipsLayer", _coin)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

--展示新手引导层
function PokerRecallMgr:showGuideLayer(_highlightNodeList, _npcGuideNodeList, _scale)
    if not tolua.isnull(self.m_guideLayer) then
        self.m_guideLayer:removeSelf()
    end
    --玩家带付费项且没有付费过,关闭引导界面
    local gameData = self:getCurPokerGameData()
    if gameData then
        local leftCount = gameData:getLeftCount()
        local isMark = gameData:getIsMark()
        local pokerRecallStatus = self:getPokerRecallStatus()

        if isMark then
            if not pokerRecallStatus and leftCount <= 0 then
                self.m_guideLayer = util_createView("PokerRecallGuideLayer", _highlightNodeList, _npcGuideNodeList, _scale)
                gLobalViewManager:getViewLayer():addChild(self.m_guideLayer, ViewZorder.ZORDER_GUIDE + 1)
            end
        end
    end
end

--断线重连时新手引导状态
function PokerRecallMgr:setGuideStatus(_status)
    self.m_guideStatus = _status
end

function PokerRecallMgr:getGuideStatus()
    return self.m_guideStatus
end

-- ************************ 协议 *************************** --
--发送翻牌协议
function PokerRecallMgr:sendPlayMessage(_gameId, _index, _isChange)
    local successFunc = function(_data)
        --通知界面刷新数据
        release_print("--------通知界面去做UI显示:2")
        self:collectCallBack(_data)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_CARD_CLICK, _index)
        --只要翻牌一次就向邮件发送消息，刷新邮件
        if not self.m_isFirst then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
            self.m_isFirst = true
        end
    end

    local failedFunc = function()
        --翻牌失败
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()

        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_CARD_CLICK_FAILED, _index)
    end
    gLobalViewManager:addLoadingAnimaDelay()
    PokerRecallNet:requestPokerRecallPlay(_gameId, _index, _isChange, successFunc, failedFunc)
end

--发送领取奖励协议
function PokerRecallMgr:sendRewardMessage(_idx)
    local successFunc = function(target, result)
        --通知界面做表现
        --此时证明玩家已经玩了这个游戏。如果邮件框显示
        gLobalNoticManager:postNotification(ViewEventType.NOTIFE_POKER_RECALL_REFRESH_INBOX)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_COLLECT_REWARD)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_PAYTABLE_STOPACTION)
        --刷新邮件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        self:resetTouchCount()
        --self:resetGameDataIndex()
    end

    local failedFunc = function(target, result)
        --领取奖励失败此时通知弹板让按钮可以点击
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_COLLECT_REWARD_FAILED)
        gLobalViewManager:removeLoadingAnima()
    end

    PokerRecallNet:requestPokerRecallReward(_idx, successFunc, failedFunc)
end

function PokerRecallMgr:collectCallBack(_resultData)
    --发送事件告诉PayTable是哪个中奖了
    local gameData = self:getCurPokerGameData()
    if gameData then
        local pokerRewardData = gameData:getPokerReward()
        if not pokerRewardData then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_STOP_REWARD_ACTION)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_PAY_TABLE)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POKER_RECALL_PAYTABLE_RUNACTION)
    end
end

function PokerRecallMgr:setCurPokerGameId(_gameId)
    if not _gameId then
        -- 取最新的GameData
        local gameData = self:getData()
        if gameData then
            local lastData = gameData:getLastPokerGameData()
            if lastData then
                _gameId = lastData:getGameId()
            end
        end
    end
    self.m_curGameId = _gameId
end
function PokerRecallMgr:getCurPokerGameId()
    return self.m_curGameId
end

-- ********************** End ****************** --
--获取当前小游戏数据
function PokerRecallMgr:getCurPokerGameData()
    local gameData = self:getData()
    if gameData then
        if self.m_curGameId then
            return gameData:getCurPokerGameDataById(self.m_curGameId)
        end
    end
    return nil
end

function PokerRecallMgr:isHasPlaying()
    local gameData = self:getData()
    if gameData then
        local _curIdx = gameData:getCurPokerRecallGameIdx()
        return _curIdx > 0
    end
    return false
end

-- function PokerRecallMgr:resetGameDataIndex()
--     local gameData = self:getData()
--     if gameData then
--         gameData:resetGameDataIndex()
--     end
-- end

function PokerRecallMgr:setTouchCount()
    self.m_touchCount = self.m_touchCount + 1
end

function PokerRecallMgr:getTouchCount()
    return self.m_touchCount
end

function PokerRecallMgr:resetTouchCount()
    if self.m_touchCount >= 5 then
        self.m_touchCount = 0
    end
end

-- 解决开局不让玩家点击按钮
function PokerRecallMgr:setToucElementStatus(_status)
    self.m_canTouch = _status
end

-- 外部获取这个状态值决定能否点击
function PokerRecallMgr:getTouchElementStatus()
    return self.m_canTouch
end

return PokerRecallMgr
