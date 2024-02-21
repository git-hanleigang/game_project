local SendDataManager = require "network.SendDataManager"
local ThanksGivingBonuLayer = class("ThanksGivingBonuLayer", util_require("base.BaseGame"))
function ThanksGivingBonuLayer:initUI(machine)
    self:createCsbNode("ThanksGiving/BonusGame.csb")
    self.m_startAniIsEnd = false--界面start动画是否播完
    self.m_dataIsReceived = false--是否接收到服务器数据
    self.m_machine = machine
    self.m_allOpenEggNum = 0
    self.m_jackpotMultiple = {"Grand","50","20","10"}

    self:initView()
    self:enableBtn(false)
    self:runCsbAction("idle")
    gLobalNoticManager:postNotification("CodeGameScreenThanksGivingMachine_eggBonusStart")
    self:runCsbAction("start",false,function ()
        self.m_startAniIsEnd = true
        self:enableBtn(true)
    end)
    self:sendData()
end

function ThanksGivingBonuLayer:initView()
    --添加鸡
    self.m_chicken = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
    self:findChild("ThanksGiving_ji"):addChild(self.m_chicken)
    util_spinePlay(self.m_chicken,"idleframe5",true)
    --添加鸡蛋
    self.m_eggNodeTab = {}
    for i = 1,12 do
        local egg = util_createAnimation("ThanksGiving_egg.csb")
        egg:playAction("idle",false)
        self:findChild("ThanksGiving_egg_"..i):addChild(egg)
        table.insert(self.m_eggNodeTab,egg)
        self:addClick(self:findChild("Panel_"..i))
        egg.isOpen = false
    end
    self:eggYaoyiyao()
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeThanksGivingSrc.ThanksGivingJackPotBarView")
    self:findChild("ThanksGiving_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self.m_machine)
    self.m_jackpotBar:runCsbAction("idle3",false)
    --添加计数圈圈
    self.m_countCirclesNodeTab = {}
    for i = 1,4 do
        local countCircles = util_createAnimation("ThanksGiving_yuan.csb")
        self.m_jackpotBar:findChild("ThanksGiving_yuan_"..i):addChild(countCircles)
        table.insert(self.m_countCirclesNodeTab,countCircles)
        countCircles.showNum = 0
        for j = 1,3 do
            local mulType = self.m_jackpotMultiple[i]
            countCircles:findChild(mulType.."_"..j):setVisible(true)
        end
        --添加圈圈上的光圈特效
        local lightCircles = util_createAnimation("ThanksGiving_yuan_L.csb")
        countCircles:findChild("guangquanNode"):addChild(lightCircles)
        lightCircles:playAction("actionframe",true)
        countCircles:findChild("guangquanNode"):setVisible(false)
    end

    util_setCascadeOpacityEnabledRescursion(self,true)
end
--随机几个没开的鸡蛋摇一摇
function ThanksGivingBonuLayer:eggYaoyiyao()
    local noOpenEggTab = {}
    for i,eggNode in ipairs(self.m_eggNodeTab) do
        if eggNode.isOpen == false then
            table.insert(noOpenEggTab,eggNode)
        end
    end
    local randNum = math.random(3,5)
    if randNum > #noOpenEggTab then
        randNum = #noOpenEggTab
    end
    for i = 1,randNum do
        local index = math.random(1,#noOpenEggTab)
        noOpenEggTab[index]:playAction("idle4",false)
    end
    performWithDelay(self:findChild("ThanksGiving_chui"),function ()
        self:eggYaoyiyao()
    end,1 + 20/30)
end
function ThanksGivingBonuLayer:onEnter()
    ThanksGivingBonuLayer.super.onEnter(self)
    --添加结算弹框
    gLobalNoticManager:addObserver(self,function(self,params)
        self:showSettlementLayer()
    end,"ThanksGivingBonuLayer_showSettlementLayer")
end

function ThanksGivingBonuLayer:onExit()
    ThanksGivingBonuLayer.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function ThanksGivingBonuLayer:enableBtn(isEnable)
    if isEnable == true then
        if self.m_startAniIsEnd == false or self.m_dataIsReceived == false then
            return
        end
    end
    for i = 1,12 do
        self:findChild("Panel_"..i):setTouchEnabled(isEnable)
    end
end

function ThanksGivingBonuLayer:clickFunc(sender)
    local name = sender:getName()
    local index = tonumber(string.match(name,"%d+"))
    self:startOpenEgg(index)
end
--打开一个鸡蛋
function ThanksGivingBonuLayer:startOpenEgg(index)
    if self.m_eggNodeTab[index].isOpen == false then
        if self.m_allOpenEggNum < #self.m_spinDataResult.bonus.extra.picks then
            self.m_allOpenEggNum = self.m_allOpenEggNum + 1
            self.m_eggNodeTab[index].isOpen = true
            local pickResult = tonumber(self.m_spinDataResult.bonus.extra.picks[self.m_allOpenEggNum])
            --添加锤子
            local hammer = util_createAnimation("ThanksGiving_chui.csb")
            self:findChild("ThanksGiving_chui"):addChild(hammer)

            local worldPos = self.m_eggNodeTab[index]:getParent():convertToWorldSpace(cc.p(100,81)) 
            local pos = hammer:getParent():convertToNodeSpace(worldPos)
            hammer:setPosition(pos)

            self.m_eggNodeTab[index]:findChild("BitmapFontLabel_"..self.m_jackpotMultiple[(pickResult+1)]):setVisible(true)

            self:enableBtn(false)
            gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_hammerHit.mp3")
            hammer:playAction("actionframe",false)
            performWithDelay(self,function ()
                -- if self.m_allOpenEggNum >= #self.m_spinDataResult.bonus.extra.picks then
                --     util_spinePlay(self.m_chicken,"jackpot2",false)
                --     self.m_chicken:addAnimation(0,"idleframe6",false)
                -- else
                    util_spinePlay(self.m_chicken,"jackpot1",false)
                    self.m_chicken:addAnimation(0,"idleframe5",true)
                    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_chickenShock.mp3")
                -- end

                hammer:removeFromParent()
                self.m_eggNodeTab[index]:playAction("actionframe",false)

                local collectParticle = util_createAnimation("ThanksGiving_egg_lizi.csb")
                self:addChild(collectParticle)
                collectParticle:findChild("Particle_1"):setPositionType(0)
                collectParticle:findChild("Particle_1"):resetSystem()
                
                
                local startWorldPos = self.m_eggNodeTab[index]:findChild("root"):getParent():convertToWorldSpace(cc.p(self.m_eggNodeTab[index]:findChild("root"):getPosition()))
                local startPos = self:convertToNodeSpace(startWorldPos)
                -- collectParticle:setPosition(cc.pAdd(startPos,cc.p(0,45)))
                collectParticle:setPosition(startPos)

                local endNode = self.m_countCirclesNodeTab[pickResult+1]:findChild("yuan_"..self.m_countCirclesNodeTab[pickResult+1].showNum + 1)
                local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
                local endPos = self:convertToNodeSpace(endWorldPos)

                local move = cc.MoveTo:create(1,endPos)
                local cfunc = cc.CallFunc:create(function ()
                    self.m_countCirclesNodeTab[pickResult+1].showNum = self.m_countCirclesNodeTab[pickResult+1].showNum + 1
                    self.m_countCirclesNodeTab[pickResult+1]:playAction("actionframe"..self.m_countCirclesNodeTab[pickResult+1].showNum,false)
                    self.m_countCirclesNodeTab[pickResult+1]:findChild("Particle_"..self.m_countCirclesNodeTab[pickResult+1].showNum):setVisible(true)
                    self.m_countCirclesNodeTab[pickResult+1]:findChild("Particle_"..self.m_countCirclesNodeTab[pickResult+1].showNum):setPositionType(0)
                    self.m_countCirclesNodeTab[pickResult+1]:findChild("Particle_"..self.m_countCirclesNodeTab[pickResult+1].showNum):resetSystem()
                    if self.m_countCirclesNodeTab[pickResult+1].showNum == 2 then
                        self.m_countCirclesNodeTab[pickResult+1]:findChild("guangquanNode"):setVisible(true)
                    end

                    if self.m_allOpenEggNum >= #self.m_spinDataResult.bonus.extra.picks then
                        gLobalNoticManager:postNotification("CodeGameScreenThanksGivingMachine_clearCurMusicBg")
                        self:enableBtn(false)
                        self:openEggEnd()
                        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_jackpotCollectEnd.mp3")
                        for i,v in ipairs(self.m_jackpotMultiple) do
                            if i == pickResult+1 then
                                self.m_jackpotBar:findChild("guang_"..pickResult+1):setVisible(true)
                                self.m_jackpotBar:findChild("Particle_"..pickResult+1):setVisible(true)
                                self.m_jackpotBar:findChild("Particle_"..pickResult+1):setPositionType(0)
                                self.m_jackpotBar:findChild("Particle_"..pickResult+1):resetSystem()
                            else
                                self.m_jackpotBar:findChild("guang_"..i):setVisible(false)
                            end
                            self.m_countCirclesNodeTab[i]:findChild("guangquanNode"):setVisible(false)

                        end
                        self.m_jackpotBar:runCsbAction("actionframe",true)


                    
                        util_spinePlay(self.m_chicken,"jackpot2",false)
                        self.m_chicken:addAnimation(0,"idleframe6",false)
                    else
                        self:enableBtn(true)
                    end

                    collectParticle:removeFromParent()
                end)
                local seq = cc.Sequence:create({move,cfunc})
                collectParticle:runAction(seq)
                gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_jackpotCollect.mp3")
            end,15/30)
            
        end
    end
end
--鸡蛋敲完了
function ThanksGivingBonuLayer:openEggEnd()
    self:findChild("ThanksGiving_chui"):stopAllActions()
    performWithDelay(self,function ()
        --没开的鸡蛋变暗
        for i,eggNode in ipairs(self.m_eggNodeTab) do
            if eggNode.isOpen == false then
                self.m_allOpenEggNum = self.m_allOpenEggNum + 1
                local pickResult = self.m_spinDataResult.bonus.extra.left[self.m_allOpenEggNum - #self.m_spinDataResult.bonus.extra.picks]
                eggNode:findChild("BitmapFontLabel_"..self.m_jackpotMultiple[(pickResult+1)]):setVisible(true)
                eggNode:playAction("dark",false)
            end
        end
        performWithDelay(self,function ()
            self:showSettlementLayer()
        end,1)
    end,1)
end
--弹出结算界面
function ThanksGivingBonuLayer:showSettlementLayer()
    if self.m_spinDataResult.bonus.extra.type == 0 then
        local settlementLayer = util_createView("CodeThanksGivingSrc.ThanksGivingJackPotWinView")
        if globalData.slotRunData.machineData.p_portraitFlag then
            settlementLayer.getRotateBackScaleFlag = function() return false end
        end
        gLobalViewManager:showUI(settlementLayer)
        settlementLayer:initViewData(1,self.m_spinDataResult.bonus.extra.winCoins,function ()
            self:closeSelf()
        end)
    else
        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_BonusGameOverView.mp3")
        local settlementLayer = util_createView("CodeThanksGivingSrc.ThanksGivingBonusGameOverView")
        if globalData.slotRunData.machineData.p_portraitFlag then
            settlementLayer.getRotateBackScaleFlag = function() return false end
        end
        gLobalViewManager:showUI(settlementLayer)
        settlementLayer:initViewData(self.m_spinDataResult.avgBet,tonumber(self.m_jackpotMultiple[self.m_spinDataResult.bonus.extra.type + 1]),self.m_spinDataResult.bonus.extra.winCoins,function ()
            self:closeSelf()
        end)
    end
end
--数据发送
function ThanksGivingBonuLayer:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
--接收返回消息
function ThanksGivingBonuLayer:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        if spinData.action == "FEATURE" then
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_WheelWinCoins = spinData.result.bonus.bsWinCoins
            
            self.m_totleWimnCoins = spinData.result.winAmount

            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            self.m_spinDataResult = spinData.result
        
            self.m_machine:SpinResultParseResultData(spinData)
            -- self.m_data = spinData.result.selfData--服务器传过来的selfData字段
            self:bonusStart()
        end
        
    else
        -- 处理消息请求错误情况
    end
end
function ThanksGivingBonuLayer:setAvgBet(avgbet)
    self:findChild("m_lb_coins"):setString(util_formatCoins(avgbet,50))
    self:updateLabelSize({label = self:findChild("m_lb_coins"),sx = 1.8,sy = 1.8},228)
end
--收到消息后 开始bonus小游戏
function ThanksGivingBonuLayer:bonusStart()
    self.m_dataIsReceived = true
    self:enableBtn(true)

    -- gLobalNoticManager:postNotification("ThanksGivingBoottomUiView_updateTotalBet",{util_getFromatMoneyStr(self.m_spinDataResult.avgBet)})
end

function ThanksGivingBonuLayer:closeSelf()
    self:runCsbAction("over",false,function()
        gLobalNoticManager:postNotification("CodeGameScreenThanksGivingMachine_eggbonusOver")
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
        self:removeFromParent()
    end)
end
return ThanksGivingBonuLayer