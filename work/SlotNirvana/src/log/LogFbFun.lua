--[[
    fbFun LOG
    轮播页 fbfun 每点击一次发一次
]]
local NetworkLog = require "network.NetworkLog"
local LogFbFun = class("LogFbFun", NetworkLog)

function LogFbFun:ctor()
    NetworkLog.ctor(self)
end

function LogFbFun:sendLogMessage(...)
    local args = {...}
    -- 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end

--下载相关log
function LogFbFun:sendOpenFbFunLog()
    gL_logData:syncUserData()
    gL_logData:syncEventData("FanpageView")

    local messageData = {
        type = "Click"
    }

    gL_logData.p_data = messageData
    self:sendLogData()
end
-- 外部调用接口 end   ----------------------------------------------------------

-- fb活动打点
function LogFbFun:sendFbActLog(_layerActType, _actionType, _popupType, _popupSite, _popupBtp, _backStatus)
    -- if _actionType == "Popup" then
    --     return
    -- end
    -- type 功能
    -- 加好友弹板=AddFriend
    -- 粉丝小组宣传弹板=Group
    -- 社团宣传弹板=Community
    -- SettingsFB=SettingFB"
    -- 涂色分享=ColoringContestShare
    -- 三周年挑战活动分享=MemoryLaneShare
    -- 圣诞签到分享=HolidaySign

    -- actionType 弹窗还是点击链接去fb
    -- 弹窗弹出=Popup
    -- 点击按钮=Click

    -- popupType 弹窗类型 actionType 为popup时传就行
    -- 自动弹出=Auto
    -- 手动点击=Tap

    -- clickSite 弹窗 和 点击 来源
    -- 轮播图=LobbyCarousel
    -- 展示位=LobbyDisplay
    -- 新闻中心=HotNews
    -- 自动弹窗=Auto
    -- 设置界面=Setting

--  backStatus 返回状态

    local popupSiteStr = type(_popupSite) == "string" and _popupSite
    if not popupSiteStr then
        popupSiteStr = self:getActPopupSiteStr(_popupSite)
    end
    gL_logData:syncUserData()
    gL_logData:syncEventData("FaceBookActivity")
    local messageData = {
        type = _layerActType or "",
        actionType = _actionType or "",
        popupType = _popupType or "",
        clickSite = popupSiteStr
    }
    if _popupBtp and _popupBtp ~= "" then
        messageData.btp = _popupBtp
    end
    if _backStatus and _backStatus ~= "" then
        messageData.sst = _backStatus
    end    
    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 获取 fb活动 弹窗打点来源
function LogFbFun:getActPopupSiteStr(_popupSite)
    local siteStr = ""
    if _popupSite == ACT_LAYER_POPUP_TYPE.AUTO then
        siteStr = "Auto"
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.SLIDE then
        siteStr = "LobbyCarousel"
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.HALL then
        siteStr = "LobbyDisplay"
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.ENTRANCE then
        siteStr = "HotNews"
    end

    return siteStr
end

return LogFbFun
