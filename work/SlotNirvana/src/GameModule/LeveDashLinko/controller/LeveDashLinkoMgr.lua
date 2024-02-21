--[[
]]
require("GameModule.LeveDashLinko.config.LeveDashLinkoConfig")
local LeveDashLinkoNet = require("GameModule.LeveDashLinko.net.LeveDashLinkoNet")
local LeveDashLinkoMgr = class("LeveDashLinkoMgr", BaseGameControl)
local RotateScreen = require("base.RotateScreen")

function LeveDashLinkoMgr:ctor()
    LeveDashLinkoMgr.super.ctor(self)
    self.m_preMachineData = nil --关卡场景跳过来的关卡数据
    self:setRefName(G_REF.LeveDashLinko)
    self.m_netModel = LeveDashLinkoNet:getInstance() -- 网络模块
end

function LeveDashLinkoMgr:parseData(_netData)
    if not _netData then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.LeveDashLinko.model.LeveDashLinkoData"):create()
        _data:parseData(_netData)
        self:registerData(_data)
    else
        _data:parseData(_netData)
    end
end

function LeveDashLinkoMgr:setCurGameNewStatus(_isNewGame)
    self.m_isCurGameNew = _isNewGame
end

function LeveDashLinkoMgr:getCurGameNewStatus()
    return self.m_isCurGameNew
end

function LeveDashLinkoMgr:setCurGameId(_id)
    self.m_curGameId = _id
    self.m_curGameData = nil
end

function LeveDashLinkoMgr:getCurGameId()
    return self.m_curGameId
end

function LeveDashLinkoMgr:removeGame()
    self.m_curGameId = nil
    self.m_curGameData = nil
end

function LeveDashLinkoMgr:getCurType()
    if not self:getData() then
        return 0
    end
    local games = self:getData():getGames()
    local id = self:getCurGameId()
    local type = 0
    for i,v in ipairs(games) do
        if id == v:getIndex() then
            type = v:getGameType()
        end
    end
    return type
end

function LeveDashLinkoMgr:getCurRang()
    if not self:getData() then
        return 0
    end
    local games = self:getData():getGames()
    local id = self:getCurGameId()
    local type = 0
    for i,v in ipairs(games) do
        if id == v:getIndex() then
            type = v:getRange()
        end
    end
    return type
end

function LeveDashLinkoMgr:getIsGames()
    if not self:getData() then
        return false
    end
    local games = self:getData():getGames()
    local isOpen = false
    if games and #games > 0 then
        if games[#games]:getGameStatus() == LeveDashLinkoConfig.GameStatus.Init then
            isOpen = true
        end
    end
    return isOpen
end
--断线回来
function LeveDashLinkoMgr:getIsLoginGames()
    if not self:getData() then
        return false
    end
    local games = self:getData():getGames()
    local isOpen = nil
    if games and #games > 0 then
        for i,v in ipairs(games) do
            local status = v:getGameStatus()
            local leftTime = v:getLeftTime()
            if status == LeveDashLinkoConfig.GameStatus.Playing and leftTime > 0 then
                isOpen = v:getIndex()
                break
            end
        end
        -- local game = games[#games]
        -- local status = game:getGameStatus()
        -- local leftTime = game:getLeftTime()
        -- if status == LeveDashLinkoConfig.GameStatus.Playing and leftTime > 0 then
        --     isOpen = game:getIndex()
        -- end
    end
    return isOpen
end

function LeveDashLinkoMgr:getEnterGameData()
    if not self:getData() then
        return nil
    end
    local games = self:getData():getGames()
    if games and #games > 0 then
        return games[#games]:getIndex()
    else
        return nil
    end
end

function LeveDashLinkoMgr:getEnterGameWin()
    if not self:getData() then
        return nil
    end
    local games = self:getData():getGames()
    if games and #games > 0 then
        return games[#games]:getGameWin()
    else
        return nil
    end
end

function LeveDashLinkoMgr:getEnterJackMul()
    local defult = {0,0,0,0}
    if not self:getData() then
        return defult
    end
    local games = self:getData():getGames()
    if games and #games > 0 then
        return games[#games]:getJackMul()
    else
        return defult
    end
end

function LeveDashLinkoMgr:getCurGameData()
    local curGameId = self:getCurGameId()
    local data = self:getData()
    if curGameId and data then
        local gameData = data:getGameDataById(curGameId)
        if gameData then
            self.m_curGameData = clone(gameData)
        else
            if self.m_curGameData then
                gameData = self.m_curGameData
            end
        end
        return gameData
    end
    return nil
end

function LeveDashLinkoMgr:paresRespinData(_data)
    if _data.bet then
        self.m_Cbet = _data.bet
    end
    local gameData = clone(_data)
    if gameData.selfData.payLevel then
        self:setRewardLater(gameData.selfData.payLevel)
    else
        self:setRewardLater(0)
    end
    local respin = {reSpinCurCount = gameData.reSpinCurCount,reSpinsTotalCount = gameData.reSpinsTotalCount}
    gameData.respin = respin
    self.m_gameSpin = gameData
end

function LeveDashLinkoMgr:getRespinData()
    return self.m_gameSpin or {}
end

function LeveDashLinkoMgr:openGame()
    if not self:isDownloadTheme("Activity_LevelLink") then
        return false
    end
    self.m_popCoins = 0
    if not globalData.slotRunData.machineData then
        local info = globalData.slotRunData:getLevelInfoById(10071)
        globalData.slotRunData.machineData = info
    end
    self:setGamePortrait(globalData.slotRunData.isPortrait)
    if globalData.slotRunData.isPortrait == false then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(true)
        globalData.slotRunData.isPortrait = true
        RotateScreen:getInstance():initScreenDir()
    end
    if not gLobalViewManager:isLobbyView() then
        self:setGameMudel(globalData.slotRunData.currSpinMode)
        self:setGameStage(globalData.slotRunData.gameSpinStage)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    end
    local view = util_createView("Activity.LevelDashLink.LevelDashLinkGame")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function LeveDashLinkoMgr:LevelGame()
    self:removeGame()
    if not self:getGamePortrait() then
        globalData.slotRunData.isChangeScreenOrientation = true
        globalData.slotRunData:changeScreenOrientation(false)
        globalData.slotRunData.isPortrait = false
        RotateScreen:getInstance():initScreenDir()
    end
    self:PlayerOver() 
end

function LeveDashLinkoMgr:setGamePortrait(_flag)
    self.m_gamePortrait = _flag
end

function LeveDashLinkoMgr:getGamePortrait()
    return self.m_gamePortrait
end

function LeveDashLinkoMgr:setGameMudel(_mode)
    self.m_gameMudel = _mode
end

function LeveDashLinkoMgr:getGameMudel()
    return self.m_gameMudel
end

function LeveDashLinkoMgr:setGameStage(_mode)
    self.m_gameStage = _mode
end

function LeveDashLinkoMgr:getGameStage()
    return self.m_gameStage
end

function LeveDashLinkoMgr:enterGame(_GameId, _isTriggerGame, _isNewGame, _over)
    self:setCurGameNewStatus(_isNewGame == true)
    self:setCurGameId(_GameId)
    local gameData = self:getCurGameData()
    if gameData then
        -- TODO plinko splunk log
        if _isTriggerGame == true then
            gLobalLevelRushManager:clearHadPopList()
            gLobalLevelRushManager:addHadPopList("end_" .. globalData.userRunData.levelNum, true)
            local view = self:showStartLayer()
            return view ~= nil
        else
            -- if _isNewGame == true then
            --     local bReq = G_GetMgr(G_REF.Plinko):requestActiveGame(
            --         function()
            --             self:showMainLayer()
            --             -- if not tolua.isnull(self) then
            --             -- end
            --         end,
            --         function(_bReqCB)
            --             if _bReqCB then
            --                 self:exitGame(false)
            --             end
            --         end
            --     )
            --     return bReq
            -- else
            --     local view = self:showMainLayer()
            --     return view ~= nil
            -- end
            self:requestActiveGame(function()
                --请求成功，进入游戏
                self:openGame()
            end,function()
                --失败
            end)
        end
        return true
    end
    return false
end

function LeveDashLinkoMgr:exitGame(_isUpdateInbox)
    LeveDashLinkoMgr.super.exitGame(self)
    -- 刷新邮箱
    if _isUpdateInbox == true then
        G_GetMgr(G_REF.Inbox):getDataMessage()
    end
end

-- 获取上个场景 type
function LeveDashLinkoMgr:getPreMachineData()
    return self.m_preMachineData
end

-- 获取 场景layer
function LeveDashLinkoMgr:getSceneLayer(_preMachineData)
    self.m_preMachineData = _preMachineData
    local layer = util_createView("ItemGame.PlinkoCode.mainUI.PlinkoMainUI")
    layer:setName("PlinkoMainUI")
    return layer
end

function LeveDashLinkoMgr:isCanShowLayer()
    return LeveDashLinkoMgr.super.isCanShowLayer(self)
end

function LeveDashLinkoMgr:isTriggerNewGame()
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getData()
    if not data:isHaveUnActiveGame() then
        return false
    end
    local activityData = gLobalLevelRushManager:getLevelRushData()
    if not activityData then
        return false
    end
    if not activityData:getActivityOpen() then
        return false
    end
    local endLv = activityData:getEndLevel()
    if globalData.userRunData.levelNum ~= endLv then
        return false
    end
    if not gLobalLevelRushManager:checkFirstPopByCurLevel(2, endLv) then
        return false
    end
    return true
end

-- 显示主界面
function LeveDashLinkoMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    gLobalViewManager:gotoSceneByType(SceneType.Scene_BeerPlinko)
end

function LeveDashLinkoMgr:showWelcomUI(_over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("PlinkoWelcomeUI") ~= nil then
        return
    end
    local view = util_createView(PlinkoConfig.luaPath .. "welcomeUI.PlinkoWelcomeUI", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LeveDashLinkoMgr:showStartLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("LevelDLinkoStartUI") ~= nil then
        return
    end
    local gameData = self:getCurGameData()
    if not gameData then
        return
    end
    local view = util_createView("startUI.LevelDLinkoStartUI")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示结算界面
function LeveDashLinkoMgr:showRewardLayer(_over,_coins)
    self.m_popCoins = _coins
    local view = util_createView("Activity.LevelDashLink.LevelDLRewardLayer", _over,_coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 付费确认界面
function LeveDashLinkoMgr:showPurchaseLayer(_over)
    local view = util_createView("Activity.LevelDashLink.LevelDLPayLayer", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 付费确认界面
function LeveDashLinkoMgr:showPurchaseConfirmLayer(_over)
    local view = util_createView("Activity.LevelDashLink.LevelDLPayComLayer", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

--最新付费确认界面
function LeveDashLinkoMgr:showPurchaseConfirmTwoLayer(_over)
    local view = util_createView("Activity.LevelDashLink.LevelDLPayComTwoLayer", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 最新付费界面
function LeveDashLinkoMgr:showPurchaseTwoLayer()
    local view = util_createView("Activity.LevelDashLink.LevelDLPayTwoLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 体验付费界面
function LeveDashLinkoMgr:showLaterLayer()
    local view = util_createView("Activity.LevelDashLink.LevelDLPayLaterLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 体验领奖界面
function LeveDashLinkoMgr:showLaterRewardLayer(_over,_coins)
    self.m_popCoins = _coins
    local view = util_createView("Activity.LevelDashLink.LevelDLRewardLaterLayer",_over,_coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 体验领奖确认界面
function LeveDashLinkoMgr:showRewardComLayer(_over,_coins)
    self.m_popCoins = _coins
    local view = util_createView("Activity.LevelDashLink.LevelDLRewardComLayer",_over,_coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

--进入小游戏
function LeveDashLinkoMgr:requestActiveGame(_success, _fail)
    local successFunc = function(_result)
        self:paresRespinData(_result)
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail(true)
        end
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    local data = self:getData()
    if data and gameId then
        local gameData = data:getGameDataById(gameId)
        if gameData then
            self.m_netModel:requestActiveGame(gameId, successFunc, failFunc)
            return true
        end
    end
    if _fail then
        _fail()
    end
end

function LeveDashLinkoMgr:requestPlayGame(_success, _fail)
    local successFunc = function(_result)
        --dump(_result)
        self:paresRespinData(_result)
        gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_RESPIN_RESULT,self:getRespinData())
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    self.m_netModel:requestPlayGame(gameId,successFunc, failFunc)
end

function LeveDashLinkoMgr:requestCollectGame()
    local successFunc = function(_result)
        --dump(_result)
        if _result then
            self:setGamePay(_result)
            self:paresRespinData(_result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PL_REWARD_COLLECT, {isSuc = true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PL_REWARD_COLLECT, {isSuc = false})
        end
    end
    local failFunc = function()
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    local data = self:getData()
    if data and gameId then
        self.m_netModel:requestCollectGame(gameId,successFunc, failFunc)
    end
end

function LeveDashLinkoMgr:requestPayLater(_payLevel,_success, _fail)
    local successFunc = function(_result)
        self:setRewardLater(_payLevel)
        local pay = _payLevel + 1
        gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_PAY,pay)
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    self.m_netModel:requestPayLater(gameId,successFunc, failFunc, _payLevel)
end

function LeveDashLinkoMgr:requestQuietLater(_success, _fail)
    local successFunc = function(_result)
        gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_PAY_QUIET)
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    self.m_netModel:requestQuietLater(gameId,successFunc, failFunc, _payLevel)
end

function LeveDashLinkoMgr:setGamePay(_result)
    self.m_gamepay = {}
    self.m_gamepay[1] = _result.selfData.payParams1
    self.m_gamepay[2] = _result.selfData.payParams2
    self.m_gamepay[3] = _result.selfData.payParams3
    self.m_gamepay[4] = self:getCurGameData():getPrice()
    self.m_gamepay[5] = _result.selfData.winUpTo
    self.m_gamepay[6] = _result.selfData.newPayParams2
    self.m_gamepay[7] = _result.selfData.newWinUpTo
    local newK = self:getCurGameData():getNewPrice()
    if newK.key then
        self.m_gamepay[8] = newK.price
    end
end

function LeveDashLinkoMgr:setRewardLater(_index)
    if _index and _index ~= "" then
        self.m_payIndex = tonumber(_index) + 1
    end
end

function LeveDashLinkoMgr:getPayLevel()
    local rt = 0
    if self.m_payIndex then
        rt = self.m_payIndex
    end
    return rt
end

function LeveDashLinkoMgr:getPayLevelNew()
    local rt = 0
    if self.m_payIndex then
        rt = self.m_payIndex - 1
    end
    return rt
end
--先玩后付奖励付费
function LeveDashLinkoMgr:getRewardLater()
    if not self.m_payIndex then
        self.m_payIndex = 1
    end
    return self:getPayPartem(self.m_payIndex)
end

function LeveDashLinkoMgr:getRewardLaterIndex()
    if not self.m_payIndex then
        self.m_payIndex = 1
    end 
    return self.m_payIndex - 1
end

function LeveDashLinkoMgr:getGamePay()
    return self.m_gamepay or {}
end

function LeveDashLinkoMgr:getNewP()
    local _data = self:getCurGameData()
    local newp = _data:getNewPrice()
    if newp and newp.key ~= nil and newp.key ~= "" then
        return true
    end
    return false
end

function LeveDashLinkoMgr:getLater()
    local _data = self:getCurGameData()
    local newp = _data:getPayLater()
    return newp
end

function LeveDashLinkoMgr:getPayIndex()
    return self.m_payId or 0
end

function LeveDashLinkoMgr:getPayPartem(_flag)
    --flag 2 新版本
    local pay = {}
    local _data = self:getCurGameData()
    if _flag == 2 then
        local two = _data:getNewPrice()
        pay.key = two.key
        pay.price = two.price
        pay.keyId = two.keyId
    else
        pay.key = _data:getKey()
        pay.price = _data:getPrice()
        pay.keyId = _data:getKeyId()
    end
    return pay
end

function LeveDashLinkoMgr:requestBuyPay(_flag)
    local data = self:getCurGameData()
    if not data then
        return
    end
    local nums = tonumber(_flag) - 1
    self:setRewardLater(nums)
    local pay = self:getPayPartem(_flag)
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = pay.key
    goodsInfo.goodsPrice = pay.price
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)

    -- -- 添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(data, data:getShopItem())
    -- gLobalSendDataManager:getLogIap():setItemList(itemList)

    globalData.iapRunData.p_activityId = "PERL_LINK"
    globalData.iapRunData.p_contentId = self:getCurGameId()

    local function success()
        self:buySuccess(_flag)
    end
    local function fail()
    end
    local ret = gLobalSaleManager:purchaseGoods(BUY_TYPE.PERL_LINK, pay.key, pay.price, tostring(self:getPayLevelNew()), 0, success, fail)
    if not ret then
        globalData.iapRunData.p_activityId = nil
        globalData.iapRunData.p_contentId = nil
    end
end

function LeveDashLinkoMgr:requestNewBuyPay()
    local data = self:getCurGameData()
    if not data then
        return
    end
    local pay = self:getRewardLater()
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = pay.key
    goodsInfo.goodsPrice = pay.price
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self.m_payId = pay.keyId

    -- -- 添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(data, data:getShopItem())
    -- gLobalSendDataManager:getLogIap():setItemList(itemList)

    globalData.iapRunData.p_activityId = "PERL_NEW_LINK"
    globalData.iapRunData.p_contentId = self:getCurGameId()

    local function success()
        gLobalViewManager:checkBuyTipList(
           function()
               gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_REWARD_SUCCESS)
           end
        )
    end
    local function fail()
    end
    local ret = gLobalSaleManager:purchaseGoods(BUY_TYPE.PERL_NEW_LINK, pay.key, pay.price, tostring(self:getPayIndex()), 0, success, fail)
    if not ret then
        globalData.iapRunData.p_activityId = nil
        globalData.iapRunData.p_contentId = nil
    end
end

--放到最后检查流程
function LeveDashLinkoMgr:PlayerOver()
    local lTatolBetNum = self.m_Cbet
    if not lTatolBetNum then
        lTatolBetNum = 1
    end
    if not self.m_popCoins then
        self.m_popCoins = 0
    end
    local beishu = tonumber(self.m_popCoins)/tonumber(lTatolBetNum)
    local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("LevelDash", "LevelDash_" .. beishu)
    if view then
        view:setOverFunc(function()
            if not gLobalViewManager:isLobbyView() then
               gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
            end
            gLobalViewManager:checkBuyTipList()
        end)
    else
        if not gLobalViewManager:isLobbyView() then
           gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
        end
        gLobalViewManager:checkBuyTipList()
    end
end

function LeveDashLinkoMgr:buySuccess(_flag)
    printInfo("LeveDashLinkoMgr 促销购买成功！")
    self:doFuncByPurchase(function()
        self:requestActiveGame(function()
            --请求成功，进入游戏
            gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_PAY,_flag)
        end,function()
            --失败
        end)
    end)
    -- gLobalViewManager:checkBuyTipList(
    --     function()
    --         self:requestActiveGame(function()
    --             --请求成功，进入游戏
    --             gLobalNoticManager:postNotification(LeveDashLinkoConfig.event.NOTIFY_PERLINK_PAY)
    --         end,function()
    --             --失败
    --         end)
    --     end
    -- )
end

-- 检测 list 调用方法
function LeveDashLinkoMgr:triggerDropFuncNext()
    self.m_triggerIndex = (self.m_triggerIndex or 0) + 1
    if self.m_triggerIndex > #self.m_purchaseFuncList then
        self.m_triggerIndex = 0
        if self.m_purchaseFuncOver then
            self.m_purchaseFuncOver("GameContinue")
        end
        return
    end
    local func = self.m_purchaseFuncList[self.m_triggerIndex]
    if func then
        func()
    end
end

function LeveDashLinkoMgr:initPurchaseFuncList()
    local list = {}
    list[#list + 1] = handler(self, self.triggerDropCards)
    list[#list + 1] = handler(self, self.triggerLuckyStamp)
    self.m_purchaseFuncList = list
end

function LeveDashLinkoMgr:doFuncByPurchase(_over)
    self.m_triggerIndex = 0
    self.m_purchaseFuncOver = _over
    self:initPurchaseFuncList()
    self:triggerDropFuncNext()
end

function LeveDashLinkoMgr:triggerDropCards()
    -- 有卡片掉落 --
    if CardSysManager:needDropCards("Purchase") == true then
        CardSysManager:doDropCards(
            "Purchase",
            function()
                self:triggerDropFuncNext()
            end
        )
    else
        self:triggerDropFuncNext()
    end
end

function LeveDashLinkoMgr:triggerLuckyStamp()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data and data:getNeedStampNum() > 0 and data:getLeftTime() > 0 then
        G_GetMgr(G_REF.LuckyStamp):enterGame(
            function()
                -- gLobalViewManager:triggerFuncNext() --执行下一个方法
                self:triggerDropFuncNext()
            end
        )
    else
        -- gLobalViewManager:triggerFuncNext() --执行下一个方法
        self:triggerDropFuncNext()
    end
end

return LeveDashLinkoMgr
