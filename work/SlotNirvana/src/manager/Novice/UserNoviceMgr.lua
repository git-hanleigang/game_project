--[[
    用户新手期
    author:{author}
    time:2023-02-01 18:24:19
]]
local NoviceActivityItemConfig = nil
local NovicePopupItemConfig = nil
local NovicePopupControlData = nil
local UserNoviceMgr = class("UserNoviceMgr", BaseGameControl)

function UserNoviceMgr:ctor()
    UserNoviceMgr.super.ctor(self)
    self:setRefName(G_REF.UserNovice)

    -- 新手期功能信息列表
    self.m_activityItemConfigs = {}
    self.m_activityRefConfigs = {}

    -- 新手期资源列表
    self.m_dlZips = {}
    self.m_dlZips["1"] = {}

    -- 弹板信息配置数据
    -- self.m_popupConfigs = {}
    -- 新手期弹板控制配置数据
    self.m_popupControlDatas = {}
end

function UserNoviceMgr:parseData(datas)
    if datas.newUserConfigPopup ~= nil and #(datas.newUserConfigPopup) > 0 then
        self:parsePopUpCtrlDatas(datas.newUserConfigPopup)
    end

    if datas.newUserActivityOpen ~= nil and #(datas.newUserActivityOpen) > 0 then
        self:parseActivityOpenData(datas.newUserActivityOpen)
    end
end

-- 解析功能开启配置
function UserNoviceMgr:parseActivityOpenData(datas)
    for i = 1, #datas do
        local data = datas[i]

        -- 功能配置
        self:parseActivityItemConfig(data)
    end
end

-- 功能配置
function UserNoviceMgr:parseActivityItemConfig(data)
    if not data then
        return
    end

    if not NoviceActivityItemConfig then
        NoviceActivityItemConfig = require("manager.Novice.NoviceActivityItemInfo")
    end

    local bigType = ACTIVITY_TYPE[data.bigType]
    local itemCfg = NoviceActivityItemConfig:create()
    itemCfg:parseData(data, bigType)

    if not self.m_activityItemConfigs["" .. bigType] then
        self.m_activityItemConfigs["" .. bigType] = {}
    end

    self.m_activityItemConfigs["" .. bigType]["" .. itemCfg:getActivityID()] = itemCfg

    -- 添加功能主题
    self:parseThemeZip(itemCfg:getThemeName(), itemCfg:getRefName())
end

function UserNoviceMgr:getActivitiesByType(nType)
    return self.m_activityItemConfigs["" .. nType] or {}
end

-- 新用户活动配置
function UserNoviceMgr:getActivityConfigById(activityId, nType)
    local callFunc = function(tbInfo)
        return tbInfo["" .. activityId]
    end

    local _info = nil
    if nType then
        local infoList = self:getActivitiesByType(nType)
        if infoList then
            _info = callFunc(infoList)
        end
    else
        for k, v in pairs(self.m_activityItemConfigs) do
            _info = callFunc(v)
            if _info then
                break
            end
        end
    end
    return _info
end

--根据Ref引用名获得活动配置
function UserNoviceMgr:getActivityConfigByRef(refName, nType)
    local callFunc = function(tbInfo)
        for k, v in pairs(tbInfo) do
            if v and v:getRefName() == refName then
                return v
            end
        end
    end

    local _info = nil
    if nType then
        local infoList = self:getActivitiesByType(nType)
        if infoList then
            _info = callFunc(infoList)
        end
    else
        for k, v in pairs(self.m_activityItemConfigs) do
            _info = callFunc(v)
            if _info then
                break
            end
        end
    end
    return _info
end

-- 获得功能点AB分组
function UserNoviceMgr:getABValue(activityId, posKey)
    local _config = self:getActivityConfigById(activityId)
    if _config then
        return _config:getABValue(posKey)
    else
        return ""
    end
end

-- 主题资源
function UserNoviceMgr:parseThemeZip(_themeName, _refName)
    if not _themeName or not _refName then
        return
    end

    local ret = {}
    ret[#ret + 1] = _themeName
    globalData.GameConfig:checkAddRelativeDownload(ret, _themeName, _refName)

    for i = 1, #ret do
        -- 从dynamic中找到下载信息
        local _theme = ret[i]
        local dyInfo = globalData.GameConfig.dynamicData["" .. _theme]
        if dyInfo then
            local dlInfo = {
                key = dyInfo.zipName,
                md5 = dyInfo.md5,
                type = dyInfo.type,
                zOrder = "1",
                size = (dyInfo.size or 123)
            }

            table.insert(self.m_dlZips["1"], dlInfo)
        end
    end
end

-- 新手期功能弹窗信息
function UserNoviceMgr:parseNovicePopUpItemConfigs(data)
    if not data then
        return
    end

    -- if not NovicePopupItemConfig then
    --     NovicePopupItemConfig = require("manager.Novice.NovicePopupItemConfig")
    -- end

    -- local item = NovicePopupItemConfig:create()
    -- item:parseData(data)
    local popUpId = data.popupId
    local item = PopUpManager:getPopUpInfoById(popUpId)
    if item then
        -- local _cpItem = clone(item)
        local _cpItem = item
        _cpItem.leftLevel = 1
        _cpItem.rightLevel = -1
        _cpItem:setNovice(true)
    -- self:addPopUpItem(self.m_popupConfigs, _cpItem)
    end
end

-- function UserNoviceMgr:addPopUpItem(tbPopUps, item)
--     if not item then
--         return
--     end
--     -- 判断点位类型
--     local pos = item:getPosType()
--     local popUpId = item:getPopUpId()
--     if not tbPopUps["" .. pos] then
--         tbPopUps["" .. pos] = {}
--     end
--     -- 判断id是否已经存在
--     local popUpInfo = tbPopUps["" .. pos]["" .. popUpId]
--     if not popUpInfo then
--         tbPopUps["" .. pos]["" .. popUpId] = item
--     end
-- end

-- ========================================
-- 解析弹窗配置
function UserNoviceMgr:parsePopUpCtrlDatas(datas)
    for i = 1, #datas do
        local data = datas[i]
        self:parseNovicePopUpCtrlData(data)

        -- 功能弹窗
        self:parseNovicePopUpItemConfigs(data)
    end
end

-- 新手期弹窗控制数据
function UserNoviceMgr:parseNovicePopUpCtrlData(data)
    if not data then
        return
    end
    if not NovicePopupControlData then
        NovicePopupControlData = require("manager.Novice.NovicePopupControlData")
    end

    local item = NovicePopupControlData:create()
    item:parseData(data)
    self.m_popupControlDatas[item:getRefName()] = item
end

--[[
    @desc: 根据程序引用名获取弹窗控制逻辑
    author:徐袁
    time:2020-12-19 16:11:26
    @return:
]]
-- function UserNoviceMgr:getPopupControlData(popupItem)
--     if not popupItem then
--         return nil
--     end
--     local refName = popupItem:getRefName()

--     return self:getPopupControlDataByRef(refName)
-- end

function UserNoviceMgr:getPopupControlDataByRef(refName)
    if not refName then
        return nil
    end

    local controlData = self.m_popupControlDatas["" .. refName]

    if controlData and controlData:isOpen() then
        return controlData
    end

    return nil
end

function UserNoviceMgr:getDlZips(resType)
    -- return self.m_dlZips["" .. resType] or {}
    local dlZips = {}
    local _dlZips = self.m_dlZips["" .. resType] or {}
    for i = 1, #_dlZips do
        local _info = _dlZips[i]
        if _info then
            local state = globalDynamicDLControl:isDownLoad(_info.key, _info.md5)
            if state ~= 2 then
                table.insert(dlZips, _info)
            end
        end
    end

    return dlZips
end

-- 是否在活动总入口中
function UserNoviceMgr:isEntryOpen(refName)
    local _info = self:getPopupControlDataByRef(refName)
    if _info then
        return (_info:isEntryOpen() > 0)
    end
    return false
end

return UserNoviceMgr
