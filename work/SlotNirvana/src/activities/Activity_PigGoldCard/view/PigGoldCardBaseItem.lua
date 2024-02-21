
--[[
Author: dhs
Date: 2022-03-03 21:04:24
LastEditTime: 2022-03-03 21:04:25
LastEditors: your name
Description: 小猪折扣送金卡新活动处理道具item
FilePath: /SlotNirvana/src/activities/Activity_PigGoldCard/view/PigGoldCardBaseItem.lua
--]]
local PigGoldCardBaseItem = class("PigGoldCardBaseItem",BaseView)

function PigGoldCardBaseItem:initDatas(_csbPath)
    PigGoldCardBaseItem.super.initDatas(self)
    self.m_csbPath = _csbPath
end

function PigGoldCardBaseItem:initUI()
    -- 获取活动数据
    PigGoldCardBaseItem.super.initUI(self)
    self.m_nodeItem = self:findChild("node_reward")
    self.m_nodeCheck = self:findChild("sp_check")
    self.m_nodeCheck:setVisible(false)
    self:initView()
end

function PigGoldCardBaseItem:getCsbName()
    return self.m_csbPath
end

function PigGoldCardBaseItem:initView()
    local gameData = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()
    if gameData then
        
        local itemList = gameData:getItems()
        local itemStatus = gameData:getStatus()
        
        -- 加载奖励
        local rewardUIList = {}
        local isVisible = false
        for i = 1, #itemList do
            local data = itemList[i]
            data:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
            rewardUIList[#rewardUIList + 1] = data
            local status = itemStatus[i]
            local itemNode = gLobalItemManager:addPropNodeList(rewardUIList, ITEM_SIZE_TYPE.REWARD, scale, width)
            self.m_nodeItem:addChild(itemNode)
            if status == 1 then
                isVisible = true
            end
            self.m_nodeCheck:setVisible(isVisible)
        end 
    end
end

return PigGoldCardBaseItem