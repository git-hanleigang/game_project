local NutCarnivalPickGameView = class("NutCarnivalPickGameView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

function NutCarnivalPickGameView:initDatas(_machine)
    self.m_machine = _machine
    self.m_clickState = false
    self.m_bonusData = {
        index        = 1,
        process      = {},
        extraProcess = {},
        award        = {
            name = "",
            coins = 0
        },
    }
    --[[
        m_bonusData = {
            index = 1,         --当前进度
            process = {},      --每次点击结果
            extraProcess = {}, --剩余结果结果
            award  = {         --最终奖励
                name = "grand",
                coins = 0
            }
        }
    ]]
    
    self.m_clickIndexList = {}
    self.m_awardFinishCount     = 0
    self.m_addRewardList  = {}
    --随机抖动的数量
    self.m_shakeCount = 0
    --[[
        m_addRewardList = {
            {}
        }
    ]]
end
function NutCarnivalPickGameView:initUI()
    self:createCsbNode("NutCarnival/NutCarnivalJackpot.csb")
    
    self.m_pickGameJackpotBar = util_createView("CodeNutCarnivalSrc.NutCarnivalPickGame.NutCarnivalPickGameJackPotBar", self.m_machine)
    self:findChild("Node_jackpotBar"):addChild(self.m_pickGameJackpotBar)

    self:initPickItem()
end


--重置ui状态
function NutCarnivalPickGameView:resetUi()
    self:resetPickItem()
    self.m_pickGameJackpotBar:resetUi()
end
function NutCarnivalPickGameView:startGame(_data, _fun)
    self.m_bonusData = _data
    self.m_endFun    = _fun
    self.m_clickIndexList = {}
    self.m_awardFinishCount = 0
    self.m_addRewardList    = {}
    
    self:startCountDownPickItemIdle()
    self:startPickItemIdleAnim()
    self:startNextPick()
end
function NutCarnivalPickGameView:endGame()
    self:stopPickItemIdleAnim()
    self:stopCountDownPickItemIdle()
    self:endGameShowOtherReward(function()
        if self.m_endFun then
            self.m_endFun()
            self.m_endFun = nil
        end
    end)
end



function NutCarnivalPickGameView:startNextPick()
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index > maxIndex then
        self.m_machine:levelPerformWithDelay(self, 0.5, function()
            self:endGame()
        end)
        return
    end
    self.m_clickState = true
end
-- 向场上添加奖励
function NutCarnivalPickGameView:addReward(_pickItem, _rewardIndex)
    table.insert(self.m_addRewardList, {_pickItem, _rewardIndex})
    if #self.m_addRewardList > 1 then
        return
    end
    self:addRewardStart(_pickItem, _rewardIndex)
end
function NutCarnivalPickGameView:addRewardStart(_pickItem, _rewardIndex)
    local rewardName = self.m_bonusData.process[_rewardIndex]
    local jpIndex = self.m_machine.JackpotTypeToIndex[rewardName]
    local jpCount = self:getRewardCount(rewardName, _rewardIndex)
    self:playJackpotCollectAnim(_pickItem, jpIndex, jpCount, function()
        self:addRewardOver()
    end)
end
function NutCarnivalPickGameView:addRewardOver()
    self.m_awardFinishCount = self.m_awardFinishCount + 1
    table.remove(self.m_addRewardList, 1)
    if #self.m_addRewardList > 0 then
        local pickItem    = self.m_addRewardList[1][1]
        local rewardIndex = self.m_addRewardList[1][2]
        self:addRewardStart(pickItem, rewardIndex)
    else
        local maxIndex = #self.m_bonusData.process
        if self.m_bonusData.index > maxIndex and self.m_awardFinishCount >= maxIndex then
            self:startNextPick()
        end
    end
end

function NutCarnivalPickGameView:playJackpotCollectAnim(_pickItem, _jpIndex, _progressValue, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_itemFly)
    local flyTime = 21/60
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_pickGameJackpotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    local endPos      = self:convertToNodeSpace(endWorldPos)
    local flyCsb = util_createAnimation("NutCarnival_lizi.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)
    local particleName = "Particle_1"
    local particleNode = flyCsb:findChild(particleName)
    particleNode:setVisible(true)
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_itemFlyOver)
            self.m_pickGameJackpotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)

            _fun()

            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end

--[[
    翻牌节点
]]
function NutCarnivalPickGameView:initPickItem()
    self.m_pickItems = {}
    for _index=1,15 do
        local itemIndex = _index
        local parent  = self:findChild(string.format("Node_%d", itemIndex))
        local itemCsb = util_createAnimation("NutCarnival_jackpot_huasheng.csb")
        parent:addChild(itemCsb)
        self.m_pickItems[itemIndex] = itemCsb
        -- 点击事件
        local Panel = itemCsb:findChild("Panel_click")
        Panel:addTouchEventListener(function(...)
            return self:pickItemClick(itemIndex, ...)
        end)
    end
end
function NutCarnivalPickGameView:resetPickItem()
    for i,_pickItem in ipairs(self.m_pickItems) do
        _pickItem:runCsbAction("normal", false)
        for k,_jpType in pairs(self.m_machine.ServerJackpotType) do
            local awardNodeName = _jpType
            local awardNode = _pickItem:findChild(awardNodeName)
            awardNode:setVisible(false)
            --压暗
            local darkNodeName = string.format("Node_%s", _jpType)
            _pickItem:findChild(darkNodeName):setVisible(false)
        end
    end
end
--[[
    5s无操作播放道具抖动
]]
function NutCarnivalPickGameView:startCountDownPickItemIdle()
    self:stopCountDownPickItemIdle()
    self.m_shakeCount = 0
    local time = 5
    self.m_updatePickItemIdle = schedule(self,function()
        time = time - 1
        if time <= 0 then
            self:stopCountDownPickItemIdle()
            self.m_shakeCount = 3
        end
    end, 1)
end
function NutCarnivalPickGameView:stopCountDownPickItemIdle()
    if self.m_updatePickItemIdle then
        self:stopAction(self.m_updatePickItemIdle)
        self.m_updatePickItemIdle = nil
    end
end
function NutCarnivalPickGameView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    -- 随机三只播放idle
    local fnPlayPickItemIdle = function()
        local playCount = 0
        local idleIndexList = {}
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            local bClick = false
            for i,_pickItemndex in ipairs(self.m_clickIndexList) do
                if _itemIndex == _pickItemndex then
                    bClick = true
                    break
                end
            end
            if not bClick then
                table.insert(idleIndexList, _itemIndex)
            end
        end
        local commonList = {}
        while #idleIndexList > self.m_shakeCount do
            local itemIndex = table.remove(idleIndexList, math.random(1, #idleIndexList))
            table.insert(commonList, itemIndex)
        end
        for i,_pickItemndex in ipairs(commonList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:runCsbAction("idle", true)
        end
        for i,_pickItemndex in ipairs(idleIndexList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:runCsbAction("idle2", false)
        end
    end

    fnPlayPickItemIdle()
    schedule(self:findChild("Node_pickItem"), function()
        fnPlayPickItemIdle()
    end, 159/60)
end
function NutCarnivalPickGameView:stopPickItemIdleAnim()
    local pickNode = self:findChild("Node_pickItem")
    pickNode:stopAllActions()
end
function NutCarnivalPickGameView:pickItemClick(_index)
    if not self.m_clickState then
        return
    end
    for i,_itemIndex in ipairs(self.m_clickIndexList) do
        if _itemIndex == _index then
            return
        end
    end
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_itemClick)
    table.insert(self.m_clickIndexList, _index)
    self.m_clickState = false
    local rewardName = self.m_bonusData.process[self.m_bonusData.index]
    local pickItem   = self.m_pickItems[_index]
    local curRewardIndex  = self.m_bonusData.index
    self.m_bonusData.index = self.m_bonusData.index + 1
    --翻开奖励
    self:playPickItemOpenAnim(pickItem, rewardName, function()
        self:addReward(pickItem, curRewardIndex)
    end)
    --倒计时重置
    self:startCountDownPickItemIdle()
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index <= maxIndex then
        self:startNextPick()
    end
end
function NutCarnivalPickGameView:changePickItemRewardVisible(_pickItem, _rewardName)
    local awardNodeName = _rewardName
    local awardNode = _pickItem:findChild(awardNodeName)
    awardNode:setVisible(true)
    --压暗
    local darkNodeName = string.format("Node_%s", _rewardName)
    _pickItem:findChild(darkNodeName):setVisible(true)
end
function NutCarnivalPickGameView:playPickItemOpenAnim(_pickItem, _rewardName, _fun)
    self:changePickItemRewardVisible(_pickItem, _rewardName)
    _pickItem:runCsbAction("fankui", false, _fun)
end

function NutCarnivalPickGameView:endGameShowOtherReward(_fun)
    local fankuiTime = 63/60
    local darkTime   = 21/60
    local actionTime = 120/60
    local rewardSymbolDelay = fankuiTime + darkTime
    --奖池触发
    local jpIndex = self.m_machine.JackpotTypeToIndex[self.m_bonusData.award.name]
    self.m_machine:levelPerformWithDelay(self, rewardSymbolDelay, function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_jackpotBarTrigger)
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_itemTrigger)
        self.m_pickGameJackpotBar:playProgressFinishAnim(jpIndex, 3)
    end)
    -- 已点击
    for _clickIndex,itemIndex in ipairs(self.m_clickIndexList) do
        local rewardName = self.m_bonusData.process[_clickIndex]
        local bReward    = rewardName == self.m_bonusData.award.name
        local animName   = bReward and "actionframe" or "yaan"
        local pickItem   = self.m_pickItems[itemIndex]
        local delayTime  = bReward and rewardSymbolDelay or fankuiTime
        self.m_machine:levelPerformWithDelay(self, delayTime, function()
            pickItem:runCsbAction(animName, false)
        end)
    end
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_itemDark)
    -- 未点击 翻开->爆点->压暗
    for i,_otherRewardName in ipairs(self.m_bonusData.extraProcess) do
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            local bClick = false
            for _clickIndex,itemIndex in ipairs(self.m_clickIndexList) do
                if _itemIndex == itemIndex then
                    bClick = true
                    break
                end
            end
            if not bClick then
                table.insert(self.m_clickIndexList, _itemIndex)
                self:playPickItemOpenAnim(_pickItem, _otherRewardName, function()
                    _pickItem:runCsbAction("yaan", false)
                end)
                break
            end
        end
    end
    local delayTime = fankuiTime + darkTime + actionTime
    self.m_machine:levelPerformWithDelay(self, delayTime, function()
        _fun()
    end)
end
--[[
    奖池
]]
function NutCarnivalPickGameView:initJackpotBar()
    self.m_pickGameJackpotBar = util_createView("CodeKangaPocketsSrc.KangaPocketsBonus.KangaPocketsBonusJackPotBar", {machine = self.m_machine})
    self:findChild("Node_Jackpot"):addChild(self.m_pickGameJackpotBar)
end

--[[
    处理bonusData数据
]]
function NutCarnivalPickGameView:getRewardCount(_rewardName, _limitIndex)
    local count = 0
    for _index,rewardName in ipairs(self.m_bonusData.process) do
        if rewardName == _rewardName and _index <= _limitIndex then
            count = count + 1
        end
    end
    return count
end

return NutCarnivalPickGameView