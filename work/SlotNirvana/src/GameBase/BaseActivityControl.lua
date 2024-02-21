--[[
    游戏活动基本控制类
    author: 徐袁
    time: 2021-07-01 18:19:09
]]
local Facade = require("GameMVC.core.Facade")
local _BaseActivityControl = class("BaseActivityControl", BaseGameControl)

function _BaseActivityControl:ctor()
    _BaseActivityControl.super.ctor(self)
    -- 前置活动引用名列表
    self.m_preModuleRef = {}
end

-- 添加前置功能引用名
function _BaseActivityControl:addPreRef(refName)
    if not refName or refName == "" then
        return
    end
    table.insert(self.m_preModuleRef, refName)
end
-- 获得数据
function _BaseActivityControl:getData(refName)
    refName = refName or self:getRefName()
    -- return Facade:getInstance():getModel(refName)
    return globalData.commonActivityData:getActivityDataByRef(refName, true)
end

function _BaseActivityControl:checkPreRefName(refName)
    if not refName or refName == self:getRefName() then
        for i = 1, #self.m_preModuleRef do
            local _preRefName = self.m_preModuleRef[i]
            local _preMgr = self:getMgr(_preRefName)
            if not _preMgr or not _preMgr:isRunning() then
                return false
            end
        end
    end
    return true
end

function _BaseActivityControl:getRunningData(refName)
    if not self:checkPreRefName(refName) then
        return nil
    end

    return _BaseActivityControl.super.getRunningData(self, refName)
end

-- 是否可显示展示页
function _BaseActivityControl:isCanShowHall()
    if not self:isDownloadLobbyRes() then
        return false
    end

    local data = self:getRunningData()
    if not data then
        return false
    end

    if (data.isSleeping and data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    local _hallImages = data.p_hallImages or {}
    if #_hallImages == 0 or _hallImages[1] == "" then
        return false
    end

    return true
end

function _BaseActivityControl:getHallPath(hallName)
    return "Icons/" .. hallName .. "HallNode"
end

-- 大厅展示入口
function _BaseActivityControl:getHallModule()
    if not self:isDownloadLobbyRes() then
        return ""
    end

    local _module = "views.lobby.HallNode"
    local _hallName = self:getHallName()
    if _hallName ~= "" then
        local _filePath = self:getHallPath(_hallName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            _module, _ = string.gsub(_filePath, "/", ".")
        end
    end

    return _module
end

-- 是否可显示轮播页
function _BaseActivityControl:isCanShowSlide()
    if not self:isDownloadLobbyRes() then
        return false
    end

    local data = self:getRunningData()
    if not data then
        return false
    end

    if (data.isSleeping and data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    if not data.p_slideImage or data.p_slideImage == "" then
        return false
    end

    return true
end

function _BaseActivityControl:getSlidePath(slideName)
    return "Icons/" .. slideName .. "SlideNode"
end

-- 轮播入口
function _BaseActivityControl:getSlideModule()
    if not self:isDownloadLobbyRes() then
        return ""
    end

    local _module = "views.lobby.SlideNode"
    local _slideName = self:getSlideName()
    if _slideName ~= "" then
        local _filePath = self:getSlidePath(_slideName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            _module, _ = string.gsub(_filePath, "/", ".")
        end
    end

    return _module
end

function _BaseActivityControl:getBottomPath(lobbyName)
    return "Activity." .. lobbyName
end

-- 大厅底部入口
function _BaseActivityControl:getLobbyBottomModule()
    local _lobbyName = self:getLobbyBottomName()
    if _lobbyName ~= "" then
        local _filePath = "views/Activity_LobbyIcon/" .. _lobbyName
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        else
            return self:getBottomPath(_lobbyName)
        end
    else
        return ""
    end
end

function _BaseActivityControl:getEntryPath(entryName)
   return "Activity/" .. entryName .. "EntryNode" 
end

-- 关卡内入口
function _BaseActivityControl:getEntryModule()
    if not self:isDownloadRes() then
        return ""
    end

    local _entryName = self:getEntryName()
    if _entryName ~= "" then
        local _filePath = self:getEntryPath(_entryName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

--添加该活动 关联下载文件 (宣传，代码)
function _BaseActivityControl:addDefExtendResList(_themeName)
    if not _themeName then
        return
    end

    local list = {
        _themeName .. "_loading",
        _themeName .. "_Loading",
        _themeName .. "Loading",
        _themeName .. "Code",
        _themeName .. "_Code"
    }
    self:addExtendResList(list)
end

return _BaseActivityControl
