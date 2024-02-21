--[[
    DuckShot
]]
local DuckShotNet = require("GameModule.DuckShot.net.DuckShotNet")
local DuckShotControl = class("DuckShotControl", BaseGameControl)

function DuckShotControl:ctor()
    DuckShotControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DuckShot)

    self.m_curPlayGameIndex = 0
    self.m_isPlaying = false
    self.m_isReconnect = false
    self.m_jackpotGrand = false

    self.m_net = DuckShotNet:getInstance()
end

function DuckShotControl:parseData(_gameData, _isLogon)
    if not _gameData then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.DuckShot.model.DuckShotData"):create()
        _data:parseData(_gameData, _isLogon)
        self:registerData(_data)
    else
        _data:parseData(_gameData, _isLogon)
    end
end

function DuckShotControl:getPlayStatusDuckShotGameData()
    local gameData = nil
    local gameDatas =  self:getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k,v in pairs(list) do
            if v.gameData:isPlaying() then
                gameData = v.gameData
                break
            end
        end
    end
    return gameData
end

function DuckShotControl:showDuckShotGameView(_gameData, _overCallback)
    local gameData = _gameData or self:getPlayStatusDuckShotGameData()
    local showFlag = nil
    if gameData then 
        showFlag = self:showMainLayer(gameData, _overCallback)
    end
    return showFlag
end

function DuckShotControl:getDuckShotGameDataByIndex(_index)
    local gameData = nil
    local gameDatas = self:getData()
    if gameDatas then 
        local list = gameDatas:getList()
        for i,v in pairs(list) do
            if v.gameIndex == _index then 
                gameData = v.gameData
                break
            end
        end 
    end

    return gameData
end

function DuckShotControl:setPlayGameIndex(_index)
    self.m_curPlayGameIndex = _index or 0
end

function DuckShotControl:getPlayGameIndex()
    return self.m_curPlayGameIndex
end

function DuckShotControl:setPlayStatus(_flag)
    self.m_isPlaying = _flag
end

function DuckShotControl:getPlayStatus()
    return self.m_isPlaying
end

function DuckShotControl:setReconnectStatus(_flag)
    self.m_isReconnect = _flag
end

function DuckShotControl:getReconnectStatus()
    return self.m_isReconnect
end

function DuckShotControl:getJackpotGrand()
    return self.m_jackpotGrand
end

function DuckShotControl:setJackpotGrand(_flag)
    self.m_jackpotGrand = _flag
end

-- 大厅展示资源判断
function DuckShotControl:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

-- 显示主界面
function DuckShotControl:showMainLayer(_param, _overCallback)
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        if _overCallback then 
            _overCallback()
        end
        return nil
    end
    local showFlag = nil
    if gLobalViewManager:getViewByExtendData("Activity_DuckShot") == nil then
        local frameCache = cc.SpriteFrameCache:getInstance()
        frameCache:addSpriteFrames("Activity/DuckShot/ui/ui_plist/mainUIEfPlist.plist")
        frameCache:addSpriteFrames("Activity/DuckShot/ui/ui_plist/mainUIPlist.plist")
        
        local gameView = util_createView("Activity.Activity_DuckShotMainLayer", _param)
        if gameView ~= nil then
            -- gameView:insertPlistInfo("Activity/DuckShot/ui/ui_plist/mainUIEfPlist.plist")
            -- gameView:insertPlistInfo("Activity/DuckShot/ui/ui_plist/mainUIPlist.plist")
            if _overCallback then
                gameView:setOverFunc(_overCallback)
            end
            showFlag = true
            gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
        end
    end
    return showFlag
end

function DuckShotControl:getNewCreateGameData(_source)
    local newGame = {}
    local gameDatas = self:getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k,v in pairs(list) do
            if v.gameData:getSource() == _source and not v.notNewGame then
                v.notNewGame = true
                table.insert(newGame, v)
            end
        end
    end
    return newGame
end

function DuckShotControl:showPlayTipLayer(_overCallback)
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        if _overCallback then 
            _overCallback()
        end
        return nil
    end
    if gLobalViewManager:getViewByExtendData("Activity_DuckShotPlayTipLayer") == nil then
        local gameView = util_createView("Activity.Activity_DuckShotPlayTipLayer", _overCallback)
        if gameView ~= nil then
            gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
        end
    end
end

function DuckShotControl:showWheelLayer(_gameIndex, _grandCoins)
    local view = util_createView("Activity.Activity_DuckShotRewardWheelLayer", _gameIndex, _grandCoins)
    if view then 
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DuckShotControl:showWelcomeLayer()
    local view = util_createView("Activity.Activity_DuckShotWelcomeLayer")
    if view then 
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DuckShotControl:showRewardLayer(_type, _gameIndex, _coins)
    local view = util_createView("Activity.Activity_DuckShotRewardLayer", _type, _gameIndex, _coins)
    if view then 
        -- view:insertPlistInfo("Activity/DuckShot/ui/ui_plist/rewardUIPlist.plist")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DuckShotControl:showPayLayer(_gameIndex)
    local view = util_createView("Activity.Activity_DuckShotPayLayer", _gameIndex)
    if view then 
        -- view:insertPlistInfo("Activity/DuckShot/ui/ui_plist/payUIPlist.plist")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DuckShotControl:showPayQuitConfirmation(_data)
    local view = util_createView("Activity.Activity_DuckShotPayQuitConfirmation", _data)
    if view then 
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- 发射
function DuckShotControl:sendCollect(_index, _layer)
    self.m_net:sendCollect(_index, _layer)
end

-- 命中
function DuckShotControl:sendBulletHit(params)
    self.m_net:sendBulletHit(params)
end

-- 关闭
function DuckShotControl:sendPayClose(_index)
    self.m_net:sendPayClose(_index)
end

-- 激活
function DuckShotControl:sendGamePlay(_index)
    self.m_net:sendGamePlay(_index)
end

-- 付费
function DuckShotControl:buyPayDuckShot(_data)
    if not _data then
        release_print("clickBuyBtn buyFailed, DuckShotGameData is NIL")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BUY_FAILED)
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
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.DUCK_SHOT_TYPE,
        _data:getBuyKey(),
        _data:getPrice(),
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BUY_FAILED)
        end
    )
end

function DuckShotControl:buySuccess()
    globalData.LevelRushLuckyStampCoinsEndPos = {
        x = display.width * 0.1,
        y = display.height - util_getBangScreenHeight() - 30
    }
    gLobalViewManager:checkBuyTipList(function()
        globalData.LevelRushLuckyStampCoinsEndPos = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BUY_SUCCESS)
    end)
end

function DuckShotControl:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "DuckShot"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "DuckShot"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return DuckShotControl
