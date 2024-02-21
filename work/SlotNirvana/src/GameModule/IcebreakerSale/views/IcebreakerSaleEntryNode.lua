--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 16:57:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 16:58:09
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/views/IcebreakerSaleEntryNode.lua
Description: 新版破冰促销 关卡左边条入口
--]]
local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
local IcebreakerSaleEntryNode = class("IcebreakerSaleEntryNode", BaseView)

function IcebreakerSaleEntryNode:getCsbName()
    return "Activity/csd/IcebreakerSale_Entrance.csb"
end

function IcebreakerSaleEntryNode:initCsbNodes()
    self.m_nodeDot = self:findChild("node_reddot")
    self.m_lbDot = self:findChild("lb_reddot")
    self.m_nodePanelSize = self:findChild("Node_PanelSize")
    self:addClick(self.m_nodePanelSize)
end

function IcebreakerSaleEntryNode:initUI()
    IcebreakerSaleEntryNode.super.initUI(self)
    self.m_data = G_GetMgr(G_REF.IcebreakerSale):getData()

    self:updateRedDotUI()
    schedule(self, util_node_handler(self, self.updateRedDotUI), 1)
end

function IcebreakerSaleEntryNode:updateRedDotUI()
    local list = self.m_data:checkCanCollectList()
    self.m_lbDot:setString(#list)
    self.m_nodeDot:setVisible(#list>0)
end

function IcebreakerSaleEntryNode:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "Node_PanelSize" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.IcebreakerSale):showMainLayer()
    end
end

-- 入口 大小 (工具类会调用 排序 layout)
function IcebreakerSaleEntryNode:getPanelSize()
    local size = self.m_nodePanelSize:getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size.height}
end

function IcebreakerSaleEntryNode:onEnter()
    IcebreakerSaleEntryNode.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, function()
        gLobalActivityManager:removeActivityEntryNode("IcebreakerSaleEntryNode")
    end, IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER) --功能结束
end

-- 监测 有小红点或者活动进度满了
function IcebreakerSaleEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    if self.m_nodeDot then
        bHadRed = self.m_nodeDot:isVisible() 
    end
    local bProgMax = false
    return {bHadRed, bProgMax}
end

return IcebreakerSaleEntryNode