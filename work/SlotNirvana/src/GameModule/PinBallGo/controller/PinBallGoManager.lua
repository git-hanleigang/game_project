--[[
    弹珠小游戏
]]
local PinBallGoNet = require("GameModule.PinBallGo.net.PinBallGoNet")
local PinBallGoManager = class("PinBallGoManager", BaseActivityControl)
local Notifier = require("GameMVC.patterns.Notifier")

PinBallGoManager.PINBALLGO_CODE_PATH = {}
PinBallGoManager.PINBALLGO_RES_PATH = {}
PinBallGoManager.PINBALLGO_EXTRA_CONFIG = {}
PinBallGoManager.BASE_CONFIG_PATH = "GameModule/PinBallGo/config/PinBallGoConfig.lua"
PinBallGoManager.ROADLINES_CONFIG_PATH = "Activity/PinBallGo_RoadLines"

function PinBallGoManager:ctor()
    PinBallGoManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PinBallGo)
    self.m_netModel = PinBallGoNet:getInstance() -- 网络模块
    self.m_CurGameId = 1
    self:initBaseConfig()
end

function PinBallGoManager:parseData(data, isLogin)
    if not data then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.PinBallGo.model.PinBallGoData"):create()
        _data:parseData(data, isLogin)
        self:registerData(_data)
    else
        _data:parseData(data, isLogin)
    end
end

function PinBallGoManager:getData(refName)
    refName = refName or self:getRefName()
    return Notifier.getData(self, refName)
end

function PinBallGoManager:getPlayStatusPinBallGoGameData()
    local gameData = nil
    local gameDatas = self:getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k, oneData in pairs(list) do
            if oneData:isPlaying() then
                gameData = oneData
                break
            end
        end
    end
    return gameData
end

function PinBallGoManager:getPinBallGoGameDataByIndex(_index)
    local gameData = nil
    local gameDatas = self:getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k, oneData in pairs(list) do
            if oneData:getIndex() == _index then
                gameData = oneData
                break
            end
        end
    end
    return gameData
end

function PinBallGoManager:getNewGameDataBySource(_source)
    local newGame = {}
    local gameDatas = self:getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k, oneData in pairs(list) do
            if oneData:getSource() == _source and oneData:getIsNewGameData() then
                oneData:setIsNewGameData(false)
                table.insert(newGame, oneData)
            end
        end
    end
    return newGame
end

function PinBallGoManager:setCurrentUesGameID(gameID)
    self.m_CurUseGameID = gameID
end
function PinBallGoManager:getCurrentUesGameID()
    return self.m_CurUseGameID
end

function PinBallGoManager:getCurrentUesGameData()
    return self:getPinBallGoGameDataByIndex(self.m_CurUseGameID)
end

function PinBallGoManager:getGameType()
    local gameData = self:getCurrentUesGameData()
    if gameData:isPaid() then
        return 2
    end
    return 1
end

function PinBallGoManager:showPinBallGoGameView(_gameData, _overCallback)
    local gameData = _gameData or self:getPlayStatusPinBallGoGameData()
    local showFlag = nil
    if gameData then
        showFlag = self:showMainLayer(gameData, _overCallback)
    end
    return showFlag
end

function PinBallGoManager:isCanShowLayer()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return false
    end
    return true
end

function PinBallGoManager:showPlayTipLayer(_overCallback)
    -- 判断资源是否下载
    if not self:isCanShowLayer() then
        if _overCallback then
            _overCallback()
        end
        return nil
    end
    if gLobalViewManager:getViewByExtendData("PinBallGo_TriggerBoardLayer") == nil then
        local gameView = util_createView(self:getConfigInfo("CODE", "PinBallGo_TriggerBoardLayer"), _overCallback)
        if gameView ~= nil then
            gameView:setName("PinBallGo_TriggerBoardLayer")
            gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
        end
    end
end

function PinBallGoManager:showMainLayer(gameData, _overCallback)
    if not self:isCanShowLayer() then
        if _overCallback then
            _overCallback()
        end
        return nil
    end
    if gLobalViewManager:getViewByName("PinBallGo_GameLayer") ~= nil then
        return nil
    end
    self:setCurrentUesGameID(gameData:getIndex())
    local view = util_createView(self:getConfigInfo("CODE", "PinBallGo_GameLayer"), gameData, _overCallback)
    view:setName("PinBallGo_GameLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function PinBallGoManager:showRewardLayer(rewardData, _overFun)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PinBallGo_VersionRewardLayer") ~= nil then
        return nil
    end
    local view = util_createView(self:getConfigInfo("CODE", "PinBallGo_VersionRewardLayer"), rewardData, _overFun)
    view:setName("PinBallGo_VersionRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function PinBallGoManager:showPurcheaseLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PinBallGo_PurchaseLayer") ~= nil then
        return nil
    end
    local view = util_createView(self:getConfigInfo("CODE", "PinBallGo_PurchaseLayer"))
    view:setName("PinBallGo_PurchaseLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function PinBallGoManager:showPayQuitConfirmation(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PinBallGo_PurchaseConfirmationLayer") ~= nil then
        return nil
    end
    local view = util_createView(self:getConfigInfo("CODE", "PinBallGo_PurchaseConfirmationLayer"), _data)
    view:setName("PinBallGo_PurchaseConfirmationLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function PinBallGoManager:getCurrentGameType()
    return m_CurUseGameData:getGameDataType()
end

-- 是否在游戏中
function PinBallGoManager:setIsInGame(isInGame)
    self.m_isInGame = isInGame
end
function PinBallGoManager:isInGame()
    return self.m_isInGame
end

function PinBallGoManager:setIsResetBall(isResetBall)
    self.m_isResetBall = isResetBall
end
function PinBallGoManager:isResetBall()
    return self.m_isResetBall
end

-- 是否在免费版切换到付费版中
function PinBallGoManager:setIsInGameChangeLogic(isInGameChange)
    self.m_isInGameChange = isInGameChange
end
function PinBallGoManager:isInGameChangeLogic()
    return self.m_isInGameChange
end

------------------------------------------------- 支付相关-------------------------------------------------------
-- 付费
function PinBallGoManager:buyPayPinBallGo(_data)
    if not _data then
        release_print("clickBuyBtn buyFailed, PinBallGoData is NIL")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_BUY_PINBALL_PAY, {success = false})
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getBuyKey()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, _data:getShopItem())
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseActivityGoods(
        "PinBallGo",
        "" .. _data:getIndex(),
        BUY_TYPE.PINBALLGO,
        _data:getBuyKey(),
        _data:getPrice(),
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_BUY_PINBALL_PAY, {success = false})
        end
    )
end

function PinBallGoManager:buySuccess()
    globalData.LevelRushLuckyStampCoinsEndPos = {
        x = display.width * 0.1,
        y = display.height - util_getBangScreenHeight() - 30
    }
    gLobalViewManager:checkBuyTipList(
        function()
            globalData.LevelRushLuckyStampCoinsEndPos = nil
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AFTER_BUY_PINBALL_PAY, {success = true})
        end
    )
end

function PinBallGoManager:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "PinballGo"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "PinballGo"
    purchaseInfo.purchaseStatus = "PinballGo"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

----------------------------------------------------- 请球数据相关 -------------------------------------------
-- 单个cell 领奖
function PinBallGoManager:collectCellReward()
    local pos = 9
    self.m_HitPos = self:getCurrentUesGameData():getTargetPos()
    local index = self:getCurrentUesGameData():getIndex()
    self.m_netModel:sendHitCell(index, self.m_HitPos)
end

function PinBallGoManager:getHitPos()
    if not self.m_HitPos then
        self.m_HitPos = self:getCurrentUesGameData():getTargetPos()
    end
    return self.m_HitPos
end

function PinBallGoManager:collectReward()
    local index = self:getCurrentUesGameData():getIndex()
    self.m_netModel:sendCollectReward(index)
end

-- 激活
function PinBallGoManager:sendPlayGame(_index)
    self.m_netModel:sendPlayGame(_index)
end

------------------------------ 多主题设计提供新接口 -----------------
--[[
    @desc: 初始化基础配置信息
]]
function PinBallGoManager:loadConfig(_path)
    self.m_configData = nil
    local configPath = _path
    self.m_configData = util_require(configPath)
end

function PinBallGoManager:getConfig()
    if self.m_configData == nil then
        self:loadConfig()
    end
    return self.m_configData
end

function PinBallGoManager:initBaseConfig()
    --备份基础配置
    self.m_baseConfigData = nil
    self.m_configData = nil
    self:loadConfig(self.BASE_CONFIG_PATH)
    self:bakBaseConfig()
    self.m_lastThemeName = ACTIVITY_REF.PinBallGo
end

function PinBallGoManager:bakBaseConfig()
    self.m_baseConfigData = clone(self.m_configData)
    -- 先刷新一次值
    self.PINBALLGO_CODE_PATH = {}
    self.PINBALLGO_RES_PATH = {}
    self.PINBALLGO_EXTRA_CONFIG = {}
    -- 重新导入一次 base 路径
    self:updateCodeInfo(self.m_baseConfigData.code)
    self:updateResInfo(self.m_baseConfigData.res)
    self:updateExtraInfo(self.m_baseConfigData.extra)
end

function PinBallGoManager:updateConfig()
    local activityThemeName = self:getThemeName()
    if self.m_lastThemeName and self.m_lastThemeName == activityThemeName then
        return
    end

    -- 是否下载完毕
    if not self:isDownloadRes(activityThemeName) then
        return
    end

    local bCheckTheme = false
    if activityThemeName == ACTIVITY_REF.PinBallGo then
        -- 不需要进行检测 默认走基础配置
    else
        -- 检测每个主题活动的配置文件是否存在
        if G_GetMgr(ACTIVITY_REF.PinBallGo):isDownloadRes() then
            local len = string.len("Activity_PinBallGo") + 1
            local themeName = string.sub(activityThemeName, len) -- 获取具体的主题名
            local filePath = "DailyPass" .. themeName .. "Code/" .. "DailyPass" .. themeName .. "Config"
            --重置基础配置
            local configPath = filePath
            self:loadConfig(configPath)
            bCheckTheme = true
            self.m_lastThemeName = activityThemeName
        end
    end

    -- 重置一下路径
    self.PINBALLGO_CODE_PATH = {}
    self.PINBALLGO_RES_PATH = {}
    self.PINBALLGO_EXTRA_CONFIG = {}
    -- 重新导入一次 base 路径
    self:updateCodeInfo(self.m_baseConfigData.code)
    self:updateResInfo(self.m_baseConfigData.res)
    self:updateExtraInfo(self.m_baseConfigData.extra)
    if bCheckTheme then
        -- 再导入一次当前主题的配置
        self:updateCodeInfo(self.m_configData.code)
        self:updateResInfo(self.m_configData.res)
        self:updateExtraInfo(self.m_configData.extra)
    end
end

--lua文件更新路径
function PinBallGoManager:updateCodeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            self.PINBALLGO_CODE_PATH[key] = value
        end
    end
end
--修改资源路径
function PinBallGoManager:updateResInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            self.PINBALLGO_RES_PATH[key] = value
        end
    end
end
--修改额外数据
function PinBallGoManager:updateExtraInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            self.PINBALLGO_EXTRA_CONFIG[key] = value
        end
    end
end

function PinBallGoManager:getConfigInfo(configType, key) -- CODE RES  EXTRA
    if configType == "CODE" then
        return self.PINBALLGO_CODE_PATH[key]
    elseif configType == "RES" then
        return self.PINBALLGO_RES_PATH[key]
    elseif configType == "EXTRA" then
        return self.PINBALLGO_EXTRA_CONFIG[key]
    end
end

--[[
    @desc: 加载路线
    author:{author}
    time:2022-06-28 15:11:50
    @return:
]]
function PinBallGoManager:localPathConfig()
    if not self.m_pathVec then
        local activityThemeName = self:getThemeName()
        if not self:isDownloadRes(activityThemeName) then
            return
        end
        self.m_pathVec = util_require(self:getConfigInfo("EXTRA", "Path_Path"))
        if not self.m_pathVec then
            print("ERROR")
        end
    end
end

function PinBallGoManager:getLineByLineIndex(lineId)
    return self.m_pathVec[lineId]
end

-------------------------多主题设计提供新接口   end ------------

return PinBallGoManager
