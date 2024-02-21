--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-15 14:56:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-15 15:59:58
FilePath: /SlotNirvana/src/activities/Activity_TreasureHunt/controller/ActTreasureHuntMgr.lua
Description: 寻宝之旅 管理器mgr
--]]
local ActTreasureHuntMgr = class("ActTreasureHuntMgr", BaseActivityControl)
local TreasureHuntConfig = util_require("activities.Activity_TreasureHunt.config.TreasureHuntConfig")

function ActTreasureHuntMgr:ctor()
    ActTreasureHuntMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.TreasureHunt)
end

-- 获取网络 obj
function ActTreasureHuntMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local ActNoviceTrailNet = util_require("activities.Activity_TreasureHunt.net.TreasureHuntNet")
    self.m_net = ActNoviceTrailNet:getInstance()
    return self.m_net
end

function ActTreasureHuntMgr:getPopModule()
    return "Activity_TreasureHunt.Activity.views.TreasureHuntMainLayer"
end

function ActTreasureHuntMgr:getEntryModule()
    return "Activity_TreasureHunt.Activity.views.TreasureHuntEntryNode"
end

-- 自动弹出 主弹板去领奖
function ActTreasureHuntMgr:checkAutoPopColMainLayer(_lvUp)
    if not self:isCanShowLayer() then
        return false
    end

    local data = self:getRunningData()

    local unlockLv = data:getUnlockLv()
    local bLock = globalData.userRunData.levelNum < unlockLv
    if bLock then
        return false
    end

    if _lvUp and globalData.userRunData.levelNum == unlockLv then
        -- 升级正好解锁了
        return true
    end
    
    local bestTaskData = data:getBestTaskData()
    if not bestTaskData then
        return false
    end
    return bestTaskData:getProgPercent() >= 100
end

-- 显示主界面
function ActTreasureHuntMgr:showMainLayer()
    if not gLobalViewManager:isLevelView() then
        -- 不在关卡里不显示
        return
    end
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByName("TreasureHuntMainLayer") then
        return
    end

    local luaPath = "Activity_TreasureHunt.Activity.views.TreasureHuntMainLayer"
    if globalData.slotRunData.isPortrait then
        luaPath = "Activity_TreasureHunt.Activity.views.TreasureHuntMainLayer_Portrait"
    end
    local view = util_createView(luaPath)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 奖励弹板
function ActTreasureHuntMgr:showRewardLayer(_params)
    if type(_params) ~= "table" then
        return
    end

    local rewardList = {}
    local taskCoins = tonumber(_params.collectCoins) or 0
    local levelCoins = tonumber(_params.levelCoins) or 0
    local coins = taskCoins + levelCoins
    if coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(coins, 6))
        table.insert(rewardList, itemData)
    end
    for _, severData in ipairs(_params.collectItems or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(severData)
        table.insert(rewardList, shopItem)
    end

    if #rewardList == 0 or gLobalViewManager:getViewByName("TreasureHuntRewardLayer") then
        return
    end

    local view = util_createView("Activity_TreasureHunt.Activity.views.TreasureHuntRewardLayer", rewardList, coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- spin 更新任务数据
function ActTreasureHuntMgr:spinUpdateLevelTaskInfo(_data)
    if type(_data) ~= "table" or not _data.updateLevel then
        return
    end

    local data = self:getData()
    if not data then
        return
    end

    data:spinUpdateLevelTaskInfo(_data.updateLevel)
    gLobalNoticManager:postNotification(TreasureHuntConfig.EVENT_NAME.NOTICE_UPDATE_TREASURE_DASH_MACHINE_ENTRY)
end

function ActTreasureHuntMgr:sendCollectReq(_seq)
    if not _seq then
        return
    end

    self:getNetObj():sendCollectReq(_seq)
end

return ActTreasureHuntMgr