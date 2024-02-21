--[[
    大厅入口数据
    author: 徐袁
    time: 2021-07-23 17:01:25
]]
local LevelRecmdInfo = import(".LevelRecmdInfo")

local LevelRecmdData = class("LevelRecmdData", BaseSingleton)

-- 忽略列表(特殊关卡不显示在分类列表)
local LEVEL_IGNORE_LIST = {
    ["MasterStamp"] = true,
    ["FarmMoolahRaid"] = true,
    ["RocketPup"] = true,
}

function LevelRecmdData:ctor()
    LevelRecmdData.super.ctor(self)
    -- 关卡推荐分组数据
    self.m_levelRecmdData = {}
    -- 可展示的分组数据
    self.m_showingRecmdGrops = {}
    -- 关卡推荐分组名索引
    self.m_levelRecmdGroupIndex = {}

    -- 最后一次Spin的关卡名
    self.m_lastSpinLevelName = ""

    -- 解锁的关卡表
    self.m_unlockLevels = {}

    -- 更新最近Spin过的关卡
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateLastSpinLevel()
        end,
        ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL
    )
end

-- 解析关卡推荐分组数据
function LevelRecmdData:parseLevelRecmdData(data)
    if not data or #data <= 0 then
        return
    end

    local levelIgnoreList = LEVEL_IGNORE_LIST or {}
    self.m_levelRecmdData = {}
    self.m_levelRecmdGroupIndex = {}
    for i = 1, #data do
        local _info = data[i]
        local _lvInfo = LevelRecmdInfo:create()
        _lvInfo:parseData(_info, levelIgnoreList)
        if _lvInfo:isExpire() then
            table.insert(self.m_levelRecmdData, _lvInfo)
        end
    end

    -- 排序
    table.sort(
        self.m_levelRecmdData,
        function(a, b)
            return a:getOrder() < b:getOrder()
        end
    )

    for k = 1, #self.m_levelRecmdData do
        local _info = self.m_levelRecmdData[k]
        if _info then
            self.m_levelRecmdGroupIndex[_info:getRecmdName()] = k
        end
    end

    -- 第一个可显示的默认展开
    local isFirstShow = false
    self.m_showingRecmdGrops = {}
    for j = 1, #self.m_levelRecmdData do
        local _info = self.m_levelRecmdData[j]
        if _info then
            if self:isCanShow(_info) and self:isCanUnfold(_info:getGroup()) then
                if (not isFirstShow) then
                    _info:setShowState(true)
                    isFirstShow = true
                end

                table.insert(self.m_showingRecmdGrops, _info:getRecmdName())
            end
        end
    end
end

-- 是否能够展开
function LevelRecmdData:isCanUnfold(_group)
    if _group == RecmdGroup.NewGame or _group == RecmdGroup.Jackpot or _group == RecmdGroup.Link or  
    _group == RecmdGroup.Retro or _group == RecmdGroup.Collect or _group == RecmdGroup.Magic then
        return false
    end
    return true
end

function LevelRecmdData:isCanShow(_info)
    if not _info then
        return false
    end
    if not _info:isCanShow() then
        return false
    end
    -- 绑定了活动，但是活动没有激活
    local bindRef = _info:getBindRef()
    if bindRef and bindRef ~= "" then
        local bindMgr = G_GetMgr(bindRef)
        if not bindMgr then
            sendBuglyLuaException("bindRef:[" .. tostring(bindRef) .. "] is invalid!!!")
            return false
        elseif (not bindMgr:isRunning()) then
            return false
        end
    end    
    return true
end

-- 刷新解锁的关卡数据
function LevelRecmdData:freshUnlockLevels()
    self.m_unlockLevels = {}
    self.m_showingRecmdGrops = {}

    for j = 1, #self.m_levelRecmdData do
        local _info = self.m_levelRecmdData[j]
        if _info and self:isCanShow(_info) then
            if _info:isUnlockGroup() then
                self:addUnlockLvs(_info:getLevelNames())
            end

            table.insert(self.m_showingRecmdGrops, _info:getRecmdName())
        end
    end
end

function LevelRecmdData:getShowingRecmdGrops()
    return self.m_showingRecmdGrops
end

function LevelRecmdData:getLevelRecmdData()
    return self.m_levelRecmdData
end

-- 获取推荐
function LevelRecmdData:getRecmdInfoByGroup(group)
    group = group or ""
    local index = self.m_levelRecmdGroupIndex[group]
    if not index then
        return nil, nil
    end

    local _data = self.m_levelRecmdData[index] or {}
    return index, _data
end

-- 设置展示状态
function LevelRecmdData:setRecmdShowState(group, isShow)
    local _, _data = self:getRecmdInfoByGroup(group)
    if _data then
        _data:setShowState(isShow)
    end
end

-- 更新最后一次Spin关卡记录
function LevelRecmdData:updateLastSpinLevel()
    local info = globalData.slotRunData:getLastEnterLevelInfo()
    if not info then
        return
    end

    local _levelName = info.p_name or ""
    if _levelName == "" or _levelName == self.m_lastSpinLevelName then
        return
    end

    local levelIgnoreList = LEVEL_IGNORE_LIST or {}
    if levelIgnoreList[_levelName] then
        return
    end

    local index = string.find(_levelName, "_H")
    local lvName = ""
    if index then
        lvName = string.sub(_levelName, 1, index - 1)
    else
        lvName = _levelName
    end
    self:addLatelyPlayLevel(lvName)
end

-- 添加最近Spin过的关卡名
function LevelRecmdData:addLatelyPlayLevel(levelName)
    if not levelName or levelName == "" then
        return
    end

    local index, _data = self:getRecmdInfoByGroup(RecmdGroup.Lately)

    if not _data then
        return
    end

    local _levelNames = _data:getLevelNames()
    local isHasLv = false
    if _levelNames[1] and _levelNames[1] == levelName then
        return
    end

    for i = 1, #_levelNames do
        if _levelNames[i] == levelName then
            isHasLv = true
            table.remove(_levelNames, i)
            break
        end
    end
    table.insert(_levelNames, 1, levelName)
    if not isHasLv then
        local count = #_levelNames
        if count > 6 then
            table.remove(_levelNames, count)
        end
    end
end

function LevelRecmdData:addUnlockLvs(levelNames)
    levelNames = levelNames or {}
    for i = 1, #levelNames do
        local _lvName = levelNames[i]
        if not self.m_unlockLevels[_lvName] then
            self.m_unlockLevels[_lvName] = true
        end
    end
end

function LevelRecmdData:isLevelUnlock(levelName)
    if self.m_unlockLevels[levelName] then
        return true
    else
        return false
    end
end

--[[
    @desc: 获得关卡入口下载顺序
    author:{author}
    time:2022-02-02 13:51:02
    @return:
]]
function LevelRecmdData:getLevelsDLOrderList()
    local _orderList = {}
    local _orderIdx = 1
    local _tbLevel = {}
    local showGrops = self:getShowingRecmdGrops()
    for i = 1, #showGrops do
        local _group = showGrops[i]
        local _, _info = self:getRecmdInfoByGroup(_group)
        if _info then
            local _levelNames = _info:getLevelNames()
            for j = 1, #_levelNames do
                local _lvName = _levelNames[j]
                local _lvInfo = globalData.slotRunData:getLevelInfoByName(_lvName)
                if _lvInfo and _lvInfo.p_levelName then
                    -- 关卡模块名
                    local _modulName = _lvInfo.p_levelName or ""
                    local _orderId = _tbLevel[_modulName]
                    if not _orderId and _modulName ~= "" then
                        _tbLevel[_modulName] = _orderIdx
                        _orderIdx = _orderIdx + 1
                    end
                end
            end
        end
    end

    for k, v in pairs(_tbLevel) do
        _orderList[v] = k
    end

    return _orderList
end

return LevelRecmdData
