--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-09 17:41:07
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-09 17:41:19
FilePath: /SlotNirvana/src/common/ActivityManagerExSlotLeft.lua
Description: ActivityManager逻辑拆分 (关卡左边条逻辑)
--]]
local ActivityManagerExSlotLeft = gLobalActivityManager
local SlotLeftFloatCfg = util_require("GameModule.FloatView.config.SlotLeftFloatCfg")

-- 是否是minz关卡
function ActivityManagerExSlotLeft:isMinzLevel()
    if G_GetMgr(ACTIVITY_REF.Minz) then
        return G_GetMgr(ACTIVITY_REF.Minz):isMinzLevel()
    end
    return false
end

-- 是否是DiyFeature 触发关卡
function ActivityManagerExSlotLeft:isDiyFeatureLevel()
    if G_GetMgr(ACTIVITY_REF.DiyFeature) then
        return G_GetMgr(ACTIVITY_REF.DiyFeature):isDiyFeatureLevel()
    end
    return false
end

--处理具体活动，在哪个位置显示
function ActivityManagerExSlotLeft:InitMachineLeftNode(node)
    if node == nil then
        return
    end

    if self:isMinzLevel() then
        return
    end

    if self:isDiyFeatureLevel() then
        return
    end
    local zOrder = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
	if globalData.slotRunData.isPortrait then
        zOrder = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM
    end
    G_GetMgr(G_REF.FloatView):creatMachineFloatView(node, zOrder)
end

-- 更新 关卡左边条
function ActivityManagerExSlotLeft:showActivityEntryNode()
    gLobalNoticManager:postNotification(SlotLeftFloatCfg.EVENT_NAME.UPDATE_SLOT_LEFT_ENTRY_VIEW)
end

--只显示一个活动的详情其他活动小图标移动走  展开某一功能
function ActivityManagerExSlotLeft:showEntryNodeInfo(name, func)
    local info = {
        type = SlotLeftFloatCfg.SHOW_TYPE.UNFOLD,
        viewRefKey = name, 
        func = func
    }
    gLobalNoticManager:postNotification(SlotLeftFloatCfg.EVENT_NAME.NOTIFY_SWITCH_LEFT_FLOAT_SHOW_TYPE, info)
end
--重置回小图标状态 收起某一功能
function ActivityManagerExSlotLeft:resetEntryNodeInfo(name, func)
    local info = {
        type = SlotLeftFloatCfg.SHOW_TYPE.FOLD,
        viewRefKey = name, 
        func = func
    }
    gLobalNoticManager:postNotification(SlotLeftFloatCfg.EVENT_NAME.NOTIFY_SWITCH_LEFT_FLOAT_SHOW_TYPE, info)
end

--刷新左边关卡入口 -- 左边条 传入的活动名称被删除掉
function ActivityManagerExSlotLeft:removeActivityEntryNode(name)
    G_GetMgr(G_REF.FloatView):removeSlotLeftEntryNode(name)
end

-- 添加某一功能 气泡（不被左边条listView裁剪)
function ActivityManagerExSlotLeft:addPushViews(_entryNodeName, _pushRootPos, _createCsbPath, _pushViewName)
    local info = {
        viewRefKey = _entryNodeName, 
        viewPath = _createCsbPath,
        bubblePosW = _pushRootPos,
        bubbleName = _pushViewName
    }
    G_GetMgr(G_REF.FloatView):addSlotLeftFloatBubbleView(info)
end
-- 获取某一功能 气泡（不被左边条listView裁剪)
function ActivityManagerExSlotLeft:getPushViews(_entryNodeName, _pushViewName, _newRootPos)
    local info = {
        viewRefKey = _entryNodeName, 
        bubbleName = _pushViewName
    }
    return G_GetMgr(G_REF.FloatView):getSlotLeftFloatBubbleView(info)
end
-- 移除某一功能 气泡（不被左边条listView裁剪)
function ActivityManagerExSlotLeft:removePushViews(_entryNodeName, _pushViewName)
    local info = {
        viewRefKey = _entryNodeName, 
        bubbleName = _pushViewName
    }
    G_GetMgr(G_REF.FloatView):removeSlotLeftFloatBubbleView(info)
end

-- 获取某一功能 是否是展开状态
function ActivityManagerExSlotLeft:getLeftFrameIsOpenProgress(_entryNodeName)
    return G_GetMgr(G_REF.FloatView):checkSlotLeftViewUnfload(_entryNodeName)
end

-- 获取 某一功能 进入大厅是否可自动展开（我看原来也没啥用)
function ActivityManagerExSlotLeft:getAutoChangeToProgress(_entryNodeName)
    -- 记录当前节点是否能够进入关卡后自动展开
    return false
end

-- 获取左边条横向依靠  方向
function ActivityManagerExSlotLeft:getLeftFrameDirection()
    return G_GetMgr(G_REF.FloatView):getSlotLeftDirection()
end

-- 获取 左边条 某一功能入口
function ActivityManagerExSlotLeft:getEntryNode(_entryNodeName, _bCheckSmallEntryNode)
    return G_GetMgr(G_REF.FloatView):getSlotLeftEntryNode(_entryNodeName, _bCheckSmallEntryNode)
end

-- 获取 左边条 某一功能入口 是否显示
function ActivityManagerExSlotLeft:getEntryNodeVisible(_entryNodeName)
    local bShow = G_GetMgr(G_REF.FloatView):checkSlotLeftEntryShow()
    if not bShow then
        return false
    end
    local entryNode = self:getEntryNode(_entryNodeName, true) -- 缩小状态
    if tolua.isnull(entryNode) then
        return false
    end

    return entryNode:isVisible() and entryNode:getParent():isVisible()
end

-- 获取 左边条 箭头 按钮位置 w
function ActivityManagerExSlotLeft:getEntryArrowWorldPos()
    -- return G_GetMgr(G_REF.FloatView):getSlotLeftBtnDownPosW()
    return G_GetMgr(G_REF.FloatView):getSlotTopFlyPosW()
end

-- 获取 左边条 根节点
function ActivityManagerExSlotLeft:getEntryRootNode()
    return  G_GetMgr(G_REF.FloatView):getSlotLeftRootNode()
end

-- 设置 左边条 节点 缩放值
function ActivityManagerExSlotLeft:setSlotFloatLayerLeft(_slotId, _scale)
    local slotId = _slotId
    if not slotId then
        local curMachineData = globalData.slotRunData.machineData or {}
        slotId = curMachineData.p_id
    end
    if not slotId or not _scale then
        return
    end

    local machineNormalId = "1" .. string.sub(tostring(slotId) or "", 2)
    _scale = tonumber(_scale) or 1
    self._slotFloatLeftScaleList[machineNormalId] = _scale
end
function ActivityManagerExSlotLeft:getSlotFloatLayerLeft(_slotId)
    local slotId = _slotId
    if not slotId then
        local curMachineData = globalData.slotRunData.machineData or {}
        slotId = curMachineData.p_id
    end
    if not slotId then
        return
    end
    local machineNormalId = "1" .. string.sub(tostring(slotId) or "", 2)
    return self._slotFloatLeftScaleList[machineNormalId]
end

-- 获取关卡左边条
function  ActivityManagerExSlotLeft:getSlotLeftFloatView()
    return G_GetMgr(G_REF.FloatView):getSlotLeftFloatView()
end

-- 设置 关卡左边条 显隐
function ActivityManagerExSlotLeft:setSlotLeftFloatVisible(_bVisible)
    G_GetMgr(G_REF.FloatView):setSlotLeftFloatVisible(_bVisible)
end