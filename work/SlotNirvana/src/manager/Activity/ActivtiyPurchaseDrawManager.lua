--[[
Author: cxc
Date: 2021-04-30 11:37:19
LastEditTime: 2021-06-06 20:07:11
LastEditors: Please set LastEditors
Description:  HAT TRICK DELUXE 活动 购买充值触发的活动 管理器
FilePath: /SlotNirvana/src/manager/Activity/ActivtiyPurchaseDrawManager.lua
--]]
local ActivtiyPurchaseDrawManager = class("ActivtiyPurchaseDrawManager",util_require("baseActivity.BaseActivityManager"))

function ActivtiyPurchaseDrawManager:getInstance()
    if self.m_instance == nil then
        self.m_instance = ActivtiyPurchaseDrawManager.new()
	end
	return self.m_instance
end

function ActivtiyPurchaseDrawManager:ctor()
   self.m_popMainLayerRefCount = 0 --检查是不是要弹出主面板引用计数
   self.m_randomItemRewardList = {}
end

-- 获取活动数据
function ActivtiyPurchaseDrawManager:getActivityData( )
    local activityData = clone(G_GetActivityDataByRef(ACTIVITY_REF.PurchaseDraw))
    if activityData then
        local themeName = activityData:getThemeName()
        self.m_refName = activityData:getRefName()
        self.m_luaName = themeName
        return activityData
    end
    return nil
end

function ActivtiyPurchaseDrawManager:getConfig()
    if not self.m_configData then
        local actData = self:getActivityData()
        local configPath = "Activity/" .. self.m_luaName .. "Config"
        self.m_configData = util_getRequireFile(configPath)
    end
    
    return self.m_configData
end

function ActivtiyPurchaseDrawManager:getIsOpen()
    local actData = self:getActivityData()

    if not actData then
        return false
    end

    if actData:isRunning() and not globalDynamicDLControl:checkDownloading(actData:getThemeName()) then 
        return true
    end

    return false
end

function ActivtiyPurchaseDrawManager:createActMainLayer(_callback)
    _callback = _callback or function() end
    if gLobalViewManager:getViewLayer():getChildByName("PurchaseDrawMainLayer") then
        _callback()
        return
    end

    local mainLayerPath = "Activity/"..self.m_luaName
    local mainlayer = util_createFindView(mainLayerPath)
    if not mainlayer then
        _callback()
        return
    end

    mainlayer:setOverFunc(_callback)
    mainlayer:setName("PurchaseDrawMainLayer")
    mainlayer:setExtendData("PurchaseDrawMainLayer")
    gLobalViewManager:showUI(mainlayer,ViewZorder.ZORDER_UI)
end

function ActivtiyPurchaseDrawManager:popActMainLayer(_callback)
    if not self:getIsOpen() then
        if _callback then
            _callback()
        end
        return
    end

    self:createActMainLayer(_callback)
end

function ActivtiyPurchaseDrawManager:addAutoPopMainLayerRefCount()
    self.m_popMainLayerRefCount = self.m_popMainLayerRefCount + 1
end
function ActivtiyPurchaseDrawManager:resetAutoPopMainLayerRefCount()
    self.m_popMainLayerRefCount = 0
end
function ActivtiyPurchaseDrawManager:checkPopMainLayer(_callback)
    _callback = _callback or function() end

    if not self:getIsOpen() then
        _callback()
        return
    end

    if self.m_popMainLayerRefCount <= 0 then
        _callback()
        return 
    end

    -- 是否有可领取的
    local bActive = self:checkIsActive()
    if not bActive then
        _callback()
        return
    end

    self:createActMainLayer(_callback)
    -- self.m_popMainLayerRefCount = self.m_popMainLayerRefCount - 1 
end

-- 是否是 高倍模式
function ActivtiyPurchaseDrawManager:checkIsDeluxeModule()
    return false
end

-- 是否 被激活
function ActivtiyPurchaseDrawManager:checkIsActive()
    local actData = self:getActivityData()
    if not actData then
        return false
    end

    return actData:checkIsActive()
end

-- 设置 帽子奖励是否可以点击
function ActivtiyPurchaseDrawManager:setHatBtnClickEnabled(_enabled)
    self.m_hatBtnEnabled = _enabled
end
function ActivtiyPurchaseDrawManager:getHatBtnClickEnabled()
    return self.m_hatBtnEnabled
end

-- 获取 未领取的的奖励 随机排布
function ActivtiyPurchaseDrawManager:getRandomItemReward()
    if not next(self.m_randomItemRewardList) then
        local actData = self:getActivityData()
        if not actData then
            return
        end 
        local normalRewardList = actData:getNormalRewardList()
        local collectIdx = actData:getLastCollectIdx()

        if #normalRewardList <= 0 or collectIdx <= 0 then
            return
        end

        self.m_randomItemRewardList = table.values(normalRewardList)
        table.remove(self.m_randomItemRewardList, collectIdx)
    end
    
    return table.remove(self.m_randomItemRewardList, util_random(1, #self.m_randomItemRewardList))
end
function ActivtiyPurchaseDrawManager:resetRandomItemReward()
    self.m_randomItemRewardList = {}
end

------------------ 网络接口 ------------------
-- 领取奖励
function ActivtiyPurchaseDrawManager:sendCollectHatRewardReq()
    gLobalViewManager:addLoadingAnima(false, 2)
    
	local function successCallFunc(target, resData)
        print("cxc--success--", resData)
        gLobalViewManager:removeLoadingAnima()

        local config = self:getConfig()
        local eventName = "HAT_TRICK_COLLECT_REWARD_SUCCESS"
        if config then
           eventName = config.EVENT_NAME.COLLECT_REWARD_SUCCESS
        end
        gLobalNoticManager:postNotification(eventName)
    end

    local function failedCallFunc(target, code, errorMsg)
        print("cxc--failed--", code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local actionData = self:getSendActionData(ActionType.HatTrickCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFunc)
end
------------------ 网络接口 ------------------

return ActivtiyPurchaseDrawManager