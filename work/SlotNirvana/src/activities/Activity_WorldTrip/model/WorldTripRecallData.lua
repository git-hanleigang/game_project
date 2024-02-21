-- 新版大富翁数据解析

local ShopItem = util_require("data.baseDatas.ShopItem")
local WorldTripRecallData = class("WorldTripRecallData")

function WorldTripRecallData:ctor()
    self:clearCellIdx()
end

-- message WorldTripRecallGame {
--     optional int32 current = 1; //当前位置
--     repeated WorldTripChapterPosition positionList = 2; //格子信息
--     optional int32 needGems = 3; //复活所需宝石
--     optional bool resurrected = 4; //是否复活过
--     optional WorldTripGameReward winReward = 5; //赢得的奖励
-- }
function WorldTripRecallData:parseData(data)
    if not data then
        return
    end
    self.tarCellIdx = data.current
    self.cells = self:parseCellData(data.positionList)
    self.needGems = data.needGems
    self.bl_resurrected = data.resurrected
    self.rewards = self:parseRewards(data.winReward)

    if self.lastCellIdx == 0 then
        self.lastCellIdx = self.tarCellIdx
    end
    if self.curCellIdx == 0 then
        self.curCellIdx = self.tarCellIdx
    end
    if self.endCellIdx == 0 then
        self.endCellIdx = self.tarCellIdx
    end
end

-- message WorldTripChapterPosition {
--     optional int32 index = 1; //格子索引
--     optional int32 type = 2; //格子类型 0:空 1:金币 2:物品 3:前进 4:后退 5:促销buff
--     optional int32 forwardNum = 3; //前进格子数
--     optional int32 backwardNum = 4; //后退格子数
--    optional WorldTripGameReward reward = 5;//奖励
-- }
function WorldTripRecallData:parseCellData(data)
    if not data then
        return
    end
    local cell_list = {}
    for _idx, _data in ipairs(data) do
        if _data then
            local cell_data = {}
            cell_data.idx = _data.index
            cell_data.cell_type = _data.type
            cell_data.step = 0

            if cell_data.cell_type == 4 then
                cell_data.step = _data.forwardNum
            elseif cell_data.cell_type == 5 then
                cell_data.step = _data.backwardNum
            end
            cell_data.rewards = self:parseRewards(_data.reward)
            cell_list[_idx] = cell_data
        end
    end

    return cell_list
end

-- message WorldTripGameReward {
--     optional int64 coins = 1; //金币奖励
--     repeated ShopItem itemList = 2; //物品奖励
-- }
function WorldTripRecallData:parseRewards(data)
    if not data then
        return
    end
    local rewards = {coins = 0, items = {}}
    if data then
        if data.coins and tonumber(data.coins) > 0 then
            rewards.coins = tonumber(data.coins)
        end
        if data.itemList and table.nums(data.itemList) > 0 then
            for _, item_data in ipairs(data.itemList) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data)
                table.insert(rewards.items, shopItem)
            end
        end
    end
    return rewards
end

function WorldTripRecallData:setRouters(routerList)
    if routerList and table.nums(routerList) > 0 then
        for idx, pos in ipairs(routerList) do
            if idx then
                local cell_data = self:getCellData(idx)
                if cell_data then
                    cell_data.pPos = pos
                end
            end
        end
    end
end

------------------------------------    游戏进度数据    ------------------------------------
-- 小游戏掷骰子结果
function WorldTripRecallData:parseRecallPlayData(data)
    if not data then
        return
    end
    self.tarCellIdx = data.current

    if data.needGems and data.needGems > 0 then
        self.needGems = tonumber(data.needGems)
    end
    if data.resurrected ~= nil then
        self.bl_resurrected = data.resurrected
    end

    if data.winReward and table.nums(data.winReward) > 0 then
        self.rewards = self:parseRewards(data.winReward)
    end
end

------------------------------------    获取游戏数据    ------------------------------------

-- 设置当前格子id
function WorldTripRecallData:setCurIdx(_idx)
    local cells_max = self:getTotalCells()
    if _idx > cells_max then
        _idx = _idx - cells_max
    end
    self.curCellIdx = _idx
end

-- 获取当前格子id
function WorldTripRecallData:getCurIdx()
    return self.curCellIdx
end

function WorldTripRecallData:setLastIndex(_index)
    self.lastCellIdx = _index
end
-- 上一次移动位置
function WorldTripRecallData:getLastIdx()
    return self.lastCellIdx
end

-- 获取下一个路点
function WorldTripRecallData:getNextRouter()
    if self.curCellIdx == self.tarCellIdx then
        return false
    end
    local cur_idx = self:getCurIdx()
    local next_idx = cur_idx + 1
    local cells_max = self:getTotalCells()
    if next_idx > cells_max then
        next_idx = next_idx - cells_max
    end
    local cell_data = self:getCellData(next_idx)
    return cell_data
end

function WorldTripRecallData:getEndIdx()
    return self.endCellIdx
end

function WorldTripRecallData:getTargetIdx()
    return self.tarCellIdx
end

function WorldTripRecallData:resetCellIdx()
    self.lastCellIdx = self.tarCellIdx
    self.curCellIdx = self.tarCellIdx
    self.endCellIdx = self.tarCellIdx
end

-- 当前步骤的奖励是否已经获取
function WorldTripRecallData:isCellComplete(_idx)
    if not _idx or _idx <= 0 then
        return false
    end
    local cur_idx = self:getCurIdx()
    return cur_idx >= _idx
end

-- {
--     idx = 1,
--     cell_type = 1,
--     step = 0,
--     rewards = {coins = 0, items = {}}
-- }
function WorldTripRecallData:getCellData(idx)
    if self.cells and self.cells[idx] then
        return self.cells[idx]
    end
end

function WorldTripRecallData:getTotalCells()
    if not self.cells then
        return 0
    end
    return #self.cells
end

function WorldTripRecallData:getCurCellData()
    local cur_idx = self:getCurIdx()
    local cur_cell = self:getCellData(cur_idx)
    if cur_cell then
        return cur_cell
    end
end

-- 获取小游戏数据
function WorldTripRecallData:getRecallData()
    return self.recallData
end

-- 获取小游戏奖励
function WorldTripRecallData:getRecallReward()
    return self.rewards
end

function WorldTripRecallData:clearCellIdx()
    self.curCellIdx = 0
    self.lastCellIdx = 0
    self.endCellIdx = 0
    self.tarCellIdx = 0
end

return WorldTripRecallData
