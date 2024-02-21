--[[
    小游戏控制
    author: 徐袁
    time: 2021-03-21 11:28:16
]]
require("GameModule.CardMiniGames.Statue.StatuePick.StatuePickConfig")
local StatuePickRewardData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickRewardData")
GD.StatuePickGameData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickGameData"):getInstance()
local StatuePickControl = class("StatuePickControl", BaseSingleton)

function StatuePickControl:ctor()
    StatuePickControl.super.ctor(self)
end

function StatuePickControl:getInstance()
    if not self._instance then
        self._instance = self.__index:create()
        self._instance:initObserver()
    end
    return self._instance
end

function StatuePickControl:initObserver()
end

function StatuePickControl:enterStatuePickSys()
    -- 处理背景音效
    -- gLobalSoundManager:pauseBgMusic()
    -- self.m_pickGameBg = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueBackGround, true)
    gLobalSoundManager:playSubmodBgm(CardResConfig.CARD_MUSIC.StatueBackGround, "StatuePickGame", ViewZorder.ZORDER_UI)
end

function StatuePickControl:exitStatuePickSys()
    -- 处理背景音效
    -- if self.m_pickGameBg then
    --     gLobalSoundManager:stopAudio(self.m_pickGameBg)
    -- end
    -- gLobalSoundManager:resumeBgMusic()
    gLobalSoundManager:removeSubmodBgm("StatuePickGame")
end

-- 显示过场云彩动画界面
function StatuePickControl:showCloudLayer()
    self:enterStatuePickSys()
    local view = gLobalViewManager:getViewByName("StatuePickCloudLayer")
    if not view then
        view = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickCloudLayer")
        view:setName("StatuePickCloudLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_GUIDE)
    end
end

-- 显示小游戏界面
function StatuePickControl:showStatuePickMainLayer()
    local view = gLobalViewManager:getViewByName("StatuePickMainLayer")
    if not view then
        view = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickMainLayer")
        view:setName("StatuePickMainLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- 展示开始界面动画
function StatuePickControl:showStartLayer()
    local view = gLobalViewManager:getViewByName("StatuePickStartLayer")
    if not view then
        view = util_createView("GameModule.CardMiniGames.Statue.StatuePick/StatuePickStartLayer")
        view:setName("StatuePickStartLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- 开箱次数用完，显示购买游戏次数和领取界面
function StatuePickControl:showPicksOver()
    local view = gLobalViewManager:getViewByName("StatuePickOverLayer")
    if not view then
        view = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickOverLayer")
        view:setName("StatuePickOverLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
    end
end

-- 检查PICK次数
function StatuePickControl:checkPicks()
    if StatuePickGameData:getPicks() <= 0 then
        -- 是否能有购买次数
        if not StatuePickGameData:isHasBuyTimes() then
            -- 申请结算
            self:requestCollectRewards()
        else
            gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_PICKS_FINISHED)
        end
    else
        -- 晃动
        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_SHAKE_TIMER, {status = "resumeShake"})
    end
end

-- 显示领奖界面
function StatuePickControl:showCollectLayer()
    local view = gLobalViewManager:getViewByName("StatuePickCollectLayer")
    if not view then
        view = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickCollectLayer")
        view:setName("StatuePickCollectLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- 进入小游戏
function StatuePickControl:requestEnterGame()
    -- local status = StatuePickGameData:getGameStatus()
    -- if status == StatuePickStatus.FINISH then
    --     return
    -- end

    -- 显示过场动画
    self:showCloudLayer()
end

-- 开始游戏
function StatuePickControl:requestStartGame()
    local successCallFunc = function()
        local view = gLobalViewManager:getViewByName("StatuePickStartLayer")
        if StatuePickGameData:getGameStatus() ~= StatuePickStatus.FINISH then
            local callFunc = function()
                gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_GAME_START)
            end

            if view then
                view:closeUI(callFunc)
            else
                callFunc()
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_GAME_UPDATE)
            local callFunc = function()
                local mainView = gLobalViewManager:getViewByName("StatuePickMainLayer")
                if mainView then
                    mainView:closeUI()
                end
            end
            if view then
                view:closeUI(callFunc)
                self:exitStatuePickSys()
            end
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFunc = function()
        gLobalViewManager:removeLoadingAnima()
    end

    gLobalViewManager:addLoadingAnima(true)
    local tExtraInfo = {type = StatuePickGameType.START}
    CardSysNetWorkMgr:sendCardSpecialGameRequest(tExtraInfo, successCallFunc, failedCallFunc)
end

-- 开箱子
function StatuePickControl:requestOpenBox(index)
    -- 判断剩余次数
    local _picks = StatuePickGameData:getPicks()
    if _picks <= 0 then
        return
    end
    -- 判断箱子是否已打开
    local boxInfo = StatuePickGameData:getBoxReward(index)
    if not boxInfo or boxInfo:isOpened() then
        return
    end

    local successCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_OPEN_BOX, {index = index})
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFunc = function()
        gLobalViewManager:removeLoadingAnima()
    end

    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBoxClick)

    gLobalViewManager:addLoadingAnima(true)
    local boxId = boxInfo:getId()
    local tExtraInfo = {id = boxId, type = StatuePickGameType.PLAY}

    gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_SHAKE_TIMER, {status = "clearShake"})
    -- 发送开宝箱消息
    CardSysNetWorkMgr:sendCardSpecialGameRequest(tExtraInfo, successCallFunc, failedCallFunc)
end

-- 购买PICK次数
function StatuePickControl:buyPicks()
    -- 钻石是否足够
    local _price = StatuePickGameData:getBuyPrice()
    -- 当前玩家的宝石数
    local userGemsNum = globalData.userRunData.gemNum or 0
    if not _price or _price > userGemsNum then
        local callback = function()
            self:openGemStore()
        end
        local view = gLobalViewManager:getViewByName("StatuePickOverLayer")
        if not view then
            callback()
        else
            view:closeUI(callback)
        end
        return
    end

    local successCallFunc = function()
        globalData.userRunData.gemNum = globalData.userRunData.gemNum - _price
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)

        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_BUY_PICKS_RESULT, {result = true})
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_BUY_PICKS_RESULT, {result = false})
    end

    local tExtraInfo = {type = StatuePickGameType.PURCHASE}
    CardSysNetWorkMgr:sendCardSpecialGameRequest(tExtraInfo, successCallFunc, failedCallFunc)
end

-- 结算
function StatuePickControl:requestCollectRewards()
    gLobalViewManager:addLoadingAnima(true)
    local successCallFunc = function()
        local callFunc = function()
            self:showCollectLayer()
        end
        local view = gLobalViewManager:getViewByName("StatuePickOverLayer")
        if view then
            view:closeUI(callFunc)
        else
            callFunc()
        end

        local gems = StatuePickRewardData:getInstance():getGems()
        if gems > 0 then
            globalData.userRunData.gemNum = globalData.userRunData.gemNum + gems
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        end

        local coins = StatuePickRewardData:getInstance():getCoins()
        if coins > 0 then
            globalData.userRunData:setCoins(globalData.userRunData.coinNum + coins)
        end

        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_COLLECT_REWARD_RESULT, {result = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_COLLECT_REWARD_RESULT, {result = false})
        gLobalViewManager:removeLoadingAnima()
    end
    local tExtraInfo = {type = StatuePickGameType.FINISH}
    CardSysNetWorkMgr:sendCardSpecialGameRequest(tExtraInfo, successCallFunc, failedCallFunc)
end

function StatuePickControl:openGemStore()
    local params = {shopPageIndex = 2 , dotKeyType = "Push", dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
    local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
    view.buyShop = true

    view:setOverFunc(
        function()
            self:showPicksOver()
        end
    )
end

-- 是否正在升级
function StatuePickControl:setBoxInLevelup(isLevelup)
    self.m_isBoxLevelup = isLevelup
end

function StatuePickControl:getBoxInLevelup()
    return self.m_isBoxLevelup
end

return StatuePickControl
