local CookieCrunchRightBarManager = class("CookieCrunchRightBarManager",util_require("Levels.BaseLevelDialog"))
local CookieCrunchRightBar = require "CodeCookieCrunchSrc.CookieCrunchRightBar"

local JackpotFreeDelay = {28/60, 22/60, 16/60, 10/60}

--[[
    _data = {
        {                
            parent  = cc.Node,       --父节点
            jpIndex = 1,             --奖池索引     
        }
    }
]]
function CookieCrunchRightBarManager:initDatas(_machine, _data)
    self.m_machine  = _machine
    self.m_initData = _data
end

function CookieCrunchRightBarManager:initUI()
    
    self.m_barList = {}
    for _index,_data in ipairs(self.m_initData) do
        local className = _data.jpIndex <= 0 and "CodeCookieCrunchSrc.CookieCrunchLoadingBar" or "CodeCookieCrunchSrc.CookieCrunchJackPotBar"
        _data.barIndex  = _index
        local bar = util_createView(className, self.m_machine, _data)
        _data.parent:addChild(bar)

        bar:resetShow()
        self.m_barList[_index] = bar
    end
end
--[[
    状态相关
]]
function CookieCrunchRightBarManager:upDateProgress(_times, _playAnim)
    for i,_bar in ipairs(self.m_barList) do
        local curState = _bar.m_finishState
        local state    = false
        
        if i <= 4 then
            state = _times >= i
        elseif i < #self.m_barList then
            state = _times == i
        else
            state = _times >= i
        end

        if state ~= curState then
            _bar:setFinishState(state)
            _bar:upDateFinishStateAnim(_playAnim)
        end
    end

    return 0.5
end
--[[
    模式相关
]]
function CookieCrunchRightBarManager:upDateModel(_sModel, _playAnim)
    for i,_bar in ipairs(self.m_barList) do
        local curModel = _bar.m_model
        if _sModel ~= curModel then
            local barData = self.m_initData[i]

            local delayTime = 0
            if _playAnim and barData.jpIndex > 0 then
                delayTime = JackpotFreeDelay[barData.jpIndex]
            end

            self.m_machine:levelPerformWithDelay(delayTime, function()
                _bar:setModel(_sModel)
                _bar:upDateModelAnim(_playAnim)
            end)
        end
    end
end
--[[
    jackpotBar
]]
function CookieCrunchRightBarManager:upDateAllJackpotBarValue(_sModel, _playAnim)
    local isFree = nil

    if nil ~= _sModel then
        isFree = CookieCrunchRightBar.MODEL.FREE == _sModel
    else
        local collectLeftCount = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        isFree = collectTotalCount > 0 and collectLeftCount > 0
    end

    for _index,_data in ipairs(self.m_initData) do
        if _data.jpIndex > 0 then
            local jackpotBar = self.m_barList[_index]
            local vaule = self.m_machine:getCookieCrunchJackpotValue(isFree, _data.jpIndex)
            local delayTime = 0
            if _playAnim then
                delayTime = JackpotFreeDelay[_data.jpIndex]
            end
            
            self.m_machine:levelPerformWithDelay(delayTime, function()
                jackpotBar:updateJackpotInfo(vaule, _playAnim)
            end)
        end
    end
end
function CookieCrunchRightBarManager:getJackpotIndexByTimes(_times)
    local jackpotIndex = #(self.m_barList) - _times + 1
    if jackpotIndex <= #(self.m_machine.m_baseJackpot) then
        -- 处理一下连线次数高于8次的情况
        jackpotIndex = math.max(1, jackpotIndex)
        return jackpotIndex
    end
    return 0
end

--[[
    消除玩法结束相关
]]
-- 消除完毕 开始结算进度
function CookieCrunchRightBarManager:playDownOverAnim(_times, _bTriggerFree,_fun)
    local jpIndex = self:getJackpotIndexByTimes(_times)

    if not _bTriggerFree and jpIndex > 0 then
        local barIndex = 1 + #self.m_barList - jpIndex
        local jackpotbar = self.m_barList[barIndex]
        jackpotbar:playWinAnim(_fun)
    else
        self:clearProgress(_fun)
    end
end

function CookieCrunchRightBarManager:clearProgress(_fun)
    self:upDateProgress(0, true)
    if _fun then
        _fun()
    end
end


return CookieCrunchRightBarManager