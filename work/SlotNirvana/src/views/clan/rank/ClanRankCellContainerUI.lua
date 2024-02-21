--[[
Author: cxc
Date: 2022-02-24 15:29:22
LastEditTime: 2022-02-24 15:30:01
LastEditors: cxc
Description: 公会排行 排行cellList容器
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankCellContainerUI.lua
--]]
local ClanRankCellContainerUI = class("ClanRankCellContainerUI", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRankCellContainerUI:ctor()
    ClanRankCellContainerUI.super.ctor(self)

    self.m_size = cc.size(0, 0)
    self.m_cellSize = cc.size(0, 0)
end

function ClanRankCellContainerUI:updateUI(_type, _listData, _containerW)
    self.m_type = _type
    self.m_listData = _listData
    local clanSimpleInfo = ClanManager:getClanData():getClanSimpleInfo()
    self.m_selfClanCid = clanSimpleInfo:getTeamCid()
    self.m_containerW = _containerW or 0 
    self:setPositionX(self.m_containerW * 0.5)

    -- 背景与内容高度差init
    self:initContentCellPading()
    -- 背景显隐
    self:initBgUI()
    -- cell列表
    self:initCellListUI()
end

function ClanRankCellContainerUI:getCsbName()
    return "Club/csd/RANK/Club_rank_colorPlate.csb"
end

function ClanRankCellContainerUI:initContentCellPading()
    -- up
    local imgVUp = self:findChild("imgV_up")
    local layoutUp = self:findChild("layout_upList")
    self.m_padingUp = imgVUp:getContentSize().height - layoutUp:getContentSize().height

    -- down
    local imgVDown = self:findChild("imgV_down")
    local layoutDown = self:findChild("layout_downList")
    self.m_padingDown = imgVDown:getContentSize().height - layoutDown:getContentSize().height
end

-- 背景显隐
function ClanRankCellContainerUI:initBgUI()
    local nodeUp = self:findChild("node_up")
    local nodeDown = self:findChild("node_down")
    local nodeUnchanged = self:findChild("node_unchanged")
    nodeUp:setVisible(self.m_type == ClanConfig.RankUpDownEnum.UP)
    nodeDown:setVisible(self.m_type == ClanConfig.RankUpDownEnum.DOWN)
    nodeUnchanged:setVisible(self.m_type == ClanConfig.RankUpDownEnum.UNCHANGED)
end

-- 背景 大小
function ClanRankCellContainerUI:updateBgUI(_height)
    local imgViewBg = nil
    if self.m_type == ClanConfig.RankUpDownEnum.UP then
        imgViewBg = self:findChild("imgV_up")
    elseif self.m_type == ClanConfig.RankUpDownEnum.DOWN then
        imgViewBg = self:findChild("imgV_down")
    end
    if not imgViewBg then
        return
    end

    imgViewBg:setContentSize(cc.size(imgViewBg:getContentSize().width, _height))
end

-- cell列表
function ClanRankCellContainerUI:initCellListUI()
    local padding = 0
    local layout = self:findChild("layout_unchanged")
    if self.m_type == ClanConfig.RankUpDownEnum.UP then
        layout = self:findChild("layout_upList")
        padding = self.m_padingUp
    elseif self.m_type == ClanConfig.RankUpDownEnum.DOWN then
        layout = self:findChild("layout_downList")
        padding = self.m_padingDown
    end
    layout:setBackGroundColorOpacity(0)

    local childCount = layout:getChildrenCount()
    for i=1, #self.m_listData do
        local rankCellData = self.m_listData[i]
        local cellView = layout:getChildByName("ContainerUIChildLayout_" .. i)
        if cellView then
            local cellUI = cellView:getChildByName("ClanRankCellUI")
            cellUI:updateUI(rankCellData, self.m_selfClanCid)
        else
            local cellView = self:cerateCellUI(rankCellData)
            cellView:setName("ContainerUIChildLayout_" .. i)
            layout:addChild(cellView)
        end
    end
    if childCount > #self.m_listData then
        self:delOverCellItem(layout, #self.m_listData+1, childCount)
    end

    layout:setLayoutType(ccui.LayoutType.VERTICAL)
    layout:requestDoLayout()
    local height = self.m_cellSize.height * #self.m_listData + padding
    layout:setContentSize(self.m_containerW, height - padding)
    self.m_size = cc.size(self.m_containerW, height)
    self:updateBgUI(height)
end

-- 删除listView溢出的 节点
function ClanRankCellContainerUI:delOverCellItem(_layout, _startIdx, _endIdx)
    for i=_startIdx, _endIdx do
        _layout:removeChildByName("ContainerUIChildLayout_" .. i)
    end
end

-- 创建cell
function ClanRankCellContainerUI:cerateCellUI(_rankCellData)
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    local view = util_createView("views.clan.rank.ClanRankCellUI")
    view:updateUI(_rankCellData, self.m_selfClanCid)
    view:setName("ClanRankCellUI")
    local cellSize = view:getContentSize()
    self.m_cellSize = cellSize
    layout:addChild(view)
    layout:setContentSize(cc.size(self.m_containerW, cellSize.height))
    view:move(self.m_containerW * 0.5, cellSize.height * 0.5)
    layout:move(self.m_containerW * 0.5, cellSize.height * 0.5)
    -- layout:setBackGroundColorOpacity(200)
	-- layout:setBackGroundColorType(2)
	-- layout:setBackGroundColor(cc.c3b(0,255,0))

    return layout
end

-- 获取cellSize
function ClanRankCellContainerUI:getContentSize()
    return self.m_size
end

return ClanRankCellContainerUI