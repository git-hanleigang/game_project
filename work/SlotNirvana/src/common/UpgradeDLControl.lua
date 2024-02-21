local BaseDLControl = require("common.BaseDLControl")
local UpgradeDLControl = class("UpgradeDLControl",BaseDLControl)
function UpgradeDLControl:getInstance()
    if not UpgradeDLControl.instance then
        UpgradeDLControl.instance = UpgradeDLControl:create()
        UpgradeDLControl.instance:initData()
    end

    return UpgradeDLControl.instance
end
--热更不通过父类处理
function UpgradeDLControl:onDownload()
    
end
--热更不通过父类处理
function UpgradeDLControl:notifyDownLoad(url, downType, data)

end

function UpgradeDLControl:checkDownloadJson(url, info)
    local downLoadDelegate = nil
    if DEBUG == 2 and info and info.key == "Version" then
        downLoadDelegate = xcyy.SlotsUtil:beginDownLoad(url)
    else
        downLoadDelegate = self:beginDownLoad(url)
    end
    if info then
        local downInfo = {key = info.key, url = info.url, md5 = info.md5, percent=0.01, size = info.size}
        self.m_downLoadInfo = downInfo
        self:pushUnzipInfo(url, info)
    end
end

-- 获得下载进度
function UpgradeDLControl:getDLProgress(_percent)
    local _progress = 0
    local _info = self.m_downLoadInfo
    if _info then
        local _size = _info.size or 0
        _progress = math.floor(_size * _percent)
    
        return self:getDlTxt(_progress) .. "/" .. self:getDlTxt(_size)
    else
        return ""
    end
end

function UpgradeDLControl:setDownLoadInfoLog()
    -- 覆盖base的log
end

return UpgradeDLControl