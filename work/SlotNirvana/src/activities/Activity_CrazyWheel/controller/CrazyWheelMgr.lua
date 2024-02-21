--[[

]]

require("activities.Activity_CrazyWheel.config.CrazyWheelCfg")
local CrazyWheelMgr = class("CrazyWheelMgr", BaseActivityControl)

function CrazyWheelMgr:ctor()
    CrazyWheelMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CrazyWheel)
    self:setDataModule("GameModule.CrazyWheel.model.CrazyWheelData")
end

function CrazyWheelMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "EntryNode" 
end

function CrazyWheelMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function CrazyWheelMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function CrazyWheelMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function CrazyWheelMgr:isCanShowPop()
    return CrazyWheelMgr.super.isCanShowPop(self)
end

function CrazyWheelMgr:isCanShowLobbyLayer()
    return CrazyWheelMgr.super.isCanShowLobbyLayer(self)
end

function CrazyWheelMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("Activity_CrazyWheel") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local filePath = themeName .. "/Activity_CrazyWheel"
    if not (util_IsFileExist(filePath .. ".lua") or util_IsFileExist(filePath .. ".luac")) then
        return
    end
    local view = util_createView(themeName .. ".Activity_CrazyWheel")
    if view then
        view:setName("Activity_CrazyWheel")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CrazyWheelMgr:showSelectTipLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CWSelectTipLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.CWSelectTipLayer", _over)
    if view then
        view:setName("CWSelectTipLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CrazyWheelMgr:showRoundTipLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CWRoundTipLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.CWRoundTipLayer", _over)
    if view then
        view:setName("CWRoundTipLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CrazyWheelMgr:showBuyLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CWBuyLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.CWBuyLayer")
    if view then
        view:setName("CWBuyLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CrazyWheelMgr:showRewardLayer(_coins, _gems, _items, _over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CrazyWheelRewardLayer") ~= nil then
        return nil
    end
    local rewardData = {}
    local coins = toLongNumber(0)
    coins:setNum(_coins)
    if toLongNumber(coins) > toLongNumber(0) then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        table.insert(rewardData, itemData)
    end
    if _gems and _gems > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Gem", _gems)
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_ADD}
        table.insert(rewardData, itemData)
    end
    if _items and #_items > 0 then
        for i=1,#_items do
            local itemData = _items[i]
            -- 刷新高倍场点数
            if string.find(itemData.p_icon, "Pouch") then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:refreshBagsNum(itemData.p_icon, itemData.p_num)                
            end
            if itemData.p_icon == "Gem" then
                itemData.p_mark = {ITEM_MARK_TYPE.CENTER_ADD}
            end
            table.insert(rewardData, itemData)
        end
    end

    -- 队列
    local _funcList = {}
    _funcList[#_funcList + 1] = function()
        self:triggerDropCards("Crazy Wheel")
    end
    _funcList[#_funcList + 1] = function()
        -- 刷新高倍场点数
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
        if _over then
            _over()
        end
    end
    self.m_dropFuncList = _funcList
    local function closeReward()
        self:triggerDropFuncNext()
    end
    local view = gLobalItemManager:createRewardLayer(rewardData, closeReward, coins)
    if view then
        view:setName("CrazyWheelRewardLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CrazyWheelMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("CWInfoLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.CWInfoLayer")
    if view then
        view:setName("CWInfoLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end


-- 检测 list 调用方法
function CrazyWheelMgr:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        return
    end
    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉卡
function CrazyWheelMgr:triggerDropCards(_source)
    if CardSysManager:needDropCards(_source) == true then
        CardSysManager:doDropCards(
            _source,
            function()
                self:triggerDropFuncNext()
            end,
            true
        )
    else
        self:triggerDropFuncNext()
    end
end
--[[---------------------------------------------------------------------
    接口
]]
-- play
function CrazyWheelMgr:requestPlay(_multiple, _success, _fail)
    local data = self:getRunningData()
    if not data then
        return false
    end
    G_GetNetModel(NetType.CrazyWheel):requestPlay(_multiple, _success, _fail)
    return true
end
-- 买券
function CrazyWheelMgr:buyLottery(_num, _success, _fail)
    local data = self:getRunningData()
    if not data then
        return false
    end
    G_GetNetModel(NetType.CrazyWheel):buyLottery(_num, _success, _fail)
    return true
end
-- 领奖
function CrazyWheelMgr:requestCollect(_success, _fail)
    local data = self:getRunningData()
    if not data then
        return false
    end
    G_GetNetModel(NetType.CrazyWheel):requestCollect(_success, _fail)
    return true
end


return CrazyWheelMgr