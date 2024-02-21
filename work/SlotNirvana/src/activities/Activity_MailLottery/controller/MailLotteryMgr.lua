--[[
    收集邮件抽奖
]]

local MailLotteryNet = require("activities.Activity_MailLottery.net.MailLotteryNet")
local MailLotteryMgr = class("MailLotteryMgr", BaseActivityControl)
local Config = require("activities.Activity_MailLottery.config.MailLotteryConfig")

function MailLotteryMgr:ctor()
    MailLotteryMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MailLottery)
    self.m_netModel = MailLotteryNet:getInstance() -- 网络模块
end


function MailLotteryMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MailLotteryMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MailLotteryMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .."/" .. popName
end

function MailLotteryMgr:sendMail(_data)
    local successCallback = function(_result)  
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MAILOTTERY_SENDMAIL,{success = true})
    end

    local failedCallback = function(errorCode, errorData) 
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MAILOTTERY_SENDMAIL)
    end
    self.m_netModel:sendMail(_data,successCallback,failedCallback)
end

function MailLotteryMgr:showTipsLayer(_data)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("TipsView") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".ViewCode.TipsView", _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view 
end

function MailLotteryMgr:showCheckLayer()
    -- if not self:isCanShowLayer() then
    --     return
    -- end
    if self:getLayerByName("CheckLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".ViewCode.CheckLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view 
end

return MailLotteryMgr
