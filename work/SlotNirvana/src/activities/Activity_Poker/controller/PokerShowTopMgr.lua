--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-27 16:22:58
]]
local PokerShowTopNet = require("activities.Activity_Poker.net.PokerShowTopNet")
local PokerShowTopMgr = class("PokerShowTopMgr", BaseActivityControl)

function PokerShowTopMgr:ctor()
    PokerShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PokerShowTop)
    self:addPreRef(ACTIVITY_REF.Poker)

    self.m_net = PokerShowTopNet:getInstance()
end

function PokerShowTopMgr:getNet()
    return self.m_net
end

function PokerShowTopMgr:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PokerRankUI") ~= nil then
        return nil
    end
    local uiView = util_createView("Activity.PokerCode.PokerRank.PokerRankUI", params)
    uiView:setName("PokerRankUI")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    return uiView
end

-- 发送获取排行榜消息
function PokerShowTopMgr:getRank(loadingLayerFlag)
    -- 数据不全 不执行请求
    if not G_GetMgr(ACTIVITY_REF.Poker):getRunningData() then
        return
    end

    local successCallFunc = function(rankData)
        if rankData ~= nil then
            local pokerData = G_GetMgr(ACTIVITY_REF.Poker):getRunningData()
            if pokerData then
                pokerData:parsePokerRankConfig(rankData)
            end
        end
    end

    self.m_net:sendActionRank(loadingLayerFlag, successCallFunc)
end

return PokerShowTopMgr
