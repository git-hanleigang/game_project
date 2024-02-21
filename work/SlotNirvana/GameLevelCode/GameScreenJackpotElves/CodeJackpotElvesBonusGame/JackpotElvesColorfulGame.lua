---
--xcyy
--2018年5月23日
--JackpotElvesColorfulGame.lua

local JackpotElvesColorfulGame = class("JackpotElvesColorfulGame",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "JackpotElvesPublicConfig"
local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}


function JackpotElvesColorfulGame:initUI(params)
    self.m_machine = params.machine

    self.m_isClicked = false
    
    self.m_endFunc = nil --结束回调
    self:createCsbNode("JackpotElves/JackpotElvesJackpot.csb")

    self.m_markView = self:findChild("Panel_zhezhao")
    self.m_markView:setVisible(false)
    util_playFadeOutAction(self.m_markView, 0)

    self.flyNum = 6

    
    --先创建前20个
    self.m_redItems = {}
    self.m_greenItems = {}
    for index = 1,20 do
        local redItem = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfulItem",{index = index,parent = self,type = "red"})
        self:findChild("Node_"..index):addChild(redItem)
        redItem.indexPos = index
        self.m_redItems[index] = redItem
        redItem:resetStatus()
        redItem.m_parentNode = self:findChild("Node_"..index)

        local greenItem = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfulItem",{index = index,parent = self,type = "green"})
        self:findChild("Node_"..index):addChild(greenItem)
        greenItem.indexPos = index
        self.m_greenItems[index] = greenItem
        greenItem:resetStatus()
        greenItem.m_parentNode = self:findChild("Node_"..index)
    end

    --再创建后4个 ,红色占最后一行后4个,
    for index = 1,4 do
        local redItem = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfulItem",{index = #self.m_redItems + 1,parent = self,type = "red"})
        self:findChild("Node_".. (index + 21)):addChild(redItem)
        redItem.indexPos = index + 21
        self.m_redItems[#self.m_redItems + 1] = redItem
        redItem:resetStatus()
        redItem.m_parentNode = self:findChild("Node_".. (index + 21))

        local greenItem = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfulItem",{index = #self.m_greenItems + 1,parent = self,type = "green"})
        self:findChild("Node_"..(index + 20)):addChild(greenItem)
        greenItem.indexPos = index + 20
        self.m_greenItems[#self.m_greenItems + 1] = greenItem
        greenItem:resetStatus()
        greenItem.m_parentNode = self:findChild("Node_"..(index + 20))
    end

    self.m_jackpotBar = util_createView("CodeJackpotElvesBonusGame.JackpotElvesJackPotBarInColorful",{machine = self.m_machine})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    local redNote = util_createAnimation("JackpotElves_jackpot_note.csb")
    redNote:findChild("Node_green"):setVisible(false)
    self:findChild("Node_red_note"):addChild(redNote)
    redNote:playAction("idle", true)

    local greenNote = util_createAnimation("JackpotElves_jackpot_note.csb")
    greenNote:findChild("Node_red"):setVisible(false)
    self:findChild("Node_green_note"):addChild(greenNote)
    greenNote:playAction("idle", true)
    
    self.m_upgradeNode = util_createAnimation("JackpotElves_jackpot_upgrade.csb")
    self:findChild("Node_upgrade_shuoming"):addChild(self.m_upgradeNode)
    self.m_upgradeNode:setVisible(false)

    self.m_upgradeView = util_createAnimation("JackpotElves_upgrade_tanban.csb")
    self:findChild("Node_buff_tanban"):addChild(self.m_upgradeView)
    self.m_upgradeView:setVisible(false)

    self.m_upgradeReward = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfullUpgrade")
    self:findChild("Node_jiesuan"):addChild(self.m_upgradeReward)
    self.m_upgradeReward:setVisible(false)

    self.m_redElve = util_spineCreate("JackpotElves_juese_hong", true, true)
    self:findChild("Node_red_role"):addChild(self.m_redElve)
    self:playElveIdle(self.m_redElve, true)

    self.m_greenElve = util_spineCreate("JackpotElves_juese_lv", true, true)
    self:findChild("Node_green_role"):addChild(self.m_greenElve)
    self:playElveIdle(self.m_greenElve, true)

    self.m_buffStar = util_createView("CodeJackpotElvesBonusGame.JackpotElvesColorfullStar")
    self.m_buffStar:setVisible(false)
    self:findChild("Node_buff_green"):addChild(self.m_buffStar)

    util_playFadeOutAction(self, 0)
    self:setVisible(false)
end

function JackpotElvesColorfulGame:markVisibleAnim(isShow, func)
    if isShow then
        self.m_markView:setVisible(isShow)
        util_playFadeOutAction(self.m_markView, 0)
        util_playFadeInAction(self.m_markView, 0.3, function()
            if func then
                func()
            end
        end)
    else
        util_playFadeOutAction(self.m_markView, 0.3, function ()
            self.m_markView:setVisible(isShow)
            if func then
                func()
            end
        end)
    end
end

function JackpotElvesColorfulGame:onEnter()
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    -- if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                assert(self.m_csbNode, "csbNode is nill !!! cname is " .. self.__cname)
                
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
                local a = globalData.slotRunData:isMachinePortrait()
                if globalData.slotRunData:isMachinePortrait() then
                    self:resetItemsPos()
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    -- end
end

--[[
    小精灵idle
]]
function JackpotElvesColorfulGame:playElveIdle(spineElve, isInit)
    local animName = "idleframe2"
    if spineElve == self.m_redElve then
        animName = "idle"
    end
    if isInit ~= true then
        local randomNum = math.random(2, 5)
        if spineElve == self.m_redElve and randomNum == 4 then
            animName = "idleframe4"
        elseif spineElve == self.m_greenElve and randomNum == 3 then
            animName = "idleframe3"
        end
    end

    self:playSpineAnim(spineElve, animName, false, function ()
        self:playElveIdle(spineElve)
    end)
end

--[[
    初始化数据
]]
function JackpotElvesColorfulGame:initGameData( )

    self.m_resultData = self.m_bonusData.result
    self.jackpot_win = self.m_bonusData.jackpot_win
    local jackpotGet = self.m_bonusData.jackpot_get
    
    --最终赢的jackpot
    self.m_winJackpotType = jackpotGet[#jackpotGet]

    if self.m_upgrade == true then
        for id = 1, #JACKPOT_TYPE, 1 do
            if self.m_winJackpotType == JACKPOT_TYPE[id] then
                self.m_upgradeJackpotType = JACKPOT_TYPE[id - 1]
                if id == 1 then
                    self.m_upgradeJackpotType = JACKPOT_TYPE[id]
                end
                break
            end
        end
    end

    self.m_winCoins = 0

    -- 当前点开的jackpot 数组
    self.m_vecJackpotItems = {}
    --总的奖励数量
    self.m_totalReardData = {}
    for k,jackpotType in pairs(JACKPOT_TYPE) do
        self.m_totalReardData[jackpotType] = 3
        self.m_vecJackpotItems[jackpotType] = {}
    end
    self.m_totalReardData["buff"] = 3
    self.m_vecJackpotItems["buff"] = {}

    --剩下的未点击的位置
    self.m_leftPosIndex = {}
    for index = 1,24 do
        self.m_leftPosIndex[index] = index
    end

    --当前点击奖励的索引
    self.m_curRewardIndex = 0
    -- 当前获得jackpot的索引
    self.m_jackpotWinIndex = 0
    
end

--[[
    显示界面
]]
function JackpotElvesColorfulGame:showView(bonusData,func)
    self:setEndFunc(func)
    self.m_colorType = bonusData.wildType --0 红色 1 绿色
    self.m_upgrade = bonusData.upgrade[self.m_colorType + 1]
    self.m_bonusData = bonusData

    self:setVisible(true)
    
    util_playFadeInAction(self, 0.5)

    --更新界面UI
    self:updateViewUI()
    --初始化数据
    self:initGameData()

    self:resetView()
end

function JackpotElvesColorfulGame:updateViewUI()
    if self.m_colorType == 0 then
        self:findChild("Node_green"):setVisible(false)
        self:findChild("Node_green_role"):setVisible(false)
        self:findChild("Node_red"):setVisible(true)
        self:findChild("Node_red_role"):setVisible(true)
    else
        self:findChild("Node_green"):setVisible(true)
        self:findChild("Node_green_role"):setVisible(true)
        self:findChild("Node_red"):setVisible(false)
        self:findChild("Node_red_role"):setVisible(false)
    end
    
    if self.m_upgrade == true then
        self.m_upgradeView:setVisible(true)
        self:markVisibleAnim(true)
        self:delayCallBack(1, function ()
            self.m_upgradeView:playAction("start", false, function ()
                self.m_upgradeView:setVisible(false)
                self:markVisibleAnim(false)
                self.m_upgradeNode:setVisible(true)
                self.m_upgradeNode:playAction("idle", true)
            end)
        end)
    else
        self.m_upgradeNode:setVisible(false)
    end

    self.m_randomRemindAction = schedule(self, function()
        self:randomRemindAnim()
    end, 5)
end

--[[
    重置界面显示
]]
function JackpotElvesColorfulGame:resetView()
    for index = 1,24 do
        self.m_redItems[index]:resetStatus()
        self.m_redItems[index]:setVisible(self.m_colorType == 0)

        self.m_greenItems[index]:resetStatus()
        self.m_greenItems[index]:setVisible(self.m_colorType == 1)
    end
    self.m_isClicked = false
    self.m_jackpotBar:resetUI(self.m_machine.m_iBetLevel)
end

--[[
    设置结束回调
]]
function JackpotElvesColorfulGame:setEndFunc(func)
    self.m_endFunc = func
end

--[[
    点击道具回调
]]
function JackpotElvesColorfulGame:clickItem(clickIndex)
    if self.m_isClicked then
        return false
    end
    self.m_isClicked = true
    if self.m_randomRemindAction then
        self:stopAction(self.m_randomRemindAction)
        self.m_randomRemindAction = nil
    end

    local function endFunc()

        --玩法结束
        if self.m_curRewardIndex >= #self.m_resultData then
            self:runOverAni()
        else
            --恢复可点击状态
            self.m_isClicked = false
            self.m_randomRemindAction = schedule(self, function()
                self:randomRemindAnim()
            end, 5)
        end
    end

    --获取点击位置
    local item = self:getItemByIndex(clickIndex)

    self.m_curRewardIndex = self.m_curRewardIndex + 1
    local rewardData = self.m_resultData[self.m_curRewardIndex]
    if type(rewardData) == "string" then
        item:updateUI("jackpot",rewardData)
        --减少盘面上对应的奖励数量
        self.m_totalReardData[rewardData] = self.m_totalReardData[rewardData] - 1
        self.m_vecJackpotItems[rewardData][#self.m_vecJackpotItems[rewardData] + 1] = item
    elseif type(rewardData) == "table" then
        item:updateUI("buff",rewardData[2])
        --减少盘面上对应的奖励数量
        self.m_totalReardData["buff"] = self.m_totalReardData["buff"] - 1
        self.m_vecJackpotItems["buff"][#self.m_vecJackpotItems["buff"] + 1] = item
    end
    item:openGiftBox(type(rewardData),function ()
        if type(rewardData) == "string" then
            local collectCount = 3 - self.m_totalReardData[rewardData]
            local jackpotCollect = self.m_jackpotBar:getJackpotCollectItem(rewardData, collectCount)
            local parentNode = self:findChild("root")
            local endPos = util_convertToNodeSpace(jackpotCollect, parentNode)
            local startPos = util_convertToNodeSpace(item, parentNode)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotCollectFankui)
            self:flyParticleAnim(startPos, endPos, function()
                self.m_jackpotBar:refreshCollectCount(rewardData,collectCount)
            end)
            endFunc()
        else
            self:hitBuffAni(rewardData, item, function(  )

                endFunc()
            end)
        end
        
    end)
    
end

--[[
    获取buff动画
]]
function JackpotElvesColorfulGame:hitBuffAni(rewardData, item, func)
    self.flyNum = 6
    self:markVisibleAnim(true)
    local oldParent = item:getParent()
    self:changeParent2Root(item)
    if self.m_colorType == 0 then --红色buff

        item:runCsbAction("actionframe2", false, function()
            self:runRedWildEffctAni(rewardData[2], function ()
                self:markVisibleAnim(false, function()
                    util_changeNodeParent(oldParent, item)
                    item:setPosition(0, 0)
                end)
                
                if func then
                    func()
                end
            end)
        end)
        
    else    --绿色buff

        item:runCsbAction("actionframe2", false, function()
            util_changeNodeParent(oldParent, item)
            item:setPosition(0, 0)
            self:runGreenWildEffectAni(rewardData[2],func, item)
        end)
        
    end
end

--[[
    红色玩法buff效果
]]
function JackpotElvesColorfulGame:runRedWildEffctAni(rewardData, func)
    self:darkBuffJackpot(rewardData, function ()
        self:darkBuffJackpotBar(rewardData, func)
    end)
end
--[[
    buff对应的jackpot压黑
]]
function JackpotElvesColorfulGame:darkBuffJackpot(rewardData, func)
    --去掉界面剩余的jackpot
    local leftCount = self.m_totalReardData[rewardData]
    local leftItems = self:getLeftItems()
    self.m_totalReardData[rewardData] = 0

    --从还没选择位置随机进行压黑
    for index = 1,leftCount do
        local randIndex = math.random(1,#leftItems)
        local randItem = leftItems[randIndex]

        --刷新数据显示
        randItem:updateUI("jackpot",rewardData)
        local oldParent = randItem:getParent()
        self:changeParent2Root(randItem)
        randItem:buffTrrigerDarkAnim(function()
            self:delayCallBack(1 + 1/10,function ()
                util_changeNodeParent(oldParent, randItem)
                randItem:setPosition(0, 0)
            end)
            if index == leftCount then
                if func then
                    func()
                end
            end
        end)
        table.remove(leftItems,randIndex)
    end

    local vecItems = self.m_vecJackpotItems[rewardData]
    for index = 1, #vecItems, 1 do
        local item = vecItems[index]
        if item.m_isDarkStatus ~= true then
            local oldParent = item:getParent()
            self:changeParent2Root(item)
            self:delayCallBack(1,function ()
                item:jackpotDarkAnim(function()
                    -- self:delayCallBack(1/9,function ()
                        util_changeNodeParent(oldParent, item)
                        item:setPosition(0, 0)
                    -- end)
                
                end)
            end)
            
            --- fankui1 0.9s
        end
    end
end
--[[
    飞粒子动画
]]
function JackpotElvesColorfulGame:flyParticleAnim(startPos, endPos, func)
    local parentNode = self:findChild("root")
    local flyNode = util_createAnimation("JackpotElves_tw_lizi.csb")
    for id = 1, 3, 1 do
        local particle = flyNode:findChild("ef_lizi"..id)
        particle:setPositionType(0)
        particle:resetSystem()
    end
    parentNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local moveTo = cc.MoveTo:create(0.5, endPos)
    local callFunc = cc.CallFunc:create(function()
        for id = 1, 3, 1 do
            local particle = flyNode:findChild("ef_lizi"..id)
            particle:stopSystem()
        end
        self:delayCallBack(0.5, function ()
            flyNode:removeFromParent()
        end)
        if func then
            func()
        end
    end)
    flyNode:runAction(cc.Sequence:create(moveTo, callFunc))
end
--[[
    ackpotBar对应的jackpot显示压黑
]]
function JackpotElvesColorfulGame:darkBuffJackpotBar(rewardData, func)
    --jackpotBar对应的jackpot显示压黑
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotchangeHide)
    self:playSpineAnim(self.m_redElve, "shifa", false, function ()
        self:playElveIdle(self.m_redElve, true)
    end)
    local jackptItem = self.m_jackpotBar:getItemByType(rewardData)
    local parentNode = self:findChild("root")
    self:delayCallBack(1.1, function()
        local endPos = util_convertToNodeSpace(jackptItem, parentNode)
        local startPos = util_convertToNodeSpace(self:findChild("Node_red_role"), parentNode)
        startPos = cc.p(startPos.x + 80, startPos.y + 80)
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotchangeHide)
        self:flyParticleAnim(startPos, endPos, function()
            self.m_jackpotBar:runDarkAni(rewardData)
            if func then
                func()
            end
        end)
    end)

end

--[[
    绿色buff动画
]]
function JackpotElvesColorfulGame:runGreenWildEffectAni(rewardData, func, item)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotTrigger)
    self.m_buffStar:setVisible(true)
    local parentNode = self:findChild("root")
    local endPos = util_convertToNodeSpace(self.m_buffStar, parentNode)
    local startPos = util_convertToNodeSpace(self:findChild("Node_green_role"), parentNode)
    startPos = cc.p(startPos.x - 155, startPos.y + 50)
    self.m_buffStar:showStar(rewardData, function ()
        self:delayCallBack(10 / 60, function ()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_starRotateForLv)
            self:playSpineAnim(self.m_greenElve, "actionframe3_1", false, function ()
                -- self:flyParticleAnim(startPos, endPos)
                self:continuedFlyParticleAnim(startPos, endPos)
                self:playSpineAnim(self.m_greenElve, "actionframe3", true)
            end)
        end)
        self.m_buffStar:changeJackpotAnim(function()
            self:delayCallBack(0.75, function ()
                self.m_jackpotBar:showRewardAnim(rewardData)
            end)
            self:playSpineAnim(self.m_greenElve, "actionframe3_2", false, function ()
                self:playElveIdle(self.m_greenElve, true)
                self:delayCallBack(2, function()
                    self.m_buffStar:hideStar(function()
                        self:delayCallBack(0.5, function ()
                            -- self.m_jackpotBar:runDarkAni(rewardData)
                            self.m_jackpotBar:runDarkAniForLv(rewardData)
                        end)
                        self:showJackpotWinCoins(rewardData, function()
                            self:markVisibleAnim(false)
                            -- self:delayCallBack(0.5, function ()
                                item:starChangeJackpot()
                                self:darkBuffJackpot(rewardData)
                            -- end)
                            if func then
                                func()
                            end
                        end)
                    end)
                end)
            end)
        end)
    end)
    
end

function JackpotElvesColorfulGame:continuedFlyParticleAnim(startPos, endPos)
    if self.flyNum == 0 then
        return
    end
    self:flyParticleAnim(startPos, endPos)
    self.flyNum = self.flyNum - 1
    self:delayCallBack(2/3,function ()
        self:continuedFlyParticleAnim(startPos, endPos)
    end)
end

--[[
    显示jackpot赢钱
]]
function JackpotElvesColorfulGame:showJackpotWinCoins(jackpotType,func)
    --升级弹框显示的Jackpot
    
    --显示jackpot赢钱
    self.m_jackpotWinIndex = self.m_jackpotWinIndex + 1
    local curWinCoins = self.jackpot_win[self.m_jackpotWinIndex]
    self.m_winCoins = self.m_winCoins + curWinCoins
    globalData.slotRunData.lastWinCoin = self.m_winCoins
    --刷新赢钱
    self.m_machine:updateBottomCoins(self.m_winCoins, false, true,self.m_winCoins - curWinCoins)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
    --     self.m_winCoins, false, true,self.m_winCoins - curWinCoins
    -- })
    self.m_jackpotBar:showIdleAnim(jackpotType)
    --显示jackpot赢钱界面
    self.m_machine:showJackpotWinView(jackpotType,curWinCoins,function(  )

        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    获取还没点击的位置
]]
function JackpotElvesColorfulGame:getLeftItems()
    local leftItems = {}
    local targetItems
    if self.m_colorType == 0 then
        targetItems = self.m_redItems
    else
        targetItems = self.m_greenItems
    end
    
    for index = 1,#targetItems do
        local item = targetItems[index]
        if not item.m_isClicked then
            leftItems[#leftItems + 1] = item
        end
    end

    return leftItems
end

--[[
    获取点击的位置
]]
function JackpotElvesColorfulGame:getItemByIndex(itemIndex)
    if self.m_colorType == 0 then
        return self.m_redItems[itemIndex]
    else
        return self.m_greenItems[itemIndex]
    end
end

--[[
    结束动画
]]
function JackpotElvesColorfulGame:runOverAni(func)
    -- 没有点开的礼盒动画
    local leftItems = self:getLeftItems()
    for jackpot, leftCount in pairs(self.m_totalReardData) do
        for index = 1, leftCount, 1 do
            local randIndex = math.random(1,#leftItems)
            local randItem = leftItems[randIndex]

            --刷新数据显示
            if jackpot ~= "buff" then
                randItem:updateUI("jackpot", jackpot)
            else
                randItem:updateUI("buff")
            end
            randItem:giftBoxDarkAnim()
            table.remove(leftItems,randIndex)
        end
    end
    if self.m_upgrade then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_threeToOne)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElve_rawForJackpotBuling)
    end
    for jackpot, vecItems in pairs(self.m_vecJackpotItems) do
        for index = 1, #vecItems, 1 do
            local item = vecItems[index]
            if jackpot == self.m_winJackpotType then
                item.oldParent = item:getParent()
                self:changeParent2Root(item)
                item:jackptRewardAnim(self.m_upgrade)
            else
                item:jackpotDarkAnim()
            end
        end
        
    end

    
        
    for id = 1, #JACKPOT_TYPE, 1 do
        local jackpotType = JACKPOT_TYPE[id]
        if jackpotType ~= self.m_winJackpotType then
            self.m_jackpotBar:expectOverAnim(jackpotType)
        end
    end

    if self.m_upgrade == true then
        self:delayCallBack(70 / 60, function ()
            self:upgradeJackpot()
        end)
    else
        local m_reelJackpotType = self.m_bonusData.true_jackpot_get[#self.m_bonusData.true_jackpot_get]
        self.m_jackpotBar:showRewardAnim(m_reelJackpotType)
        self:delayCallBack(2.5, function ()
            self:resetItemsParent()
        end)

        self:delayCallBack(2, function ()
            
            self:showJackpotWinCoins(m_reelJackpotType,function(  )
        
                if type(func) == "function" then
                    func()
                end
        
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                    self.m_machine:updateTopCoins()
                end
            end)
        end)
    end
    
end
--[[
    触发jackpot 放回原来的父节点
]]
function JackpotElvesColorfulGame:resetItemsParent()
    local vecItems = self.m_vecJackpotItems[self.m_winJackpotType]
    for index = 1, #vecItems, 1 do
        local item = vecItems[index]
        util_changeNodeParent(item.oldParent, item)
        item:setPosition(0, 0)
        item:runIdleAnim()
    end
end
--[[
    特殊效果子节点提层级
]]
function JackpotElvesColorfulGame:changeParent2Root(child, zorder)
    local parentNode = self:findChild("root")
    local pos = util_convertToNodeSpace(child, parentNode)
    util_changeNodeParent(parentNode, child, zorder or 2)
    child:setPosition(pos)
end

function JackpotElvesColorfulGame:resetItemsPos()
    -- for index = 1,24 do
    --     local redItem = self.m_redItems[index]
    --     util_changeNodeParent(redItem.m_parentNode, redItem)
    --     redItem:setPosition(cc.p(0,0))

    --     local greenItem = self.m_greenItems[index]
    --     util_changeNodeParent(greenItem.m_parentNode, greenItem)
    --     greenItem:setPosition(cc.p(0,0))
    -- end
    for i,v in ipairs(self.m_redItems) do
        local redItem = self.m_redItems[i]
        util_changeNodeParent(redItem.m_parentNode, redItem)
        redItem:setPosition(cc.p(0,0))
    end
    for i,v in ipairs(self.m_greenItems) do
        local greenItem = self.m_greenItems[i]
        util_changeNodeParent(greenItem.m_parentNode, greenItem)
        greenItem:setPosition(cc.p(0,0))
    end
end

--[[
    jackpot升级
]]
function JackpotElvesColorfulGame:upgradeJackpot()
    
    local vecItems = self.m_vecJackpotItems[self.m_winJackpotType]
    for index = 1, #vecItems, 1 do
        local endPos = cc.p(self:findChild("Node_jiesuan"):getPosition())
        local item = vecItems[index]
        item:runIdleAnim()
        local moveTo = cc.MoveTo:create(0.5, endPos)
        local callFunc = cc.CallFunc:create(function()
            util_changeNodeParent(item.oldParent, item)
            item:setPosition(0, 0)
            item:setVisible(false)
            if index == #vecItems then
                self:upgradeAnim()
            end
        end)
        item:runAction(cc.Sequence:create(moveTo, callFunc))
    end
end
--[[
    升级动画
]]
function JackpotElvesColorfulGame:upgradeAnim()
    local m_reelJackpotType = self.m_bonusData.true_jackpot_get[#self.m_bonusData.true_jackpot_get]
    self.m_upgradeReward:setVisible(true)
    self.m_upgradeReward:showUpgradeNode(self.m_winJackpotType, function()
        self:changeParent2Root(self.m_upgradeNode, 3)
        self.m_upgradeNode:playAction("shengji", false, function()
            self.m_upgradeNode:setVisible(false)
            util_changeNodeParent(self:findChild("Node_upgrade_shuoming"), self.m_upgradeNode)
            self.m_upgradeNode:setPosition(0, 0)
        end)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_tipToJackpot)
        self:delayCallBack(40 / 60, function()
            local endPos = cc.p(self:findChild("Node_jiesuan"):getPosition())
            local moveTo = cc.MoveTo:create(22 / 60, endPos)
            local callFunc = cc.CallFunc:create(function ()
                self.m_upgradeReward:updateJackpotUI(function()
                    --self.m_upgradeJackpotType
                    self.m_jackpotBar:showRewardAnim(m_reelJackpotType)
                    self:delayCallBack(2, function ()
                        self.m_upgradeReward:setVisible(false)
                        --self.m_upgradeJackpotType
                        self:showJackpotWinCoins(m_reelJackpotType, function(  )
                            if type(self.m_endFunc) == "function" then
                                self.m_endFunc()
                            end
                        end)
                    end)
                end)
            end)
            
            self.m_upgradeNode:runAction(cc.Sequence:create(moveTo, callFunc))
        end)
    end)

end
--[[
    礼盒提示抖动动画
]]
function JackpotElvesColorfulGame:randomRemindAnim()
    local leftItems = self:getLeftItems()
    local randomNum = math.random(2, 3)
    for index = 1, randomNum, 1 do
        local randIndex = math.random(1,#leftItems)
        local randItem = leftItems[randIndex]
        if randItem then
            randItem:clickRemindAnim()
            table.remove(leftItems,randIndex)
        end
        
    end
end
--[[
    spine 动画
]]
function JackpotElvesColorfulGame:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

--[[
    延迟回调
]]
function JackpotElvesColorfulGame:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return JackpotElvesColorfulGame