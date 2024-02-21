--[[--
]]
local BaseServerMailData = util_require("GameModule.Inbox.model.mailData.BaseServerMailData")
local BaseInboxRunData = class("BaseInboxRunData")
function BaseInboxRunData:ctor()
    self.m_mailDatas = {}
    self.m_clanCardData = {}
end

function BaseInboxRunData:initMailData(_netDatas)
    -- local filterMailData  = self:filterMailData(temp or self.m_mailDatas)
    if _netDatas and #_netDatas > 0 then
        self.m_mailDatas = {}
        for k, _netData in pairs(_netDatas) do
            local mData = BaseServerMailData:create()
            mData:parseData(_netData)
            if self:isCanShowNetMail(mData) then
                table.insert(self.m_mailDatas, mData)
            end
        end
    end
end

function BaseInboxRunData:getMailData()
    return self.m_mailDatas
end

function BaseInboxRunData:isCanShowNetMail(_mailData)
    -- 集卡新手期 不返回 常规集卡邮件数据
    if _mailData:isCardType() and globalData:isCardNovice() then
        return false
    end
    if _mailData:getLeftTime() <= 0 then
        return false
    end
    local mailInfo = InboxConfig.InBoxNetNameMap["".._mailData:getType()]
    if mailInfo then
        -- 检测Inbox_Collect资源
        if mailInfo.isDownLoad and not globalDynamicDLControl:checkDownloaded("Inbox_Collect") then
            return false
        end
        -- 关联资源检测
        if not self:checkRelRes(mailInfo.relRes) then
            return false
        end
    end
    return true
end

-- 关联资源检测
function BaseInboxRunData:checkRelRes(_relResData)
    if _relResData and #_relResData > 0 then
        for i,v in ipairs(_relResData) do
            local mgr = G_GetMgr(v)
            if mgr and mgr.isDownloadRes then
                local isDownload = mgr:isDownloadRes()
                return isDownload
            else
                local activityData = G_GetActivityDataByRef(v)
                if activityData then
                    local themeName = ""
                    local isDownload = false
                    if activityData.getThemeName then
                        themeName = activityData:getThemeName()
                    end
                    if themeName and themeName ~= "" then
                        isDownload = self:isDownloadRes(themeName)
                    else
                        isDownload = self:isDownloadRes(v)
                    end
                    return isDownload
                else
                    local isDownload = self:isDownloadRes(v)
                    return isDownload
                end
            end
        end
    end
    return true
end

-- 资源是否下载完成
function BaseInboxRunData:isDownloadRes(zipName)
    if not self:checkRes(zipName) then
        return false
    end

    local isDownloaded = self:checkDownloaded(zipName)
    if not isDownloaded then
        return false
    end

    if self:checkRes(zipName .. "_Code") or self:checkRes(zipName .. "Code") then
        -- 存在代码资源包才判断
        isDownloaded = self:checkDownloaded(zipName .. "_Code") or self:checkDownloaded(zipName .. "Code")
        if not isDownloaded then
            return false
        end
    end

    return true
end

-- 检查资源是否存在
function BaseInboxRunData:checkRes(resName)
    local datas = globalData.GameConfig.dynamicData or {}
    local data = datas[resName]
    if not data then
        return false
    else
        return true
    end
end

-- 检查下载的资源
function BaseInboxRunData:checkDownloaded(resName)
    return globalDynamicDLControl:checkDownloaded(resName)
end


return BaseInboxRunData