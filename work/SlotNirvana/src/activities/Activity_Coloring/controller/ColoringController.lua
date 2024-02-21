--[[
    涂色游戏管理器
]]
local ColoringNet = require("activities.Activity_Coloring.net.ColoringNet")
local ColoringController = class(" ColoringController", BaseActivityControl)

-- 构造函数
function ColoringController:ctor()
    ColoringController.super.ctor(self)

    self:setRefName(ACTIVITY_REF.Coloring)
    self.m_coloringNet = ColoringNet:getInstance()
end

function ColoringController:isDownloadLobbyRes()
    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)

    local isDownloaded = self:checkDownloaded(themeName .. "_loading")
    if not isDownloaded then
        return false
    end

    return true
end

function ColoringController:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    
    local uiView = util_createView("Activity.Activity_ColoringMainLayer")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ColoringController:showNoItemTipLayer()
    local uiView = util_createView("Activity.Activity_ColoringNoItemTipLayer")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ColoringController:showRuleLayer()
    local uiView = util_createView("Activity.Activity_ColoringRuleLayer")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ColoringController:showFinishLayer(_chapterIndex)
    local uiView = util_createView("Activity.Activity_ColoringPaintingFinishLayer", _chapterIndex)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ColoringController:showColoringCollect(_pos)
    local uiView = util_createView("Activity.Activity_ColoringItemCollect", _pos)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

-- 颜料选择
function ColoringController:selectPigments(_index, _color)
    self.m_coloringNet:selectPigments(_index, _color)
end

-- 购买解锁
function ColoringController:payUnlock(_index)
    self.m_coloringNet:payUnlock(_index)
end

function ColoringController:setEntryNode(_node)
    self.m_node_entry = _node
end

-- 关卡内入口节点位置
function ColoringController:getLevelEntryNodePos()
    local worldPos = nil
    if self.m_node_entry and not tolua.isnull(self.m_node_entry) then
        local _isVisible = gLobalActivityManager:getEntryNodeVisible("HourDealEntryNode")
        if _isVisible then 
            worldPos = self.m_node_entry:getParent():convertToWorldSpace(cc.p(self.m_node_entry:getPosition()))
        else
            -- 隐藏图标的时候使用箭头坐标
            worldPos = gLobalActivityManager:getEntryArrowWorldPos()
        end
    end
    return worldPos
end

-- 角标资源
function ColoringController:getLevelLogoRes()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end

    if globalData.slotRunData.isPortrait then 
        return "Activity/ui/level/Inbox_Coloring_logo_shu.png"
    else
        return "Activity/ui/level/Inbox_Coloring_logo_heng.png"
    end
end

function ColoringController:getLevelLogoNode()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end

    local node, act  = util_csbCreate("Activity/Coloring_EntryNode_Icon.csb")

    if node then 
        if globalData.slotRunData.isPortrait then 
            node:getChildByName("sp_heng"):setVisible(false)
        else
            node:getChildByName("sp_shu"):setVisible(false)
        end
    end
    return node, act
end

function ColoringController:getLevelHeipingNode()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end

    local node, act  = util_csbCreate("Activity/ef_heiping.csb")
    return node, act, 40
end

function ColoringController:parseSlotPaintData(_data)
    local data = self:getRunningData()
    if data then 
        data:parseSlotPaintData(_data)
    end
end

function ColoringController:getSlotPaintData()
    local data = self:getRunningData()
    if data then 
        return data:getSlotPaintData()
    else
        return 0, 0
    end
end

function ColoringController:clearSlotPaintData()
    local data = self:getRunningData()
    if data then 
        data:clearSlotPaintData()
    end
end

return ColoringController
