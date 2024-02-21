--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 16:53:14
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 20:02:23
FilePath: /SlotNirvana/src/common/ActivityManagerExSlotRight.lua
Description: ActivityManager逻辑拆分 (关卡右边条逻辑)
--]]
local ActivityManagerExSlotRight = gLobalActivityManager

-- 右侧条
local tbRightEntryOrders = {
    G_REF.TomorrowGift,
    ACTIVITY_REF.DiamondMania,
    -- ACTIVITY_REF.WildChallenge,
    ACTIVITY_REF.RepartWin,
    ACTIVITY_REF.RepeatFreeSpin,
    ACTIVITY_REF.RepartJackpot,
    ACTIVITY_REF.EchoWin,
    ACTIVITY_REF.BigWin_Challenge,
    G_REF.GrowthFund,
    ACTIVITY_REF.PayRank,
    ACTIVITY_REF.LevelUpPass,
    G_REF.LevelRoad,
    ACTIVITY_REF.BlindBox,
    G_REF.BrokenSaleV2
    -- "Activity_BonusHunt",
    -- "Activity_BonusHuntCoin"
}

--升级，是开启关卡内活动入口 - 右边条
function ActivityManagerExSlotRight:InitMachineRightNode()
    --已开启的活动，添加入口
    local index = 1
    local m_rootNodeRightIsAdd = {}
    -- local datas = globalData.commonActivityData:getActivitys()

    -- for k, value in pairs(datas) do
    --     local data = value
    for i = 1, #tbRightEntryOrders do
        local _ref = tbRightEntryOrders[i]
        local data = nil
        local _mgr = G_GetMgr(_ref)
        if _mgr then
            data = _mgr:getRightFrameRunningData()
        else
            data = G_GetActivityDataByRef(_ref)
        end
        -- if data ~= nil and data:isRunning() and (data.getPositionBar and data:getPositionBar() == 0) then
        if data then
            -- local creatFun = function()
            --     local entryNode = self:createEntryNode(data)
            --     if entryNode ~= nil then
            --         local size = nil
            --         if entryNode.getRightFrameSize then
            --             size = entryNode:getRightFrameSize()
            --         else
            --             size = {widht = 100, height = 80}
            --         end
            --         local nodeData = {
            --             node = entryNode,
            --             name = data:getRefName(),
            --             size = size,
            --             info = data
            --         }
            --         m_rootNodeRightIsAdd[index] = nodeData
            --         index = index + 1
            --     end
            -- end

            -- if _ref == ACTIVITY_REF.BonusHunt or _ref == ACTIVITY_REF.BonusHuntCoin then
            --     local bonusHuntData = G_GetActivityDataByRef(ACTIVITY_REF.BonusHunt)
            --     if not bonusHuntData then
            --         bonusHuntData = G_GetActivityDataByRef(ACTIVITY_REF.BonusHuntCoin)
            --     end
            --     if bonusHuntData and bonusHuntData:isOpen() and bonusHuntData.p_activityId == data.p_id then
            --         if bonusHuntData:isBonusHuntLevel(globalData.slotRunData.machineData.p_id) then
            --             creatFun()
            --         end
            --     end
            -- else
            --     creatFun()
            -- end
            local nodeData = {
                name = data:getRefName(),
                size = {widht = 100, height = 80},
                info = data
            }
            m_rootNodeRightIsAdd[index] = nodeData
            index = index + 1
        end
    end

    return m_rootNodeRightIsAdd
end

--创建关卡内入口Node
function ActivityManagerExSlotRight:createEntryNode(activityData)
    if activityData ~= nil then
        local refName = activityData:getRefName()
        --quest走自己的配置
        -- if refName == ACTIVITY_REF.Quest then
        --     return G_GetMgr(ACTIVITY_REF.Quest):getQuestEntryNode({activityId = activityData:getActivityID()})
        -- end
        --将活动ID传入
        local entryModule = ""
        local activityId = nil
        local _mgr = G_GetMgr(activityData:getRefName())
        if _mgr then
            if _mgr:isCanShowEntry() then
                entryModule = _mgr:getEntryModule()
            end
        else
            entryModule = activityData:getEntryModule()
        end
        if entryModule == "" then
            return nil
        end

        if activityData.getActivityID then
            activityId = activityData:getActivityID()
        end

        --将活动ID传入
        return util_createView(entryModule, {activityId = activityId})
    end

    return nil
end

function ActivityManagerExSlotRight:setSlotFloatLayerRight(_slotId, _scale)
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
    self._slotFloatRightScaleList[machineNormalId] = _scale
end
function ActivityManagerExSlotRight:getSlotFloatLayerRight(_slotId)
    local slotId = _slotId
    if not slotId then
        local curMachineData = globalData.slotRunData.machineData or {}
        slotId = curMachineData.p_id
    end
    if not slotId then
        return
    end
    local machineNormalId = "1" .. string.sub(tostring(slotId) or "", 2)
    return self._slotFloatRightScaleList[machineNormalId]
end

-- 设置 关卡右边条 显隐
function ActivityManagerExSlotRight:setSlotRightFloatVisible(_bVisible)
    local rightParent = gLobalViewManager:getViewLayer():getParent()
    if not rightParent then
        return
    end

    local rightFrameLayer = rightParent:getChildByName("GameRightFrame")
    if rightFrameLayer then
        rightFrameLayer:setVisible(_bVisible and true or false)
    end
end