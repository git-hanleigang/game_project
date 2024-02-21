--[[

    author:{author}
    time:2020-10-28 11:57:40
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local EntranceData = class("EntranceData", BaseActivityData)
local ActivityEntranceConfig = require("data.baseDatas.ActivityEntranceConfig")

function EntranceData:ctor()
    EntranceData.super.ctor(self)
    self.p_open = true

    self:resetRedPointData()
    self:loadRedPointData()
    self:initRedPointData()
end

function EntranceData:getCellDatas()
    local cellDatas = {}
    local cellCfg = globalData.GameConfig:getActivityNoticeConfig()
    for i = 1, #cellCfg do
        local cellInfo = cellCfg[i]
        if cellInfo and cellInfo:isOpen() then
            local _refName = cellInfo:getRefName()
            -- 判断是否是新手期功能入口
            local isOpen = true
            local isNovice = cellInfo:isNovice()
            if isNovice then
                isOpen = G_GetMgr(G_REF.UserNovice):isEntryOpen(_refName)
            end

            if isOpen then
                local _refMgr = G_GetMgr(_refName)
                if _refMgr then
                    if _refMgr:isCanShowInEntrance() and isNovice == _refMgr:isNovice() then
                        table.insert(cellDatas, cellInfo)
                    end
                else
                    local _activityData = G_GetActivityDataByRef(_refName)
                    if _activityData and _activityData:isRunning() and isNovice == _activityData:isNovice() and self:checkLuaModule(_activityData:getPopModule()) then
                        table.insert(cellDatas, cellInfo)
                    end
                end
            end
        end
    end

    local birthdayMgr = G_GetMgr(ACTIVITY_REF.Birthday)
    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if birthdayMgr and not isNovice then
        local data = birthdayMgr:getRunningData()
        if data and not data:isEditBirthdayInfo() then
            local entranceData = {
                id = 0,
                description = "编辑生日信息",
                programName = "Activity_Birthday_Publicity",
                descriptionName = "Birthday Edit",
                open = 1,
                type = 1,
                weekDay = "1;2;3;4;5;6;7",
                startDate = "",
                endDate = "",
            }
            local cellInfo = ActivityEntranceConfig:create()
            cellInfo:parseData(entranceData)
            if cellInfo and cellInfo:isOpen() then
                table.insert(cellDatas, cellInfo)
            end
        end
    end

    self.m_cellDatas = cellDatas
    return cellDatas
end

-- 检查主题模块
function EntranceData:checkLuaModule(modulePath)
    if not modulePath then
        return false
    end

    local _fileName, count = string.gsub(modulePath, "%.", "/")

    if not util_IsFileExist(_fileName .. ".lua") and not util_IsFileExist(_fileName .. ".luac") then
        return false
    end

    return true
end

function EntranceData:getCellData(index)
    if index > #self.m_cellDatas then
        return nil
    end

    return self.m_cellDatas[index]
end

-- 获取小红点记录
function EntranceData:loadRedPointData()
    local strData = gLobalDataManager:getStringByField("EntranceRedPoint", "{}")
    local tbData = cjson.decode(strData)

    self.m_lastUpdateTime = tbData.lastUpdateTime or 0
    self.m_redPointData = tbData.redPoint or {}
end

-- 存本地
function EntranceData:saveLocalData()
    local tbData = {
        lastUpdateTime = self.m_lastUpdateTime,
        redPoint = self.m_redPointData
    }
    local strData = cjson.encode(tbData)
    gLobalDataManager:setStringByField("EntranceRedPoint", strData)
end

-- 初始化数据
function EntranceData:initRedPointData()
    -- 是否跨天
    local oldSecs = self.m_lastUpdateTime
    local newSecs = util_getCurrnetTime()
    -- 服务器时间戳转本地时间
    local oldTM = util_UTC2TZ(oldSecs, -8)
    local newTM = util_UTC2TZ(newSecs, -8)

    if oldTM.day ~= newTM.day then
        self:resetRedPointData()
    end
end

function EntranceData:resetRedPointData()
    self.m_lastUpdateTime = 0
    self.m_redPointData = {}
end

-- 是否显示小红点
function EntranceData:isShowRedPoint(index)
    if not index then
        return false
    end

    local _info = self:getCellData(index)
    if not _info then
        return false
    end

    local refName = _info:getRefName()
    local _info = self:getRPInfo(refName)
    if _info then
        return false
    end

    return true
end

function EntranceData:getRPInfo(refName)
    return self.m_redPointData[refName]
end

-- 设置小红点记录
function EntranceData:setRedPointData(index)
    if not index then
        return false
    end

    local _info = self:getCellData(index)
    if not _info then
        return false
    end

    local refName = _info:getRefName()

    self.m_redPointData["" .. refName] = refName
    self.m_lastUpdateTime = math.floor(util_getCurrnetTime())

    self:saveLocalData()
end

-- 获得小红点数量
function EntranceData:getShowRedPointCount()
    local count = 0
    local _cellDatas = self:getCellDatas() or {}
    for i = 1, #_cellDatas do
        local _info = _cellDatas[i]
        local _refName = _info:getRefName()
        if not self:getRPInfo(_refName) and _refName ~= ACTIVITY_REF.Notification then
            count = count + 1
        end
    end
    return count
end

-- 是否可显示弹板
function EntranceData:isCanShowPopView()
    if not EntranceData.super.isCanShowPopView(self) then
        return false
    end

    -- 判断数据
    local temp = globalData.GameConfig:getHotTodayConfigs()
    if not temp then
        return
    end

    return true
end

-- 获得指定活动的页签数
function EntranceData:getCellIdxByRefName(_refName)
    local idx = 0
    local cellDatas = self:getCellDatas() or {}
    for i = 1, #cellDatas do
        local info = cellDatas[i]
        local refName = info:getRefName()
        if _refName == refName then
            idx = i
        end
    end
    return idx
end

return EntranceData
