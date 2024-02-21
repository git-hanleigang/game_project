--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-08 14:14:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-08 14:14:55
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankRewardsInfoLayer.lua
Description: 排行榜奖励 弹板
--]]
local ClanRankRewardsInfoLayer = class("ClanRankRewardsInfoLayer", BaseLayer)

function ClanRankRewardsInfoLayer:initDatas(_rewardList, _selfRank)
    self.m_rewardList = _rewardList or {}
    self.m_selfRank = _selfRank or 1

    self:setKeyBackEnabled(true)
    self:setExtendData("ClanRankRewardsInfoLayer")
    self:setLandscapeCsbName("Club/csd/RANK/TopTeam/RankRewardsShow_mainUI.csb")
end

function ClanRankRewardsInfoLayer:initCsbNodes()
    self.m_listView = self:findChild("ListView_1")
    self.m_listViewSize = self.m_listView:getContentSize()
end

function ClanRankRewardsInfoLayer:initView()
    self.m_listView:removeAllItems()
	self.m_listView:setTouchEnabled(true)
    self.m_listView:setScrollBarEnabled(false)

    for i=0, math.ceil(#self.m_rewardList * 0.5) - 1 do
        local data_1 = self.m_rewardList[i * 2 + 1]
        local data_2 = self.m_rewardList[i * 2 + 2]
        local layout = self:createCellLayout({data_1, data_2})
        self.m_listView:pushBackCustomItem(layout)
    end 
end

function ClanRankRewardsInfoLayer:createCellLayout(_dataList)
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    local cellSize = cc.size(525, 81)
    local spaceX = self.m_listViewSize.width - cellSize.width * 2
    for i=1, #_dataList do
        local view = util_createView("views.clan.rank.ClanRankRewardsInfoCellUI", _dataList[i], self.m_selfRank)
        cellSize = view:getContentSize()
        view:move(cellSize.width*(i-0.5) + (i-1)*spaceX, cellSize.height*0.5)
        layout:addChild(view)
    end
    
    layout:setContentSize(cc.size(self.m_listViewSize.width, cellSize.height))
    -- layout:setBackGroundColorOpacity(200)
	-- layout:setBackGroundColorType(2)
	-- layout:setBackGroundColor(cc.c3b(0,255,0))

    return layout
end

function ClanRankRewardsInfoLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanRankRewardsInfoLayer