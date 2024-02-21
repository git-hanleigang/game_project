local BaseView = require("base.BaseView")
local AdsChallengeTaskCellNode = class("AdsChallengeTaskCellNode", BaseView)

function AdsChallengeTaskCellNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function AdsChallengeTaskCellNode:getCsbName()
    if self.m_isPortrait then
        return "Ad_Challenge/csb/Ad_Challenge_Cell_Shu.csb"
    else
        return "Ad_Challenge/csb/Ad_Challenge_Cell.csb"
    end
end
function AdsChallengeTaskCellNode:initCsbNodes()
    self.m_nodeRewardVec = {}
    local beginIndex = 1
    for i = 1, 3 do
        local oneTypeNode = {}
        for j = 1, i do
            oneTypeNode[j] = self:findChild("node_itme" .. beginIndex)
            beginIndex = beginIndex + 1
        end
        self.m_nodeRewardVec[i] = oneTypeNode
    end
    self.m_txt_desc = self:findChild("txt_desc")
    self.m_node_complete = self:findChild("node_complete")
    self.m_node_complete:setVisible(false)

    self.m_nodeVideoIconList = {}
    for m = 1, 2 do
        self.m_nodeVideoIconList[m] = {}
        for n = 1, 4 do
            local node = self:findChild("node_pos" .. m .. "_" .. n)
            if node then
                table.insert(self.m_nodeVideoIconList[m], node)
            end
        end
    end
end

-- 刷新数据
function AdsChallengeTaskCellNode:updateData(_rewardTask)
    local itemDataList = {}
    -- 金币道具
    local coins = _rewardTask.coins
    if coins and tonumber(coins) > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", tonumber(coins))
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList + 1] = itemData
    end

    if _rewardTask.taskItems then
        for i, v in ipairs(_rewardTask.taskItems) do
            local itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            itemDataList[#itemDataList + 1] = itemData
        end
    end

    local choseNodeRewardIndex = #itemDataList <= 3 and #itemDataList or 3
    for i, itemData in ipairs(itemDataList) do
        local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
        if self.m_nodeRewardVec[choseNodeRewardIndex] and self.m_nodeRewardVec[choseNodeRewardIndex][i] then
            self.m_nodeRewardVec[choseNodeRewardIndex][i]:addChild(itemNode)
        end
    end

    self.m_txt_desc:setString("" .. _rewardTask.targetWatchCount .. " REWARD VIDEOS")
    self.m_node_complete:setVisible(
        _rewardTask.collected and not gLobalAdChallengeManager:willDoComplete(_rewardTask.targetWatchCount)
    )

    self.m_videoIconList = {}
    local arr = self.m_nodeVideoIconList[1]
    if _rewardTask.targetWatchCount % 3 == 0 then
        arr = self.m_nodeVideoIconList[2]
    end
    local maxPoint = globalData.AdChallengeData.m_maxWatchCount
    local currentWatchCount = globalData.AdChallengeData:getLastWatchCount()
    local curPoint = globalData.AdChallengeData:getCurrentWatchCount()
    if curPoint <= maxPoint and curPoint - currentWatchCount > 1 then
        currentWatchCount = curPoint - 1
        globalData.AdChallengeData:setLastWatchCount(currentWatchCount)
    end
    for i, v in ipairs(arr) do
        local addCount = globalData.AdChallengeData:getAddCount()
        local videoIconNode = util_createAnimation("Ad_Challenge/csb/Ad_video_icon.csb")
        if videoIconNode then
            v:addChild(videoIconNode)
            if currentWatchCount >= addCount then
                videoIconNode:playAction("idle1", true)
            else
                videoIconNode:playAction("idle2", true)
            end
            self.m_videoIconList[addCount] = videoIconNode
        end
        globalData.AdChallengeData:setAddCount(addCount + 1)
    end
end

function AdsChallengeTaskCellNode:doTaskComplete(_rewardTask)
    self.m_node_complete:setVisible(_rewardTask.collected)
end

function AdsChallengeTaskCellNode:getVideoIconPos()
    local currentWatchCount = globalData.AdChallengeData:getCurrentWatchCount()
    if self.m_videoIconList and self.m_videoIconList[currentWatchCount] then
        local node = self.m_videoIconList[currentWatchCount]
        if node then
            local worldPos = node:convertToWorldSpace(cc.p(node:getPosition()))
            return worldPos
        end
    end
    return nil
end

function AdsChallengeTaskCellNode:refreshUI()
    local currentWatchCount = globalData.AdChallengeData:getCurrentWatchCount()
    if self.m_videoIconList and self.m_videoIconList[currentWatchCount] then
        local node = self.m_videoIconList[currentWatchCount]
        if node then
            node:playAction(
                "start",
                false,
                function()
                    node:playAction("idle1", true)
                end,
                60
            )
        end
    end
end

return AdsChallengeTaskCellNode
