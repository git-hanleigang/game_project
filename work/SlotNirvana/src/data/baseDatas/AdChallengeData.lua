--[[
    活动任务数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local AdChallengeData = class("AdChallengeData")
function AdChallengeData:ctor()
    self.m_stageReward = {}
    self.m_currentWatchCount = 0
    self.m_maxWatchCount = 1000000
    self.isDataInit = false
    self.m_isOver = false
    self.m_addCount = 1
    self.m_lastWatchCount = nil
end

function AdChallengeData:parseData(_data)
    self.isDataInit = true 
    self.m_currentCompleteMap  = {}
    self.m_currentCompleteVec   = {}
    self.m_doComplete = false
    if _data.rewards then
        self.m_stageReward = {}
        for index, value in ipairs(_data.rewards) do
            local rewardTask = {}
            rewardTask.coins = value.coins
            if value.items then
                local taskItems = {}
                for i, itemData in ipairs(value.items) do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(itemData, true)
                    if globalData:isCardNovice() and shopItem.p_type == "Package" then
                        -- 新手集卡期不显示 集卡 道具
                    else
                        table.insert(taskItems, shopItem)
                    end
                end
                rewardTask.taskItems = taskItems
            end
            rewardTask.collected = not not value.collect
            rewardTask.targetWatchCount = value.point
            self.m_currentCompleteMap[rewardTask.targetWatchCount] = rewardTask.collected and 1 or 0
            self.m_currentCompleteVec[index] = rewardTask.collected and 1 or 0
            self.m_stageReward[#self.m_stageReward + 1] = rewardTask
        end
    end
    
    if #self.m_stageReward > 0 then
        self.m_maxWatchCount = self.m_stageReward [#self.m_stageReward].targetWatchCount
    end
    self.m_currentWatchCount = _data.points
    for key, value in pairs(self.m_currentCompleteMap) do
        if value == 0 and key <= self.m_currentWatchCount then
            self.m_doComplete = true
        end
    end
    self.m_isOver = not _data.status

    if self.m_lastWatchCount == nil or self.m_lastWatchCount > self.m_currentWatchCount then
        self.m_lastWatchCount = self.m_currentWatchCount
        if self.m_doComplete then
            if self.m_currentWatchCount < self.m_maxWatchCount then
                self.m_lastWatchCount = self.m_lastWatchCount - 1
            end
        end
    end
end

function AdChallengeData:getCurrentWatchCount()
    return self.m_currentWatchCount
end

function AdChallengeData:isHasAdChallengeActivity()
    return globalData.adsRunData.p_isNull == false and globalData.adsRunData:CheckAdByPosition(PushViewPosType.LobbyPos) and self.isDataInit and  not self.m_isOver
end

function AdChallengeData:setIsOver(isOver)
    self.m_isOver = isOver
end

function AdChallengeData:getAddCount()
    return self.m_addCount
end

function AdChallengeData:setAddCount(val)
    self.m_addCount = val
end

function AdChallengeData:getLastWatchCount()
    return self.m_lastWatchCount
end

function AdChallengeData:setLastWatchCount(val)
    self.m_lastWatchCount = val
end

return AdChallengeData