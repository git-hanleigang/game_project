--[[
    袋鼠商店：翻牌后是免费多玩一次
]]
local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShopPage2x = class("KangaroosShopPage2x", util_require("base.BaseView"))

function KangaroosShopPage2x:initUI(pageIndex, pageCellIndex)
    local resourceFilename = "OutbackFrontierShop/Socre_Kangaroos_fanzhuan2x.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self:initData(pageIndex, pageCellIndex)
end

function KangaroosShopPage2x:initData(pageIndex, pageCellIndex)
    self.m_pageIndex    = pageIndex
    self.m_pageCellIndex= pageCellIndex
end

function KangaroosShopPage2x:updateUI(noPlayStart, free, half, callBack)
    local mores = KangaroosShopData:getShopFreeMore()
    self.m_more = mores[self.m_pageIndex]
    if noPlayStart then
        if self.m_more then
            self:runCsbAction("breath", true)
        else
            self:runCsbAction("idle", true)
        end
    else
        self:runCsbAction("start", false, function( )
            if callBack then
                callBack()
            end            
            if self.m_more then
                self:runCsbAction("breath", true)
            else
                self:runCsbAction("idle", true)
            end
        end)
    end    
end

return KangaroosShopPage2x