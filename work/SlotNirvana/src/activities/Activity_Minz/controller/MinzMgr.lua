--[[
    Minz管理层
]]
local MinzNet = require("activities.Activity_Minz.net.MinzNet")
local MinzGuideMgr = require("activities.Activity_Minz.controller.MinzGuideMgr")
local MinzMgr = class("MinzMgr", BaseActivityControl)
-- Minz关卡ID
local MINZ_LEVEL_ID = {
    ["10209"] = true
}
-- Minz主题对应关卡ID
local SLOT_LEVELID_LIST = {
    [1] = "10209"
}
-- 构造函数
function MinzMgr:ctor()
    MinzMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.Minz)
    self.m_MinzNet = MinzNet:getInstance()
    self.m_MinzGuide = MinzGuideMgr:getInstance()
    self.m_isMinzGame = false -- 是否是minz关卡
    self.m_position = {}
    self.m_ownTagList = {} -- 玩家拥有的雕像id列表
    self.m_newTagList = {} -- new标签id列表 结构：{themeId_albumId = { id }}
    self.m_isEnoughBuy = false
    self.m_lastEnterLevelInfo = nil
    self:registerListener()
end

function MinzMgr:getGuide()
    return self.m_MinzGuide
end

function MinzMgr:parseSpinData(_data)
    local gameData = self:getRunningData()
    if gameData then
        gameData:parseData(_data)
    end
end

function MinzMgr:registerListener()
    -- 进入关卡消息回调
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuc = params[1]
            local resultData = params[2]
            if isSuc == true and resultData then
                local resultList = cjson.decode(resultData.result)
                self.m_isMinzGame = resultList.minzGame or false
                if self.m_isMinzGame then
                    gLobalActivityManager:showActivityEntryNode()
                end
            end
        end,
        ViewEventType.NOTIFY_GETGAMESTATUS
    )
end

-- 获取配置文件
function MinzMgr:getConfig()
    local theme = self:getThemeName()
    if not self.m_configData and self:isCanShowLayer() then
        --获取配置文件
        local configPathLua = "MinzCode/MinzConfig.lua"
        local configPathLuac = "MinzCode/MinzConfig.luac"
        if util_IsFileExist(configPathLua) or util_IsFileExist(configPathLuac) then
            self.m_configData = util_require(configPathLua)
            self.m_configData.setThemePath(theme)
        end
    end
    return self.m_configData
end

-- 关卡是否能够弹出主界面
function MinzMgr:isPopMainLayer()
    if self:isCanShowLayer() then
        local data = self:getRunningData()
        local isMinzLevel = self:isMinzLevel()
        local activeAlbum = data:getAlbumDataByActive()
        if activeAlbum and not isMinzLevel then
            return true
        end
    end
    return false
end

function MinzMgr:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("MinzMainLayer") then
        return nil
    end
    self.m_MinzGuide:onRegist(ACTIVITY_REF.Minz)
    local mainLayerPath = "MinzCode.MinzMainLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.MAIN_LAYER then
        mainLayerPath = config.CODE_PATH.MAIN_LAYER
    end
    local uiView = util_createView(mainLayerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function MinzMgr:showRuleLayer(params)
    if gLobalViewManager:getViewByExtendData("MinzRuleLayer") then
        return nil
    end
    local layerPath = "MinzCode.MinzRulerLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.RULE_LAYER then
        layerPath = config.CODE_PATH.RULE_LAYER
    end
    local uiView = util_createView(layerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function MinzMgr:showShopLayer(params)
    if gLobalViewManager:getViewByExtendData("MinzShopLayer") then
        return nil
    end
    local layerPath = "MinzCode.MinzShopLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.SHOP_LAYER then
        layerPath = config.CODE_PATH.SHOP_LAYER
    end
    local uiView = util_createView(layerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

-- 商店第二货币补全弹板
function MinzMgr:showShopGemLayer(params)
    if gLobalViewManager:getViewByExtendData("MinzShopGemLayer") then
        return nil
    end
    local layerPath = "MinzCode.MinzShopGemLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.SHOP_GEM_LAYER then
        layerPath = config.CODE_PATH.SHOP_GEM_LAYER
    end
    local uiView = util_createView(layerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

-- 每日首次进入可掉落minz点数关卡弹板
function MinzMgr:showFirstLayer(params)
    if gLobalViewManager:getViewByExtendData("MinzFirstLayer") then
        return nil
    end
    local layerPath = "MinzCode.MinzFirstLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.FIRST_LAYER then
        layerPath = config.CODE_PATH.FIRST_LAYER
    end
    local uiView = util_createView(layerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

-- 每日首次进入可掉落minz点数关卡二次确认弹板
function MinzMgr:showFirstConfirmLayer(params)
    if gLobalViewManager:getViewByExtendData("MinzFirstConfirmLayer") then
        return nil
    end
    local layerPath = "MinzCode.MinzFirstConfirmLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.FIRST_CONFIRM_LAYER then
        layerPath = config.CODE_PATH.FIRST_CONFIRM_LAYER
    end
    local uiView = util_createView(layerPath, params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function MinzMgr:popupMinzFirstLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if self:isMinzLevel() then
        return nil
    end
    if not self:getIsMinzGame() then
        return nil
    end
    local curTime = util_getCurrnetTime()
    local popTime = gLobalDataManager:getNumberByField("popupMinzFirstLayerZeroTime", 0)
    local compareTime = popTime + 24 * 60 * 60
    if curTime < compareTime then
        return nil
    end
    gLobalDataManager:setNumberByField("popupMinzFirstLayerZeroTime", curTime)
    local uiView = self:showFirstLayer()
    return uiView
end

-- 请求购买宝箱
function MinzMgr:requestBuyBox(params)
    self:setOwnTagList() -- 玩家当前拥有的雕像id
    local successCallback = function(resData)
        self:setNewTagList()
        self:setEnoughBuy()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MINZ_BUY_BOX, {result = resData, themeId = params.themeId, themeData = params.themeData})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MINZ_BUY_BOX, false)
    end
    local _gems = params.gems or 0
    local _count = params.count or 1
    local logManager = gLobalSendDataManager:getMinzActivity()
    if logManager then
        logManager:sendPageLog(_count)
    end
    self.m_MinzNet:requestBuyBox({gems = _gems, count = _count}, successCallback, failedCallback)
end

-- 关卡角标点数
function MinzMgr:getLevelLogoRes()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local sign, act = util_csbCreate("Activity_Minz/csd/minz_SlotsPoints.csb")
    return sign, act
end

-- 关卡角标大小
function MinzMgr:getLogoSize()
    return cc.size(55, 55)
end

function MinzMgr:setSlotData(play_data)
    self:parseSlotData(play_data)
end

function MinzMgr:parseSlotData(_data)
    self.slot_point = _data.point or 0
    self.slot_total = _data.totalPoint or 0
    self.slot_entory = _data.point
    -- local keys = table.keys(_data.positions)
    -- local values = table.values(_data.positions)
    -- self.m_position = {}
    -- for i=1,#keys do
    --     self.m_position[i] = values[i]
    -- end
    self.m_position = _data.positions
    local data = self:getRunningData()
    if data then
        if _data.totalPoint then
            data:setPoints(_data.totalPoint)
        end
        if _data.minBet then
            data:setBet(_data.minBet)
        end
    end
end

function MinzMgr:getEntryPoint()
    return self.slot_entory or 0
end
-- 获取本次spin产出logo个数
function MinzMgr:getSlotData()
    -- return #self.m_position,self.slot_point
    return 0, 0
end

-- 获取本次spin位置和点数
function MinzMgr:getPointData()
    return self.m_position
end

-- 清空本次spin数据
function MinzMgr:clearSlotData()
    self.slot_point = 0
    self.m_position = nil
end

function MinzMgr:getEntryModule()
    if not self:isCanShowLayer() then
        return ""
    end
    if not self:getIsMinzGame() then
        return ""
    end
    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local isSleeping = activityData:isSleeping()
    if isSleeping then
        return
    end
    local _module = "MinzCode.MinzEntryNode"
    return _module
end

-- 是否是掉落minz点数的关卡
function MinzMgr:getIsMinzGame()
    local machineData = globalData.slotRunData.machineData
    if machineData and machineData.getMinzGame then
        local isMinzGame = machineData:getMinzGame()
        return isMinzGame
    end
    return self.m_isMinzGame
end

-- minz开关 (传的必须是字符类型"true" or "false")
function MinzMgr:setMinzSwitch(_val)
    local data = self:getRunningData()
    if data then
        local endTime = data:getExpireAt()
        gLobalDataManager:setStringByField("minzSwitch" .. endTime, _val)
    end
    -- bet气泡
    G_GetMgr(G_REF.BetBubbles):refreshBetBubble(ACTIVITY_REF.Minz, _val == "true")
    -- 发消息通知GameBottomNode改变bet显示
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_BET_EXTRA_COST_SWITCH, {name = ACTIVITY_REF.Minz})
end

-- minz开关"true" or "false"（在关卡中spin是否掉落点数） 服务器那边规定必须是字符类型不能是布尔类型
function MinzMgr:getMinzSwitch()
    local data = self:getRunningData()
    if data then
        local endTime = data:getExpireAt()
        return gLobalDataManager:getStringByField("minzSwitch" .. endTime, "false")
    end
    return nil
end

-- minz开关 是否是开着的
function MinzMgr:getIsMinzSwitchOn()
    local minzSwitch = self:getMinzSwitch()
    if minzSwitch and minzSwitch == "true" then
        return true
    end
    return false
end

-- 进入minz关卡返回大厅按钮，左边条，右边条屏蔽
function MinzMgr:getMinzLevelId()
    return MINZ_LEVEL_ID
end

-- 进入minz的主题关卡ID列表
function MinzMgr:getSlotLevelIdList()
    return SLOT_LEVELID_LIST
end

-- 是否是minz关卡
function MinzMgr:isMinzLevel(_curMachineData)
    local data = self:getRunningData()
    if data then
        local curMachineData = _curMachineData or globalData.slotRunData.machineData
        if curMachineData and curMachineData.p_id then
            local level_id = tostring(curMachineData.p_id)
            if MINZ_LEVEL_ID[level_id] then
                return true
            end
        end
    end
    return false
end

-- -- 获得关卡bet加成
-- function MinzMgr:getMinzBetPercent(_betValue)
--     local betPercent = 0
--     local data = self:getRunningData()
--     if data then
--         local isMinzGame = self:getIsMinzGame()
--         local minzSwithcOn = self:getIsMinzSwitchOn()
--         if isMinzGame and minzSwithcOn then
--             betPercent = data:getExtraBetPercent()
--         end
--     end
--     return betPercent
-- end

-- 消耗额外金币需要实现的方法
function MinzMgr:getBetExtraPercent()
    local betPercent = 0
    local data = self:getRunningData()
    if data then
        local isMinzGame = self:getIsMinzGame()
        local minzSwithcOn = self:getIsMinzSwitchOn()
        if isMinzGame and minzSwithcOn then
            betPercent = data:getExtraBetPercent()
        end
    end
    return betPercent
end

function MinzMgr:setOwnTagList()
    local data = self:getRunningData()
    if data then
        self.m_ownTagList = data:getOwnStatuesId()
        self:setNewTagList()
    end
end

function MinzMgr:getOwnTagList()
    return self.m_ownTagList or {}
end

function MinzMgr:setNewTagList()
    local data = self:getRunningData()
    if data then
        local curIdList = data:getOwnStatuesId()
        local lastIdList = self:getOwnTagList()
        for k, v in pairs(lastIdList) do
            self.m_newTagList[k] = {}
            local curInfo = curIdList[k]
            if curInfo and #curInfo > 0 then
                for i = 1, #curInfo do
                    local index = table.indexof(v, curInfo[i])
                    if not index then
                        table.insert(self.m_newTagList[k], curInfo[i])
                    end
                end
            end
        end
    end
end

function MinzMgr:getNewTagList()
    return self.m_newTagList
end

function MinzMgr:getNewTagListById(_themeId, _albumId)
    return self.m_newTagList[_themeId .. "_" .. _albumId] or {}
end

function MinzMgr:setNewTagListEmptyById(_themeId, _albumId)
    self.m_newTagList[_themeId .. "_" .. _albumId] = {}
end

function MinzMgr:setEnoughBuy()
    local data = self:getRunningData()
    if data then
        self.m_isEnoughBuy = data:isEnoughBuy()
    end
end

function MinzMgr:isEnoughBuy()
    local data = self:getRunningData()
    if not data then
        return false
    end
    local _isEnoughBuy = data:isEnoughBuy()
    if _isEnoughBuy then
        if self.m_isEnoughBuy then
            return false
        end
    end
    self.m_isEnoughBuy = _isEnoughBuy
    return self.m_isEnoughBuy
end

function MinzMgr:setLastEnterLevelInfo()
    local machineData = globalData.slotRunData:getLastEnterLevelInfo()
    if not self:isMinzLevel(machineData) then
        self.m_lastEnterLevelInfo = machineData
    end
end

function MinzMgr:getLastEnterLevelInfo()
    return self.m_lastEnterLevelInfo
end

function MinzMgr:isCanShowBetBubble()
    if not MinzMgr.super.isCanShowBetBubble(self) then
        return false
    end
    -- 判断是否有数据
    local act_data = self:getRunningData()
    if not act_data then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    -- 判断是否会掉落minz点数关卡
    local isMinzGame = self:getIsMinzGame()
    if not isMinzGame then
        return false
    end
    -- 判断当前是否是minz关卡
    local isMinzLevel = self:isMinzLevel()
    if isMinzLevel then
        return false
    end
    -- 开关
    local isMinzSwitchOn = self:getIsMinzSwitchOn()
    if not isMinzSwitchOn then
        return false
    end
    return true
end

function MinzMgr:getBetBubblePath(_refName)
    return "BetExtraBubbleCode/" .. _refName .. "BetExtraNode"
end

function MinzMgr:getBuyBoxIndex()
    return self.m_buyBoxIndex or 1
end

function MinzMgr:setBuyBoxIndex(_index)
    self.m_buyBoxIndex = _index or 1
end

return MinzMgr
