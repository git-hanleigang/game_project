---
--xcyy
--2018年5月23日
--GhostBlasterPickItem.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterPickItem = class("GhostBlasterPickItem",util_require("base.BaseView"))

function GhostBlasterPickItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_index = params.index

    self.m_isClicked = false
    self.m_spine = util_spineCreate("GhostBlaster_Box_tb",true,true)

    self:addChild(self.m_spine)

     --创建点击区域
     local layout = ccui.Layout:create() 
     self:addChild(layout)    
     layout:setAnchorPoint(0.5,0.5)
     layout:setContentSize(CCSizeMake(300,300))
     layout:setTouchEnabled(true)
     self:addClick(layout)
 
     --显示区域
    --  layout:setBackGroundColor(cc.c3b(255, 0, 0))
    --  layout:setBackGroundColorOpacity(255)
    --  layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

    self.m_rewardNode = util_createAnimation("GhostBlaster_picktanban_0.csb")
    self:addChild(self.m_rewardNode)
    self.m_rewardNode:setVisible(false)
end

--默认按钮监听回调
function GhostBlasterPickItem:clickFunc(sender)

    if self.m_isClicked or self.m_parentView.m_isWaiting then
        return
    end
    self.m_isClicked = true

    self.m_parentView:clickFunc(self)
end

--[[
    显示动画
]]
function GhostBlasterPickItem:showAni()
    util_spinePlay(self.m_spine,"start")
    util_spineEndCallFunc(self.m_spine,"start",function()
        util_spinePlay(self.m_spine,"idle",true)
    end)
end

--[[
    飞行动效
]]
function GhostBlasterPickItem:runFlyAni()
    util_spinePlay(self.m_spine,"fly")
    self.m_rewardNode:setVisible(false)
end

--[[
    刷新奖励
]]
function GhostBlasterPickItem:showRewardAni(rewardType,pickIndex,freeCount)
    self.m_rewardNode:setVisible(true)
    self.m_rewardNode:findChild("Node_FG"):setVisible(rewardType == "free")
    self.m_rewardNode:findChild("Node_FG_0"):setVisible(rewardType == "free")
    self.m_rewardNode:findChild("Node_coins"):setVisible(rewardType ~= "free")
    self.m_rewardNode:findChild("Node_coins_0"):setVisible(rewardType ~= "free")
    
    if rewardType ~= "free" then
        local multi = tonumber(rewardType)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local winScore = lineBet * multi
        local m_lb_coins = self.m_rewardNode:findChild("m_lb_coins")
        m_lb_coins:setString(util_formatCoins(winScore,3))

        local m_lb_coins_1 = self.m_rewardNode:findChild("m_lb_coins_1")
        m_lb_coins_1:setString(util_formatCoins(winScore,3))
    else
        for index = 1,5 do
            self.m_rewardNode:findChild("fs_count_"..(index + 3)):setVisible(freeCount == (index + 3))
            self.m_rewardNode:findChild("fs_count_"..(index + 3).."_0"):setVisible(freeCount == (index + 3))
        end
    end
    if pickIndex == self.m_index then
        self.m_rewardNode:runCsbAction("actionframe")
        util_spinePlay(self.m_spine,"actionframe")
        util_spineEndCallFunc(self.m_spine,"actionframe",function()
            util_spinePlay(self.m_spine,"actionframe2",true)
        end)
    else

        util_spinePlay(self.m_spine,"yaan")
        self.m_rewardNode:runCsbAction("yaan")
    end
end
return GhostBlasterPickItem