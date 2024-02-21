--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-04-28 16:04:08
    describe:刮刮卡管理层
]]
local ScratchCardsNet = require("activities.Activity_ScratchCards.net.ScratchCardsNet")
local ScratchCardsMgr = class("ScratchCardsMgr", BaseActivityControl)

function ScratchCardsMgr:ctor()
    ScratchCardsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ScratchCards)

    self.m_netModel = ScratchCardsNet:getInstance() -- 网络模块
end

function ScratchCardsMgr:requestRefreshView(data) --刷新界面
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_REFRESHVIEW_SUCESS, true)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_REFRESHVIEW_SUCESS, false)
    end
    self.m_netModel:requestOpenView(data, successFunc, failedCallFunc)
end

function ScratchCardsMgr:requestFree(data) --免费领取刮刮卡
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_BUY_SUCESS, {index = 1, btnInx = 1})
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_BUY_SUCESS, false)
    end
    self.m_netModel:requestFree(data, successFunc, failedCallFunc)
end

function ScratchCardsMgr:requestScratch(data) --刮卡完成
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_SCRATCH_SUCESS)
    end

    local failedCallFunc = function()
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestScratch(data, successFunc, failedCallFunc)
end

function ScratchCardsMgr:requestCloseView(data) --关闭刮卡界面
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_UIVIEW_OPERATIONLAYER_CLOSE)
    end

    local failedCallFunc = function()
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestCloseView(data, successFunc, failedCallFunc)
end

function ScratchCardsMgr:requestBuyGoods(data)
    local successFunc = function()
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_BUY_SUCESS, data)
        end)
    end

    local failedCallFun = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SCRATCHCARDS_REQUEST_BUY_SUCESS, false)
    end
    self.m_netModel:requestBuyGoods(data, successFunc, failedCallFun)
end

----------------------------------------------- 华丽分割线 -----------------------------------------------

function ScratchCardsMgr:showMainLayer(param)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ScratchCardsMainLayer") then
        return nil
    end
    local view = util_createFindView("Activity/ScratchCardsMain/ScratchCardsMainLayer", param)
    -- 检查资源完整性
    if view ~= nil and view.isCsbExist ~= nil and view:isCsbExist() then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--帮助界面
function ScratchCardsMgr:showExplainLayer(param)
    local view = util_createView("Activity/ScratchCardsExplain/ScratchCardsExplain", param)
    -- 检查资源完整性
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--刮刮卡操作界面
function ScratchCardsMgr:showOperationMainLayer(_index, _openSource)
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local view = util_createView("Activity.ScratchCardsOperation.ScratchCardsOperationMainLayer", _index, _openSource)
    -- 检查资源完整性
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--刮刮卡奖励界面
function ScratchCardsMgr:showScratchCardsRewardLayer(param)
    local view = util_createView("Activity.ScratchCardsReward.ScratchCardsRewardLayer", param)
    -- 检查资源完整性
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--刮刮卡关闭说明界面
function ScratchCardsMgr:showScratchCardsDialogLayer(param)
    local view = util_createView("Activity.ScratchCardsOperation.ScratchCardsDialog", param)
    -- 检查资源完整性
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end


----------------------------------------------- 打点 -----------------------------------------------
-- 弹框日志
function ScratchCardsMgr:sendOpenLog(isLevelUp)
    -- 发送打点日志
    local entryName = "loginLobbyPush"
    local entryType = "lobby"
    if isLevelUp then
        entryName = "levelUpPush"
        local curMachineData = globalData.slotRunData.machineData or {}
        entryType = curMachineData.p_name
    end
    gLobalSendDataManager:getLogIap():setEntryType(entryType)
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", entryName)

    local type = "Open"
    local pageName = "PushPage"
    gLobalSendDataManager:getScratchActivity():sendPageLog(pageName, type)
end

-- 点击日志
function ScratchCardsMgr:sendClickLog(isLevelUp)
    -- 发送打点日志
    local entryName = "loginLobbyPush"
    local entryType = "lobby"
    if isLevelUp then
        entryName = "levelUpPush"
        local curMachineData = globalData.slotRunData.machineData or {}
        entryType = curMachineData.p_name
    end
    gLobalSendDataManager:getLogIap():setEntryType(entryType)
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", entryName)

    local type = "Click"
    local pageName = "PushPage"
    gLobalSendDataManager:getScratchActivity():sendPageLog(pageName, type)
end

return ScratchCardsMgr
