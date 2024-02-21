--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-07 20:21:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-07 20:21:29
FilePath: /SlotNirvana/src/log/LogNovice.lua
Description: 新手期 打点
--]]
local NetworkLog = require "network.NetworkLog"
local LogNovice = class("LogNovice",NetworkLog)

function LogNovice:ctor()
    NetworkLog.ctor(self)
    self:resetNoviceData()
end

function LogNovice:resetNoviceData()
    self:resetNewUserGoCardSysSign()
end

-- 新手期集卡宣传图 进入集卡 标识，后边点击第一个卡册需要用
function LogNovice:setNewUserGoCardSysSign(_bool, _entrySite)
    self.m_cardPubEnterInfo = {
        bPubEnter = _bool,
        entrySite = _entrySite
    }
end
function LogNovice:getNewUserGoCardSysSign()
    return self.m_cardPubEnterInfo
end
function LogNovice:resetNewUserGoCardSysSign()
    self.m_cardPubEnterInfo = {}
end

--[[
@description: 新手期弹窗 打点
@parmas: _popUpType 事件类型
@parmas: _popupName 弹窗名称
@parmas: enteryOpen 打开方式 手动还是自动
@parmas: _bCancelCheck 活动收集弹板是否去掉对勾

@return {*}
--]]
function LogNovice:sendPopupLayerLog(_popUpType, _popupName, _entrySite, _bCancelCheck, _bClickFirstCardAlbum)
    local log_data = {}
    log_data.tp = _popUpType
    log_data.pn = _popupName
    log_data.et = self:getEntryType()
    log_data.en = self:getEntrySize(_entrySite)
    log_data.eo = _entrySite == ACT_LAYER_POPUP_TYPE.AUTO and "PushOpen" or "TapOpen"

    log_data.buff = _bClickFirstCardAlbum and 1 or 0
    log_data.stats = _bCancelCheck and 1 or 0

    gL_logData:syncUserData()
    gL_logData:syncEventData("NUPopup")
    gL_logData.p_data = log_data

    self:sendLogData()
end

-- 获取 弹板位置类型
function LogNovice:getEntryType()
    local str = ""
    if gLobalViewManager:isLobbyView() then
        str = "Lobby"
    elseif gLobalViewManager:isLevelView() then
        str = "Game"
    end

    return str
end

-- 获取 弹窗位置 
function LogNovice:getEntrySize(_popupSite)
    local siteStr = ""
    if _popupSite == ACT_LAYER_POPUP_TYPE.AUTO then
        siteStr = "Auto"
        if gLobalViewManager:isLobbyView() then
            siteStr = "LoginLobbyPush"
        elseif gLobalViewManager:isLevelView() then
            siteStr = "SpinPush"
        end
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.SLIDE then
        siteStr = "LobbyCarousel"
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.HALL then
        siteStr = "LobbyDisplay"
    elseif _popupSite == ACT_LAYER_POPUP_TYPE.ENTRANCE then
        siteStr = "HotNews"
    else
        siteStr = _popupSite
    end

    return siteStr
end

return  LogNovice