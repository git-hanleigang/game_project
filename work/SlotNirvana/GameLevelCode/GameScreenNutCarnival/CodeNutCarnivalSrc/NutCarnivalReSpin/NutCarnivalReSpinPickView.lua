--[[
    
]]
local NutCarnivalReSpinPickView = class("NutCarnivalReSpinPickView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

function NutCarnivalReSpinPickView:initUI(_machine)
    self.m_machine = _machine

    self.m_clickState = false
    self.m_clickIndex = 1

    self:createCsbNode("NutCarnival_respin_choose.csb")
    self:initPickItem()
end


function NutCarnivalReSpinPickView:startGame(_data, _fun)
    --[[
        m_bonusData = {
            --最终奖励
            symbolType   = SYMBOL_SpecialBonus_1,
            --剩余结果结果
            extraProcess = {}, 
        }
    ]]
    self.m_bonusData = _data
    self.m_endFun    = _fun
    self:playStartAnim(function()
        self:startPickItemIdleAnim()

        self.m_clickState = true
    end)
end
function NutCarnivalReSpinPickView:endGame()
    self:endGameShowOtherReward(function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinPick_over)
        self:playOverAnim(function()
            if self.m_endFun then
                self.m_endFun()
                self.m_endFun = nil
            end
        end)
    end)
end

--[[
    时间线
]]
function NutCarnivalReSpinPickView:playStartAnim(_fun)
    self:runCsbAction("start", false, _fun)
end
function NutCarnivalReSpinPickView:playOverAnim(_fun)
    self:runCsbAction("over", false, _fun)
end

--[[
    翻牌节点
]]
function NutCarnivalReSpinPickView:initPickItem()
    self.m_pickItems = {}
    for _index=1,5 do
        local itemIndex = _index
        local parent  = self:findChild(string.format("Node_%d", itemIndex))
        local itemCsb = util_createAnimation("NutCarnival_respin_choose_songguo.csb")
        parent:addChild(itemCsb)
        self.m_pickItems[itemIndex] = itemCsb
        -- 点击事件
        local Panel = itemCsb:findChild("Panel_click")
        Panel:addTouchEventListener(function(...)
            return self:pickItemClick(itemIndex, ...)
        end)
    end
end
function NutCarnivalReSpinPickView:resetPickItem()
    for i,_pickItem in ipairs(self.m_pickItems) do
        _pickItem:runCsbAction("idle", false)
        for _index=1,4 do
            _pickItem:findChild(string.format("Node_bonus_%d", _index)):setVisible(false)
        end
    end
end
function NutCarnivalReSpinPickView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    -- 随机三只播放idle
    local fnPlayPickItemIdle = function()
        local playCount = 0
        local idleIndexList = {}
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            table.insert(idleIndexList, _itemIndex)
        end
        while #idleIndexList > 3 do
            local itemIndex = table.remove(idleIndexList, math.random(1, #idleIndexList))
        end
        for i,_pickItemndex in ipairs(idleIndexList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:runCsbAction("idle2", false)
        end
    end

    fnPlayPickItemIdle()
    schedule(self:findChild("Node_pickItem"), function()
        fnPlayPickItemIdle()
    end, 120/60)
end
function NutCarnivalReSpinPickView:stopPickItemIdleAnim()
    local pickNode = self:findChild("Node_pickItem")
    pickNode:stopAllActions()
end
function NutCarnivalReSpinPickView:pickItemClick(_index)
    if not self.m_clickState then
        return
    end
    self.m_clickState = false
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinPick_click)

    self.m_clickIndex = _index
    local pickItem   = self.m_pickItems[_index]
    local symbolType = self.m_bonusData.symbolType
    self:stopPickItemIdleAnim()
    self:playPickItemOpenAnim(pickItem, symbolType, function()
        self:endGame()
    end)
end
function NutCarnivalReSpinPickView:changePickItemRewardVisible(_pickItem, _rewardName)
    local bonusIndex = self.m_machine:getSpecialBonusIndex(_rewardName)
    local awardNodeName = string.format("Node_bonus_%d", bonusIndex)
    local awardNode = _pickItem:findChild(awardNodeName)
    awardNode:setVisible(true)
end
function NutCarnivalReSpinPickView:playPickItemOpenAnim(_pickItem, _rewardName, _fun)
    self:changePickItemRewardVisible(_pickItem, _rewardName)
    _pickItem:runCsbAction("fankui", false, _fun)
end
function NutCarnivalReSpinPickView:endGameShowOtherReward(_fun)
    local soundKey  = string.format("sound_NutCarnival_reSpinPick_itemTrigger_%d", math.random(1, 2))
    local soundName = PublicConfig[soundKey]
    gLobalSoundManager:playSound(soundName)
    
    local otherIndex = 1
    for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
        local bClick   = _itemIndex == self.m_clickIndex
        local animName = bClick and "actionframe" or "yaan"
        if not bClick then
            local otherRewardName = self.m_bonusData.extraProcess[otherIndex]
            self:changePickItemRewardVisible(_pickItem, otherRewardName)
            otherIndex = otherIndex + 1
        end
        _pickItem:runCsbAction(animName, false)
    end
    --收集栏触发
    self.m_machine.m_collectBar:playTriggerAnim(self.m_bonusData.symbolType, _fun)
end

return NutCarnivalReSpinPickView