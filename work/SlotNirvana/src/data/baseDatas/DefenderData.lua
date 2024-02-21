--[[
    author:JohnnyFred
    time:2019-11-19 10:25:19
]]
local DefenderCellData = require "data.baseDatas.DefenderCellData"
local DefenderActivityConfig = require "data.defenderData.DefenderActivityConfig"

local BaseActivityData = require "baseActivity.BaseActivityData"
local DefenderData = class("DefenderData", BaseActivityData)

function DefenderData:parseData(data, isNetData)
    BaseActivityData.parseData(self, data)
    self.sequence = data.sequence
    self.stages = data.stages
    self.currentStage = data.currentStage
    self.totalHp = data.totalHp
    self.currentHp = data.currentHp

    self.cells = {}
    for i = 1, #data.cells do
        local cellData = data.cells[i]
        local cellItem = DefenderCellData:create()
        cellItem:parseData(cellData)
        self.cells[i] = cellItem
    end

    self.cellIndex = data.cellIndex
    self.skips = data.skips
    self.rankUp = data.rankUp
    self.lastGame = data.lastGame
    self.difficulty = data.difficulty
    if data.activities then
        self.activities = DefenderActivityConfig:create()
        self.activities:parseData(data.activities)
    end

    self:checkAddExtraCoin(isNetData)
    self:setStageCoins()
    gLobalSendDataManager:getNetWorkDefender():setRoundNum(self.currentStage)
    gLobalSendDataManager:getNetWorkDefender():setSequence(self.sequence)
end

function DefenderData:checkAddExtraCoin(isNetData)
    local activityData = self:getMiddleActivity()
    if isNetData and activityData ~= nil and activityData:isOpen() and tonumber(activityData.value) ~= nil then
        local stageInfo = self:getCurrentStageInfo()
        if stageInfo ~= nil then
            stageInfo.coins = tonumber(stageInfo.coins) * ((100 + tonumber(activityData.value)) / 100)
        end
    end
end

function DefenderData:setStageCoins()
    self.m_stageCoins = 0
    if self.stages and #self.stages > 0 then
        local stage = self.stages[#self.stages]
        if stage.coins then --coins
            self.m_stageCoins = stage.coins
        end
    end
end

--是否是完成状态
function DefenderData:checkTaskDone(taskList)
    local result = true
    for i = 1, #taskList do
        if not taskList[i].completed then
            result = false
            break
        end
    end
    return result
end

function DefenderData:getTaskDone()
    return self.taskDone
end

function DefenderData:setTaskDone(flag)
    self.taskDone = flag
end

function DefenderData:getSequence()
    return self.sequence
end

function DefenderData:getStages()
    return self.stages
end

function DefenderData:getCurrentStage()
    return self.currentStage
end

function DefenderData:getTotalHp()
    return self.totalHp
end

function DefenderData:getCurrentHp()
    return self.currentHp
end

function DefenderData:getCells()
    return self.cells
end

function DefenderData:getCellIndex()
    return self.cellIndex
end

function DefenderData:setCellIndex(index)
    self.cellIndex = index
end

function DefenderData:getSkips()
    return self.skips
end

function DefenderData:getRankUp()
    return self.rankUp
end

function DefenderData:getLastGame()
    return self.lastGame
end

function DefenderData:setEntryNodeState(isOpen)
    self.entryNodeState = isOpen
end

function DefenderData:getEntryNodeState()
    return self.entryNodeState
end

--是否到期  用于活动到期时 商店道具删除的检测逻辑用
function DefenderData:getDistory()
    return self.isDistory
end

function DefenderData:setDistory(flag)
    self.isDistory = flag
end

function DefenderData:getCurrentStageInfo()
    local curStageIndex = self:getCurrentStage()
    local stages = self:getStages()
    return stages[curStageIndex + 1]
end

function DefenderData:getCellInfoByIndex(index)
    local cells = self:getCells()
    local cellInfo = cells[index + 1]
    return cellInfo
end

function DefenderData:getCurrentCellInfo()
    return self:getCellInfoByIndex(self:getCellIndex())
end

function DefenderData:getCurrentPlayerTasks()
    local cells = self:getCells()
    local curCellIndex = self:getCellIndex()
    local cellInfo = cells[curCellIndex + 1]
    local tasks = nil
    if cellInfo ~= nil and cellInfo.type == "task" then
        tasks = cellInfo.tasks
    end
    return tasks
end

function DefenderData:getSmalllAndBigAttackHp()
    local cells = self:getCells()
    local smallHp, bigHp = 0, 0
    for k, v in ipairs(cells) do
        local attackHp = v.attackHp
        if attackHp ~= nil and attackHp ~= 0 then
            local icon = v.icon
            if icon == "Defender_cell_smallAttack" then
                smallHp = attackHp
            elseif icon == "Defender_cell_bigAttack" then
                bigHp = attackHp
            end
        end
    end
    return smallHp, bigHp
end

--更新任务数据
function DefenderData:updateTasks(taskList)
    if not taskList then
        return
    end
    local cell = self:getCurrentCellInfo()
    if cell then
        local oldState = self:checkTaskDone(cell.tasks)
        local newState = self:checkTaskDone(taskList)
        if not oldState and newState then -- 新数据完成 旧数据完成
            self:setTaskDone(true)
        else
            self:setTaskDone(false)
        end
    else
        self:setTaskDone(false)
    end
    for i = 1, #cell.tasks do
        cell.tasks[i]:parseData(taskList[i])
    end
end

function DefenderData:checkCurTaskDone()
    local cell = self:getCurrentCellInfo()
    if cell then
        return self:checkTaskDone(cell.tasks)
    end
    return false
end

function DefenderData:getGotoLevelName()
    local levelName = ""
    local task = self:getCurrentPlayerTasks()
    if task ~= nil then
        for i = 1, #task do
            if task[i] and task[i].recommendGames then
                levelName = task[i].recommendGames
                break
            end
        end
    end
    return levelName
end

function DefenderData:getAddLinkActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.addLink]
    end
    return nil
end

function DefenderData:getMissionActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.mission]
    end
    return nil
end

function DefenderData:getDoubleBuffActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.doubleBuff]
    end
    return nil
end

function DefenderData:getDoubleCardActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.doubleCard]
    end
    return nil
end

function DefenderData:getJuniorActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.junior]
    end
    return nil
end

function DefenderData:getMiddleActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.middle]
    end
    return nil
end

function DefenderData:getSpecialActivity()
    if self.activities and self.activities.m_activityList then
        return self.activities.m_activityList[self.activities.special]
    end
    return nil
end

function DefenderData:checkActivityOpen()
    local update = function()
        if self.activities and self.activities.m_activityList then
            local acitivtyList = self.activities.m_activityList
            for k, v in ipairs(acitivtyList) do
                if not v:isOpen() then
                    if k == self.activities.addLink then --更新大厅link标签
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO)
                    elseif k == self.activities.middle then
                        self.stages = self.data.stages
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, v.activityId)
                end
            end
        end
    end

    if not self:isRunning() then -- 活动关闭时的特殊处理
        if not self:getDistory() then
            self:setDistory(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, self.activityId)

            local m_shopDats = globalData.shopRunData:getShopItemDatas()
            for i = 1, #m_shopDats do
                local shopData = m_shopDats[i]
                if shopData.p_displayList then
                    for j = #shopData.p_displayList, 1, -1 do
                        local tempDis = shopData.p_displayList[j]
                        if tempDis.p_icon == "DefenderSkip" or tempDis.p_icon == "DefenderDoubleTask" then
                            table.remove(shopData.p_displayList, j)
                        end
                    end
                end
            end
            update()
        end
        return
    end
    update()
end

function DefenderData:checkGuideStatus()
    local step = gLobalDataManager:getNumberByField("DEFENDER_GUIDE_STEP", 0)
    if DEFENDER_GUIDE_START == true and step == 0 then
        self:savaDefenderGuideOver()
    end
end

function DefenderData:getDefenderGuideStep()
    local step = gLobalDataManager:getNumberByField("DEFENDER_GUIDE_STEP", 0)
    return step
end

function DefenderData:setDefenderGuideStep(step)
    gLobalDataManager:setNumberByField("DEFENDER_GUIDE_STEP", step)
end

function DefenderData:getDefenderGuideOver()
    local isOver = gLobalDataManager:getBoolByField("DEFENDER_GUIDE_OVER", false)
    return isOver
end

function DefenderData:savaDefenderGuideOver()
    gLobalDataManager:setBoolByField("DEFENDER_GUIDE_OVER", true)
end

return DefenderData
