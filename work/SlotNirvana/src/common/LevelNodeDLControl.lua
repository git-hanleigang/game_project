-- Created by jfwang on 2019-05-05.
-- 动态下载控制器
--

local BaseDLControl = require("common.BaseDLControl")
local LevelNodeDLControl = class("LevelNodeDLControl", BaseDLControl)
LevelNodeDLControl.instance = nil
function LevelNodeDLControl:getInstance()
    if not LevelNodeDLControl.instance then
        LevelNodeDLControl.instance = LevelNodeDLControl:create()
        LevelNodeDLControl.instance:initData()
    end

    return LevelNodeDLControl.instance
end

function LevelNodeDLControl:purge()
    self:clearData()
end

--开始后台下载重写
function LevelNodeDLControl:startDownload(vType, levelNodeList)
    if not CC_DYNAMIC_DOWNLOAD then
        return
    end
    if not levelNodeList or #levelNodeList == 0 then
        return
    end
    table.sort(
        levelNodeList,
        function(a, b)
            return tonumber(a.zOrder) < tonumber(b.zOrder)
        end
    )
    for i = 1, #levelNodeList do
        if levelNodeList[i] then
            self.m_downloadQueue:push(levelNodeList[i])
        end
    end
    BaseDLControl.startDownload(self, vType)
end

--是否处于下载中或者准备下载
function LevelNodeDLControl:checkDownloading(key)
end

-- 获得下载进度(阶段百分比，阶段大小，总大小，已完成大小)
function LevelNodeDLControl:getDLProgress(_percent, _stageSize, _totalSize, _accomplishSize)
    _stageSize = _stageSize or 0
    _totalSize = _totalSize or 0

    local _progress = 0

    if _stageSize > 0 and _totalSize > 0 then
        _progress = math.floor(_stageSize * _percent)
        _progress = _progress + (_accomplishSize or 0)
        return self:getDlTxt(_progress) .. "/" .. self:getDlTxt(_totalSize)
    else
        return ""
    end
end

function LevelNodeDLControl:unZipCompleted(dlInfo)
    LevelNodeDLControl.super.unZipCompleted(self, dlInfo)
    if not dlInfo then
        return
    end

    local _levelName = string.gsub(dlInfo.key, "Level_", "GameScreen")
    -- 更新入口信息
    globalData.slotRunData:updateLobbyEntryInfo(_levelName)
end

return LevelNodeDLControl
