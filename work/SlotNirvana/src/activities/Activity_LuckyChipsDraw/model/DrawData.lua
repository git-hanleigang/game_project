--幸运筹码嘉年华抽奖 ios fix 
local BaseActivityData = require "baseActivity.BaseActivityData"
local DrawCellData = require "activities.Activity_LuckyChipsDraw.model.DrawCellData"
local DrawTaskData = require "activities.Activity_LuckyChipsDraw.model.DrawTaskData"
local DrawData = class("DrawData",BaseActivityData)
DrawData.m_leftChips = nil              --剩余次数
DrawData.m_refreshChips = nil           --刷新需要的次数
DrawData.m_drawCells = nil              --奖励列表
DrawData.m_drawTaskData = nil           --任务数据
DrawData.m_cost = nil                   --每次spin消耗
DrawData.m_round = nil                  --当前轮次
DrawData.m_maxRound = nil               --轮数上限
DrawData.m_isPopView = nil              --是否可以弹窗  

function DrawData:parseData(data,isNetData)
    BaseActivityData.parseData(self,data,isNetData)
    self.m_leftChips = data.leftChips or 0          --剩余次数
    self.m_refreshChips = data.refreshChips or 1    --刷新
    self:parseCellsData(data.drawCells)             --奖励列表
    self:parseTaskData(data.drawTask)               --任务数据
    self.p_openLevel = globalData.constantData.DRAW_OPEN_LEVEL or 20    --开启等级
    self.m_cost = data.cost or 1                    --每次spin消耗
    self.m_round = data.round or 1                  --当前轮次
    self.m_maxRound = data.maxRound or 3            --轮数上限
end

--是否可以刷新
function DrawData:canRefresh()
    if self.m_leftChips>=self.m_refreshChips then
        return true
    end
    return false
end
--是否可以玩小游戏
function DrawData:canPress()
    if self.m_leftChips>=self.m_cost then
        return true
    end
    return false
end
--是否可以领取任务
function DrawData:canCollectTask()
    if self.m_drawTaskData and self.m_drawTaskData:canCollectTask() then
        return true
    end
    return false
end
--是否完成所有轮次
function DrawData:isOverGame()
    if not self.m_round or not self.m_maxRound then
        return false
    end
    if self.m_round > self.m_maxRound then
        return true
    end
    return false
end

function DrawData:checkCompleteCondition()
    return self:isOverGame()
end

function DrawData:isRunning()
    if not DrawData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

--今日任务是否完成
function DrawData:isCollectedTask()
    if self.m_drawTaskData and self.m_drawTaskData.m_collected then
        return true
    end
    return false
end
--奖励列表
function DrawData:parseCellsData(drawCells)
    self.m_drawCells = {}
    if drawCells ~= nil and drawCells ~= "" and #drawCells>0 then
        for i = 1, #drawCells do
            local cell = DrawCellData:create()
            cell:parseData(drawCells[i])
            self.m_drawCells[i]=cell
        end
    end
end
--任务数据
function DrawData:parseTaskData(drawTask)
    self.m_drawTaskData = DrawTaskData:create()
    self.m_drawTaskData:parseData(drawTask)
end
--获取奖励列表
function DrawData:getCellList()
    return self.m_drawCells
end

--获取主题
function DrawData:getActTheme()
    local themeName =  self:getThemeName() or ""
    local actTheme = string.gsub(themeName, ACTIVITY_REF.LuckyChipsDraw, "")
    return actTheme or ""
end

--获取主题 对应的lua 文件 path
function DrawData:getActThemeLuaName(_str)
    _str = _str or ""
    local actTheme = self:getActTheme()
    local appendStr = _str .. actTheme
    if util_getRequireFile(appendStr) then
        return appendStr
    end

    return _str
end

--获取主题 对应的 资源 文件 path
function DrawData:getActThemeResPath(_str)
    _str = _str or "%s"
    local actTheme = self:getActTheme() -- 主题名字
    local resPath = string.format(_str, actTheme)
    if util_IsFileExist(resPath) then
        return resPath
    end

    return nil
end

return DrawData