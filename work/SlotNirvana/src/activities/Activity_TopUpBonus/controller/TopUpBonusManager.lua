-- 气球挑战管理器

local TopUpBonusNet = require("activities.Activity_TopUpBonus.net.TopUpBonusNet")
local TopUpBonusManager = class("TopUpBonusManager", BaseActivityControl)

-- 存一些本地数据
function TopUpBonusManager:ctor()
    TopUpBonusManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TopUpBonus)
    self.m_topUpBonusNet = TopUpBonusNet:getInstance()
    self.bl_itemEnable = true
    self.m_configInit = false
    self.TopUpBonusConfig = util_require("activities.Activity_TopUpBonus.config.TopUpBonusConfig")
end

function TopUpBonusManager:getConfig()
    local data = self:getRunningData()
    if not data then
        return
    end
    local cur_theme = data:getThemeName()
    local config_theme = self.TopUpBonusConfig.getThemeName()
    if not cur_theme or cur_theme ~= config_theme or not self.m_configInit then
        self.m_configInit = true
        self.TopUpBonusConfig.setThemeName(cur_theme)
    end
    return self.TopUpBonusConfig
end

------------------------------ 活动中用到的一些标记位 ------------------------------
function TopUpBonusManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_TopUpBonus") == nil then
        local data = self:getRunningData()
        local themeName = data:getThemeName()
        local luaPath = self:getConfig().getThemeFile(themeName)
        local mainUI = util_createFindView(luaPath)
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function TopUpBonusManager:requestCollect(price,index)
    self.m_topUpBonusNet:requestCollect(price,index)
end

function TopUpBonusManager:hasRewards()
    local act_data = self:getRunningData()
    if act_data then
        return act_data:hasRewards()
    end
    return false
end

function TopUpBonusManager:recordRewardsList(data)
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    act_data:recordRewardsList(data)
end

function TopUpBonusManager:addRewardPops(pop_list)
    if not pop_list or table.nums(pop_list) <= 0 then
        return
    end

    if self.pop_list then
        printError("TopUpBonusManager 存在掉落列表残留")
        self.pop_list = nil
    end
    self.pop_list = pop_list
end

function TopUpBonusManager:popNext()
    if not self.pop_list then
        return
    end
    if table.nums(self.pop_list) <= 0 then
        self.pop_list = nil
        return
    end

    local popFunc = self.pop_list[1]
    table.remove(self.pop_list, 1)
    if popFunc and type(popFunc) == "function" then
        local bl_succ = popFunc()
        if not bl_succ then
            self:popNext()
        end
    end
end

-- 是否可显示展示页
function TopUpBonusManager:isCanShowHall()
    local isCanShow = TopUpBonusManager.super.isCanShowHall(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
    end
    return isCanShow
end

-- 是否可显示轮播页
function TopUpBonusManager:isCanShowSlide()
    local isCanShow = TopUpBonusManager.super.isCanShowSlide(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
    end
    return isCanShow
end

-- 是否可显示在hotnews里
function TopUpBonusManager:isCanShowInEntrance()
    local isCanShow = TopUpBonusManager.super.isCanShowInEntrance(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.display then
            isCanShow = false
        end
    end
    return isCanShow
end

function TopUpBonusManager:setItemTouchEnabled(bl_enable)
    self.bl_itemEnable = bl_enable
end

function TopUpBonusManager:getItemTouchEnabled()
    return self.bl_itemEnable
end


function TopUpBonusManager:showWheelLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_TopUpBonusWheel") == nil then
        local data = self:getRunningData()
        local themeName = data:getThemeName()
        local luaPath = "Activity/" ..themeName .. "WheelLayer"
        local mainUI = util_createFindView(luaPath)
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end


function TopUpBonusManager:requestPlayWheel(type)
    self.m_topUpBonusNet:requestPlayWheel(type)
end

function TopUpBonusManager:showTipLayer(noCallfun, okCallfun)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("Activity_TopUpBonusTip") == nil then
        local data = self:getRunningData()
        local themeName = data:getThemeName()
        local luaPath = "Activity/" ..themeName .. "TipLayer"
        local mainUI = util_createFindView(luaPath,noCallfun,okCallfun)
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function TopUpBonusManager:setDoingWheelAct(isDoing)
    self.m_isDoingWheelAct  = isDoing
end

function TopUpBonusManager:isDoingWheelAct()
    return not not self.m_isDoingWheelAct
end


function TopUpBonusManager:requestGetPool(isFirstEnter)
    local activitydata = self:getRunningData()
    if not activitydata then
        return 
    end
    if self.m_requestGetPool then
        return
    end
    if not self.m_isFirstEnter then
        self.m_isFirstEnter = true
    elseif isFirstEnter and self.m_isFirstEnter then
        return
    end
    self.m_requestGetPool = true
    self.m_topUpBonusNet:requestRefreshActivityData()
end

function TopUpBonusManager:clearRequestGetPool()
    self.m_requestGetPool = false
end

function TopUpBonusManager:updateTopUpBonusGoldIncrease(forceInit,data)
    local activityData = self:getRunningData()
    local timeOut = false
    if activityData then
        if activityData:updateTopUpBonusGoldIncrease(forceInit,data) then
            timeOut = true
        end
    end
    if timeOut then
        self:requestGetPool()
    end
end

-- 第二个返回值 是否是展示名字
function TopUpBonusManager:getRunGoldCoin()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getRunGoldCoin()
    end
    return 1111111
end


function TopUpBonusManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function TopUpBonusManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end


function TopUpBonusManager:isWillRefreshWheel()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:isWillRefreshWheel()
    end
    return false
end

function TopUpBonusManager:clearWillRefreshWheel()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:clearWillRefreshWheel()
    end
end

return TopUpBonusManager
