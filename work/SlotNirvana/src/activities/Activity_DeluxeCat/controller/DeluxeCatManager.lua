local DeluexeCatNet = require("activities.Activity_DeluxeCat.net.DeluxeCatNet")
local DeluxeCatManager = class("DeluxeCatManager", BaseActivityControl)

-- function DeluxeCatManager:getInstance()
--     if self.m_instance == nil then
--         self.m_instance = DeluxeCatManager.new()
--     end
--     return self.m_instance
-- end

function DeluxeCatManager:ctor()
    DeluxeCatManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubCat)

    self.m_dropCatFoodList1 = {} -- Low
    self.m_dropCatFoodList2 = {} -- Middle
    self.m_dropCatFoodList3 = {} -- High

    self.m_overCb = nil
    self.m_bPanelAutoClose = false
    self.m_catNet = DeluexeCatNet:getInstance()
    self:getConfig()
end

function DeluxeCatManager:getConfig()
    if not self.m_config then
        self.m_config = require("activities.Activity_DeluxeCat.config.DeluxeCatConfig")
    end

    return self.m_config
end

-- 猫的 活动数据

function DeluxeCatManager:getCatServerData()
    return self:getRunningData()
end

-- 猫主面板
-- function DeluxeCatManager:setCurMainView(_curMainView)
--     self.m_curMainView = _curMainView
-- end

function DeluxeCatManager:getCurMainView()
    -- return self.m_curMainView
    return gLobalViewManager:getViewByName("CatMainView")
end

-- 领取每日免费的猫粮
function DeluxeCatManager:getDaliyFreeCatFoodReq()
    --联网检查
    -- if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
    --     gLobalViewManager:showReConnect(true)
    --     return
    -- end

    local Activity_CatConfig = self:getConfig()
    if not Activity_CatConfig then
        return
    end

    local function successCallFunc(resultData)
        if resultData and resultData.DailyRewards then
            gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.GAIN_FREE_FOOD_SUCCESS, resultData.DailyRewards)
        end
    end

    local function failedCallFunc()
        gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.RESET_FREE_FOOD_TOUCH_ENABLED)
    end

    self.m_catNet:sendGetDaliyFreeCatFoodReq(successCallFunc, failedCallFunc)
end

-- 投喂
function DeluxeCatManager:feedCatReq(_catIdx, _foodTypeStr, _useNum)
    local Activity_CatConfig = self:getConfig()
    if not Activity_CatConfig then
        gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.RESET_RUNNING_ACT_SIGN)
        return
    end

    gLobalViewManager:addLoadingAnimaDelay(2) -- 2秒后判断要不要loading

    local function successCallFunc(rewardData)
        gLobalViewManager:removeLoadingAnima()

        gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.FEED_CAT_SUCCESS, rewardData)
    end

    local function failedCallFunc()
        gLobalViewManager:removeLoadingAnima()

        gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.SHOW_MAX_STEP_GUIDE)
        gLobalNoticManager:postNotification(Activity_CatConfig.EVENT_NAME.RESET_RUNNING_ACT_SIGN)
    end

    self.m_catNet:sendFeedCatReq(_catIdx, _foodTypeStr, _useNum, successCallFunc, failedCallFunc)
end

-- 显示主面板
function DeluxeCatManager:showMainLayer(_bExLobbyEnter)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity.Activity_CatMainView", _bExLobbyEnter)
    if tolua.isnull(view) then
        return nil
    end
    view:setName("CatMainView")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

function DeluxeCatManager:setPopCatFoodTempList(_list)
    self.m_shopItemList = _list
end
function DeluxeCatManager:getPopCatFoodTempList(_list)
    return self.m_shopItemList
end
function DeluxeCatManager:resetCatFoodTempList()
    self.m_shopItemList = {}
end

function DeluxeCatManager:autoPopCatFoodLayer(_cb)
    _cb = _cb or handler(self, self.resetCatFoodTempList)
    if self.m_shopItemList and next(self.m_shopItemList) then
        self:popCatFoodRewardPanel(self.m_shopItemList, _cb)
        return
    end

    _cb()
end

-- 弹出猫粮的弹板(只显示一种猫粮)
-- version 2021-07-09 12:09:48 可能一下掉落几种猫粮
function DeluxeCatManager:popCatFoodRewardPanel(_shopItemDataList, _callback, _bAuto)
    _callback = _callback or function()
        end

    if not _shopItemDataList or not next(_shopItemDataList) then
        _callback()
        return
    end

    self.m_overCb = _callback
    self.m_bPanelAutoClose = _bAuto

    self:parseDropCatFoodListData(_shopItemDataList)
    self:dropCatFoodRewardLayerNext()
end

-- 解析需要 掉落的猫粮 列表（分好类）
function DeluxeCatManager:parseDropCatFoodListData(_shopItemDataList)
    if not _shopItemDataList or not next(_shopItemDataList) then
        return
    end

    for i, itemInfo in ipairs(_shopItemDataList) do
        for j=1,1 do
            local icon = itemInfo.p_icon or ""
            if not string.find(icon, "CatFood") then
                break
            end
    
            local idx = string.sub(icon, -1)
            local list = self["m_dropCatFoodList" .. idx]
            if not list then
                break
            end
    
            local catFoodData = list[1]
            if not catFoodData then
                table.insert(list, itemInfo)
            else
                catFoodData.p_num = catFoodData.p_num + itemInfo.p_num
            end
            
        end
    end
end

-- 掉落猫粮 弹出猫粮弹板
function DeluxeCatManager:dropCatFoodRewardLayerNext()
    local catFoodList = {}
    for i = 1, 3 do
        local dropCatFoodList = self["m_dropCatFoodList" .. i] or {}
        if next(dropCatFoodList) then
            catFoodList = dropCatFoodList
            break
        end
    end

    if not next(catFoodList) then
        if self.m_overCb then
            self.m_overCb()
            self.m_overCb = nil
        end
        return
    end

    local foodRewardPanel = util_createFindView("Activity/Activity_CatFoodReward", clone(catFoodList), self.m_bPanelAutoClose)
    if not foodRewardPanel then
        if self.m_overCb then
            self.m_overCb()
            self.m_overCb = nil
        end
        return
    end

    foodRewardPanel.m_callback = nil --(热更了代码但未动态下载更新报错  m_callalbask 会变成bool类型 m_callalbask = self.m_bPanelAutoClose)
    foodRewardPanel:setOverFunc(
        function()
            self:dropCatFoodRewardLayerNext()
        end
    )
    table.remove(catFoodList, 1)
    gLobalViewManager:getViewLayer():addChild(foodRewardPanel, ViewZorder.ZORDER_UI)
end

-- 手动改变猫粮数量
function DeluxeCatManager:changeCatFoodNum(_idx, _count)
    local actData = self:getCatServerData()
    if not actData then
        return
    end

    actData:setFoodNum(_idx, _count)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXE_CAT_FOOD_COUNT_REFRESH)
end

return DeluxeCatManager
