--[[--
    章节数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local RedecorNodeData = import(".RedecorNodeData")
local RedecorChapterData = class("RedecorChapterData")

-- message RedecorateChapter {
--     optional int64 rewardCoins = 1;    //章节奖励基础金币
--     repeated ShopItem rewardItems = 2;    //章节奖励物品
--     repeated RedecorateNode nodes = 3;    //节点列表
--     optional int32 nodeNum = 4;    //节点数量
--   }
function RedecorChapterData:parseData(_netData)
    self.p_coins = tonumber(_netData.rewardCoins)

    self.p_rewardItems = {}
    if _netData.rewardItems and next(_netData.rewardItems) and #_netData.rewardItems > 0 then
        for i = 1, #_netData.rewardItems do
            local rData = ShopItem:create()
            rData:parseData(_netData.rewardItems[i])
            table.insert(self.p_rewardItems, rData)
        end
    end

    self.p_nodes = {}
    if _netData.nodes and next(_netData.nodes) and #_netData.nodes > 0 then
        for i = 1, #_netData.nodes do
            local rData = RedecorNodeData:create()
            rData:parseData(_netData.nodes[i])
            table.insert(self.p_nodes, rData)
        end
    end

    self.p_nodeNum = _netData.nodeNum
end

-- 章节奖励基础金币
function RedecorChapterData:getCoins()
    return self.p_coins
end
-- 章节奖励物品
function RedecorChapterData:getRewardItems()
    return self.p_rewardItems
end
-- 节点列表
function RedecorChapterData:getNodes()
    return self.p_nodes
end
-- 节点数量
function RedecorChapterData:getNodeNum()
    return self.p_nodeNum
end

function RedecorChapterData:isChapterComplete()
    if self.p_nodes and #self.p_nodes > 0 then
        for i = 1, #self.p_nodes do
            if not self.p_nodes[i]:isComplete() then
                return false
            end
        end
    end
    return true
end

-- 获得章节家具：已解锁，未完成的
function RedecorChapterData:getCurChapterWaitNodes()
    -- 如果有未选择风格的家具，暂时用此家具数据
    local unSelStyleNodes = self:getUnSelectStyleNodes()
    if unSelStyleNodes and #unSelStyleNodes > 0 then
        return unSelStyleNodes
    end
    local furnitures = {}
    local cNodes = self:getNodes()
    if cNodes and #cNodes > 0 then
        for i = 1, #cNodes do
            local cNode = cNodes[i]
            if not cNode:isComplete() and cNode:getOpen() then
                table.insert(furnitures, cNode)
            end
        end
    end
    return furnitures
end

-- 获得章节家具：所有未完成的
function RedecorChapterData:geUnCompletedNodeNum()
    local stepCount = 0
    local cNodes = self:getNodes()
    if cNodes and #cNodes > 0 then
        for i = 1, #cNodes do
            local cNode = cNodes[i]
            if not cNode:isComplete() then
                stepCount = stepCount + 1
            end
        end
    end
    return stepCount
end

-- 获得章节家具：所有完成的
function RedecorChapterData:getCompletedNodeNum()
    local stepCount = 0
    local cNodes = self:getNodes()
    if cNodes and #cNodes > 0 then
        for i = 1, #cNodes do
            local cNode = cNodes[i]
            if cNode:isComplete() then
                stepCount = stepCount + 1
            end
        end
    end
    return stepCount
end

-- 获得章节中 已完成已开启，但是没有选择风格的家具，在打开装修主界面的时候优先弹出
function RedecorChapterData:getUnSelectStyleNodes()
    local nodes = {}
    local cNodes = self:getNodes()
    if cNodes and #cNodes > 0 then
        for i = 1, #cNodes do
            local cNode = cNodes[i]
            if cNode:isComplete() and cNode:getOpen() and cNode:getCurStyle() == -1 and cNode:getRefName() ~= "qingLi" then
                table.insert(nodes, cNode)
            end
        end
    end
    return nodes
end

return RedecorChapterData
