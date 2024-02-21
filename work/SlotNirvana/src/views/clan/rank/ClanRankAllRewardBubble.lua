--[[
Author: cxc
Date: 2022-02-23 12:21:57
LastEditTime: 2022-02-23 12:21:58
LastEditors: cxc
Description: 公会 排行 所有排行奖励的气泡
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankAllRewardBubble.lua
--]]
local ClanRankRewardCell = class("ClanRankRewardCell", BaseView)
function ClanRankRewardCell:getCsbName()
    return "Club/csd/RANK/club_rank_reward_cell.csb"
end
function ClanRankRewardCell:initUI(_cellData)
    ClanRankRewardCell.super.initUI(self)

	-- rankDesc 
	local lbRank = self:findChild("lb_rank")
	lbRank:setString(_cellData:getRankDesc())
	util_scaleCoinLabGameLayerFromBgWidth(lbRank, 70, 1)
	-- rankReward
	local nodeRewards = self:findChild("node_reward")
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemNode = gLobalItemManager:addPropNodeList(_cellData:getRewardList(), ITEM_SIZE_TYPE.TOP, 0.7, width, true)
	itemNode:move(0, width * 0.1)
	nodeRewards:addChild(itemNode)
end

local ClanRankAllRewardBubble = class("ClanRankAllRewardBubble", BaseView)
function ClanRankAllRewardBubble:initUI()
    ClanRankAllRewardBubble.super.initUI(self)
    
    -- 触摸
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    self:addChild(touch, -1)
	performWithDelay(self, function()
		if tolua.isnull(touch) then
			return
		end
		touch:move(self:convertToNodeSpaceAR(display.center))
	end, 0)
    touch:setSwallowTouches(true)
    self:addClick(touch)
	-- touch:setBackGroundColorOpacity(120)
	-- touch:setBackGroundColorType(2)
	-- touch:setBackGroundColor(cc.c3b(255,0,0))

	-- 适配
    local homeView = gLobalViewManager:getViewByExtendData("ClanHomeView")
    if homeView then
        self:setScale(homeView:getUIScalePro())
		touch:setScale(10) -- 触摸面板大点
    end    

	self:setVisible(false)
end

function ClanRankAllRewardBubble:getCsbName()
    return "Club/csd/RANK/Club_rank_all_reward.csb"
end

-- 初始化节点
function ClanRankAllRewardBubble:initCsbNodes()
    self.m_listView = self:findChild("ListView_rewards")
	self.m_listView:removeAllItems()
	self.m_listView:setTouchEnabled(true)
    self.m_listView:setScrollBarEnabled(false)

	self.m_cellLayoutW = self.m_listView:getContentSize().width
end

-- 奖励
function ClanRankAllRewardBubble:updateUI(_rewardList)
    if not _rewardList and not next(_rewardList) then
		return
	end

	self.m_listView:removeAllItems()
	for i=1, #_rewardList do
		local rewardData = _rewardList[i]
		local layout = ccui.Layout:create()
		layout:setContentSize(cc.size(self.m_cellLayoutW, 40))
		local view = ClanRankRewardCell:create(rewardData) 
		view:initData_(rewardData)
		layout:addChild(view)
		view:move(self.m_cellLayoutW * 0.5, 20)
		self.m_listView:pushBackCustomItem(layout)
	end
end

--结束监听
function ClanRankAllRewardBubble:clickEndFunc(sender)
	gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

	self:hideBubbleTip()
end

-- 切换气泡显隐
function ClanRankAllRewardBubble:switchBubbleVisible()
    if self.m_bActing then
        return
    end

    if self:isVisible() then
        self:hideBubbleTip()
    else
        self:showBubbleTip()
    end
end

function ClanRankAllRewardBubble:showBubbleTip()
    self.m_bActing = true
	self:setVisible(true)
	self:runCsbAction("show", false, function()
        self.m_bActing = false
		performWithDelay(self, function()
			self:hideBubbleTip()
		end, 5)
	end, 60)
end

function ClanRankAllRewardBubble:hideBubbleTip()
	self:stopAllActions()
    self.m_bActing = true
	self:runCsbAction("hide", false, function()
        self.m_bActing = false
		self:setVisible(false)
	end, 60)
end

return ClanRankAllRewardBubble