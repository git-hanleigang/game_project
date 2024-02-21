--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-29 17:55:39
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-29 18:17:46
FilePath: /SlotNirvana/src/views/lobby/LevelIcebreakerSaleSlideNode.lua
Description: 新版破冰促销 轮播图
--]]
local LevelIcebreakerSaleSlideNode = class("LevelIcebreakerSaleSlideNode", BaseView)

function LevelIcebreakerSaleSlideNode:getCsbName()
    return "Icons/IcebreakerSaleSlide.csb"
end

function LevelIcebreakerSaleSlideNode:initUI()
    LevelIcebreakerSaleSlideNode.super.initUI(self)

    self:runCsbAction("idle", true)
    self:initView()
end

function LevelIcebreakerSaleSlideNode:initView()
    local lbDiscount = self:findChild("lb_label_buy")
    local data = G_GetMgr(G_REF.IcebreakerSale):getData()
    local discount = data:getDiscount()
    lbDiscount:setString(string.format("-%s%%", discount))
    util_scaleCoinLabGameLayerFromBgWidth(lbDiscount, 80, 1)


    -- local bPay = data:checkHadPay()
    -- local nodeDiscount = self:findChild("node_label_buy")
    -- nodeDiscount:setVisible(not bPay)
end

--点击回调
function LevelIcebreakerSaleSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelIcebreakerSaleSlideNode:clickLayer()
    G_GetMgr(G_REF.IcebreakerSale):showMainLayer()
end

return LevelIcebreakerSaleSlideNode