--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-25 16:15:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-25 16:16:11
FilePath: /SlotNirvana/src/views/lobby/LevelFirstSaleMultiHallNode.lua
Description: 三档首充 展示
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelFirstSaleMultiHallNode = class("LevelFirstSaleMultiHallNode", LevelFeature)

function LevelFirstSaleMultiHallNode:createCsb()
    LevelFirstSaleMultiHallNode.super.createCsb(self)
    self:createCsbNode("Promotion/FirstMultiSale/Icons/FirstSaleMulti_Hall.csb")
    self:runCsbAction("idle", true)

    self:initView()
    schedule(self, util_node_handler(self, self.updateDt), 1)
end

function LevelFirstSaleMultiHallNode:initView()
    local data = G_GetMgr(G_REF.FirstSaleMulti):getData()

    local worth = data:getHallSlideShowWorth()
    local lbPriceWorth = self:findChild("lb_priceWorth")
    lbPriceWorth:setString("WORTH $" .. worth)

    local price = data:getLastLevelDisPrice()
    local lbPrice = self:findChild("lb_priceNow")
    lbPrice:setString("$" .. price)
end

function LevelFirstSaleMultiHallNode:updateDt()
    if not G_GetMgr(G_REF.FirstSaleMulti):isRunning() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE)
    end
end

function LevelFirstSaleMultiHallNode:clickFunc(sender)
    local view = G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = ACT_LAYER_POPUP_TYPE.HALL})
    -- 按钮名字  类型是url
    if view and gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view,"LevelFirstSaleMulti",DotUrlType.UrlName,true,DotEntrySite.UpView,DotEntryType.Lobby)
    end
end

return LevelFirstSaleMultiHallNode