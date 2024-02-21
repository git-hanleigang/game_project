--[[
]]
require("GameModule.Plinko.config.PlinkoConfig")
local PlinkoMgr = class("PlinkoMgr", BaseGameControl)

function PlinkoMgr:ctor()
    PlinkoMgr.super.ctor(self)
    self.m_preMachineData = nil --关卡场景跳过来的关卡数据
    self:setRefName(G_REF.Plinko)
end

function PlinkoMgr:parseData(_netData)
    if not _netData then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.Plinko.model.PlinkoData"):create()
        _data:parseData(_netData)
        self:registerData(_data)
    else
        _data:parseData(_netData)
    end
end

function PlinkoMgr:setCurGameNewStatus(_isNewGame)
    self.m_isCurGameNew = _isNewGame
end

function PlinkoMgr:getCurGameNewStatus()
    return self.m_isCurGameNew
end

function PlinkoMgr:setCurGameId(_id)
    if not _id then
        local data = self:getData()
        if data then
            local newestGameData = data:getNewestGameData()
            if newestGameData then
                self.m_curGameId = newestGameData:getIndex()
            end
        end
    else
        self.m_curGameId = _id
    end
end

function PlinkoMgr:getCurGameId()
    return self.m_curGameId
end

function PlinkoMgr:getCurGameData()
    local curGameId = self:getCurGameId()
    local data = self:getData()
    if curGameId and data then
        local gameData = data:getGameDataById(curGameId)
        return gameData
    end
    return nil
end

-- 回调
function PlinkoMgr:setExitGameCallFunc(_over)
    self.m_over = _over
end

function PlinkoMgr:runExitGameCallFunc()
    if self.m_over then
        self.m_over()
        self.m_over = nil
    end
end

function PlinkoMgr:enterGame(_GameId, _isTriggerGame, _isNewGame, _over)
    self:setCurGameNewStatus(_isNewGame == true)
    self:setCurGameId(_GameId)
    self:setExitGameCallFunc(_over)
    local gameData = self:getCurGameData()
    if gameData then
        -- TODO plinko splunk log
        self:clearErrorLogMsg()
        if _isTriggerGame == true then
            gLobalLevelRushManager:clearHadPopList()
            gLobalLevelRushManager:addHadPopList("end_" .. globalData.userRunData.levelNum, true)
            local view = self:showStartLayer()
            return view ~= nil
        else
            if _isNewGame == true then
                local bReq = G_GetMgr(G_REF.Plinko):requestActiveGame(
                    function()
                        self:showMainLayer()
                        -- if not tolua.isnull(self) then
                        -- end
                    end,
                    function(_bReqCB)
                        if _bReqCB then
                            self:exitGame(false)
                        end
                    end
                )
                return bReq
            else
                local view = self:showMainLayer()
                return view ~= nil
            end
        end
        return true
    end
    return false
end

function PlinkoMgr:exitGame(_isUpdateInbox)
    PlinkoMgr.super.exitGame(self)
    -- 刷新邮箱
    if _isUpdateInbox == true then
        G_GetMgr(G_REF.Inbox):getDataMessage()
    end
    self:runExitGameCallFunc()
end

-- 获取上个场景 type
function PlinkoMgr:getPreMachineData()
    return self.m_preMachineData
end

-- 获取 场景layer
function PlinkoMgr:getSceneLayer(_preMachineData)
    self.m_preMachineData = _preMachineData
    local layer = util_createView("ItemGame.PlinkoCode.mainUI.PlinkoMainUI")
    layer:setName("PlinkoMainUI")
    return layer
end

function PlinkoMgr:isCanShowLayer()
    if PlinkoConfig.TEST_MODE == true then
        return true
    end
    return PlinkoMgr.super.isCanShowLayer(self)
end

function PlinkoMgr:isTriggerNewGame()
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
function PlinkoMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    gLobalViewManager:gotoSceneByType(SceneType.Scene_BeerPlinko)
end

function PlinkoMgr:showWelcomUI(_over)
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

function PlinkoMgr:showStartLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("PlinkoStartUI") ~= nil then
        return
    end
    local gameData = self:getCurGameData()
    if not gameData then
        return
    end
    local view = util_createView(PlinkoConfig.luaPath .. "startUI.PlinkoStartUI")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示结算界面
function PlinkoMgr:showRewardLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("PlinkoRewardUI") ~= nil then
        return
    end
    local view = util_createView(PlinkoConfig.luaPath .. "rewardUI.PlinkoRewardUI", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 付费确认界面
function PlinkoMgr:showPurchaseLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("PlinkoPurchaseUI") ~= nil then
        return
    end
    local view = util_createView(PlinkoConfig.luaPath .. "purchaseUI.PlinkoPurchaseUI", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 付费确认界面
function PlinkoMgr:showPurchaseConfirmLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("PlinkoPurchaseConfirmUI") ~= nil then
        return
    end
    local view = util_createView(PlinkoConfig.luaPath .. "purchaseUI.PlinkoPurchaseConfirmUI", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function PlinkoMgr:requestActiveGame(_success, _fail)
    local successFunc = function(_result)
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
            G_GetNetModel(NetType.Plinko):requestActiveGame(gameId, successFunc, failFunc)
            return true
        end
    end
    if _fail then
        _fail()
    end
end

function PlinkoMgr:requestPlayGame(_success, _fail)
    local successFunc = function(_result)
        -- TODO plinko splunk log
        self:addErrorLogMsg("PlinkoMgr:requestPlayGame successFunc")
        if _success then
            _success()
        end
    end
    local failFunc = function()
        -- TODO plinko splunk log
        self:addErrorLogMsg("PlinkoMgr:requestPlayGame failFunc")
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    -- dump(self.m_collisions, "---- self.m_collisions ----", 3)
    if self.m_collisions and table.nums(self.m_collisions) > 0 then
        -- TODO plinko splunk log
        self:addErrorLogMsg("PlinkoMgr:requestPlayGame")
        local gameId = self:getCurGameId()
        local data = self:getData()
        if data and gameId then
            local gameData = data:getGameDataById(gameId)
            if gameData then
                G_GetNetModel(NetType.Plinko):requestPlayGame(gameId, self.m_collisions, successFunc, failFunc)
                return
            end
        end
    end
    failFunc()
end

function PlinkoMgr:requestCollectGame()
    local successFunc = function(_result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_PLINKO_COLLECT_GAME, {isSuc = true})
    end
    local failFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_PLINKO_COLLECT_GAME, {isSuc = false})
        gLobalViewManager:showReConnect()
    end
    local gameId = self:getCurGameId()
    local data = self:getData()
    if data and gameId then
        local gameData = data:getGameDataById(gameId)
        if gameData then
            G_GetNetModel(NetType.Plinko):requestCollectGame(gameId, successFunc, failFunc)
            return
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_PLINKO_COLLECT_GAME, {isSuc = false})
end

function PlinkoMgr:requestBuyPay(_gameId, _key, _price, _success, _fail)
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _key
    goodsInfo.goodsPrice = _price
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)

    -- -- 添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(data, data:getShopItem())
    -- gLobalSendDataManager:getLogIap():setItemList(itemList)

    globalData.iapRunData.p_activityId = "LUCKYFISH"
    globalData.iapRunData.p_contentId = _gameId

    local function success()
        if _success then
            _success()
        end
    end
    local function fail()
        if _fail then
            _fail()
        end
    end
    local ret = gLobalSaleManager:purchaseGoods(BUY_TYPE.LUCKY_FISH, _key, _price, 0, 0, success, fail)
    if not ret then
        globalData.iapRunData.p_activityId = nil
        globalData.iapRunData.p_contentId = nil
    end
end

-- 检测 list 调用方法
function PlinkoMgr:triggerDropFuncNext()
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

function PlinkoMgr:initPurchaseFuncList()
    local list = {}
    list[#list + 1] = handler(self, self.triggerDropCards)
    list[#list + 1] = handler(self, self.triggerLuckyStamp)
    self.m_purchaseFuncList = list
end

function PlinkoMgr:doFuncByPurchase(_over)
    self.m_triggerIndex = 0
    self.m_purchaseFuncOver = _over
    self:initPurchaseFuncList()
    self:triggerDropFuncNext()
end

function PlinkoMgr:triggerDropCards()
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

function PlinkoMgr:triggerLuckyStamp()
    gLobalViewManager:checkBuyTipList(
        function()
            self:triggerDropFuncNext()
        end
    )
end

-------------- 本次掉球 --------------
--[[--
    {
        line:10         //发射位置index值
        bubble:[0,0]    //左右气泡的碰撞次数
        centre:2        //中间球碰撞次数
        drop:8          //球掉入的杯子，8是服务器定义的杯子id
        multiple:3      //中了十倍的杯子，3是服务器定义的杯子id
    }
    一个球掉落的数据
    所有数值默认是0，必须传值
    组合play接口的碰撞参数
--]]
function PlinkoMgr:resetCollisions()
    self.m_collisions = {}
end

function PlinkoMgr:initCollisions(_ballId, _ballDropPosIndex)
    if not self.m_collisions then
        self.m_collisions = {}
    end
    if not self.m_collisions[_ballId] then
        self.m_collisions[_ballId] = {
            ["line"] = _ballDropPosIndex,
            ["bubble"] = {0, 0},
            ["centre"] = 0,
            ["drop"] = 0,
            ["multiple"] = 0
        }
    end
end

function PlinkoMgr:checkIsLegality()
    local gameData = self:getCurGameData()
    if not gameData then
        return
    end
    local bubble2Data = gameData:getSpecialDingByIndex(2)
    if not bubble2Data then
        return
    end
    if bubble2Data:getCollect() == true then
        return 
    end
    if bubble2Data:getCrashCount() < bubble2Data:getNeedCrashCount() then
        return
    end
    local msg = self:getErrorLogMsg()
    for _ballId, v in pairs(self.m_collisions) do
        if v.multiple == 0 then
            -- print("--- getErrorLogMsg ---".. msg)
            util_sendToSplunkMsg("PlinkoClientDataErrorV2", msg)
        end
    end
end


function PlinkoMgr:addErrorLogMsg(_msg)
    if not self.m_splunkLog then
        self.m_splunkLog = "Msg = "
    end
    self.m_splunkLog = self.m_splunkLog .. _msg .. " -- "
end

function PlinkoMgr:getErrorLogMsg()
    return self.m_splunkLog or ""
end

function PlinkoMgr:clearErrorLogMsg()
    self.m_splunkLog = ""
end

-- 记录中了十倍奖励的杯子index
function PlinkoMgr:setDropX10CupIndex(_ballId, _cupIndex)
    if not _ballId or _cupIndex == nil then
        return
    end
    self:initCollisions(_ballId)
    self.m_collisions[_ballId]["multiple"] = _cupIndex
end

function PlinkoMgr:getDropX10CupIndex(_ballId)
    if not _ballId or not (self.m_collisions and self.m_collisions[_ballId]) then
        return nil
    end
    return self.m_collisions[_ballId]["multiple"]
end

-- _ballId， 掉落球的id
-- _contactObjId，碰撞对象的id，根据对象类型拼接，cup_1, ding_1, ding_x2, ding_x10, ding_center
function PlinkoMgr:addBallsContact(_ballId, _ballDropPosIndex, _contactObjId)
    if not _ballId or not _contactObjId then
        return
    end
    self:initCollisions(_ballId, _ballDropPosIndex)
    if _contactObjId == "ding_x2" then
        self.m_collisions[_ballId]["bubble"][1] = self.m_collisions[_ballId]["bubble"][1] + 1
    elseif _contactObjId == "ding_x10" then
        self.m_collisions[_ballId]["bubble"][2] = self.m_collisions[_ballId]["bubble"][2] + 1
    elseif _contactObjId == "ding_center" then
        self.m_collisions[_ballId]["centre"] = self.m_collisions[_ballId]["centre"] + 1
    elseif string.sub(_contactObjId, 1, 4) == "ding" then
    elseif string.sub(_contactObjId, 1, 3) == "cup" then
        self.m_collisions[_ballId]["drop"] = tonumber(string.sub(_contactObjId, 5, -1))
    end
    if PlinkoConfig.DEBUG_MODE == true then
        if string.sub(_contactObjId, 1, 3) == "cup" then
            local cos = self.m_collisions[_ballId]
            local clist = {cos["bubble"][1], cos["bubble"][2], cos["centre"], cos["drop"]}
            self:write2File(clist)
        end
    end
end

function PlinkoMgr:write2File(_contactList)
    local json = cjson.encode(_contactList)
    local logFilePath = cc.FileUtils:getInstance():getWritablePath() .. "debug_log.txt"
    io.writefile(logFilePath, json .. "\n", "a+")
end

-------------- 本次掉球 --------------

-------------- debug Temp --------------
function PlinkoMgr:getCupBallCountInfoStr()
    return cjson.encode(self.m_cupBallCountList or {})
end
function PlinkoMgr:resetCupBallCountInfo()
    self.m_cupBallCountList = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end
function PlinkoMgr:addCupBallCountByIdx(_cupIdx)
    if not self.m_cupBallCountList then
        self:resetCupBallCountInfo()
    end
    self.m_cupBallCountList[_cupIdx] = (self.m_cupBallCountList[_cupIdx] or 0) + 1
end
-------------- debug Temp --------------
function PlinkoMgr:getSpecialDingContactList()
    return cjson.encode(self.m_specialDingContactList or {})
end
function PlinkoMgr:resetSpecialDingContactList()
    self.m_specialDingContactList = {0, 0, 0}
end
-- _dingIndex, 左1 右2 中3
function PlinkoMgr:addSpecialDingContact(_dingContactId)
    if not self.m_specialDingContactList then
        self:resetSpecialDingContactList()
    end
    local dingIdx = nil
    if _dingContactId == "ding_x2" then
        dingIdx = 1
    elseif _dingContactId == "ding_x10" then
        dingIdx = 2
    elseif _dingContactId == "ding_center" then
        dingIdx = 3
    end
    if dingIdx then
        self.m_specialDingContactList[dingIdx] = (self.m_specialDingContactList[dingIdx] or 0) + 1
    end
end
-------------- debug Temp --------------

function PlinkoMgr:getBallID()
    if not self.m_ballId then
        self.m_ballId = 0
    end
    self.m_ballId = self.m_ballId + 1
    return self.m_ballId
end

return PlinkoMgr
