--[[
    聚合 - 转盘cell
]]
local HolidayChallenge_BaseWheelCell = class("HolidayChallenge_BaseWheelCell", BaseView)

function HolidayChallenge_BaseWheelCell:initDatas(_rewardData)
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self.m_rewardData = _rewardData
end

function HolidayChallenge_BaseWheelCell:getCsbName()
    return self.m_activityConfig.RESPATH.WHEEL_CELL
end

function HolidayChallenge_BaseWheelCell:initCsbNodes()
    self.m_sp_cell_jackpot = self:findChild("sp_cell_jackpot")
    self.m_sp_cel_common = self:findChild("sp_cel_common")
    self.m_node_reward = self:findChild("Node_Reward")

    self.m_sp_check = self:findChild("sp_check") --对勾
    util_setCascadeColorEnabledRescursion(self.m_sp_cell_jackpot, true)
end

function HolidayChallenge_BaseWheelCell:initUI()
    HolidayChallenge_BaseWheelCell.super.initUI(self)
    self:addItems()
end

function HolidayChallenge_BaseWheelCell:resetNodeItem()
    self:removeNodeItem()
    self:addItems()
end

function HolidayChallenge_BaseWheelCell:removeNodeItem()
    local nodeItem = self.m_node_reward
    if nodeItem and nodeItem:getChildByTag(10001) then
        nodeItem:removeChildByTag(10001)
    end
end

function HolidayChallenge_BaseWheelCell:addItems()
    local rewardData = self.m_rewardData
    if rewardData then
        local nodeItem = self.m_node_reward
        local specialMark = rewardData.m_specialMark or 0
        local color = rewardData.m_collect and cc.c4b(127, 127, 127, 255) or cc.c4b(255, 255, 255, 255)
        self.m_sp_cell_jackpot:setVisible(specialMark == 1)
        self.m_sp_cel_common:setVisible(specialMark ~= 1)
        self.m_sp_check:setVisible(rewardData.m_collect)
        if specialMark == 1 then
            self.m_sp_cell_jackpot:setColor(color)
        else
            if nodeItem then
                nodeItem:setScale(0.8)
                local coins = rewardData.m_coins or 0
                local items = rewardData.m_items or {}
                local itemData = items[1]

                if coins > 0 then
                    local tempData = gLobalItemManager:createLocalItemData("Coins", coins)
                    local item = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD)
                    if item and nodeItem then
                        item:setTag(10001)
                        nodeItem:addChild(item)
                    end
                elseif itemData then
                    local tempData = gLobalItemManager:createLocalItemData(itemData.p_icon, itemData.p_num, itemData)
                    local item = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD)
                    if item and nodeItem then
                        item:setTag(10001)
                        nodeItem:addChild(item)
                    end
                end
    
                self.m_sp_cel_common:setColor(color)
                util_setCascadeColorEnabledRescursion(self.m_sp_cel_common, true)
            end
        end
    end
end

-- 压暗打勾
function HolidayChallenge_BaseWheelCell:setDarkTick()
    local rewardData = self.m_rewardData
    if rewardData then
        local color = cc.c4b(127, 127, 127, 255)
        local specialMark = rewardData.m_specialMark or 0
        if specialMark == 1 then
            self.m_sp_cell_jackpot:setColor(color)
        else
            self.m_sp_cel_common:setColor(color)
        end
        self.m_sp_check:setVisible(true)
    end
end

-- 重置状态
function HolidayChallenge_BaseWheelCell:resetDarkTick()
    local rewardData = self.m_rewardData
    if rewardData then
        local color = cc.c4b(255, 255, 255, 255)
        local specialMark = rewardData.m_specialMark or 0
        if specialMark == 1 then
            self.m_sp_cell_jackpot:setColor(color)
        else
            self.m_sp_cel_common:setColor(color)
        end
        self.m_sp_check:setVisible(false)
    end
end


function HolidayChallenge_BaseWheelCell:playStart()
    self:runCsbAction("shanshuo", false, nil, 60)
end

function HolidayChallenge_BaseWheelCell:playOver(_cb)
    self:runCsbAction(
        "zhongjiang",
        false,
        function()
            self:setDarkTick()
            if _cb then
                _cb()
            end
        end,
        60
    )
end

return HolidayChallenge_BaseWheelCell
