--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-29 17:55:51
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-29 18:16:14
FilePath: /SlotNirvana/src/views/lobby/LevelIcebreakerSaleHallNode.lua
Description: 新版破冰促销 展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelIcebreakerSaleHallNode = class("LevelIcebreakerSaleHallNode", LevelFeature)

function LevelIcebreakerSaleHallNode:createCsb()
    LevelIcebreakerSaleHallNode.super.createCsb(self)
    self:createCsbNode("Icons/IcebreakerSaleHall.csb")
    self:runCsbAction("idle", true)

    self:initView()
end

function LevelIcebreakerSaleHallNode:getCsbName()
    return "Icons/IcebreakerSaleHall.csb"
end

function LevelIcebreakerSaleHallNode:initView()
    local lbDiscount = self:findChild("lb_label_buy")
    local data = G_GetMgr(G_REF.IcebreakerSale):getData()
    local discount = data:getDiscount()
    lbDiscount:setString(string.format("-%s%%", discount))
    util_scaleCoinLabGameLayerFromBgWidth(lbDiscount, 80, 1)

    -- local bPay = data:checkHadPay()
    -- local nodeDiscount = self:findChild("node_label_buy")
    -- nodeDiscount:setVisible(not bPay)
end

function LevelIcebreakerSaleHallNode:clickFunc(sender)
    G_GetMgr(G_REF.IcebreakerSale):showMainLayer()
end

return LevelIcebreakerSaleHallNode