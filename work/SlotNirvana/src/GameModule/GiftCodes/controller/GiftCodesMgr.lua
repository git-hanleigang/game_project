--[[
    礼物兑换码
]]
local GiftCodesNet = require("GameModule.GiftCodes.net.GiftCodesNet")
local GiftCodesMgr = class("GiftCodesMgr", BaseGameControl)

function GiftCodesMgr:ctor()
    GiftCodesMgr.super.ctor(self)
    
    self:setRefName(G_REF.GiftCodes)
    self.m_netModel = GiftCodesNet:getInstance() -- 网络模块
end

function GiftCodesMgr:requestExchange(_code)
    local successFunc = function(_data)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GIFTCODE_COLLECT,_data)  
    end
    local fileFunc = function()
    end
    self.m_netModel:requestExchange(successFunc,fileFunc,_code)
end

function GiftCodesMgr:showRewardLayer(param,_callback)
    local view = util_createView("views.GiftCodes.GiftCodesReward",param,_callback)
    self:showLayer(view,ViewZorder.ZORDER_UI)
end

return GiftCodesMgr