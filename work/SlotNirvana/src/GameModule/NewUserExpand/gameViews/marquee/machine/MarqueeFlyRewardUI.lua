--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-17 16:01:36
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-17 16:03:41
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/machine/MarqueeFlyRewardUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local MarqueeFlyRewardUI = class("MarqueeFlyRewardUI", BaseView)

function MarqueeFlyRewardUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_fly.csb"
end

function MarqueeFlyRewardUI:initUI(_rewardData)
    MarqueeFlyRewardUI.super.initUI(self)

    self.m_rewardData = _rewardData

    -- 创建 奖励副本
    self:initRewardUI()
end

-- 创建 奖励副本
function MarqueeFlyRewardUI:initRewardUI()
    local parent = self:findChild("node_fly")
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeRewardBigItemUI")
    view:hideBgUI()
    view:hideCoinBgUI()
    parent:addChild(view)
    view:updateType(self.m_rewardData)
end

function MarqueeFlyRewardUI:playFlyAni(_endPosL, _cb)
    local time = (55-10)/60
    local moveTo = cc.EaseCircleActionInOut:create(cc.MoveTo:create(time, _endPosL))
    local callFuncEnd = cc.CallFunc:create(_cb)
    local sequence = cc.Sequence:create(moveTo, callFuncEnd, cc.RemoveSelf:create(true))
    self:runAction(sequence)
    self:runCsbAction("fly") 
end

return MarqueeFlyRewardUI