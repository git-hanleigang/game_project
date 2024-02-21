local LeprechaunsCrockBonusView = class("LeprechaunsCrockBonusView",util_require("Levels.BaseLevelDialog"))

LeprechaunsCrockBonusView.RewardName = {
    Grand = "Grand",
    Mega = "Mega",
    Major = "Major",
    Minor = "Minor",
    Mini = "Mini",
    Boost = "Boost",
    SuperBoost = "SuperBoost",
    MegaBoost = "MegaBoost",
}

LeprechaunsCrockBonusView.RewardNameToJackpotIndex = {
    [LeprechaunsCrockBonusView.RewardName.Grand] = 1,
    [LeprechaunsCrockBonusView.RewardName.Mega] = 2,
    [LeprechaunsCrockBonusView.RewardName.Major] = 3,
    [LeprechaunsCrockBonusView.RewardName.Minor] = 4,
    [LeprechaunsCrockBonusView.RewardName.Mini] = 5,
}
LeprechaunsCrockBonusView.PickItemName1 = {
    [LeprechaunsCrockBonusView.RewardName.Grand] = "Node_grand",
    [LeprechaunsCrockBonusView.RewardName.Mega] = "Node_mega",
    [LeprechaunsCrockBonusView.RewardName.Major] = "Node_major",
    [LeprechaunsCrockBonusView.RewardName.Minor] = "Node_minor",
    [LeprechaunsCrockBonusView.RewardName.Mini] = "Node_mini",
}
LeprechaunsCrockBonusView.PickItemName2 = {
    [LeprechaunsCrockBonusView.RewardName.Boost] = "Node_credit",
    [LeprechaunsCrockBonusView.RewardName.SuperBoost] = "Node_credit_0",
    [LeprechaunsCrockBonusView.RewardName.MegaBoost] = "Node_credit_1",
}
LeprechaunsCrockBonusView.PickItemName3 = {
    [LeprechaunsCrockBonusView.RewardName.Grand] = "Particle_grand",
    [LeprechaunsCrockBonusView.RewardName.Mega] = "Particle_mega",
    [LeprechaunsCrockBonusView.RewardName.Major] = "Particle_major",
    [LeprechaunsCrockBonusView.RewardName.Minor] = "Particle_minor",
    [LeprechaunsCrockBonusView.RewardName.Mini] = "Particle_mini",
}
function LeprechaunsCrockBonusView:initDatas(_machine)
    self.m_machine = _machine
    self.m_clickState = false
    self.m_bonusData = {}
    self.m_clickList = {}
    self.m_addRewardList = {}
    self.m_removeLevelNums = 0
    self.m_removeLevelFlyNums = 5
    self.m_playEffectOverIndex = 0
end
function LeprechaunsCrockBonusView:initUI()
    self:createCsbNode("LeprechaunsCrock_dfdc_qipan.csb")
    self:initPickItem()
    self:initJackpotBar()
    self:initTips()

    -- 角色
    self.m_RoleSpine = util_spineCreate("LeprechaunsCrock_juese",true,true)
    self:findChild("Node_juese"):addChild(self.m_RoleSpine)
    util_spinePlay(self.m_RoleSpine, "idleframe2", true)

    -- boost框
    self.m_boostNode = util_createAnimation("LeprechaunsCrock_dfdc_Boost.csb")
    self:findChild("Node_Boost"):addChild(self.m_boostNode)
    self.m_boostNode:setVisible(false)
end

--[[
    设置boost 加成数值
]]
function LeprechaunsCrockBonusView:setBoostNum(_num)
    self.m_boostNode:findChild("m_lb_num"):setString("+"..(_num * 100).."%")
end

function LeprechaunsCrockBonusView:startGame(_data, _fun)
    self.m_bonusData = _data
    self.m_endFun = _fun
    self.m_clickList = {}
    self.m_addRewardList = {}
    
    --播放完start就可以点击了，不用等待idle和over时间线
    self:playTipsStartAnim(function()
        self.m_clickState = true
        self:setBoostNum(0)
        self:playTipsIdleAnim(function()
            self:playTipsOverAnim()
        end)
    end)
end

function LeprechaunsCrockBonusView:endGame()
    self:stopPickItemIdle()
    --没有中奖的pickitem 压暗
    self:endGameShowOtherReward()
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpot_win)

    local jpIndex = 5
    for _jackpotName, _ in pairs(self.m_bonusData.getJackpot) do
        jpIndex = self.RewardNameToJackpotIndex[_jackpotName]
    end
    self.m_jackpotBar:playJackpotWinEffect(jpIndex)
    util_spinePlay(self.m_RoleSpine, "actionframe3", false)
    util_spineEndCallFunc(self.m_RoleSpine, "actionframe3", function()
        util_spinePlay(self.m_RoleSpine, "idleframe2", true)
    end)

    --玩法结束
    self.m_machine:waitWithDelay(60/30, function()
        self:playBoostFlyEffect(jpIndex, function()
            if self.m_endFun then
                self.m_endFun()
                self.m_endFun = nil
            end
        end)
    end)
end

--[[
    boost结算
]]
function LeprechaunsCrockBonusView:playBoostFlyEffect(_jpIndex, _func)
    if self.m_boostNode:isVisible() then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_boost_flyTo_jackpot)
        self.m_boostNode:runCsbAction("actionframe", false, function()
            self:playBoostNodeFlyEffect(_jpIndex, _func)
        end)
    else
        -- 没有加成 直接开始弹jackpot弹板
        if _func then
            _func()
        end
    end
end

--[[
    boost 飞
]]
function LeprechaunsCrockBonusView:playBoostNodeFlyEffect(_jpIndex, _func)
    local flyTime = 30/60
    local startPos = util_convertToNodeSpace(self.m_boostNode, self)
    local endPos = util_convertToNodeSpace(self.m_jackpotBar:getWinJackpotParentNode(_jpIndex), self)
    local flyCsb = util_createAnimation("LeprechaunsCrock_dfdc_Boost.csb")
    self:addChild(flyCsb)

    -- 粒子
    local ParticleNode = util_createAnimation("LeprechaunsCrock_dfdc_boost_lizi.csb")
    flyCsb:addChild(ParticleNode, -1)
    local Particle = ParticleNode:findChild("Particle_1")
    Particle:setPositionType(0)
    Particle:setDuration(-1)
    Particle:resetSystem()

    flyCsb:findChild("m_lb_num"):setString(self.m_boostNode:findChild("m_lb_num"):getString())
    flyCsb:setPosition(startPos)
    flyCsb:runCsbAction("fly", false)
    self.m_boostNode:findChild("m_lb_num"):setVisible(false)

    flyCsb:runAction(cc.Sequence:create(
        cc.DelayTime:create(10/60),
        cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 2),
        cc.DelayTime:create(13/60),
        cc.CallFunc:create(function()
            self.m_boostNode:runCsbAction("over", false, function()
                self.m_boostNode:setVisible(false)
            end)
            self.m_jackpotBar:playJackpotShengJiEffect(_jpIndex)

            -- jackpot的位置显示成 最终的赢钱
            self:changeJackpotWinCoins(_jpIndex)
            self:playJackpotWinFlyEffect(_jpIndex, _func)

            Particle:stopSystem()
        end),
        cc.DelayTime:create(30/60),
        cc.RemoveSelf:create()
    ))
end

--[[
    有加成的时候  加成飞到jackpot 修改jackpot的钱
]]
function LeprechaunsCrockBonusView:changeJackpotWinCoins(_jpIndex )
    self.m_jackpotWinCoins = util_createAnimation("LeprechaunsCrock_jackpot_dfdc_fly.csb")
    self.m_jackpotBar:getWinJackpotParentNode(_jpIndex):addChild(self.m_jackpotWinCoins)
    self.m_jackpotWinCoins:findChild("m_lb_coins_1"):setString(util_formatCoins(self.m_bonusData.bonusCoins, 20))
    self.m_jackpotWinCoins:setVisible(false)
end

-- 金币跳动
function LeprechaunsCrockBonusView:jumpCoins(_node, _coins)
    local curCoins = 0
    -- 每秒60帧
    local coinRiseNum =  (_coins - 0) / (0.4 * 60)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    self.m_updateCoinsAction = schedule(self, function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _coins and curCoins or _coins
        
        local sCoins = curCoins
        if _node and _node.findChild then--加速的时候 node节点可能会被提前移除
            _node:findChild("m_lb_coins_1"):setString(util_formatCoins(sCoins, 20))
        end

        if curCoins >= _coins then
            self:stopUpDateCoins()
        end
    end,0.008)
end

function LeprechaunsCrockBonusView:stopUpDateCoins()
    if self.m_updateCoinsAction then
        self:stopAction(self.m_updateCoinsAction)
        self.m_updateCoinsAction = nil
    end
end

--[[
    重置jackpot 的钱
]]
function LeprechaunsCrockBonusView:resetJackpotWinCoins( )
    if self.m_jackpotWinCoins then
        self.m_jackpotWinCoins:removeFromParent()
        self.m_jackpotWinCoins = nil
    end

    -- 显示原来的Jackopt数值
    if self.m_oldJackpotCoinsNode then
        self.m_oldJackpotCoinsNode:setVisible(true)
    end
end

--[[
    jackpot的赢钱 飞到赢钱区
]]
function LeprechaunsCrockBonusView:playJackpotWinFlyEffect(_jpIndex, _func)
    local flyTime = 30/60
    local startPos = util_convertToNodeSpace(self.m_jackpotBar:getWinJackpotParentNode(_jpIndex), self)
    local endPos = util_convertToNodeSpace(self.m_machine.m_bottomUI.m_normalWinLabel, self)
    local flyCsb = util_createAnimation("LeprechaunsCrock_jackpot_dfdc_fly.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)
    flyCsb:runCsbAction("fly", false)
    self:jumpCoins(flyCsb, self.m_bonusData.bonusCoins)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpot_flyTo_bottom)

    -- 隐藏原来的Jackopt数值
    self.m_oldJackpotCoinsNode = self.m_jackpotBar:getWinJackpotNode(_jpIndex)
    self.m_oldJackpotCoinsNode:setVisible(false)

    flyCsb:runAction(cc.Sequence:create(
        cc.DelayTime:create(30/60),
        cc.CallFunc:create(function()
            self.m_jackpotWinCoins:setVisible(true)
        end),
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            self.m_machine.m_bottomUI:playCoinWinEffectUI()
            if _func then
                _func()
            end
        end),
        cc.RemoveSelf:create()
    ))
end

function LeprechaunsCrockBonusView:isPickFeatureOver()
    local maxIndex = #self.m_bonusData.pickJackpots
    if self.m_playEffectOverIndex >= maxIndex then
        self:endGame()
    end
end

-- 添加奖励
function LeprechaunsCrockBonusView:addReward(_pickItem, _rewardIndex)
    self:addRewardStart(_pickItem, _rewardIndex)
end

--[[
    翻开item之后 飞粒子
]]
function LeprechaunsCrockBonusView:addRewardStart(_pickItem, _rewardIndex)
    local rewardName = self.m_bonusData.pickJackpots[_rewardIndex].jackpotName
    local animTime = 0
    if self:getIsJackpot(rewardName) then
        local jpIndex = self.RewardNameToJackpotIndex[rewardName]
        local allJpCount = self:getRewardCount(rewardName, _rewardIndex)
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpot_fly)

        animTime = self:playJackpotCollectAnim(_pickItem, rewardName, jpIndex, allJpCount, true)

    elseif self:getIsBoost(rewardName) then
        local allBoostValue = self:getAllBoostValue(_rewardIndex)
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_boost_fly)
        local random = math.random(1, 10)
        if random <= 3 then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_boost_fly_say)
        end

        animTime = self:playBoostCollectAnim(_pickItem, rewardName, allBoostValue)

    else
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_remove_fly)

        animTime = self:playRemoveCollectAnim(_pickItem)
    end

    self.m_machine:waitWithDelay(animTime, function()
        self:addRewardOver()
    end)
end

function LeprechaunsCrockBonusView:addRewardOver()
    self.m_playEffectOverIndex = self.m_playEffectOverIndex + 1
    self:isPickFeatureOver()
end

--[[
    点击之后的收集 翻出jackpot
]]
function LeprechaunsCrockBonusView:playJackpotCollectAnim(_pickItem, _rewardName, _jpIndex, _progressValue, _playSound)
    local flyTime = 0.5
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_jackpotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    local endPos = self:convertToNodeSpace(endWorldPos)
    local flyCsb = util_createAnimation("LeprechaunsCrock_dfdc_tuowei.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)
    for k, _nodeName in pairs(self.PickItemName3) do
        flyCsb:findChild(_nodeName):setVisible(false)
    end
    local particleNode = flyCsb:findChild(self.PickItemName3[_rewardName])
    particleNode:setVisible(true)
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()

    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            self.m_jackpotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)

            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))

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

--[[
    收集boost
]]
function LeprechaunsCrockBonusView:playBoostCollectAnim(_pickItem, _rewardName, _allBoostValue)
    local flyTime = 0.5
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endPos = util_convertToNodeSpace(self.m_boostNode, self)
    local flyCsb = util_createAnimation("LeprechaunsCrock_dfdc_tuowei2.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)

    for i=1,2 do
        local particleNode = flyCsb:findChild("Particle_boost"..i)
        particleNode:setPositionType(0)
        particleNode:setDuration(-1)
        particleNode:resetSystem()
    end    

    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_boost_fly_fankui)

            self.m_boostNode:runCsbAction("shouji", false)
            self.m_machine:waitWithDelay(15/60, function()
                self:setBoostNum(_allBoostValue)
            end)
            
            for i=1,2 do
                local particleNode = flyCsb:findChild("Particle_boost"..i)
                particleNode:stopSystem()
                util_setCascadeOpacityEnabledRescursion(particleNode, true)
                particleNode:runAction(cc.FadeOut:create(0.5))
            end  
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
    --递增
    local fankuiTime = 1
    return flyTime + fankuiTime
end

--[[
    翻出remove之后 飞的粒子
]]
function LeprechaunsCrockBonusView:playRemoveCollectAnim(_pickItem)
    local flyTime = 1
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_jackpotBar:getProgressFlyEndPos(self.m_removeLevelFlyNums, 2)
    local endPos = self:convertToNodeSpace(endWorldPos)
    self.m_removeLevelFlyNums = self.m_removeLevelFlyNums - 1

    -- 创建粒子
    local flyNode = util_createAnimation("LeprechaunsCrock_removed_tw.csb")
    self:addChild(flyNode)

    flyNode:setPosition(cc.p(startPos))
    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 500 )

    flyNode:runCsbAction("actionframe",false,function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    self.m_machine:waitWithDelay(30/60, function()
        self.m_removeLevelNums = self.m_removeLevelNums + 1
        self.m_jackpotBar:playJackpotRemoveLevelEffect(self.m_removeLevelNums)
    end)

    return flyTime

end

--重置ui状态
function LeprechaunsCrockBonusView:resetUi(_playBuffNums)
    self:pickItemReset()
    self:resetJackpotWinCoins()
    self.m_jackpotBar:resetUi()
    self:tipsReset(_playBuffNums)
    self.m_removeLevelNums = 0
    self.m_removeLevelFlyNums = 5 --粒子飞的时候 使用
    self.m_playEffectOverIndex = 0 --点击item之后 动画播完的标识
end

--[[
    初始化pickitem
]]
function LeprechaunsCrockBonusView:initPickItem( )
    self.m_pickItems = {}
    for index = 1, 18 do
        local index = index
        local parent  = self:findChild(string.format("Node_%d", index))
        parent:removeAllChildren()
        local animCsb = util_createAnimation("LeprechaunsCrock_dfdc.csb")
        parent:addChild(animCsb)
        self:createPickItem(animCsb)
        self.m_pickItems[index] = animCsb
        -- 点击事件
        local Panel = animCsb:findChild("Panel_click")
        Panel:addTouchEventListener(function(...)
            return self:pickItemClick(index, ...)
        end)
    end
end

--[[
    重置pickitem
]]
function LeprechaunsCrockBonusView:pickItemReset()
    -- 18个 可点击的item
    for _pickItemIndex = 1, 18 do
        local index = _pickItemIndex
        local item = self.m_pickItems[index]
        for _nodeIndex = 1, 3 do
            local itemNode = item["item".._nodeIndex]
            if _nodeIndex == 1 then
                itemNode:setVisible(true)
            else
                itemNode:setVisible(false)
                if itemNode.m_guangNode then
                    itemNode.m_guangNode:setVisible(false)
                end
            end
            itemNode:runCsbAction("idle")
        end
    end

    self:stopPickItemIdle()
    self:beginPickItemIdle()
end

--[[
    开始播放pick item idle
]]
function LeprechaunsCrockBonusView:beginPickItemIdle( )
    self.m_actionTimer = schedule(self:findChild("Node_action"), function()
        self:playPickItemIdle()
    end, 3)
end
--[[
    随机几个pickitem 播放idle动画
]]
function LeprechaunsCrockBonusView:playPickItemIdle()
    if not self:isVisible() then
        return
    end

    local randomNumsList = self:getRandomNumsList()
    for _, _posIndex in ipairs(randomNumsList) do
        local index = _posIndex
        local isPlay = true
        for _index, _itemIndex in ipairs(self.m_clickList) do
            if _itemIndex == index then
                isPlay = false
            end
        end

        if isPlay then
            local item = self.m_pickItems[index]
            if item and item["item1"] then
                local itemNode = item["item1"]
                itemNode:runCsbAction("idle1", false)
            end
        end
    end
end

--[[
    停止播放pickitem idle
]]
function LeprechaunsCrockBonusView:stopPickItemIdle()
    if self.m_actionTimer ~= nil then
        self:stopAction(self.m_actionTimer)
        self.m_actionTimer = nil
    end
end

--[[
    取几个随机的数字
]]
function LeprechaunsCrockBonusView:getRandomNumsList( )
    local numsList = {}
    -- 循环次数
    while true do
        local isRepeat = false
        local random = math.random(1,18)
        for _, _num in ipairs(numsList) do
            if random == _num then
                isRepeat = true
            end
        end
        if not isRepeat then
            table.insert(numsList, random)
        end

        if #numsList >= 5 then
            break
        end
    end

    return numsList
end

function LeprechaunsCrockBonusView:createPickItem(_node)
    for i=1, 3 do
        local item = util_createAnimation("LeprechaunsCrock_dfdc_"..(i-1)..".csb")
        _node:findChild("Node_"..i):addChild(item)
        if i > 1 then
            item:setVisible(false)
            item.m_guangNode = util_createAnimation("LeprechaunsCrock_dfdc_boost_guang.csb")
            item:findChild("Node_guang"):addChild(item.m_guangNode)
            item.m_guangNode:runCsbAction("idle", true)
            item.m_guangNode:setVisible(false)
        end

        _node["item"..i] = item
        item:runCsbAction("idle", true) 
    end
end
--[[
    点击节点
]]
function LeprechaunsCrockBonusView:pickItemClick(_index)
    if not self.m_clickState then
        return
    end
    for _, _itemIndex in ipairs(self.m_clickList) do
        if _itemIndex == _index then
            return
        end
    end

    table.insert(self.m_clickList, _index)
    self.m_clickState = false

    self:playTipsOverAnim()

    local rewardName = self.m_bonusData.pickJackpots[self.m_bonusData.index].jackpotName
    local pickItem = self.m_pickItems[_index]
    --点击jackpot
    if self:getIsJackpot(rewardName) then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_click_item)
    else
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_click_teshu_item)
    end

    local curRewardIndex = self.m_bonusData.index
    self:pickItemChangeRewardVisible(pickItem, rewardName, true, function()
        self:addReward(pickItem, curRewardIndex)
    end)

    self.m_bonusData.index = self.m_bonusData.index + 1

    local maxIndex = #self.m_bonusData.pickJackpots
    if self.m_bonusData.index <= maxIndex then
        self.m_clickState = true
    end
end

--[[
    点击翻开
]]
function LeprechaunsCrockBonusView:pickItemChangeRewardVisible(_pickItem, _rewardName, _isPlay, _func)
    --点击jackpot
    if self:getIsJackpot(_rewardName) then

        _pickItem.item1:setVisible(true)
        _pickItem.item2:setVisible(false)
        _pickItem.item3:setVisible(false)
        for k, _nodeName in pairs(self.PickItemName1) do
            _pickItem.item1:findChild(_nodeName):setVisible(_nodeName == self.PickItemName1[_rewardName])
        end

        if _isPlay then
            _pickItem.item1:runCsbAction("dianji", false, function()
                _pickItem.item1:runCsbAction("shouji", false)
            end)
            self.m_machine:waitWithDelay(0.4, function()
                if _func then
                    _func()
                end
            end)
        end
        --点击boost
    elseif self:getIsBoost(_rewardName) then

        _pickItem.item1:setVisible(false)
        _pickItem.item2:setVisible(true)
        _pickItem.item3:setVisible(false)

        for k, _nodeName in pairs(self.PickItemName2) do
            _pickItem.item2:findChild(_nodeName):setVisible(_nodeName == self.PickItemName2[_rewardName])
        end

        if _isPlay then
            _pickItem.item2:runCsbAction("dianji", false, function()
                -- 第一次点击出 boost
                if not self.m_boostNode:isVisible() then
                    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_boostView_start)
                    self.m_boostNode:setVisible(true)
                    self.m_boostNode:findChild("m_lb_num"):setVisible(true)
                    self.m_boostNode:runCsbAction("start", false, function()
                        self.m_boostNode:runCsbAction("idle", true)
                    end)
                end
            end)
            self.m_machine:waitWithDelay(0.4, function()
                if _func then
                    _func()
                end
            end)
            if _pickItem.item2.m_guangNode then
                _pickItem.item2.m_guangNode:setVisible(true)
            end
        end
    else--点击remove
        _pickItem.item1:setVisible(false)
        _pickItem.item2:setVisible(false)
        _pickItem.item3:setVisible(true)

        if _isPlay then
            _pickItem.item3:runCsbAction("dianji", false)
            self.m_machine:waitWithDelay(0.4, function()
                if _func then
                    _func()
                end
            end)
            if _pickItem.item3.m_guangNode then
                _pickItem.item3.m_guangNode:setVisible(true)
            end
        end
    end
end

--[[
    结算之前 未中奖的压暗 未翻开的翻开压暗
]]
function LeprechaunsCrockBonusView:endGameShowOtherReward()
    -- 已点击但是没获得该类型奖励的jackpot
    for _clickIndex, _itemIndex in ipairs(self.m_clickList) do
        local rewardName = self.m_bonusData.pickJackpots[_clickIndex].jackpotName
        if self:getIsJackpot(rewardName) then
        
            local bReward = false
            for _jackpotName, _ in pairs(self.m_bonusData.getJackpot) do
                if _jackpotName == rewardName then
                    bReward = true
                    break
                end
            end

            local pickItem = self.m_pickItems[_itemIndex]
            if bReward then --中奖的播放中奖时间线
                pickItem.item1:runCsbAction("actionframe", false)
            else --未中奖的压暗
                pickItem.item1:runCsbAction("dark", false)
            end

        elseif self:getIsBoost(rewardName) then

            local pickItem = self.m_pickItems[_itemIndex]
            pickItem.item2:runCsbAction("dark", false)
            if pickItem.item2.m_guangNode then
                pickItem.item2.m_guangNode:setVisible(false)
            end
        else
            local pickItem = self.m_pickItems[_itemIndex]
            pickItem.item3:runCsbAction("dark", false)
            if pickItem.item3.m_guangNode then
                pickItem.item3.m_guangNode:setVisible(false)
            end
        end
    end

    -- 未点击
    for _, _otherRewardName in ipairs(self.m_bonusData.extraJackpots) do
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
                self:pickItemChangeRewardVisible(_pickItem, _otherRewardName.jackpotName, false)
                
                _pickItem.item1:runCsbAction("actionframe_dark", false)
                _pickItem.item2:runCsbAction("actionframe_dark", false)
                _pickItem.item3:runCsbAction("actionframe_dark", false)
                break
            end
        end
    end
end

--[[
    奖池
]]
function LeprechaunsCrockBonusView:initJackpotBar()
    -- 创建jackpot pick
    self.m_jackpotBar = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockPickJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self.m_machine)
end

--[[
    提示
]]
function LeprechaunsCrockBonusView:initTips()
    self.m_tips = util_createAnimation("LeprechaunsCrock_dfdc_tishi.csb")
    self:findChild("Node_tishi"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    local Panel = self.m_tips:findChild("Panel_click")
    Panel:addTouchEventListener(function(...)
        return self:playTipsOverAnim(...)
    end)
end

--[[
    重置提示
]]
function LeprechaunsCrockBonusView:tipsReset(_playBuffNums)
    self.m_tips:findChild("Node_1"):setVisible(_playBuffNums == 0)
    self.m_tips:findChild("Node_2"):setVisible(_playBuffNums ~= 0)

    if _playBuffNums > 0 then
        for i=1, 3 do
            self.m_tips:findChild("Node_shu"..i):setVisible(i == _playBuffNums)
        end
    end
end

function LeprechaunsCrockBonusView:playTipsStartAnim(_func)
    self.m_tips:setVisible(true)
    self.m_tips.m_playOver = false
    self.m_tips:runCsbAction("start", false, function()
        _func()
    end)
end

function LeprechaunsCrockBonusView:playTipsIdleAnim(_func)
    self.m_tips:runCsbAction("idle", false, function()
        _func()
    end)
end
function LeprechaunsCrockBonusView:playTipsOverAnim()
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
function LeprechaunsCrockBonusView:getRewardCount(_rewardName, _limitIndex)
    local count = 0
    for _index,rewardName in ipairs(self.m_bonusData.pickJackpots) do
        if rewardName.jackpotName == _rewardName and _index <= _limitIndex then
            count = count + 1
        end
    end
    return count
end

--[[
    得到当前的所有boost加成值
]]
function LeprechaunsCrockBonusView:getAllBoostValue(_limitIndex)
    local value = 0
    for _index,rewardName in ipairs(self.m_bonusData.pickJackpots) do
        if self:getIsBoost(rewardName.jackpotName) and _index <= _limitIndex then
            value = value + rewardName.multiply
        end
    end
    return value
end

--[[
    判断是否是jackpot
]]
function LeprechaunsCrockBonusView:getIsJackpot(_rewardName)
    if _rewardName == self.RewardName.Mini or 
        _rewardName == self.RewardName.Minor or  
        _rewardName == self.RewardName.Major or 
        _rewardName == self.RewardName.Mega or 
        _rewardName == self.RewardName.Grand then
            return true
    end
    return false
end

--[[
    判断是否是boost
]]
function LeprechaunsCrockBonusView:getIsBoost(_rewardName)
    if _rewardName == self.RewardName.Boost or 
        _rewardName == self.RewardName.SuperBoost or 
        _rewardName == self.RewardName.MegaBoost then
            return true
    end
    return false
end

return LeprechaunsCrockBonusView