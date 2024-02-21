--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 14:38:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-27 14:38:57
FilePath: /SlotNirvana/src/activities/Activity_Blast/views/noviceTask/BlastNoviceTaskBubbleUI.lua
Description: 新手blast 任务 气泡
--]]
local BlastNoviceTaskBubbleUI = class("BlastNoviceTaskBubbleUI", BaseView)

function BlastNoviceTaskBubbleUI:initDatas(_data)
    BlastNoviceTaskBubbleUI.super.initDatas(self)

    self.m_data = _data
end

function BlastNoviceTaskBubbleUI:getCsbName()
    return "Activity/BlastBlossomTask/csb/blastMission_qipao.csb"
end

function BlastNoviceTaskBubbleUI:initUI()
    BlastNoviceTaskBubbleUI.super.initUI(self)

    self:updateUI()
    self:setVisible(false)
end

function BlastNoviceTaskBubbleUI:updateUI()
    local parent = self:findChild("Node_jiedian")
    parent:removeAllChildren()
    local missionData = self.m_data:getCurMissionData()
    local rewardList = clone(missionData:getRewardList())
    local coins = missionData:getCoins()
    if coins > 0 then
        local shopItem = gLobalItemManager:createLocalItemData("Coins", coins)
        shopItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
        table.insert(rewardList, 1, shopItem)
    end

    local scaleList = self:getItemScale()
    local itemNode = gLobalItemManager:addPropNodeList(rewardList, ITEM_SIZE_TYPE.REWARD, scaleList[#rewardList] or 1)
    parent:addChild(itemNode)
    util_setCascadeOpacityEnabledRescursion(parent, true)
end


-- 切换气泡显隐
function BlastNoviceTaskBubbleUI:switchBubbleVisible()
    if self.m_bActing then
        return
    end

    if self:isVisible() then
        self:hideBubbleTip()
    else
        self:showBubbleTip()
    end
end

function BlastNoviceTaskBubbleUI:showBubbleTip()
    if self:isVisible() then
        return
    end

    self.m_bActing = true
	self:setVisible(true)
	self:runCsbAction("show", false, function()
        self.m_bActing = false
		performWithDelay(self, function()
			self:hideBubbleTip()
		end, 5)
	end, 60)
end

function BlastNoviceTaskBubbleUI:hideBubbleTip()
    if not self:isVisible() then
        return
    end

	self:stopAllActions()
    self.m_bActing = true
	self:runCsbAction("hide", false, function()
        self.m_bActing = false
		self:setVisible(false)
	end, 60)
end

--气泡内道具的缩放值
function BlastNoviceTaskBubbleUI:getItemScale()
    return {0.9, 0.7, 0.7} -- {只有一个道具时缩放值，大于1个时缩放值}
end

return BlastNoviceTaskBubbleUI