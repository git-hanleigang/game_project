--[[--
    
]]
local Cell_Vertical = class("Cell_Vertical", BaseView)

-- _cellType: page; list
function Cell_Vertical:initDatas(_pageIndex, _cellType, _vipLevel)
    self.m_pageIndex = _pageIndex
    self.m_cellType = _cellType
    self.m_vipLevel = _vipLevel
end

function Cell_Vertical:getCsbName()
    return "VipNew/csd/rewardUI/Cell_Vertical.csb"
end

function Cell_Vertical:initCsbNodes()
    self.m_nodeTitle = self:findChild("node_title")
    self.m_nodeGezis = self:findChild("node_gezis")
    self.m_nodeCells = {}
    for i = 1, VipConfig.CellNum do
        local cell = self:findChild("node_gezi" .. i)
        table.insert(self.m_nodeCells, cell)
    end
    self.m_nodeBlack = self:findChild("node_black")
    self.m_nodeBlackPlus = self:findChild("node_blackPlus")
    -- self.m_nodeEffect = self:findChild("node_effect")
end

function Cell_Vertical:initUI()
    Cell_Vertical.super.initUI(self)
    self:initCells()
    self:initEffect()
end

function Cell_Vertical:initCells()
    if self.m_cellType == "page" then
        self:initPageCells()
    elseif self.m_cellType == "listView" then
        self:initListCells()
    end
end

function Cell_Vertical:updateCells(_pageIndex)
    self.m_pageIndex = _pageIndex
    if self.m_cellType == "page" then
        self:updatePageCells()
    elseif self.m_cellType == "listView" then
        self:updateListCells()
    end
end

function Cell_Vertical:initEffect()
    local curVipLevel = self:getCurVipLevel()
    if self.m_vipLevel == curVipLevel then
        local effect = util_createAnimation("VipNew/csd/rewardUI/ReelEffect.csb")
        self:addChild(effect)
        effect:setScaleX(0.98)
        effect:setPositionX(-1)
        effect:playAction("run", true, nil, 60)
        local node_boost = effect:findChild("bost")
        local isFlag, vipLevel = self:isFlag()
        if isFlag then
            local flagNode = util_createView("views.vipNew.rewardUI.CellFlag")
            node_boost:addChild(flagNode)
            flagNode:updateFlag("upgraded")
        end
    end
end

function Cell_Vertical:isFlag()
    local data = G_GetMgr(G_REF.Vip):getData()
    if not data then
        return
    end
    local vipLevel = globalData.userRunData.vipLevel
    local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if VipBoostData and VipBoostData:isOpenBoost() then
        local nextData = data:getVipLevelInfo(vipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
        if nextData then
            return true, nextData.levelIndex
        end
    end
    return false
end

function Cell_Vertical:initPageCells()
    local pageCfg = VipConfig.PAGE_CONFIG[self.m_pageIndex]
    -- 标题
    local title = util_createView("views.vipNew.rewardUI.Cell_LeftTop")
    self.m_nodeTitle:addChild(title)
    -- 页签
    self.m_pageCells = {}
    for i = 1, VipConfig.CellNum do
        local cell = util_createView("views.vipNew.rewardUI.Cell_Left", i, self.m_pageIndex, pageCfg[i])
        cell:setPositionY(-6)
        self.m_nodeCells[i]:addChild(cell)
        self.m_pageCells[i] = cell
    end
end

function Cell_Vertical:updatePageCells()
    local pageCfg = VipConfig.PAGE_CONFIG[self.m_pageIndex]
    for i = 1, VipConfig.CellNum do
        self.m_pageCells[i]:updateUI(self.m_pageIndex, pageCfg[i])
    end
end

function Cell_Vertical:initListCells()
    -- 标题
    local title = util_createView("views.vipNew.rewardUI.Cell_Top", self.m_vipLevel)
    self.m_nodeTitle:addChild(title)

    -- 奖励
    local curVipLevel = self:getCurVipLevel()
    local cfg = VipConfig.LISTVIEW_CONFIG[self.m_vipLevel]
    if cfg.cType == "vertical" then
        self:showGezi()
    elseif cfg.cType == "black" then
        if curVipLevel < self.m_vipLevel - 1 then
            self:showBlack()
        else
            self:showGezi()
        end
    elseif cfg.cType == "blackPlus" then
        if curVipLevel < self.m_vipLevel - 1 then
            self:showBlackPlus()
        else
            self:showGezi()
        end
    end
end

function Cell_Vertical:updateListCells()
    if not self.m_listCells then
        return
    end
    local nums = self:getCenterNums()
    local cellNums = nums and nums[self.m_pageIndex] or {}
    local txtCfg = VipConfig.LISTCELL_TEXT[self.m_pageIndex]
    for i = 1, VipConfig.CellNum do
        self.m_listCells[i]:updateUI(txtCfg[i], cellNums[i])
    end
end

function Cell_Vertical:showGezi()
    self.m_nodeGezis:setVisible(true)
    self.m_nodeBlack:setVisible(false)
    self.m_nodeBlackPlus:setVisible(false)
    local nums = self:getCenterNums()
    local cellNums = nums and nums[self.m_pageIndex] or {}
    local txtCfg = VipConfig.LISTCELL_TEXT[self.m_pageIndex]
    self.m_listCells = {}
    local cur = false
    local curVipLevel = self:getCurVipLevel()
    if self.m_vipLevel == curVipLevel then
        cur = true
    end
    for i = 1, VipConfig.CellNum do
        local cell = util_createView("views.vipNew.rewardUI.Cell_Center", i, txtCfg[i], cellNums[i],cur)
        cell:setPositionY(-6)
        self.m_nodeCells[i]:addChild(cell)
        self.m_listCells[i] = cell
    end
end

function Cell_Vertical:showBlack()
    self.m_nodeGezis:setVisible(false)
    self.m_nodeBlack:setVisible(true)
    self.m_nodeBlackPlus:setVisible(false)
    local cell = util_createView("views.vipNew.rewardUI.ListCell_Black")
    self.m_nodeBlack:addChild(cell)
end

function Cell_Vertical:showBlackPlus()
    self.m_nodeGezis:setVisible(false)
    self.m_nodeBlack:setVisible(false)
    self.m_nodeBlackPlus:setVisible(true)
    local cell = util_createView("views.vipNew.rewardUI.ListCell_BlackPlus")
    self.m_nodeBlackPlus:addChild(cell)
end

function Cell_Vertical:getCurVipLevel()
    local curVipLevel = globalData.userRunData.vipLevel
    local data = G_GetMgr(G_REF.Vip):getData()
    if data then
        local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if VipBoostData and VipBoostData:isOpenBoost() then
            local nextData = data:getVipLevelInfo(curVipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
            if nextData then
                curVipLevel = nextData.levelIndex
            end
        end
    end
    return curVipLevel
end

function Cell_Vertical:getCenterNums()
    local data = G_GetMgr(G_REF.Vip):getData()
    local vipData = data:getVipLevelInfo(self.m_vipLevel)
    if self.m_vipLevel >= VipConfig.MAX_LEVEL then
        local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if VipBoostData and VipBoostData:isOpenBoost() then
            vipData = data:getVipLevelInfo(self.m_vipLevel + VipBoostData.p_extraVipLevel)
        end
    end
    -- assert(vipData ~= nil, "vipData is nil")
    return vipData and vipData:getCenterNums() or {}
end

function Cell_Vertical:getCellSize()
    return cc.size(203, 546)
end

return Cell_Vertical
