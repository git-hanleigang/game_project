local MayanMysteryBonusView = class("MayanMysteryBonusView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MayanMysteryPublicConfig"

MayanMysteryBonusView.RewardName = {
    epic = "epic",
    grand = "grand",
    major = "major",
    minor = "minor",
    mini = "mini",
}

MayanMysteryBonusView.RewardNameToJackpotIndex = {
    [MayanMysteryBonusView.RewardName.epic] = 1,
    [MayanMysteryBonusView.RewardName.grand] = 2,
    [MayanMysteryBonusView.RewardName.major] = 3,
    [MayanMysteryBonusView.RewardName.minor] = 4,
    [MayanMysteryBonusView.RewardName.mini] = 5,
}
function MayanMysteryBonusView:initDatas(_machine)
    self.m_machine = _machine.machine
    self.m_clickState = false
    self.m_bonusData = {}
    self.m_clickList = {}
    self.m_playEffectOverIndex = 0
end
function MayanMysteryBonusView:initUI()
    self:createCsbNode("MayanMystery/DfdcScreen_0.csb")
    self:initPickItem()
    self:initJackpotBar()
    self:initTips()
end

function MayanMysteryBonusView:startGame(_data, _fun)
    self.m_endFun = _fun
    self.m_clickList = {}
    self.m_isHavePlayDoubleEffect = false
    self:setBonusData(_data)
    self:resetUi()
    
    --播放完start就可以点击了，不用等待idle和over时间线
    self:playTipsStartAnim(function()
        self.m_clickState = true
    end)
end

function MayanMysteryBonusView:endGame()
    self:stopPickItemIdle()
    --没有中奖的pickitem 压暗
    self:endGameShowOtherReward()

    -- 播放jackpot动画
    for _, _jackpotName in ipairs(self.m_bonusData.winjackpotname) do
        self:playJackpotEffect(_jackpotName)
    end
    
    --玩法结束
    self.m_machine:delayCallBack(60/30, function()
        if self.m_endFun then
            self.m_endFun()
            self.m_endFun = nil
        end
    end)
end

function MayanMysteryBonusView:isPickFeatureOver()
    local maxIndex = #self.m_bonusData.process
    if self.m_playEffectOverIndex >= maxIndex then
        self:endGame()
    end
end

-- 添加奖励
function MayanMysteryBonusView:addReward(_pickItem, _rewardIndex)
    self:addRewardStart(_pickItem, _rewardIndex)
end

--[[
    翻开item之后 飞粒子
]]
function MayanMysteryBonusView:addRewardStart(_pickItem, _rewardIndex)
    local rewardName = self.m_bonusData.process[_rewardIndex]
    local animTime = 0
    if self:getIsJackpot(rewardName) then
        local jpIndex = self.RewardNameToJackpotIndex[rewardName]
        local allJpCount = self:getRewardCount(rewardName, _rewardIndex)

        animTime = self:playJackpotCollectAnim(_pickItem, rewardName, jpIndex, allJpCount, true)
    end

    self.m_machine:delayCallBack(animTime, function()
        self:addRewardOver()
    end)
end

function MayanMysteryBonusView:addRewardOver()
    self.m_playEffectOverIndex = self.m_playEffectOverIndex + 1
    self:isPickFeatureOver()
end

--[[
    点击之后的收集 翻出jackpot
]]
function MayanMysteryBonusView:playJackpotCollectAnim(_pickItem, _rewardName, _jpIndex, _progressValue, _playSound)
    local flyTime = 0.5
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_jackpotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    local endPos = self:convertToNodeSpace(endWorldPos)
    local flyCsb = util_createAnimation("MayanMystery_twlizi.csb")
    self:addChild(flyCsb)
    flyCsb:setPosition(startPos)

    for index = 1, 3 do
        local particleNode = flyCsb:findChild("Particle_"..index)
        if particleNode then
            particleNode:setPositionType(0)
            particleNode:setDuration(-1)
            particleNode:resetSystem()
        end
    end
    
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            self.m_jackpotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)

            for index = 1, 3 do
                local particleNode = flyCsb:findChild("Particle_"..index)
                if particleNode then
                    particleNode:stopSystem()
                end
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

--重置ui状态
function MayanMysteryBonusView:resetUi()
    self.m_jackpotBar:resetView()
    self.m_playEffectOverIndex = 0 --点击item之后 动画播完的标识

    self:pickItemReset()
end

--[[
    初始化pickitem
]]
function MayanMysteryBonusView:initPickItem( )
    self.m_pickItems = {}
    for index = 1, 12 do
        local index = index
        local parent  = self:findChild(string.format("Node_%d", index))
        parent:removeAllChildren()
        local animCsb = util_createAnimation("MayanMystery_Bonus_Pick.csb")
        parent:addChild(animCsb)
        self:createPickItem(animCsb)
        self.m_pickItems[index] = animCsb
        -- 点击事件
        local Panel = animCsb:findChild("click")
        Panel:addTouchEventListener(function(...)
            return self:pickItemClick(index, ...)
        end)
    end
end

--[[
    重置pickitem
]]
function MayanMysteryBonusView:pickItemReset()
    -- 12个 可点击的item
    for _pickItemIndex = 1, 12 do
        local index = _pickItemIndex
        local item = self.m_pickItems[index]
        util_spinePlay(item.m_bonusPick, "idle")
        item.m_jackpotNode:runCsbAction("idle")
    end

    self:stopPickItemIdle()
    self:beginPickItemIdle()
end

--[[
    开始播放pick item idle
]]
function MayanMysteryBonusView:beginPickItemIdle( )
    self.m_actionTimer = schedule(self:findChild("Node_action"), function()
        self:playPickItemIdle()
    end, 3)
end
--[[
    随机几个pickitem 播放idle动画
]]
function MayanMysteryBonusView:playPickItemIdle()
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
            if item and item.m_bonusPick then
                util_spinePlay(item.m_bonusPick, "idle1")
            end
        end
    end
end

--[[
    停止播放pickitem idle
]]
function MayanMysteryBonusView:stopPickItemIdle()
    if self.m_actionTimer ~= nil then
        self:stopAction(self.m_actionTimer)
        self.m_actionTimer = nil
    end
end

--[[
    取几个随机的数字
]]
function MayanMysteryBonusView:getRandomNumsList( )
    local numsList = {}
    -- 循环次数
    while true do
        local isRepeat = false
        local random = math.random(1,12)
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

function MayanMysteryBonusView:createPickItem(_node)
    local item = util_spineCreate("MayanMystery_pick", true, true)
    _node:findChild("Node_pick"):addChild(item)
    _node.m_bonusPick = item
    local coinsView = util_createAnimation("MayanMystery_dfdc_pick_jinbi.csb")
    util_spinePushBindNode(item, "shuzi", coinsView)
    _node.m_jackpotNode = coinsView

    util_spinePlay(item, "idle", true)
end
--[[
    点击节点
]]
function MayanMysteryBonusView:pickItemClick(_index)
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

    local rewardName = self.m_bonusData.process[self.m_bonusData.index]
    local pickItem = self.m_pickItems[_index]

    local curRewardIndex = self.m_bonusData.index
    self:pickItemChangeRewardVisible(pickItem, rewardName, true, function()
        self:addReward(pickItem, curRewardIndex)
    end)

    self.m_bonusData.index = self.m_bonusData.index + 1

    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index <= maxIndex then
        self.m_clickState = true
    end
end

--[[
    点击翻开
]]
function MayanMysteryBonusView:pickItemChangeRewardVisible(_pickItem, _rewardName, _isPlay, _func)
    --点击jackpot
    if self:getIsJackpot(_rewardName) then
        for k, _nodeName in pairs(self.RewardName) do
            _pickItem.m_jackpotNode:findChild(_nodeName):setVisible(_nodeName == _rewardName)
        end

        if _isPlay then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_bonusGame_click)

            if _rewardName == "epic" then
                util_spinePlay(_pickItem.m_bonusPick, "dinaji2")
            else
                util_spinePlay(_pickItem.m_bonusPick, "dinaji")
            end
            
            self.m_machine:delayCallBack(15/30, function()
                if _func then
                    _func()
                end
            end)

            self.m_machine:delayCallBack(23/30, function()
                self:playDoublePickEffect()
            end)

            -- util_spineEndCallFunc(_pickItem.m_bonusPick, "dinaji", function()
            --     util_spinePlay(_pickItem.m_bonusPick, "shouji")
            -- end)
        end
    end
end

--[[
    doublepick 出现3个一样的图标时  播放
]]
function MayanMysteryBonusView:playDoublePickEffect( )
    if self.m_indexType == 1 and not self.m_isHavePlayDoubleEffect then
        local jackpotNameNum = {}
        jackpotNameNum[1] = 0
        jackpotNameNum[2] = 0
        local clickNum = #self.m_clickList
        for _index, _rewardName in ipairs(self.m_bonusData.process) do
            if _index <= clickNum then
                for _jackpotIndex = 1, 2 do
                    if _rewardName == self.m_bonusData.winjackpotname[_jackpotIndex] then
                        jackpotNameNum[_jackpotIndex] = jackpotNameNum[_jackpotIndex] + 1
                    end
                end
            end
        end
        for _, _jackpotNum in ipairs(jackpotNameNum) do
            if _jackpotNum >= 3 then
                self.m_isHavePlayDoubleEffect = true
                for _clickIndex, _itemIndex in ipairs(self.m_clickList) do
                    local rewardName = self.m_bonusData.process[_clickIndex]
                    if self:getIsJackpot(rewardName) and rewardName == self.m_bonusData.winjackpotname[1] then
                        local pickItem = self.m_pickItems[_itemIndex]
                        if pickItem then
                            util_spinePlay(pickItem.m_bonusPick, "actionframe1", true)
                        end
                    end
                end
            end
        end
    end
end

--[[
    结算之前 未中奖的压暗 未翻开的翻开压暗
]]
function MayanMysteryBonusView:endGameShowOtherReward()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_bonusGame_win)

    -- 已点击但是没获得该类型奖励的jackpot
    for _clickIndex, _itemIndex in ipairs(self.m_clickList) do
        local rewardName = self.m_bonusData.process[_clickIndex]
        if self:getIsJackpot(rewardName) then
        
            local bReward = false
            for _, _jackpotName in ipairs(self.m_bonusData.winjackpotname) do
                if _jackpotName == rewardName then
                    bReward = true
                    break
                end
            end

            local pickItem = self.m_pickItems[_itemIndex]
            if bReward then --中奖的播放中奖时间线
                util_spinePlay(pickItem.m_bonusPick, "actionframe")
            else --未中奖的压暗
                util_spinePlay(pickItem.m_bonusPick, "actionframe_dark")
                pickItem.m_jackpotNode:runCsbAction("drak")
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
                self:pickItemChangeRewardVisible(_pickItem, _otherRewardName, false)
                
                util_spinePlay(_pickItem.m_bonusPick, "actionframe_dark")
                _pickItem.m_jackpotNode:runCsbAction("drak")
                break
            end
        end
    end
end

--[[
    奖池
]]
function MayanMysteryBonusView:initJackpotBar()
    -- 创建jackpot pick
    self.m_jackpotBar = util_createView("CodeMayanMysterySrc.MayanMysteryColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:showJackpot(true)
end

--[[
    提示
]]
function MayanMysteryBonusView:initTips()
    --tips
    self.m_wenanNode = util_createAnimation("MayanMystery_dfdc_wenan.csb")
    self:findChild("Node_wenan"):addChild(self.m_wenanNode)

    --wenan
    self.m_tipsNode = util_createAnimation("MayanMystery_dudc_gc_wenan.csb")
    self:findChild("Node_tips"):addChild(self.m_tipsNode)
    self.m_tipsNode:setVisible(false)

    -- 小过场
    self.m_smallGuoChang = util_spineCreate('MayanMystery_juese',false,true)
    self:findChild('Node_bg'):addChild(self.m_smallGuoChang)

    self.m_smallGuoChang1 = util_spineCreate('MayanMystery_juese',false,true)
    self:findChild('Node_men'):addChild(self.m_smallGuoChang1)
    self.m_smallGuoChang1:setVisible(false)
end

--[[
    不显示tips
]]
function MayanMysteryBonusView:hideTips( )
    self.m_wenanNode:findChild("Node_pick1"):setVisible(false)
    self.m_wenanNode:findChild("Node_doublepick"):setVisible(false)
    self.m_wenanNode:findChild("Node_rpizeupgrade"):setVisible(false)
    self.m_wenanNode:findChild("Node_pick2"):setVisible(false)
end

function MayanMysteryBonusView:playTipsStartAnim(_func)
    self.m_jackpotBar:playEpicHideEffect()
    self:hideTips()

    if self.m_indexType == 1 then
        self.m_wenanNode:findChild("Node_doublepick"):setVisible(true)
        self:runCsbAction("idle")
    elseif self.m_indexType == 2 then
        self.m_wenanNode:findChild("Node_rpizeupgrade"):setVisible(true)
        self:runCsbAction("idle")
    elseif self.m_indexType == 3 then
        self.m_wenanNode:findChild("Node_pick2"):setVisible(true)
        self:runCsbAction("show")
    end
    self.m_wenanNode:runCsbAction("show")

    if self.m_indexType == 3 then
        self.m_tipsNode:setVisible(false)
        self:playSmallGuoChang(_func)
    else
        util_spinePlay(self.m_smallGuoChang, "actionframe_open_idle", false)
        self.m_tipsNode:findChild("Node_double"):setVisible(self.m_indexType == 1)
        self.m_tipsNode:findChild("Node_rpizeupgrade"):setVisible(self.m_indexType == 2)
        self.m_tipsNode:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_MayanMystery_colorFul_tips"..self.m_indexType])

        self.m_tipsNode:runCsbAction("auto", false, function()
            if self.m_indexType == 1 then 
                if _func then
                    _func()
                end
            else
                self.m_jackpotBar:playRemoveMiniEffect(function()
                    self.m_jackpotBar:playEpicStartEffect(function()
                        if _func then
                            _func()
                        end
                    end)
                end) 
            end
        end)
    end
end

--[[
    处理bonusData数据
]]
function MayanMysteryBonusView:playSmallGuoChang(_func)
    util_spinePlay(self.m_smallGuoChang, "actionframe_open", false)
    util_spineEndCallFunc(self.m_smallGuoChang, "actionframe_open", function()
        if type(_func) == "function" then
            _func()
        end
    end)

    self.m_smallGuoChang1:setVisible(true)
    util_spinePlay(self.m_smallGuoChang1, "actionframe_open_men", false)
    util_spineEndCallFunc(self.m_smallGuoChang1, "actionframe_open_men", function()
        self.m_smallGuoChang1:setVisible(false)
    end)
end

--[[
    处理bonusData数据
]]
function MayanMysteryBonusView:getRewardCount(_rewardName, _limitIndex)
    local count = 0
    for _index,rewardName in ipairs(self.m_bonusData.process) do
        if rewardName == _rewardName and _index <= _limitIndex then
            count = count + 1
        end
    end
    return count
end

--[[
    判断是否是jackpot
]]
function MayanMysteryBonusView:getIsJackpot(_rewardName)
    if _rewardName == self.RewardName.mini or 
        _rewardName == self.RewardName.minor or  
        _rewardName == self.RewardName.major or 
        _rewardName == self.RewardName.grand or 
        _rewardName == self.RewardName.epic then
            return true
    end
    return false
end

--[[
    重新处理数据
]]
function MayanMysteryBonusView:setBonusData(_data)
    self.m_bonusData  = {}
    self.m_indexType = 1 --1表示double 2表示upgrade 3表示多福多彩2
    local allJackpot = {}
    if _data.selfData then
        self.m_bonusData = _data.selfData.jackpot or {}
    else
        if _data.p_selfMakeData then
            self.m_bonusData = _data.p_selfMakeData.jackpot or {}
        end
    end

    if _data.selfData and _data.selfData.bonus then
        for _type, _collectNum in pairs(_data.selfData.bonus.result) do
            if _collectNum >= 3 then
                if _type == "Double" then
                    self.m_indexType = 1
                    allJackpot = {"mini","mini","mini","minor","minor","minor","major","major","major","grand","grand","grand"}
                else
                    self.m_indexType = 2
                    allJackpot = {"minor","minor","minor","major","major","major","grand","grand","grand","epic","epic","epic"}
                end
            end
        end
    else
        self.m_indexType = 3
        allJackpot = {"mini","mini","mini","minor","minor","minor","major","major","major","grand","grand","grand"}
    end

    for _index, _jackpotType in ipairs(self.m_bonusData.process) do
        for index, jackpotType in ipairs(allJackpot) do
            if _jackpotType == jackpotType then
                table.remove(allJackpot, index)
                break
            end
        end
    end
    self.m_bonusData.extraJackpots = allJackpot
    self.m_bonusData.index = 1
end

--[[
    弹jackpot弹板的时候 播放
]]
function MayanMysteryBonusView:playJackpotEffect(_jackpotName)
    local jpIndex = self.RewardNameToJackpotIndex[_jackpotName] or 5
    self.m_jackpotBar:playJackpotWinEffect(jpIndex)
end

return MayanMysteryBonusView