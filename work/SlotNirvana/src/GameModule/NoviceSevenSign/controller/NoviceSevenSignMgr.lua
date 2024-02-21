--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:31:11
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/controller/NoviceSevenSignMgr.lua
Description: 新手期 7日签到V2 mgr
--]]
local NoviceSevenSignMgr = class("NoviceSevenSignMgr", BaseGameControl)
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function NoviceSevenSignMgr:ctor()
    NoviceSevenSignMgr.super.ctor(self)

    self:setRefName(G_REF.NoviceSevenSign)
    self:setResInApp(true)
    self:setDataModule("GameModule.NoviceSevenSign.model.NoviceSevenSignData")
end

-- 获取网络 obj
function NoviceSevenSignMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local NoviceSevenSignNet = util_require("GameModule.NoviceSevenSign.net.NoviceSevenSignNet")
    self.m_net = NoviceSevenSignNet:getInstance()
    return self.m_net
end

-- 显示主界面
function NoviceSevenSignMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByName("NoviceSevenSignMainLayer") then
        return
    end

    local view = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 奖励弹板
function NoviceSevenSignMgr:showRewardLayer(_params)
    if not self:isCanShowLayer() or type(_params) ~= "table" then
        return
    end

    local rewardList = {}
    local coins = tonumber(_params.coins) or 0
    if coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(coins, 6))
        table.insert(rewardList, itemData)
    end
    for _, severData in ipairs(_params.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(severData)
        table.insert(rewardList, shopItem)
    end

    if #rewardList == 0 or gLobalViewManager:getViewByName("NoviceSevenSignRewardLayer") then
        return
    end

    local view = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignRewardLayer", rewardList, coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 监测是否可领取
function NoviceSevenSignMgr:checkCanCollect()
    local data = self:getRunningData()
    if not data then
        return false
    end

    return data:checkCanCollect()
end

-- 签到领取
function NoviceSevenSignMgr:sendCollectReq()
    self:getNetObj():sendCollectReq()
end

return NoviceSevenSignMgr