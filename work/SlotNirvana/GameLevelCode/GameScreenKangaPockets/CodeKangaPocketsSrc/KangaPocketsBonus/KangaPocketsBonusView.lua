local KangaPocketsBonusView = class("KangaPocketsBonusView",util_require("Levels.BaseLevelDialog"))
local KangaPocketsPublicConfig = require "KangaPocketsPublicConfig"

KangaPocketsBonusView.RewardName = {
    Grand = "grand",
    Major = "major",
    Minor = "minor",
    Mini = "mini",
    Boost = "boost",
    SuperBoost = "superBoost",
    AwardAll = "wild",
}

KangaPocketsBonusView.RewardNameToJackpotIndex = {
    [KangaPocketsBonusView.RewardName.Grand] = 1,
    [KangaPocketsBonusView.RewardName.Major] = 2,
    [KangaPocketsBonusView.RewardName.Minor] = 3,
    [KangaPocketsBonusView.RewardName.Mini]  = 4,
}
KangaPocketsBonusView.JackpotIndexToRewardName = {
    [1] = KangaPocketsBonusView.RewardName.Grand,
    [2] = KangaPocketsBonusView.RewardName.Major,
    [3] = KangaPocketsBonusView.RewardName.Minor,
    [4] = KangaPocketsBonusView.RewardName.Mini,
}
KangaPocketsBonusView.PickSpineSkinName = {
    [KangaPocketsBonusView.RewardName.Grand]      = "GRAND",
    [KangaPocketsBonusView.RewardName.Major]      = "MAJOR",
    [KangaPocketsBonusView.RewardName.Minor]      = "MINOR",
    [KangaPocketsBonusView.RewardName.Mini]       = "MINI",
    [KangaPocketsBonusView.RewardName.Boost]      = "BOOST",
    [KangaPocketsBonusView.RewardName.SuperBoost] = "SUPERBOOST",
    [KangaPocketsBonusView.RewardName.AwardAll]   = "AWARDALL",
}

function KangaPocketsBonusView:initDatas(_machine)
    self.m_machine = _machine
    self.m_clickState = false
    self.m_bonusData = {
        index = 1,
        process = {},
        extraProcess = {},

    }
    --[[
        m_bonusData = {
            index = 1,         --当前进度
            process = {},      --每次点击结果
            extraProcess = {}, --剩余结果结果
            jackpotBoost = {}, --加成百分比
            jackpotList  = {   --最终奖励
                name = "grand", 
                index = 1, 
                coins = 0
            }
        }
    ]]
    
    self.m_clickList = {}
    self.m_addRewardList = {}
    --[[
        m_addRewardList = {
            {}
        }
    ]]
end
function KangaPocketsBonusView:initUI()
    self:createCsbNode("KangaPockets/GameScreenKangaPocketsBonus.csb")
    self:initJackpotBar()
    self:initTips()

    self.m_kangaPocketsRole = util_createView("CodeKangaPocketsSrc.KangaPocketsRoleSpine", {})
    self:findChild("Node_roleSpine"):addChild(self.m_kangaPocketsRole)
    self.m_kangaPocketsRole:playIdleAnim()
end


function KangaPocketsBonusView:startGame(_data, _fun)
    self.m_bonusData = _data
    self.m_endFun    = _fun
    self.m_clickList = {}
    self.m_addRewardList = {}
    
    self:playPickItemStartAnim(function()
        --播放完start就可以点击了，不用等待idle和over时间线
        self:playTipsStartAnim(function()
            self:startPickItemIdleAnim()
            self:startNextPick()
            self:playTipsIdleAnim(function()
                self:playTipsOverAnim()
            end)
        end)
    end)
end
function KangaPocketsBonusView:endGame()
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGameOver)
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGameOver_2)

    self:stopPickItemIdleAnim()
    --路牌压暗
    self:endGameShowOtherReward(nil)
    --这个动作复用袋鼠跳动的时间线，之后有新增后再新增接口
    self.m_kangaPocketsRole:playCollectBonusYuGaoAnim(nil)
    --袋鼠跳到51帧播放jackpot弹板
    self.m_machine:levelPerformWithDelay(self, 60/30, function()
        if self.m_endFun then
            self.m_endFun()
            self.m_endFun = nil
        end
    end)
end



function KangaPocketsBonusView:startNextPick()
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index > maxIndex then
        self:endGame()
        return
    end
    self.m_clickState = true

end
-- 向场上添加奖励
function KangaPocketsBonusView:addReward(_pickItem, _rewardIndex)
    table.insert(self.m_addRewardList, {_pickItem, _rewardIndex})
    if #self.m_addRewardList > 1 then
        return
    end
    self:addRewardStart(_pickItem, _rewardIndex)
end
function KangaPocketsBonusView:addRewardStart(_pickItem, _rewardIndex)
    local rewardName = self.m_bonusData.process[_rewardIndex]
    local animTime = 0
    if rewardName == self.RewardName.Mini or 
        rewardName == self.RewardName.Minor or  
        rewardName == self.RewardName.Major or 
        rewardName == self.RewardName.Grand then

        local jpIndex = self.RewardNameToJackpotIndex[rewardName]
        local jpCount = self:getRewardCount(rewardName, _rewardIndex)
        local awardAllCount = self:getRewardCount(self.RewardName.AwardAll, _rewardIndex)
        local allJpCount = jpCount + awardAllCount
        animTime = self:playJackpotCollectAnim(_pickItem, jpIndex, allJpCount, true)
    elseif rewardName == self.RewardName.Boost or 
        rewardName == self.RewardName.SuperBoost then

        if 1 == math.random(1, 3) then
            gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_pickItemClick_boost)
        end
        local boostCount = self:getRewardCount(self.RewardName.Boost, _rewardIndex)
        local superBoostCount = self:getRewardCount(self.RewardName.SuperBoost, _rewardIndex)
        local boostValue      = boostCount * self.m_bonusData.jackpotBoost[1]
        local superBoostValue = superBoostCount * self.m_bonusData.jackpotBoost[2]
        local allBoostValue   = boostValue + superBoostValue
        animTime = self:playBoostCollectAnim(_pickItem, allBoostValue)
    elseif rewardName == self.RewardName.AwardAll then 

        if 1 == math.random(1, 3) then
            gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_pickItemClick_awardAll)
        end
        local awardAllCount = self:getRewardCount(self.RewardName.AwardAll, _rewardIndex)
        for rewardName,_jpIndex in pairs(self.RewardNameToJackpotIndex) do
            local jpCount = self:getRewardCount(rewardName, _rewardIndex)
            local allJpCount = jpCount + awardAllCount
            local playSound = 1 == _jpIndex
            local jackpotCollectTime = self:playJackpotCollectAnim(_pickItem, _jpIndex, allJpCount, playSound)
            if 0 ~= animTime then
                animTime = math.min(animTime, jackpotCollectTime)
            else
                animTime = jackpotCollectTime
            end
        end
    end

    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_collectReward)
    self.m_machine:levelPerformWithDelay(self, animTime, function()
        self:addRewardOver()
    end)
end
function KangaPocketsBonusView:addRewardOver()
    table.remove(self.m_addRewardList, 1)
    if #self.m_addRewardList > 0 then
        local pickItem    = self.m_addRewardList[1][1]
        local rewardIndex = self.m_addRewardList[1][2]
        self:addRewardStart(pickItem, rewardIndex)
    else
        local maxIndex = #self.m_bonusData.process
        if self.m_bonusData.index > maxIndex then
            self:startNextPick()
        end
    end
end

function KangaPocketsBonusView:playJackpotCollectAnim(_pickItem, _jpIndex, _progressValue, _playSound)
    local flyTime = 21/60--42/60
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_jackpotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    local endPos   = self:convertToNodeSpace(endWorldPos)
    local flyCsb = util_createAnimation("KangaPockets_Jackpot_twllizi.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)
    
    local particleName = string.format("Particle_%s", self.JackpotIndexToRewardName[_jpIndex])
    local particleNode = flyCsb:findChild(particleName)
    particleNode:setVisible(true)
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            self.m_jackpotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)
            self.m_jackpotBar:setProgress(_jpIndex, _progressValue, true)

            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))

            if _playSound then
                gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_collectRewardOver)
            end
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
    -- 收集完成时不用等待完成 飞到后就可以开始下一步
    local fankuiTime = 30/60
    if _progressValue >= 3 then
        fankuiTime = 0
    end
    return flyTime + fankuiTime
end
function KangaPocketsBonusView:playBoostCollectAnim(_pickItem, _allBoostValue)
    local flyTime = 0.5
    local startPos = util_convertToNodeSpace(_pickItem, self)
    for rewardName,_jpIndex in pairs(self.RewardNameToJackpotIndex) do
        local flyCsb = util_createAnimation("KangaPockets_Jackpot_twllizi.csb")
        self:addChild(flyCsb)
        flyCsb:setPosition(startPos)

        local endWorldPos = self.m_jackpotBar:getBoostFlyEndPos(_jpIndex)
        local endPos   = self:convertToNodeSpace(endWorldPos)
        local particleName = "Particle_boost"
        local particleNode = flyCsb:findChild(particleName)
        particleNode:stopSystem()
        particleNode:setPositionType(0)
        particleNode:setDuration(-1)
        particleNode:resetSystem()
        particleNode:setVisible(true)
        local bUpdate = 1 == _jpIndex
        local distance    = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
        local radius      = distance/2
        local flyAngle    = util_getAngleByPos(startPos, endPos)
        local offsetAngle = endPos.x > startPos.x and 90 or -90
        local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius, flyAngle + offsetAngle) )
        local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius/2, flyAngle + offsetAngle) )
        flyCsb:runAction(cc.Sequence:create(
            -- cc.MoveTo:create(flyTime, endPos),
            cc.BezierTo:create(flyTime, {pos1, pos2, endPos}),
            cc.CallFunc:create(function()
                particleNode:stopSystem()
                util_setCascadeOpacityEnabledRescursion(particleNode, true)
                particleNode:runAction(cc.FadeOut:create(0.5))
                --增幅递增
                self.m_jackpotBar:playBoostAnim(_jpIndex)
                self.m_jackpotBar:setJiaoBiaoValue(_jpIndex, _allBoostValue, true)
                if bUpdate then
                    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_collectBoostRewardOver)
                    self.m_jackpotBar:startJiaoBiaoUpDate()
                end
            end),
            cc.DelayTime:create(0.5),
            cc.RemoveSelf:create()
        ))
    end
    --递增
    local fankuiTime = 1
    return flyTime + fankuiTime
end

--重置ui状态
function KangaPocketsBonusView:resetUi()
    self:pickItemReset()
    self.m_jackpotBar:resetUi()
end
--[[
    翻牌节点
]]
function KangaPocketsBonusView:pickItemReset()
    self.m_pickItems = {}
    for i=1,15 do
        local index = i
        local parent  = self:findChild(string.format("Node__%d", index))
        parent:removeAllChildren()
        local animCsb = util_createAnimation("KangaPockets_Pick.csb")
        parent:addChild(animCsb)
        local spine = util_spineCreate("Socre_KangaPockets_pick",true,true)
        animCsb:findChild("Node_spine"):addChild(spine)
        animCsb.m_spineAnim = spine
        util_setCascadeOpacityEnabledRescursion(animCsb, true)
        self.m_pickItems[index] = animCsb
        -- 点击事件
        local Panel = animCsb:findChild("Panel_click")
        Panel:addTouchEventListener(function(...)
            return self:pickItemClick(index, ...)
        end)
        animCsb:setVisible(false)
    end
end

function KangaPocketsBonusView:playPickItemStartAnim(_fun)
    local playList = {}
    for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
        if 1 == math.random(1,2) then
            table.insert(playList, 1, _pickItem)
        else
            table.insert(playList, _pickItem)
        end
    end

    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_pickItemStart)
    local interval = 0.05
    for i,_pickItem in ipairs(playList) do
        local pickItem  = _pickItem
        local delayTime = (i - 1) * interval
        self.m_machine:levelPerformWithDelay(self, delayTime, function()
            pickItem:setVisible(true)
            util_spinePlay(pickItem.m_spineAnim, "actionframe", false)
            -- util_spineEndCallFunc(pickItem.m_spineAnim, "actionframe", function()
            --     util_spinePlay(pickItem.m_spineAnim, "idle", true)
            -- end)
        end)
    end

    local delayTime = (#playList - 1) * interval + 15/30
    self.m_machine:levelPerformWithDelay(self, delayTime, function()
        _fun()
    end)
end
function KangaPocketsBonusView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    -- 随机三只播放idle
    local fnPlayPickItemIdle = function()
        local playCount = 0
        local idleIndexList = {}
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            local bClick = false
            for i,_pickItemndex in ipairs(self.m_clickList) do
                if _itemIndex == _pickItemndex then
                    bClick = true
                    break
                end
            end
            if not bClick then
                table.insert(idleIndexList, _itemIndex)
            end
        end
        while #idleIndexList > 3 do
            table.remove(idleIndexList, math.random(1, #idleIndexList))
        end
        for i,_pickItemndex in ipairs(idleIndexList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            util_spinePlay(pickItem.m_spineAnim, "idle", false)
        end
    end

    fnPlayPickItemIdle()
    schedule(self:findChild("Node_pick"), function()
        fnPlayPickItemIdle()
    end, 3)
end
function KangaPocketsBonusView:stopPickItemIdleAnim()
    local pickNode = self:findChild("Node_pick")
    pickNode:stopAllActions()
end
function KangaPocketsBonusView:pickItemClick(_index)
    if not self.m_clickState then
        return
    end
    for i,_itemIndex in ipairs(self.m_clickList) do
        if _itemIndex == _index then
            return
        end
    end

    table.insert(self.m_clickList, _index)
    self.m_clickState = false

    self:playTipsOverAnim()
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_pickItemClick)

    local rewardName = self.m_bonusData.process[self.m_bonusData.index]
    local pickItem   = self.m_pickItems[_index]
    self:pickItemChangeRewardVisible(pickItem, rewardName)

    local curRewardIndex = self.m_bonusData.index
    -- 点击反馈 -> 翻转
    -- util_spinePlay(pickItem.m_spineAnim, "shouji", false)
    -- util_spineEndCallFunc(pickItem.m_spineAnim, "shouji", function()
        util_spinePlay(pickItem.m_spineAnim, "switch", false)
        util_spineEndCallFunc(pickItem.m_spineAnim, "switch", function()
            self:addReward(pickItem, curRewardIndex)
        end)
    -- end)
    self.m_bonusData.index = self.m_bonusData.index + 1
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index <= maxIndex then
        self:startNextPick()
    end
end
function KangaPocketsBonusView:pickItemChangeRewardVisible(_pickItem, _rewardName)
    local skinName = self.PickSpineSkinName[_rewardName]
    local spine = _pickItem.m_spineAnim
    spine:setSkin(skinName)
end
function KangaPocketsBonusView:endGameShowOtherReward(_fun)
    -- 已点击但是没获得该类型奖励的jackpot
    for _clickIndex,itemIndex in ipairs(self.m_clickList) do
        local rewardName = self.m_bonusData.process[_clickIndex]
        if rewardName == self.RewardName.Grand or 
            rewardName == self.RewardName.Major or 
            rewardName == self.RewardName.Minor or 
            rewardName == self.RewardName.Mini then 
        
            local bReward = false
            for i,_jpData in ipairs(self.m_bonusData.jackpotList) do
                if _jpData.name == rewardName then
                    bReward = true
                    break
                end
            end
            if not bReward then
                local pickItem = self.m_pickItems[itemIndex]
                util_spinePlay(pickItem.m_spineAnim, "start", false)
            end

        elseif rewardName == self.RewardName.Boost or rewardName == self.RewardName.SuperBoost then
            local pickItem = self.m_pickItems[itemIndex]
            util_spinePlay(pickItem.m_spineAnim, "start", false)
        end
    end
    -- 未点击
    for i,_otherRewardName in ipairs(self.m_bonusData.extraProcess) do
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            local bClick = false
            for _clickIndex,itemIndex in ipairs(self.m_clickList) do
                if _itemIndex == itemIndex then
                    bClick = true
                    break
                end
            end
            if not bClick then
                table.insert(self.m_clickList, _itemIndex)
                self:pickItemChangeRewardVisible(_pickItem, _otherRewardName)
                util_spinePlay(_pickItem.m_spineAnim, "start", false)
                break
            end
        end
    end

    if _fun then
        self.m_machine:levelPerformWithDelay(self, 2, function()
            _fun()
        end)
    end
end
--[[
    奖池
]]
function KangaPocketsBonusView:initJackpotBar()
    self.m_jackpotBar = util_createView("CodeKangaPocketsSrc.KangaPocketsBonus.KangaPocketsBonusJackPotBar", {machine = self.m_machine})
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)
end

--[[
    提示
]]
function KangaPocketsBonusView:initTips()
    self.m_tips = util_createAnimation("KangaPockets_Bonus_tishi.csb")
    self:findChild("Node_tishi"):addChild(self.m_tips)
    self.m_tips:setVisible(false)
end
function KangaPocketsBonusView:playTipsStartAnim(_func)
    self.m_tips:setVisible(true)
    self.m_tips.m_playOver = false
    self.m_tips:runCsbAction("start", false, function()
        _func()
    end)
end
function KangaPocketsBonusView:playTipsIdleAnim(_func)
    self.m_tips:runCsbAction("idle", false, function()
        _func()
    end)
end
function KangaPocketsBonusView:playTipsOverAnim()
    if not self.m_tips:isVisible() or self.m_tips.m_playOver then
        return
    end
    self.m_tips.m_playOver = true
    self.m_tips:runCsbAction("over", false, function()
        self.m_tips:setVisible(false)
        self.m_tips.m_playOver = false
    end)
end

--[[
    处理bonusData数据
]]
function KangaPocketsBonusView:getRewardCount(_rewardName, _limitIndex)
    local count = 0
    for _index,rewardName in ipairs(self.m_bonusData.process) do
        if rewardName == _rewardName and _index <= _limitIndex then
            count = count + 1
        end
    end
    return count
end

return KangaPocketsBonusView