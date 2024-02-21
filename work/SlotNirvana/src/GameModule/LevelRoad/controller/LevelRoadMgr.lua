local LevelRoadNet = require("GameModule.LevelRoad.net.LevelRoadNet")
local LevelRoadMgr = class("LevelRoadMgr", BaseGameControl)

ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD = "NOTIFY_LEVELROAD_REQUEST_REWARD"
ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER = "NOTIFY_LEVELROAD_CLOSE_REWARDLAYER"
ViewEventType.NOTIFY_LEVELROAD_CLOSE_BOOSTLAYER = "NOTIFY_LEVELROAD_CLOSE_BOOSTLAYER"
ViewEventType.NOTIFY_LEVELROAD_BUY_SALE = "NOTIFY_LEVELROAD_BUY_SALE"
ViewEventType.NOTIFY_LEVELROAD_SALE_END = "NOTIFY_LEVELROAD_SALE_END"
ViewEventType.NOTIFY_LEVELROAD_REFRESH_LOBBY_BOTTOMNODE = "NOTIFY_LEVELROAD_REFRESH_LOBBY_BOTTOMNODE"

function LevelRoadMgr:ctor()
    LevelRoadMgr.super.ctor(self)
    self:setRefName(G_REF.LevelRoad)
    self.m_netModel = LevelRoadNet:getInstance() -- 网络模块
    self:setDataModule("GameModule.LevelRoad.model.LevelRoadData")
    self.m_isCanShowLogoLayer = false
end

-- 等级里程碑 促销右边条节点
function LevelRoadMgr:getEntryModule()
    return "views.LevelRoad.LevelRoadSaleEntryNode"
end

function LevelRoadMgr:isCanShowEntryNode()
    if not self:isCanShowLayer() then
        return false
    end
    local curLevel = globalData.userRunData.levelNum
    if curLevel > 100 then
        return false
    end
    return true
end

-- 等级里程碑 左边条节点
function LevelRoadMgr:createEntryNode()
    if not self:isCanShowEntryNode() then
        return nil
    end
    local node = util_createView("views.LevelRoad.LevelRoadEntryNode")
    return node
end

function LevelRoadMgr:getRightFrameRunningData(refName)
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getRunningData()
    if data:isCanShowEntry() then
        return data
    end
    return false
end

-- 请求领取奖励
function LevelRoadMgr:requestCollectReward(params)
    self:setLocalPreviousExpansion()
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD, {isSuc = true, resData = resData})
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD, false)
    end
    self.m_netModel:requestCollectReward(params, successFunc, failedCallFunc)
end

-- 请求购买促销
function LevelRoadMgr:requestBuySale(params)
    local successFunc = function(resData)
        gLobalViewManager:checkBuyTipList(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_SALE_END)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_BUY_SALE, {isSuc = true})
            end
        )
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_BUY_SALE, false)
    end
    self.m_netModel:requestBuySale(params, successFunc, failedCallFunc)
end

function LevelRoadMgr:checkIsCanCollect()
    local data = self:getRunningData()
    if data then
        return data:checkIsCanCollect()
    end
    return false
end

function LevelRoadMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("LevelRoadMainLayer") then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadMainLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelRoadMgr:showRewardLayer(_params)
    if gLobalViewManager:getViewByExtendData("LevelRoadRewardLayer") then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadRewardLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelRoadMgr:showBoostTipLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("LevelRoadBoostTipLayer") then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadBoostTipLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelRoadMgr:showBoostLayer(_params)
    if gLobalViewManager:getViewByExtendData("LevelRoadBoostLayer") then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadBoostLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelRoadMgr:showLevelRoadSaleLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("LevelRoadSaleLayer") then
        return
    end
    local data = self:getRightFrameRunningData()
    if not data then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadSaleLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 跳转到大厅
function LevelRoadMgr:jumpLoobyUnlockGames(_slotId)
    self._slotId = _slotId
    if self._slotId and gLobalViewManager:isLevelView() then
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    else
        self:checkJumpLoobyUnlockGames()
    end
end
function LevelRoadMgr:checkJumpLoobyUnlockGames()
    if self._slotId and gLobalViewManager:isLobbyView() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GOTO_LEVEL_BY_ID, {levelId = self._slotId, autoEnter = false})
    end
    self._slotId = nil
end

function LevelRoadMgr:setIsCanShowLogoLayer(_isShow)
    self.m_isCanShowLogoLayer = _isShow
end

function LevelRoadMgr:isCanShowLogoLayer()
    if not self:isCanShowLayer() then
        return false
    end
    return self.m_isCanShowLogoLayer
end

function LevelRoadMgr:showLevelRoadBoostLogoLayer(_params)
    if not self:isCanShowLogoLayer() then
        return
    end
    self:setIsCanShowLogoLayer(false)
    if gLobalViewManager:getViewByExtendData("LevelRoadBoostLogoLayer") then
        return
    end
    local view = util_createFindView("views/LevelRoad/LevelRoadBoostLogoLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LevelRoadMgr:getBoostLogoLayer()
    return gLobalViewManager:getViewByExtendData("LevelRoadBoostLogoLayer")
end

-- 显示解锁的 关卡list layer
function LevelRoadMgr:showUnlockGameLayer(_gameIdList)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByName("LevelRoadBoostLogoLayer") then
        return
    end

    local view = util_createView("views.LevelRoad.LevelRoadUnlockGamesLayer", _gameIdList)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LevelRoadMgr:playStartAction(_over)
    local layer = self:getBoostLogoLayer()
    if layer then
        layer:playStartAction(_over)
    end
end

function LevelRoadMgr:getExpansionRatio()
    local data = self:getRunningData()
    if data then
        local preExpansion = self:getLocalPreviousExpansion()
        local curExpansion = data:getCurrentExpansion()
        local ratio = (curExpansion - preExpansion) / 100
        return ratio
    end
    return 0
end

function LevelRoadMgr:getLocalPreviousExpansion()
    return self.p_localPreviousExpansion or 1
end

function LevelRoadMgr:setLocalPreviousExpansion()
    local data = self:getRunningData()
    if data then
        local curExpansion = data:getCurrentExpansion()
        self.p_localPreviousExpansion = curExpansion
    end
end

return LevelRoadMgr
