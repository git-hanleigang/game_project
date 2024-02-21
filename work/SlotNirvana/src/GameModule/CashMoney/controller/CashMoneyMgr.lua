--[[
Author: your name
Date: 2022-04-19 11:14:32
LastEditTime: 2022-04-19 11:14:32
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/GameModule/CashMoney/controller/CashMoneyMgr.lua
--]]
local CashMoneyMgr = class("CashMoneyMgr", BaseGameControl)
local CashMoneyConfig = util_require("GameModule.CashMoney.config.CashMoneyConfig")
local CashMoneyNet = util_require("GameModule.CashMoney.net.CashMoneyNet")
-- 这个DataType 只是为了获得相对应的来源的游戏数据
local DataType = {
    CASHBONUS = "CashBonus", -- 这里的CashMoney 指的是正常从右下角CashBonus里进入
    PUT = "Put" -- 这里是渠道投放
}

local GameType = {
    NORMAL = "Normal", -- 这里普通版
    PAID = "Paid" -- 这里付费版
}

local TakeStatus = {
    INIT = 0,
    TAKE = 1
}

function CashMoneyMgr:ctor()
    CashMoneyMgr.super.ctor(self)
    self:setRefName(G_REF.CashMoney)
    self.m_currentGameId = 0
end

function CashMoneyMgr:setSelectPayIndex(_selectPayIndex)
    self.m_selectPayIndex = _selectPayIndex
end

function CashMoneyMgr:getSelectPayIndex()
    return self.m_selectPayIndex or 1
end

function CashMoneyMgr:parseData(_data)
    if not _data then
        return
    end

    local cashData = self:getData()
    if not cashData then
        cashData = require("GameModule.CashMoney.model.CashMoneyData"):create()
        cashData:parseData(_data)
        self:registerData(cashData)
    else
        cashData:parseData(_data)
    end
end
-- 根据游戏类型获取当前游戏状态为正在玩的游戏数据
function CashMoneyMgr:getPlayStatusGameData(_dataType)
    local gameData = nil
    local data = self:getData()
    if data then
        local gameList = data:getGameListByType(_dataType)
        for key, value in pairs(gameList) do
            local _tempGameData = value.gameData
            if _tempGameData:getGameStatus() then
                gameData = _tempGameData
                break
            end
        end
    end

    return gameData
end
-- 这里是给外部界面提供游戏当前类型是CashBonus还是投放的数据
function CashMoneyMgr:getGameType()
    return GameType
end

function CashMoneyMgr:getDataType()
    return DataType
end

-- 为外部提供记录TakeOffer状态的参数
function CashMoneyMgr:getTakeStatus()
    return TakeStatus
end

function CashMoneyMgr:getDataByGameId(_gameId)
    local gameData = nil
    local activityData = self:getData()
    if activityData then
        local gameList = activityData:getGameList()
        for i, v in pairs(gameList) do
            if v.gameId == _gameId then
                gameData = v.gameData
                break
            end
        end
    end
    return gameData
end

-- *********************************************** Layer *************************************************** --

-- 创建普通版主界面
function CashMoneyMgr:showMainLayer(_gameData, _overCall)
    if not self:isCanShowLayer() then
        if _overCall then
            _overCall()
        end
        return nil
    end

    if gLobalViewManager:getViewByExtendData("CashMoneyMainLayer") then
        return nil
    end

    local view = util_createView("CashMoney.CashMoneyNormal.CashMoneyMainLayer", _gameData)
    view:setName("CashMoneyMainLayer")
    if _overCall then
        view:setOverFunc(_overCall)
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建付费版主界面
function CashMoneyMgr:showPaidMainLayer(_gameData, _overCall)
    if not self:isCanShowLayer() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_CLOSE_NORMAL_LAYER)
        if _overCall then
            _overCall()
        end
        return nil
    end

    if gLobalViewManager:getViewByExtendData("CashMoneyPaidMainLayer") then
        return nil
    end

    local view = util_createView("CashMoney.CashMoneyPaid.CashMoneyPaidMainLayer", _gameData)
    view:setName("CashMoneyPaidMainLayer")
    if _overCall then
        view:setOverFunc(_overCall)
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建打开普通版或者付费版界面
function CashMoneyMgr:showCashMoneyGameView(_gameData, _gameType, _overCall)
    local gameData = _gameData or self:getPlayStatusGameData(_gameType)
    if gameData then
        if _gameType == GameType.NORMAL then
            self:showMainLayer(_gameData, _overCall)
        elseif _gameType == GameType.PAID then
            self:showPaidMainLayer(_gameData, _overCall)
        end
    end
end

-- 创建掉落弹板
function CashMoneyMgr:showTipsLayer(_overCall)
    -- 这里针对道具投放的数据，需要区分来源
    if not self:isCanShowLayer() then
        if _overCall then
            _overCall()
        end
        return nil
    end

    if gLobalViewManager:getViewByExtendData("CashMoneyShowTipLayer") then
        return nil
    end

    local view = util_createView("CashMoney.CashMoneyPaid.CashMoneyShowTipLayer", _overCall)
    view:setName("CashMoneyShowTipLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建引导付费界面
function CashMoneyMgr:showPurchaseLayer(_gameData, _overCall)
    if not self:isCanShowLayer() then
        if _overCall then
            _overCall()
        end
        return nil
    end

    if gLobalViewManager:getViewByExtendData("CashMoneyPurchaseLayer") then
        return nil
    end

    local view = util_createView("CashMoney.CashMoneyPaid.CashMoneyPurchaseLayer", _gameData, _overCall)
    view:setName("CashMoneyPurchaseLayer")
    if _overCall then
        view:setOverFunc(_overCall)
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建是否确认取消购买界面
function CashMoneyMgr:showPurchaseConfirmLayer(_gameData, _overCall)
    if not self:isCanShowLayer() then
        if _overCall then
            _overCall()
        end
        return nil
    end

    if gLobalViewManager:getViewByExtendData("CashMoneyPurchaseConfirmLayer") then
        return nil
    end

    local view = util_createView("CashMoney.CashMoneyPaid.CashMoneyPurchaseConfirmLayer", _gameData, _overCall)
    view:setName("CashMoneyPurchaseConfirmLayer")
    if _overCall then
        view:setOverFunc(_overCall)
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- *********************************************** Layer *************************************************** --

function CashMoneyMgr:setCurrentGameId(_gameId)
    self.m_currentGameId = _gameId or 0
end

function CashMoneyMgr:getCurrentGameId() 

    local gameId = self:getGameIdxFromCache()
    return gameId

    --return self.m_currentGameId
end

-- ****************************************** Request ************************************** --
-- play CashMoney
function CashMoneyMgr:sendPlay(_gameId)
    local successCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_PLAY, {success = true})
    end

    local failedCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_PLAY, {success = false})
    end

    CashMoneyNet:sendCashMoneyPlay(_gameId, successCall, failedCall)
end

function CashMoneyMgr:sendCollect(_gameId)
    local successCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_COLLECT, {success = true})
    end

    local failedCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_COLLECT, {success = false})
    end

    CashMoneyNet:sendCashMoneyCollect(_gameId, successCall, failedCall)
end

function CashMoneyMgr:sendClear(_gameId)
    local successCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_CLEAR, {success = true})
    end

    local failedCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_CLEAR, {success = false})
    end

    CashMoneyNet:sendCashMoneyClear(_gameId, successCall, failedCall)
end

-- 记录玩家点击过take按钮，因为范铮不愿意添加新的接口，只能用自定义接口
function CashMoneyMgr:sendMiniCashTakeStatusRequest(_gameId, _status)
    CashMoneyNet:sendSaveTakeStatusRequest(_gameId, _status)
end

-- 购买
function CashMoneyMgr:buyGoods(_gameId)
    local gameData = self:getDataByGameId(_gameId)

    if _gameId then

        -- 在这里存一下当前游戏ID
        self:saveGameIdx(_gameId)

        local selectPayIndex = self:getSelectPayIndex()

        local goodsInfo = {}
        goodsInfo.p_key = gameData:getKey(selectPayIndex)
        goodsInfo.p_price = gameData:getPrice(selectPayIndex)
        self:sendIapLog(goodsInfo)
        gLobalSaleManager:purchaseGoods(
            BUY_TYPE.MINI_GAME_CASHMONEY,
            goodsInfo.p_key,
            goodsInfo.p_price,
            0,
            0,
            function(target, result)
                self:buySuccess()
            end,
            function(target, result)
                self:buyFailed()
            end
        )
    end
end

function CashMoneyMgr:buySuccess()
    self:dropStamp()
end

function CashMoneyMgr:buyFailed()
    -- 购买失败
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_PAY, {success = false})
end

function CashMoneyMgr:dropStamp()
    local closeFunc = function()
        -- 购买成功
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASH_MONEY_PAY, {success = true})
    end
    -- 正式服需要打开这个
    gLobalViewManager:checkBuyTipList(closeFunc)
end

--打点
function CashMoneyMgr:sendIapLog(_goodsInfo)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "CashMoney"
        goodsInfo.goodsId = _goodsInfo.p_key
        goodsInfo.goodsPrice = _goodsInfo.p_price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "CashMoney"
        purchaseInfo.purchaseStatus = "CashMoney"
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function CashMoneyMgr:checkCanShowLayer()
    if not self:isCanShowLayer() then
        return false
    end
    return true
end

function CashMoneyMgr:setGameIdxKey()
    return "cashMoneyGameId"
end

function CashMoneyMgr:saveGameIdx(_idx)
    local gameIdx = tonumber(_idx)
    gLobalDataManager:setNumberByField(self:setGameIdxKey(),gameIdx)
end

function CashMoneyMgr:getGameIdxFromCache()
   return gLobalDataManager:getNumberByField(self:setGameIdxKey(),0)
end

return CashMoneyMgr
