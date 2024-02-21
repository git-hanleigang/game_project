--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-25 10:51:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-25 14:56:18
FilePath: /SlotNirvana/src/GameModule/FirstSaleMulti/controller/FirstSaleMultiMgr.lua
Description: 三档首充 mgr
--]]
local FirstSaleMultiMgr = class("FirstSaleMultiMgr", BaseGameControl)
local FirstSaleMultiConfig = util_require("GameModule.FirstSaleMulti.config.FirstSaleMultiConfig")

function FirstSaleMultiMgr:ctor()
    FirstSaleMultiMgr.super.ctor(self)

    self:setRefName(G_REF.FirstSaleMulti)
    self:setResInApp(true)
    self:setDataModule("GameModule.FirstSaleMulti.model.FirstSaleMultiData")
end

-- 获取网络 obj
function FirstSaleMultiMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local FirstSaleMultiNet = util_require("GameModule.FirstSaleMulti.net.FirstSaleMultiNet")
    self.m_net = FirstSaleMultiNet:getInstance()
    return self.m_net
end

-- 显示主界面
function FirstSaleMultiMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

	if gLobalViewManager:getViewByName("FirstSaleMultiLayer") then
        return
    end

    local view = util_createView("GameModule.FirstSaleMulti.views.FirstSaleMultiLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 去支付
function FirstSaleMultiMgr:goPurchase(_idx)
    local data = self:getData()
    local levelData = data:getLevelDataByList(_idx)
    if not levelData then
        return
    end

    self:getNetObj():goPurchase(levelData)
end
-- 设置购买后直接关闭 促销标识
function FirstSaleMultiMgr:setSaleOver()
    local data = self:getData()
    if data then
        data:setOver(true)
    end
end

return FirstSaleMultiMgr