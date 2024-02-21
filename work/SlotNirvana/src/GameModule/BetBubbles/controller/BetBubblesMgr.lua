--[[
    关卡bet上的气泡合集
    思路：
    1.数据不及时处理，以下是重新计算正在显示的气泡的情况：
        每次打开气泡
        切bet
        主动调用新增或移除气泡，且移除气泡正在显示中
        主动调用显示或隐藏气泡
    2.界面不及时响应：
        气泡正在做打开或关闭动作时，界面不响应数据的变化
]]

util_require("GameModule.BetBubbles.config.BetBubblesCfg")

local BetBubbleModuleInfo = util_require("GameModule.BetBubbles.model.BetBubbleModuleInfo")
local BetBubbleModuleData = util_require("GameModule.BetBubbles.model.BetBubbleModuleData")

local BetBubblesMgr = class("BetBubblesMgr", BaseGameControl)

function BetBubblesMgr:ctor()
    BetBubblesMgr.super.ctor(self)
    self:setRefName(G_REF.BetBubbles)

    self.m_moduleInfos = {} -- 配置数据

    self.m_moduleDatas = {} -- 所有的气泡数据

    self:onRegist()
end

function BetBubblesMgr:onRegist()
    self:parseModuleInfos(BetBubblesCfg.modules)

    -- 零点刷新消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:onRefreshBubbleDatas()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BETBUBBLE_REFRESH)
        end,
        ViewEventType.NOTIFY_ACTIVITY_ZERO_REFRESH
    )
end

function BetBubblesMgr:parseModuleInfos(_modules)
    self.m_moduleInfos = {}
    if _modules and #_modules > 0 then
        for i=1,#_modules do
            local mInfo = BetBubbleModuleInfo:create()
            mInfo:parseData(_modules[i])
            table.insert(self.m_moduleInfos, mInfo)
        end
    end
end

function BetBubblesMgr:__getModuleInfoByRef(_refName)
    if self.m_moduleInfos and #self.m_moduleInfos > 0 then
        for i=1,#self.m_moduleInfos do
            local info = self.m_moduleInfos[i]
            if info and info:isRefInModule(_refName) then
                return info
            end
        end
    end
    return
end

function BetBubblesMgr:__getModuleInfoByModuleName(_moduleName)
    if self.m_moduleInfos and #self.m_moduleInfos > 0 then
        for i=1,#self.m_moduleInfos do
            local info = self.m_moduleInfos[i]
            if info and info:getModuleName() == _moduleName then
                return info
            end
        end
    end
    return
end

function BetBubblesMgr:getZOrderInfo(_ref)
    local moduleName = nil
    local moduleInfo = self:__getModuleInfoByRef(_ref)
    if moduleInfo then
        moduleName = moduleInfo:getModuleName()
    else
        moduleName = _ref
    end
    local zOrder = BetBubblesCfg.Top_ZOrders[moduleName]
    local zOrderType = BetBubblesCfg.ZORDER_TYPE.UP
    if not zOrder then
        zOrder = BetBubblesCfg.Bottom_ZOrders[moduleName]
        zOrderType = BetBubblesCfg.ZORDER_TYPE.DOWN
    end
    if not zOrder then
        zOrder = table.nums(BetBubblesCfg.Bottom_ZOrders) + (table.nums(self.m_moduleDatas) + 1)
    end
    return zOrder, zOrderType
end

function BetBubblesMgr:__addModule(_ref)
    local moduleData = nil
    local refMgr = G_GetMgr(_ref)
    if refMgr then
        if refMgr.isCanShowBetBubble and refMgr.getBetBubbleLuaPath and refMgr:isCanShowBetBubble() then
            local luaPath = refMgr:getBetBubbleLuaPath()
            if luaPath and luaPath ~= "" then
                local moduleInfo = self:__getModuleInfoByRef(_ref)
                if not moduleInfo then
                    moduleInfo = self:__getModuleInfoByModuleName(_ref)
                end
                if moduleInfo then
                    local moduleName = moduleInfo:getModuleName()
                    local isLimitMaxH = moduleInfo:isLimitMaxH()
                    local moduleLua = moduleInfo:getModuleLua()
                    moduleData = self:getModuleDataByName(moduleName)
                    if moduleData then
                        moduleData:addRef(_ref)
                    else
                        local zOrder, zOrderType = self:getZOrderInfo(_ref)
                        moduleData = BetBubbleModuleData:create()
                        moduleData:parseData({moduleName = moduleName, moduleLua = moduleLua, refs = {_ref}, zOrder = zOrder, zOrderType = zOrderType})
                        table.insert(self.m_moduleDatas, moduleData)
                    end
                else
                    local zOrder, zOrderType = self:getZOrderInfo(_ref)
                    moduleData = BetBubbleModuleData:create()
                    moduleData:parseData({moduleName = ref, moduleLua = moduleLua, refs = {_ref}, zOrder = zOrder, zOrderType = zOrderType})
                    table.insert(self.m_moduleDatas, moduleData)
                end
            end
        end
    else
        local moduleInfo = self:__getModuleInfoByRef(_ref)
        if not moduleInfo then
            moduleInfo = self:__getModuleInfoByModuleName(_ref)
        end        
        if moduleInfo then
            local moduleName = moduleInfo:getModuleName()
            local isLimitMaxH = moduleInfo:isLimitMaxH()
            local moduleLua = moduleInfo:getModuleLua()
            moduleData = self:getModuleDataByName(moduleName)
            if moduleData then
                moduleData:addRef(_ref)
            else
                local zOrder, zOrderType = self:getZOrderInfo(_ref)
                moduleData = BetBubbleModuleData:create()
                moduleData:parseData({moduleName = moduleName, moduleLua = moduleLua, refs = {_ref}, zOrder = zOrder, zOrderType = zOrderType})
                table.insert(self.m_moduleDatas, moduleData)
            end
        end        
    end
    return moduleData
end

function BetBubblesMgr:__delModule(_moduleName)
    if self.m_moduleDatas and #self.m_moduleDatas > 0 then
        for i = #self.m_moduleDatas, 1, -1 do
            local mData = self.m_moduleDatas[i]
            if mData:getModuleName() == _moduleName then
                table.remove(self.m_moduleDatas, i)
                break
            end
        end   
    end
end

-- 尽量不给外部删除数据的权利
-- --[[-- 外部接口，活动或者功能移除自己时调用，只有当活动或者功能关闭时调用]]
-- function BetBubblesMgr:removeBetBubble(_refName)
--     local moduleData = self:getModuleDataByRef(_refName)
--     if moduleData then
--         local mName = moduleData:getModuleName()
--         -- 移除引用名数据
--         moduleData:delRef(_refName)
--         -- 移除模块
--         local isRemoveModule = false
--         local refDatas = moduleData:getRefDatas()
--         if not (refDatas and #refDatas > 0) then
--             isRemoveModule = true
--             self:__delModule()
--         end
--         -- 正在显示中的模块，通知界面
--         if moduleData:isShowing() then
--             if isRemoveModule then
--                 gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BETBUBBLE_REMOVE, {ref = _refName})
--             else
--                 gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BETBUBBLE_REMOVE, {moduleName = mName})
--             end
--         end
--     end
-- end

--[[-- 
    外部接口：刷新气泡数据和所有气泡长度，并不会主动打开或者关闭气泡
    活动或者功能移除自己时调用
    显示和隐藏当活动或功能有开关且操作开关时调用
]]
function BetBubblesMgr:refreshBetBubble(_refName, _isShow)
    local moduleData = self:getModuleDataByRef(_refName)
    if not moduleData then
        moduleData = self:__addModule(_refName)
    end
    if moduleData then
        local mName = moduleData:getModuleName()
        local refData = moduleData:getRefDataByRef(_refName)
        if refData then
            local status = _isShow and BetBubblesCfg.REF_SWITCH.ON or BetBubblesCfg.REF_SWITCH.OFF
            refData:setSwitchStatus(status)
        end
        -- 排序
        self:sortBubbles()
        -- 设置显隐属性
        self:setModuleVisible()
        -- 通知界面
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BETBUBBLE_REFRESH, {moduleName = mName})
    end
end

function BetBubblesMgr:getModuleDataByName(_moduleName)
    if self.m_moduleDatas and #self.m_moduleDatas > 0 then
        for i=1,#self.m_moduleDatas do
            local mData = self.m_moduleDatas[i]
            if mData:getModuleName() == _moduleName then
                return mData
            end
        end
    end
    return
end

function BetBubblesMgr:getModuleDataByRef(_ref)
    if self.m_moduleDatas and #self.m_moduleDatas > 0 then
        for i=1,#self.m_moduleDatas do
            local mData = self.m_moduleDatas[i]
            if mData:getRefDataByRef(_ref) then
                return mData
            end
        end
    end
    return
end

--[[-- 外部接口 获取当前正在显示的气泡数据]]
function BetBubblesMgr:getShowModuleDatas()
    local temps = {}
    if self.m_moduleDatas and #self.m_moduleDatas > 0 then
        for i=1,#self.m_moduleDatas do
            local mData = self.m_moduleDatas[i]
            if mData:isShowing() then
                table.insert(temps, mData)
            end
        end
    end
    return temps
end

function BetBubblesMgr:onRefreshBubbleDatas()
    self.m_moduleDatas = {}
    -- 系统功能
    for k,refName in pairs(G_REF) do
        self:__addModule(refName)
    end
    -- 活动
    for _,refName in pairs(ACTIVITY_REF) do
        self:__addModule(refName)
    end
    -- 排序
    self:sortBubbles()
    -- 设置显隐属性
    self:setModuleVisible()
end

function BetBubblesMgr:setModuleVisible()
    local showNum = 0
    local showMax = BetBubblesCfg.LIMIT_MAX_H
    if globalData.slotRunData.isPortrait == true then
        showMax = BetBubblesCfg.LIMIT_MAX_V
    end
    if self.m_moduleDatas and #self.m_moduleDatas > 0 then
        for i = 1, #self.m_moduleDatas do
            local mData = self.m_moduleDatas[i]
            if mData:isTop() then
                if mData:hasSwitchOnRef() then
                    if showNum <= showMax then
                        showNum = showNum + 1
                        mData:setShowing(true)
                    else
                        mData:setShowing(false)
                    end
                else
                    mData:setShowing(false)
                end
            end
        end
        -- 反向遍历从下往上排序的
        for i = #self.m_moduleDatas, 1, -1 do
            local mData = self.m_moduleDatas[i]
            if mData:isBottom() then
                if mData:hasSwitchOnRef() then
                    if showNum <= showMax then
                        showNum = showNum + 1
                        mData:setShowing(true)
                    else
                        mData:setShowing(false)
                    end
                else
                    mData:setShowing(false)
                end
            end
        end
    end
end

function BetBubblesMgr:sortBubbles()
    table.sort(self.m_moduleDatas, function(a, b)
        local aType = a:isTop() and 1 or 2
        local bType = b:isTop() and 1 or 2
        if aType == bType then
            return a:getZOrder() < b:getZOrder()
        else
            return  aType < bType
        end
    end)
end

-- -- 主界面小弹框
-- -- 不遮挡点击
-- function BetBubblesMgr:showBetBubblePopView(...)
--     if not (self.m_moduleDatas and #self.m_moduleDatas > 0) then
--         return
--     end

--     local luaFileName = "GameModule.BetBubbles.view.BetBubblesMain"
    
--     return util_createView(luaFileName, bubbleDatas, ...)
-- end

return BetBubblesMgr