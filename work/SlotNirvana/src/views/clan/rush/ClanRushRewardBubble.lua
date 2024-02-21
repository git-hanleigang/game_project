--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 18:24:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 18:24:48
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushRewardBubble.lua
Description: 公会rush 奖励气泡
--]]
local ClanRushRewardBubble = class("ClanRushRewardBubble", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRushRewardBubble:initDatas(_taskData)
    ClanRushRewardBubble.super.initDatas(self)

    self.m_taskData = _taskData
    gLobalNoticManager:addObserver(self, "hideBubbleEvt", ClanConfig.EVENT_NAME.HIDE_RUSH_GIT_BUBBLE_TIP)
end

function ClanRushRewardBubble:initUI()
    ClanRushRewardBubble.super.initUI(self)

    -- 任务奖励
    self:updateRewardUI()
    self:setVisible(false)
end

function ClanRushRewardBubble:updateUI(_taskData)
    self.m_taskData = _taskData

    -- 任务奖励
    self:updateRewardUI()
end

function ClanRushRewardBubble:getCsbName()
    return "Club/csd/Rush/node_qipao.csb"
end

-- 任务奖励
function ClanRushRewardBubble:updateRewardUI()
    local rewardList = self.m_taskData:getRewardList()
    local nodeItems = self:findChild("node_rewards")
    nodeItems:removeAllChildren()
    local sourceW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local shopItemUI = gLobalItemManager:addPropNodeList(rewardList, ITEM_SIZE_TYPE.TOP, 1, sourceW)
    shopItemUI:addTo(nodeItems)

    self:updateBubbltTipSize(shopItemUI, sourceW)
end

function ClanRushRewardBubble:updateBubbltTipSize(_refNode, _refNodeW)
    if not _refNode then
        return
    end

    local children = _refNode:getChildren()
    local lastNode = children[#children]

    if not lastNode then
        return
    end

    local lastPosX = lastNode:getPositionX()
    local w = (lastPosX + _refNodeW * 0.5) * 2  + 30-- 居中模式所以 * 2
    local spBg = self:findChild("img_bg")
    spBg:setContentSize(cc.size(w, _refNodeW + 10))
end

function ClanRushRewardBubble:switchBubbleVisible()
    local bVisible = self:isVisible()
    self:stopAllActions()

    local actName = "over"
    local cb
    if not bVisible then
        self:setVisible(true)
        actName = "start"
        cb = function()
            performWithDelay(self, function(  )
                self:switchBubbleVisible()
            end, 3)
        end
    else
        cb = function()
            self:setVisible(false)
        end
    end
    self:runCsbAction(actName, false, cb, 60) 
end


function ClanRushRewardBubble:hideBubbleEvt()
    local bVisible = self:isVisible()
    if not bVisible then
        return
    end

    self:switchBubbleVisible()
end

return ClanRushRewardBubble