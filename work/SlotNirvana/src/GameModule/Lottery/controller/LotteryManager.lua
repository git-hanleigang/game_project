--[[
Author: cxc
Date: 2021-11-18 20:09:40
LastEditTime: 2022-05-25 17:44:30
LastEditors: bogon
Description: 乐透 管理类
FilePath: /SlotNirvana/src/GameModel/Lottery/controller/LotteryManager.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryManager = class("LotteryManager", BaseGameControl)
local LotteryNetModel = util_require("GameModule.Lottery.net.LotteryNetModel")
local LotteryLbAddComponentContainer = util_require("GameModule.Lottery.controller.LotteryLbAddComponentContainer")

function LotteryManager:ctor()
    LotteryManager.super.ctor(self)
    self.m_chooseNumberList = {0, 0, 0, 0, 0, 0}
    self.m_openNumberHistoryList = {}
    self:setRefName(G_REF.Lottery)

    self.m_componentContainer = LotteryLbAddComponentContainer:create()
    -- 玩家一键领取
    self.m_randomNumberList = {}
end

function LotteryManager:getData()
    return globalData.lotteryData
end

-- 检查是否可以同步选择的号码给服务器
function LotteryManager:checkCanSyncNumberList()
    local bCanSync = true
    for _, number in pairs(self.m_chooseNumberList) do
        if number <= 0 then
            bCanSync = false
            break
        end
    end

    return bCanSync
end
-- 检查是否可以同步选择的号码给服务器
function LotteryManager:checkCanCancelChooseList()
    local bCancel = false
    for i, number in ipairs(self.m_chooseNumberList) do
        if number > 0 then
            bCancel = true
            break
        end
    end

    return bCancel
end

-- 选号界面选号列表
function LotteryManager:setChooseNumberList(_idx, _number)
    self.m_chooseNumberList[_idx] = _number
end
function LotteryManager:getChooseNumberList()
    return self.m_chooseNumberList
end
function LotteryManager:resetChooseNumberList()
    self.m_chooseNumberList = {0, 0, 0, 0, 0, 0}
end

-- 开奖历史记录
function LotteryManager:setOpenNumberHistoryList(_list)
    self.m_openNumberHistoryList = _list or {}
end
function LotteryManager:getOpenNumberHistoryList()
    return self.m_openNumberHistoryList
end
function LotteryManager:resetOpenNumberHistoryList()
    self.m_openNumberHistoryList = {}
end

-- 检查是否停止 选号
function LotteryManager:checkIsStopChoose()
    local data = self:getData()
    local endChooseTimeAt = data:getEndChooseTimeAt()
    if endChooseTimeAt < util_getCurrnetTime() then
        return false
    end

    return true
end

-- 显示乐透主界面
function LotteryManager:showMainLayer(_callFunc,_tableIndex)
    _callFunc = _callFunc or function()    end

    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("LotteryMainUI") then
        return
    end

    local view = util_createView("views.lottery.mainUI.LotteryMainUI",_callFunc,_tableIndex)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

-- 显示开奖界面
function LotteryManager:triggerOpenRewardLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local data = self:getData()
    local bCanCollect = data:checkCanCollectReward()
    if not bCanCollect then
        return false
    end

    if gLobalViewManager:getViewByExtendData("LotteryOpenReward") then
        return false
    end
    local view = util_createView("views.lottery.reward.LotteryOpenReward")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return true
end

-- 显示 选号面板
function LotteryManager:showChooseNumberLayer()
    if not self:isCanShowLayer() then
        return
    end

    -- 结束 选号时间了不弹板子
    local bCanChoose = self:checkIsStopChoose()
    if not bCanChoose then
        return
    end

    local view = util_createView("views.lottery.choose.LotteryChooseNumberLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示 奖券发送到邮箱面板
function LotteryManager:showTicketsToInboxLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("LotterTicketsToInboxLayer") then
        return
    end

    local view = util_createView("views.lottery.choose.LotterTicketsToInboxLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示 停止 选号提示面板
function LotteryManager:showTimeOutTipLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("LotterTimeOutTipLayer") then
        return
    end

    local view = util_createView("views.lottery.choose.LotterTimeOutTipLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 掉落 乐透卷
function LotteryManager:onDropLotteryTickets(_cb, _bReconnect)
    _cb = _cb or function()
        end

    -- 检查 这一期是否停止下注了
    local bCanChoose = self:checkIsStopChoose()
    if not bCanChoose and not _bReconnect then
        local view = self:showTicketsToInboxLayer()
        if view then
            view:setOverFunc(_cb)
            return
        end

        _cb()
    end

    --乐透卷数量
    local data = self:getData()
    local tickets = data:getLeftTickets()
    if tickets <= 0 then
        _cb()
        return
    end
    local yourList = data:getYoursList()
    local yourListLen = #yourList
    -- 创建协程依次掉落
    self.dropCoroutine =
        coroutine.create(
        function()
            for i = 1, tickets do
                local view = self:showChooseNumberLayer()
                if not view then
                    break
                end

                -- view:setOverFunc(
                --     function()
                --         -- tickets = tickets - 1
                --         util_resumeCoroutine(self.dropCoroutine)
                --     end
                -- )
                coroutine.yield()
            end

            local callFunc = function()
                -- 所有的选号结束 查看是否触发乐透挑战弹板
                local bPopLotteryChallenge = self:checkPopLotteryChallenge()
                if bPopLotteryChallenge then
                    self:popLotteryChallengeLayer(_cb)
                else
                    _cb()
                end
            end

            callFunc()
            
            -- -- 策划说，这个第一次选号后不再弹这个板子了
            -- if yourListLen <= 0 then
            --     self:popLotteryOpenLayer(callFunc)
            -- else
            --     callFunc()
            -- end

            self.dropCoroutine = nil
        end
    )

    util_resumeCoroutine(self.dropCoroutine)
end

-- 重启 选号弹板协程
function LotteryManager:resumeChooseNumberCoroutine()
    util_resumeCoroutine(self.dropCoroutine)
end

-- 显示 选号提示面板 _bRandom(是否是机选号码)
function LotteryManager:showChooseNumberTipLayer(_bRandom)
    local view = util_createView("views.lottery.choose.LotteryChooseBallTip", _bRandom)
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 领取奖励 面板
function LotteryManager:showCollectRewardLayer(_coins)
    local view = util_createView("views.lottery.reward.LotteryCollectReward", _coins)
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 未中奖提示 面板
function LotteryManager:showRewardTipsLayer()
    local view = util_createView("views.lottery.other.LotteryRewardTipsLayer")
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示乐透FAQ界面
function LotteryManager:showFAQView()
    local view = util_createView("views.lottery.other.LotteryFAQPanel")
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示乐透奖券弹框界面
function LotteryManager:showTicketView(_index, _cb,num)
    _cb = _cb or function()
        end
    if not self:isCanShowLayer() then
        _cb()
        return
    end
    local view = util_createView("views.lottery.other.LotteryTicketPanel", _index, _cb,num)
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 结算后弹出上一期中奖信息
function LotteryManager:popPerGrandPrizeInfoLayer(_data)
    local view = util_createView("views.lottery.other.LotteryPerGrandPrizeInfoLayer", _data)
    if not view then
        return
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 跳过开奖 结算弹板
function LotteryManager:popSkipSettlementInfoLayer(_gainCoins)
    if not _gainCoins or _gainCoins <= 0 then
        self:popSkipNoWinLayer()
    else
        self:popSkipWinLayer(_gainCoins)
    end
    
end
function LotteryManager:popSkipNoWinLayer()
    local view = util_createView("views.lottery.reward.skipReward.LotterySkipNoWinLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
function LotteryManager:popSkipWinLayer(_gainCoins)
    local view = util_createView("views.lottery.reward.skipReward.LotterySkipWinLayer", _gainCoins)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 自己选号详情 弹板
function LotteryManager:popYoursNumberListLayer()
    local view = util_createView("views.lottery.reward.skipReward.LotteryShowBetListLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 注册金币滚动组件
function LotteryManager:registerCoinAddComponent(_lb, _maxUIW, _limitStrCount)
    if not _lb then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    self.m_componentContainer:addComponent(_lb, _maxUIW, _limitStrCount)

    -- local component = cc.ComponentLua:create("views/lottery/base/LotteryLabelAddComponent.lua")
    -- if not component.__enabled then
    --     return
    -- end

    -- component:setMaxUIW(_maxUIW)
    -- component:setCoinFormatLimitCount(_limitStrCount)
    -- _lb:addComponent(component)
end

-- 显示引导 layer
function LotteryManager:showGuideLayer(_highlightNodeList, _npcGuideNodeList, _scale)
    if not tolua.isnull(self.m_guideLayer) then
        self.m_guideLayer:removeSelf()
    end

    self.m_guideLayer = util_createView("views.lottery.other.LotteryGuideLayer", _highlightNodeList, _npcGuideNodeList, _scale)
    gLobalViewManager:getViewLayer():addChild(self.m_guideLayer, ViewZorder.ZORDER_GUIDE + 1)
end

-- 开奖界面底部金币node
function LotteryManager:setBottomCoinsFlyEndNode(_node)
    self.m_flyEndNode = _node
end
function LotteryManager:getBottomCoinsFlyEndNode()
    return self.m_flyEndNode
end

------------------------------ 网络 ------------------------------
-- 乐透历史开奖
function LotteryManager:sendHistoryListReq()
    local list = self:getOpenNumberHistoryList()
    if #list > 0 then
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.RECIEVE_HISTORY_LIST)
        return
    end

    local successFunc = function(_history)
        -- _history = {{period = 20111, personCount=3, hitNumber="1-2-3-4-5-3"}}
        self:setOpenNumberHistoryList(_history)
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.RECIEVE_HISTORY_LIST)
    end
    G_GetNetModel(NetType.Lottery):sendHistoryListReq(successFunc, successFunc)
end
-- 乐透提交选号
function LotteryManager:sendSyncChooseNumber(_bRandom,_isAuto)
    local successFunc = function(_resultData)
        -- 解析数据看是否有
        self:parseRandomNumberList(_resultData)
        
        self:resetChooseNumberList()
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.RECIEVE_SYNC_CHOOSE_NUMBER)
        -- 一键选号 通知掉落界面 需要展示一键序号列表
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CREATE_RANDOM_NUMBER_SUCCESS, {isOneKey = _isAuto})
        
    end

    local numberStr = table.concat(self.m_chooseNumberList, "-")
    if _bRandom == nil then
        _bRandom = false
    end

    local failedFunc = function ()
        -- 一键选号 通知掉落界面 需要展示一键序号列表
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CREATE_RANDOM_NUMBER_SUCCESS, {isOneKey = false})
    end

    G_GetNetModel(NetType.Lottery):sendSyncChooseNumber(numberStr, _bRandom,_isAuto, successFunc , failedFunc)
end
-- 乐透获取机选号码
function LotteryManager:sendGenerateRanNumber()
    local successFunc = function(_numberList)
        if _numberList and #_numberList == 6 then
            for idx = 1, 6 do
                self.m_chooseNumberList[idx] = tonumber(_numberList[idx]) or 0
            end
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.RECIEVE_GENERATE_RANDOM_NUMBER)
        end
    end
    G_GetNetModel(NetType.Lottery):sendGenerateRanNumber(successFunc)
end
-- 乐透领取奖励
function LotteryManager:sendCollectReward()
    local successFunc = function()
        self:resetOpenNumberHistoryList()
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.RECIEVE_COLLECT_REWARD)
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.LOTTERY_HALLNODE_UPDATE_DATA)
    end
    G_GetNetModel(NetType.Lottery):sendCollectReward(successFunc, successFunc)
end
------------------------------ 网络 ------------------------------
------------------------------ 优化 ------------------------------
function LotteryManager:setChooseNumTag(_num)
    self.m_numTag = _num
end

function LotteryManager:getChooseNumTag()
    return self.m_numTag or 0
end

-- 每期第一次选号结束后弹乐透宣传弹板
function LotteryManager:popLotteryOpenLayer(_callFunc)
    _callFunc = _callFunc or function()
        end

    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("LotteryOpenLayer") then
        return
    end

    local view = util_createView("views.lottery.other.LotteryOpenLayer", _callFunc)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end
------------------------------ 优化 ------------------------------

------------------------------ 配套活动 ------------------------------
-- 乐透挑战 是否达成任务未领奖
function LotteryManager:checkPopLotteryChallenge()
    local mgr = G_GetMgr(ACTIVITY_REF.LotteryChallenge)
    if not mgr then
        return false
    end

    local bCanShowLayer = mgr:isCanShowLayer()
    if not bCanShowLayer then
        return false
    end

    local bPop = mgr:checkHadUnGainReward()
    return bPop
end

-- 乐透挑战 是否达成任务未领奖
function LotteryManager:popLotteryChallengeLayer(_cb)
    local mgr = G_GetMgr(ACTIVITY_REF.LotteryChallenge)
    if not mgr then
        if _cb then
            _cb()
        end
        return
    end

    mgr:showPopLayer(nil, _cb)
end

-- 乐透 额外奖励 领取
function LotteryManager:triggerDropExtraReward()
    local mgr = G_GetMgr(ACTIVITY_REF.LotteryJackpot)
    if not mgr then
        return false
    end

    local data = self:getData()
    if not data then
        return false
    end

    local rewardInfo = data:getLotteryExActRewardInfo()
    if not rewardInfo.rewardList or #rewardInfo.rewardList <= 0 then
        return false
    end

    local bPop = mgr:triggerDropExtraReward(rewardInfo)
    if not bPop then
        return false
    end

    return true
end

-- 乐透额外奖励 重置数据
function LotteryManager:resetDropExtraReward()
    local data = self:getData()
    if not data then
        return false
    end

    data:resetLotteryExActRewardInfo()
end
------------------------------ 配套活动 ------------------------------

------------------------------ 商城掉落临时 ------------------------------
function LotteryManager:setBuyTipDropTickets(_count)
    self.m_shopDropCount = _count
end
function LotteryManager:getBuyTipDropTickets()
    return self.m_shopDropCount or 0
end
function LotteryManager:resetBuyTipDropTickets()
    self.m_shopDropCount = 0
end
------------------------------ 商城掉落临时 ------------------------------

------------------------------ 展示一键选号 ------------------------------
-- 解析当前选号数据里是否有一键选号数据
function LotteryManager:parseRandomNumberList(_result)
    if _result.type and _result.type == "auto" then
        -- 证明此时玩家一键领取并选号
        self.m_randomNumberList = {}
        self.m_randomNumberList = _result.numbersAdd
    end
end

-- 获取当前一键选号的号码
function LotteryManager:getRandomNumberList()
    return self.m_randomNumberList or {}
end
------------------------------ 展示一键选号 ------------------------------

return LotteryManager
