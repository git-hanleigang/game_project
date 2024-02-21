--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-25 16:15:51
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-25 16:16:21
FilePath: /SlotNirvana/src/views/lobby/LevelFirstSaleMultiSlideNode.lua
Description: 三档首充  轮播
--]]
local LevelFirstSaleMultiSlideNode = class("LevelFirstSaleMultiSlideNode", BaseView)

function LevelFirstSaleMultiSlideNode:getCsbName()
    return "Promotion/FirstMultiSale/Icons/FirstSaleMulti_Slide.csb"
end

function LevelFirstSaleMultiSlideNode:initUI()
    LevelFirstSaleMultiSlideNode.super.initUI(self)

    self:runCsbAction("idle", true)
    self:initView()
    schedule(self, util_node_handler(self, self.updateDt), 1)
end

function LevelFirstSaleMultiSlideNode:initView()
    local data = G_GetMgr(G_REF.FirstSaleMulti):getData()

    local worth = data:getHallSlideShowWorth()
    local lbPriceWorth = self:findChild("lb_priceWorth")
    lbPriceWorth:setString("WORTH $" .. worth)

    local price = data:getLastLevelDisPrice()
    local lbPrice = self:findChild("lb_priceNow")
    lbPrice:setString("$" .. price)
end

function LevelFirstSaleMultiSlideNode:updateDt()
    if not G_GetMgr(G_REF.FirstSaleMulti):isRunning() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE)
    end
end

--点击回调
function LevelFirstSaleMultiSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelFirstSaleMultiSlideNode:clickLayer()
    local view = G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = ACT_LAYER_POPUP_TYPE.SLIDE})
    -- 按钮名字  类型是url
    if view and gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view,"LevelFirstSaleMulti",DotUrlType.UrlName,true,DotEntrySite.UpView,DotEntryType.Lobby)
    end
end

return LevelFirstSaleMultiSlideNode