--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-30 16:00:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-01 10:27:54
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/model/PopupSiteArchiveData.lua
Description: 运营引导 次数 cd 相关 归档数据
--]]
local PopupSiteArchiveData = class("PopupSiteArchiveData")

local ArchiveFile = "PopupSiteArchiveData.json"

function PopupSiteArchiveData:ctor()

    local data = self:getArchiveData()

    -- 点位： 次数 cd
    self._siteCountInfo = data.siteCountInfo or {}
    self._siteCDInfo = data.siteCDInfo or {}
    
    -- 弹板  cd
    self._popupCDInfo = data.popupCDInfo or {}
end

-- 2023-12-07 10:49:43  点位次数新逻辑：
    -- 1. rateUs弹板 线上玩家 extra 里存过的 次数 累加 本地记录过的 次数， 拯救老玩家BigWin弹过rateUs还重现弹
    -- 2. 点位次数 由 本地存储 放到 服务器 extra 存储， 玩家不受清缓存 和 删包重装影响
function PopupSiteArchiveData:initServerExtraSaveData(_serverData)
    if not _serverData or not _serverData["SpinWin"] then
        local bDeal = gLobalDataManager:getBoolByField("OperateGuidePopupHadSaveNet", false)
        if bDeal then
            return
        end
        
        -- 玩家 没存过 rateUs次数 直接 拿 老以前
        self._siteCountInfo["SpinWin"] = self:getSiteCount("SpinWin") + globalData.rateUsData:getRateUsCount()
        gLobalDataManager:setBoolByField("OperateGuidePopupHadSaveNet", true)
        return
    end

    self._siteCountInfo = _serverData or {}
end
function PopupSiteArchiveData:getSiteCountInfo()
    return self._siteCountInfo
end

-- 2023年12月09日17:03:21 点位cd 和 弹板cd 也存服务器
function PopupSiteArchiveData:initServerExtraSaveData_CD(_siteCDInfo, _popupCDInfo)
    if _siteCDInfo and table.nums(_siteCDInfo) > 0 then
        self._siteCDInfo = _siteCDInfo or {}
    end

    if _popupCDInfo and table.nums(_popupCDInfo) > 0 then
        self._popupCDInfo = _popupCDInfo or {}
    end
end
function PopupSiteArchiveData:getSiteCDInfo()
    return self._siteCDInfo
end
function PopupSiteArchiveData:getPopupCDInfo()
    return self._popupCDInfo
end

-- 点位添加 次数
function PopupSiteArchiveData:setSiteCount(_site)
    if not self._siteCountInfo[_site] then
        self._siteCountInfo[_site] = 0
    end
    self._siteCountInfo[_site] = self._siteCountInfo[_site] + 1
end
function PopupSiteArchiveData:getSiteCount(_site)
    return self._siteCountInfo[_site] or 0
end
function PopupSiteArchiveData:resetCount(_site)
    self._siteCountInfo[_site] = 0
end

-- 点位记录 上次弹板 监测时间
function PopupSiteArchiveData:recordSiteTime(_site)
    self._siteCDInfo[_site] = os.time()
end
function PopupSiteArchiveData:getSiteTime(_site)
    return self._siteCDInfo[_site] or 0
end

-- 记录弹板 类型 cd
function PopupSiteArchiveData:recordPopupTime(_popupType)
    self._popupCDInfo[_popupType] = os.time()
end
function PopupSiteArchiveData:getLastPopupTime(_popupType)
    return self._popupCDInfo[_popupType] or 0
end

-- 存档
function PopupSiteArchiveData:getArchiveData()
    if not util_IsFileExist(ArchiveFile) then
        return {}
    end

    local data = util_checkJsonDecode(ArchiveFile)
    return data or {}
end
function PopupSiteArchiveData:saveArchiveData()
    local siteCountInfo = self._siteCountInfo or {}
    local siteCDInfo = self._siteCDInfo or {}
    local popupCDInfo = self._popupCDInfo or {}
    table.filter(siteCountInfo, function(k, v)
        return true
    end) 

    local str = cjson.encode({
        siteCountInfo = siteCountInfo,
        siteCDInfo = siteCDInfo,
        popupCDInfo = popupCDInfo
    }) or ""
    cc.FileUtils:getInstance():writeStringToFile(str, device.writablePath .. ArchiveFile)
end

return PopupSiteArchiveData