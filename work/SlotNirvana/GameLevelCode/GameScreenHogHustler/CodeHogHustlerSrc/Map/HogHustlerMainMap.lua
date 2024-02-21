---
--xcyy
--2018年5月23日
--HogHustlerMainMap.lua
local SendDataManager = require "network.SendDataManager"
local HogHustlerMainMap = class("HogHustlerMainMap",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")
HogHustlerMainMap.ACTION_SEND=1  --发送消息阶段
HogHustlerMainMap.ACTION_RECV=2  --接受数据阶段
HogHustlerMainMap.ACTION_OVER=3  --停止阶段


function HogHustlerMainMap:initUI(machine)
    self.m_machine = machine
    self.m_isFirstTime = false
    self.m_first_step = self.ACTION_OVER  -- 新手引导状态 
    self.m_mapMul = {1, 1, 1}
    self:createCsbNode("HogHustler_dafuweng.csb")

    self.m_timingNode = cc.Node:create()
    self:addChild(self.m_timingNode)
    self.m_timingAutoNode = cc.Node:create()
    self:addChild(self.m_timingAutoNode)

    self.m_diceButton = util_createView("CodeHogHustlerSrc.Map.HogHustlerDice", self)
    self:findChild("button_ui"):addChild(self.m_diceButton)

    self.m_level_node = util_createView("CodeHogHustlerSrc.Map.HogHustlerLevelPrize", self)
    self:findChild("levelprize"):addChild(self.m_level_node)
    self.m_allWin_node = util_createAnimation("HogHustler_dafuweng_allwin.csb")
    self:findChild("allwin"):addChild(self.m_allWin_node)
    self.m_allWin_node:playAction("idle2", true)
    self:setClickPosition()
    self:initCoinsPos()
    self.m_action = self.ACTION_OVER
    self.m_Click = false
    self.m_allWin = 0
    self.m_overTotalWin = 0   --allwin用于加动画     最后退出时用服务端累加的值

    --烟花
    self.m_fireworks = util_createAnimation("HogHustler_dafuweng_yanhua.csb")
    self:findChild("yanhua"):addChild(self.m_fireworks)
    self.m_fireworks:setVisible(false)

    self.m_dice_spine = util_spineCreate("HogHustler_Prop_Dice", true, true)
    self.m_diceButton:findChild("shaizi"):addChild(self.m_dice_spine)
    self:findChild("coins_ui"):setLocalZOrder(1)
    self:findChild("button_ui"):setLocalZOrder(2)
    self.m_effectPropNode = cc.Node:create()
    self:addChild(self.m_effectPropNode, 4)
    self:runCsbAction("idle",true)
    -- self:changeClickBtnParent()


    self.m_mask = util_createAnimation("HogHustler_Mask.csb")
    self.m_effectPropNode:addChild(self.m_mask)
    self.m_mask:setVisible(false)

    self.m_guide = util_createAnimation("HogHustler_xinshoutanban.csb")
    self.m_effectPropNode:addChild(self.m_guide, 10)
    self.m_guide:setVisible(false)

    --dice0 tips
    self.m_dice0Tips = util_createView("CodeHogHustlerSrc.HogHustlerTipsView", self, "HogHustler_dafuwentips.csb", true)
    self.m_diceButton:findChild("Node_tips"):addChild(self.m_dice0Tips)
    self.m_dice0Tips:setVisible(false)
    

    self:addClick(self:findChild("Panel_tips_click"))
    self:findChild("Panel_tips_click"):setSwallowTouches(false)


    self.m_diceButton:resetToNormal()
end


function HogHustlerMainMap:onEnter()
    HogHustlerMainMap.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_allWin_node:playAction("actionframe2", false, function()
            self.m_allWin_node:playAction("idle2", true)
        end)
        self:updataAllWinNum(params[1], params[2])
    end,"MAP_ADD_COINS_SMELLYRICH")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:runDiceEffect()
        self:waitWithDelay(5/60, function()
            self:resetDiceNum()
        end)
    end,"MAP_DICE_NUM_SMELLYRICH")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:effectOver(params)
    end,"MAP_OVER_SMELLYRICH")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:initBadgeNum()
        self:updataShowBadgeNum()
    end,"MAP_BADGE_NUM_SMELLYRICH")
end

function HogHustlerMainMap:onExit()

    self:clearAutoSpinTiming()

    if self.m_circleSchedule ~= nil then
        scheduler.unscheduleGlobal(self.m_circleSchedule)
        self.m_circleSchedule = nil
    end

    HogHustlerMainMap.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function HogHustlerMainMap:setMapInfo(mapPropInfo)
    if mapPropInfo then
        self.m_mapPropInfo = mapPropInfo
    end
end

function HogHustlerMainMap:setRolePosInfo(mapPos)
    if mapPos then
        self.m_mapPos = mapPos
    end
end

function HogHustlerMainMap:setMapPrizeInfo(prize)
    self.m_prize = prize or 0
    self.m_level_node:setMapPrizeInfo(prize)
end

function HogHustlerMainMap:setDicNum(diceNum)
    self.m_diceNum = diceNum or 0
end

function HogHustlerMainMap:initCurMapItem()
    local dafuweng = self:findChild("dafuweng")
    local mapPropItemInfo = {}
    mapPropItemInfo.index = self.m_mapPos[1] + 1
    mapPropItemInfo.rolePos = self.m_mapPos[2] + 1
    mapPropItemInfo.hummerNum = self.m_mapPos[3]
    mapPropItemInfo.mapInfo = self.m_mapPropInfo[mapPropItemInfo.index]
    self.m_curMapItem = util_createView("CodeHogHustlerSrc.Map.HogHustlerMainMapItem", mapPropItemInfo, self)
    dafuweng:addChild(self.m_curMapItem)
    self.m_curMapItem:setDiceBttonWorldPos(self:getDiceBttonWorldPos())
    self.m_curMapItem:initMapScale()

    if mapPropItemInfo.index == 1 then
        local mapPropItemInfo2 = {}
        mapPropItemInfo2.index = 2
        mapPropItemInfo2.rolePos = 1
        mapPropItemInfo2.hummerNum = 1
        mapPropItemInfo2.mapInfo = self.m_mapPropInfo[mapPropItemInfo2.index]
        self.m_curMapItem2 = util_createView("CodeHogHustlerSrc.Map.HogHustlerMainMapItem", mapPropItemInfo2, self)
        dafuweng:addChild(self.m_curMapItem2)
        self.m_curMapItem2:setDiceBttonWorldPos(self:getDiceBttonWorldPos())
        self.m_curMapItem2:initMapScale()
        self.m_curMapItem2:setVisible(false)

        local mapPropItemInfo3 = {}
        mapPropItemInfo3.index = 3
        mapPropItemInfo3.rolePos = 1
        mapPropItemInfo3.hummerNum = 1
        mapPropItemInfo3.mapInfo = self.m_mapPropInfo[mapPropItemInfo3.index]
        self.m_curMapItem3 = util_createView("CodeHogHustlerSrc.Map.HogHustlerMainMapItem", mapPropItemInfo3, self)
        dafuweng:addChild(self.m_curMapItem3)
        self.m_curMapItem3:setDiceBttonWorldPos(self:getDiceBttonWorldPos())
        self.m_curMapItem3:initMapScale()
        self.m_curMapItem3:setVisible(false)
    elseif mapPropItemInfo.index == 2 then
        local mapPropItemInfo3 = {}
        mapPropItemInfo3.index = 3
        mapPropItemInfo3.rolePos = 1
        mapPropItemInfo3.hummerNum = 1
        mapPropItemInfo3.mapInfo = self.m_mapPropInfo[mapPropItemInfo3.index]
        self.m_curMapItem3 = util_createView("CodeHogHustlerSrc.Map.HogHustlerMainMapItem", mapPropItemInfo3, self)
        dafuweng:addChild(self.m_curMapItem3)
        self.m_curMapItem3:setDiceBttonWorldPos(self:getDiceBttonWorldPos())
        self.m_curMapItem3:initMapScale()
        self.m_curMapItem3:setVisible(false)
    end
end

function HogHustlerMainMap:resetData()
    local mapPropItemInfo = {}
    mapPropItemInfo.index = self.m_mapPos[1] + 1
    mapPropItemInfo.rolePos = self.m_mapPos[2] + 1
    mapPropItemInfo.hummerNum = self.m_mapPos[3]
    mapPropItemInfo.mapInfo = self.m_mapPropInfo[mapPropItemInfo.index]

    if mapPropItemInfo.index == 2 and self.m_curMapItem2 ~= nil then
        local temp = self.m_curMapItem
        self.m_curMapItem = self.m_curMapItem2
        temp:setVisible(false)
        self.m_curMapItem2 = nil
        self.m_curMapItem:resetMapItemData(mapPropItemInfo)
        self.m_curMapItem:setVisible(true)
    elseif mapPropItemInfo.index == 3 then
        if self.m_curMapItem3 ~= nil then
            local temp = self.m_curMapItem
            self.m_curMapItem = self.m_curMapItem3
            temp:setVisible(false)
            self.m_curMapItem3 = nil
            self.m_curMapItem:resetMapItemData(mapPropItemInfo)
            self.m_curMapItem:setVisible(true)
        else
            self.m_curMapItem:resetMapItemData(mapPropItemInfo)
        end
    end
end

function HogHustlerMainMap:initMap(mapInfo)
    local mapPropInfo = mapInfo.mapPropInfo
    local mapPos = mapInfo.mapPos
    local prize = mapInfo.prize
    self.m_mapMul = mapInfo.mapMul
    self.m_level_node.m_mapMul = mapInfo.mapMul
    self:setMapInfo(mapPropInfo)
    self:setRolePosInfo(mapPos)
    self:setMapPrizeInfo(prize)
    self:initCurMapItem()
    self:initLevel(self.m_mapPos[1])
    self:initDiceNum(mapInfo.diceNum)
    self:initAllWinNum()
    self:initBadgeNum()
    self:updataShowBadgeNum(true)
    self:updataShowPrizeNum()
end

function HogHustlerMainMap:initLevelPrizeNum()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    if self.m_mapMul and self.m_level_node then
        self.m_level_node:updateLevelPrize(self.m_mapMul, totalBet)
    end
end

function HogHustlerMainMap:initDiceNum(diceNum)
    self:setDicNum(diceNum)
    self:resetDiceNum()
end

--结束
function HogHustlerMainMap:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_tips_click" then
        if self.m_diceNum <= 0 then
            if self.m_dice0Tips then
                self.m_dice0Tips:TipClick()
            end
        end
    end

    if self:checkAllBtnClickStates() then
        return
    else
        
    end

    if name == "Button_1" then --返回
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        self.m_Click = true
        self:showOver()
    end
end

--每次effectover 间隔回调
function HogHustlerMainMap:timingAutoNodeFunc()
    self.m_timingAutoNode:stopAllActions()
    local diceButtonStatus = self.m_diceButton:getButtonStatus()
    if diceButtonStatus == "AUTO" then
        -- print("buttonProcess auto")
        self:buttonProcess()
    end
end

--处理dice按钮点击
function HogHustlerMainMap:buttonProcess()
    if self:checkAllBtnClickStates() then
        return
    end
    -- if self.m_first_step == self.ACTION_OVER then
        -- print(string.format("sendDATA +++++++++++++++++++++++++++ %d", self.countsend))
        self:processDiceSpin()
    -- end
end

function HogHustlerMainMap:processDiceSpin()
    if self.m_diceNum > 0 then
        self.m_diceNum  = self.m_diceNum - 1
        self:resetDiceNum()
        self:sendData()
        if self.m_isFirstTime then
            self:hideFirstStep()
        end
    else
        if self.m_dice0Tips then
            self.m_dice0Tips:TipClick()
        end
    end
end


function HogHustlerMainMap:resetDiceNum()
    self.m_diceButton:findChild("m_lb_num1"):setString(self.m_diceNum)
    self:updateLabelSize({label=self.m_diceButton:findChild("m_lb_num1"),sx=0.75,sy=0.75},79)
end

function HogHustlerMainMap:initAllWinNum()
    self.m_overTotalWin = 0
    self.m_allWin = 0
    local node = self.m_allWin_node:findChild("m_lb_coins")
    node:setString(util_formatCoins(self.m_allWin, 40))
    self:updateLabelSize({label=node,sx=1,sy=1},604)
    node:setVisible(self.m_allWin ~= 0)
    self.m_allWin_node:findChild("jinbi"):setVisible(self.m_allWin ~= 0)
end

--平均bet
function HogHustlerMainMap:updataShowPrizeNum()
   self.m_level_node:updataShowPrizeNum()
end

--徽章
function HogHustlerMainMap:initBadgeNum()
    self.m_badge_num = self.m_mapPos[4] or 0
    self.m_level_node:initBadgeNum(self.m_badge_num)
end

function HogHustlerMainMap:initLevel(pos)
    self.m_level_node:initLevel(pos)
end

--刷新徽章显示
function HogHustlerMainMap:updataShowBadgeNum(isInit)
    self.m_level_node:updataShowBadgeNum(isInit)
end

function HogHustlerMainMap:setClickPosition()
    local clickNode = self:findChild("Button_1")
    local changeX = (display.width/2) / self.m_machine.m_machineRootScale - 120 - self.m_machine.m_fixX
    local changeY = (display.height/2) / self.m_machine.m_machineRootScale - 150

    clickNode:setPosition(cc.p(changeX,changeY))

    local clickNode1 = self.m_diceButton:findChild("button_0")
    local changeY1 = (-display.height/2) / self.m_machine.m_machineRootScale  + 104
    clickNode1:setPosition(cc.p(changeX,changeY1))

end

--数据发送
function HogHustlerMainMap:sendData()
    self.m_action=self.ACTION_SEND
    local cellIndex = self.m_clickType or 0
    local sendData = {}
    sendData.pageCellIndex = cellIndex
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = sendData}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

function HogHustlerMainMap:checkAllBtnClickStates( )
    local notClick = false

    if self.m_action ~= self.ACTION_OVER then
        notClick = true
    end

    if self.m_Click then
        notClick = true
    end

    return notClick

end

function HogHustlerMainMap:resetBtnClickStates()
    self.m_action = self.ACTION_OVER
    self.m_Click = false
end

function HogHustlerMainMap:setClick(isClick)
    self.m_Click = isClick
end

function HogHustlerMainMap:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPECIAL" then
            self.m_action = self.ACTION_RECV
            self.m_machine:SpinResultParseResultData(spinData)
            local result = spinData.result
            local selfData = result.selfData
            self.m_mapAward = selfData.mapAward or 0
            self.m_overTotalWin = self.m_overTotalWin + self.m_mapAward.totalWin
            self:setDicNum(selfData.diceNum)
            self:setRolePosInfo(selfData.mapPos)
            local moveNum = self.m_mapAward.num or 0
            -- print(string.format("服务器数据： 位置%d  移动%d  骰子数%d", selfData.mapPos[2],self.m_mapAward.num,selfData.diceNum))
            self:showDiceSpineNum(moveNum, function()
                -- print("begin MOve")
                self:showDiceEffect()
            end)
        end
    else
        -- 处理消息请求错误情况
    end
end

function HogHustlerMainMap:showDiceEffect()
    
    


    local moveNum = self.m_mapAward.num or 0
    local coins = self.m_mapAward.coin or {}

    -- local curPos = nil
    -- if self.m_mapPos and self.m_mapPos[2] then
    --     curPos = self.m_mapPos[2] + 1 - moveNum
    -- end
    -- if curPos == nil then
    --     local a = 1
    -- end
    self.m_curMapItem:roleMove(moveNum, coins, function()
        self:showPropEffect()
    end)
end

--
function HogHustlerMainMap:showPropEffect()
    local propType = self.m_mapAward.type
    if propType == 0 then
        self:effectOver()
    else
        local prop_type = self.m_mapAward.type
        local prop_win = self.m_mapAward.typeWin
        local pos = self.m_mapPos[2] + 1
        if self.m_mapAward.isPass then
            pos = self.m_mapAward.oldmapPos[2] + 1
        end
        self.m_curMapItem:showPropEffect(prop_type, prop_win, pos, self.m_isFirstTime)
        local soundStr = string.format("HogHustlerSounds/sound_smellyRich_role_getProp%d.mps",util_random(1,3))
        gLobalSoundManager:playSound(soundStr)
    end 
end

function HogHustlerMainMap:updataAllWinNum(addCoins, stepNum)
    local step_Num = 12 
    if stepNum then
        step_Num = stepNum
    end
    local start_coins = self.m_allWin
    self.m_allWin  = self.m_allWin + addCoins
    local node = self.m_allWin_node:findChild("m_lb_coins")
    node:setVisible(true)
    self.m_allWin_node:findChild("jinbi"):setVisible(true)
    local addValue = addCoins / step_Num
    if step_Num > 12 then
        
        -- self.m_allWinAdd_soundId = gLobalSoundManager:playSound("HogHustlerSounds/soun_smellyRich_allWin_add.mp3")
        self.m_allWinAdd_soundId = gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_allwinappear_1_collect_end)
    end
    util_jumpNum(node,start_coins,self.m_allWin,addValue,1/60,{30}, nil, nil,function(  )
        if step_Num > 12 then
            if self.m_allWinAdd_soundId then
                gLobalSoundManager:stopAudio(self.m_allWinAdd_soundId)
                self.m_allWinAdd_soundId = nil
            end
            -- gLobalSoundManager:playSound("HogHustlerSounds/soun_smellyRich_allWin_end.mp3")
        end
    end,function()
        self:updateLabelSize({label=node,sx=1,sy=1},604)
    end)
end

function HogHustlerMainMap:getDiceBttonWorldPos()
    local worldPos = self.m_diceButton:findChild("button_0"):getParent():convertToWorldSpace(cc.p(self.m_diceButton:findChild("button_0"):getPosition()))
    return worldPos
end

function HogHustlerMainMap:getDafuwengWorldPos()
    local worldPos = self:findChild("dafuweng"):getParent():convertToWorldSpace(cc.p(self:findChild("dafuweng"):getPosition()))
    return worldPos
end

function HogHustlerMainMap:effectOver(isChange)
    if self.m_mapAward.isPass then
        self.m_level_node:upLevelAni()
    end
    -- self:waitWithDelay(0.5, function()
        if isChange then
            self.m_isFirstTime  = false
            self:findChild("Button_1"):setVisible(true)
            -- self:findChild("Button_1"):setOpacity(0)
            -- util_playFadeInAction(self:findChild("Button_1"),0.5)
        end
        if self.m_isFirstTime then
            self:showFirstStep()
        end
        globalData.slotRunData.gameEffStage = GAME_EFFECT_OVER_STATE
        self.m_action = self.ACTION_OVER
        if self.m_mapAward.isPass then
            self.m_Click = true
            -- self:waitWithDelay(105/60, function()

                self.m_diceButton:resetToNormal()

                self.m_curMapItem.m_pig:openSafeBox(function()
                    self:upRichMain()
                end, function()
                    --开保险箱时
                    self:playFireworks()
                    if self.m_curMapItem and self.m_curMapItem.m_roleItme then
                        self.m_curMapItem.m_roleItme:roelGreed()
                    end
                end)
                
            -- end)
        elseif self.m_diceNum == 0 then
            self.m_Click = true
            self:waitWithDelay(1, function()
                self:showOver()
            end)
        else

            self.m_timingAutoNode:stopAllActions()
            performWithDelay(self.m_timingAutoNode, function(  )
                self:timingAutoNodeFunc()
            end, 0.5)

        end
    -- end)
end

function HogHustlerMainMap:setFirstTime(firstTime)
    self.m_isFirstTime = firstTime
end

function HogHustlerMainMap:showStart()
    self.m_curMapItem:showRoleStart()
    self:showDiceIdle()
    if self.m_isFirstTime then
        self.m_first_step = self.ACTION_SEND
        self:findChild("Button_1"):setVisible(false)
        self:showFirstStep()  
    else
        self:findChild("Button_1"):setVisible(true)
    end
end

function HogHustlerMainMap:resetState()
    self.m_curMapItem:showRoleStart()
    if not self.m_isFirstTime then
        self:findChild("Button_1"):setVisible(true)
    end
end

function HogHustlerMainMap:showDiceIdle()
    self:initAllWinNum()
    self.m_dice_startNameStr = string.format("actionframe%d_5", 5)
    util_spinePlay(self.m_dice_spine, "idle", true)
end

function HogHustlerMainMap:showDiceSpineNum(num, callBack)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_diceNum_run.mp3")
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_dice_rock)
    local start_str = self.m_dice_startNameStr
    self.m_dice_startNameStr = string.format("actionframe%d_5", num)
    local end_str = "actionframe"..num
    util_spinePlay(self.m_dice_spine, start_str)
    util_spineEndCallFunc(self.m_dice_spine, start_str, function()
        util_spinePlay(self.m_dice_spine, end_str)
        util_spineEndCallFunc(self.m_dice_spine, end_str, function()
            local soundStr = string.format("HogHustlerSounds/sound_HogHustler_diceNum_run%d.mp3", num)
            gLobalSoundManager:playSound(soundStr)
            if callBack then
                callBack()
            end
        end)
    end)
end

function HogHustlerMainMap:showFirstStep()
    self.m_first_step = self.ACTION_SEND
    gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_dice_rolling.mp3")

    if self.m_diceButton.m_guideHands and self.m_diceButton.m_guideHands.m_csbAct and not tolua.isnull(self.m_diceButton.m_guideHands.m_csbAct) then
        util_resetCsbAction(self.m_diceButton.m_guideHands.m_csbAct)
    end    
    self.m_diceButton.m_guideHands:runCsbAction("start",false, function()
        self.m_diceButton.m_guideHands:runCsbAction("idle2",true)
        self.m_first_step = self.ACTION_OVER
    end, 60)
end

function HogHustlerMainMap:hideFirstStep()
    if self.m_diceButton.m_guideHands and self.m_diceButton.m_guideHands.m_csbAct and not tolua.isnull(self.m_diceButton.m_guideHands.m_csbAct) then
        util_resetCsbAction(self.m_diceButton.m_guideHands.m_csbAct)
    end
    self.m_diceButton.m_guideHands:runCsbAction("over",false, function()
        self.m_diceButton.m_guideHands:runCsbAction("idle",true)
    end, 60)
end

function HogHustlerMainMap:showPropMark(csbName)

end

function HogHustlerMainMap:showMask()
    self.m_mask:setVisible(true)
    self.m_mask:playAction("start", false, function()
        self.m_mask:playAction("idle", true)
    end, 60)
end

function HogHustlerMainMap:hideMask()
    self.m_mask:playAction("over", false, function()
        self.m_mask:setVisible(false)
    end, 60)
end

--type 1钥匙 2骰子 3徽章
function HogHustlerMainMap:showGuide(_func, _type, _win)
    local type = _type
    local win = _win
    local name_tag = {"Node_yaoshi", "Node_touzi", "Node_huizhang"}
    self.m_guide:setVisible(true)
    for i=1,3 do
        self.m_guide:findChild(name_tag[i]):setVisible(i == type)
        if i == 3 then
            self.m_guide:findChild("bai100"):setVisible(win == 100)
            self.m_guide:findChild("bai50"):setVisible(win == 50)
            self.m_guide:findChild("bai100zi"):setVisible(win == 100)
            self.m_guide:findChild("bai50zi"):setVisible(win == 50)
        end
    end
    
    self.m_guide:playAction("auto", false, function()
        self.m_guide:setVisible(false)
    end, 60)

    if type == 1 then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_key_popup)
    elseif type == 2 then
    elseif type == 3 then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_buff_popup)
    end

    self:waitWithDelay(130/60, function()

        local flyNode = util_createAnimation("HogHustler_xinshoutanban_fly.csb")
        self.m_effectPropNode:addChild(flyNode, 20)

        local nodePos = util_convertToNodeSpace(self.m_guide:findChild(name_tag[type]), self.m_effectPropNode)
        flyNode:setPosition(cc.p(nodePos))
        for i=1,3 do
            flyNode:findChild(name_tag[i]):setVisible(i == type)
            if i == 3 then
                flyNode:findChild("bai100"):setVisible(win == 100)
                flyNode:findChild("bai50"):setVisible(win == 50)
            end
        end

        local endPos
        if type == 1 then
            local worldPos = self.m_curMapItem:getBoxKeyWorldPos()
            endPos = self.m_effectPropNode:convertToNodeSpace(worldPos)
        elseif type == 2 then
            local worldPos = self:getDiceBttonWorldPos()
            endPos = self.m_effectPropNode:convertToNodeSpace(worldPos)
        elseif type == 3 then
            local worldPos = self.m_curMapItem:getLevelStartWorldPos()
            endPos = self.m_effectPropNode:convertToNodeSpace(worldPos)
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_buff_fly2levelprize)
        end


        flyNode:playAction("fly")

        -- self:runFibonacciCircle(flyNode, function (  )
            -- local curX = flyNode:getPositionX()
            -- local curY = flyNode:getPositionY()
            -- local centerPos = cc.p((endPos.x + curX) / 2, (endPos.y + curY) / 2)
            -- local bezier = {}
            -- bezier[1] = cc.p(curX, curY)
            -- bezier[2] = cc.p(centerPos.x - 300, centerPos.y - 300)
            -- bezier[3] = endPos

            local action_list = {}
            -- action_list[#action_list + 1] = cc.EaseIn:create(cc.BezierTo:create(90/60, bezier), 2)
            action_list[#action_list + 1] = cc.EaseIn:create(cc.MoveTo:create(45/60, endPos), 2)
            action_list[#action_list + 1] = cc.CallFunc:create(function()

                if type == 1 then
                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_flyend)
                    self.m_curMapItem:showPigEffect(win)
                elseif type == 2 then
                    gLobalNoticManager:postNotification("MAP_DICE_NUM_SMELLYRICH")
                    gLobalNoticManager:postNotification("MAP_OVER_SMELLYRICH")
                    
                elseif type == 3 then
                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_buff_fly2levelprize_fankui)
                    gLobalNoticManager:postNotification("MAP_BADGE_NUM_SMELLYRICH")
                    gLobalNoticManager:postNotification("MAP_OVER_SMELLYRICH", true)
                end

                flyNode:removeFromParent()
            end)
            
            local sq = cc.Sequence:create(action_list)
            flyNode:runAction(sq)
        -- end, 4)

        -- endPos = cc.pSub(cc.p(endPos), cc.p(self.m_prop:findChild("Node_2"):getPosition()))
        
        self:hideMask()
        if _func then
            _func()
        end
    end)
end



function HogHustlerMainMap:changeCoinsUIZorder()
    self:findChild("allwin"):setLocalZOrder(2)
end

function HogHustlerMainMap:resetCoinsUIZorder()
    self:findChild("coins_ui"):setLocalZOrder(1)
    self:findChild("allwin"):setLocalZOrder(1)
    self:findChild("levelprize"):setLocalZOrder(0)
end

function HogHustlerMainMap:upRichMain()
    local moveTo = cc.MoveTo:create(0.5,cc.p(0, -15))
    self:findChild("levelprize"):runAction(moveTo)
    self:findChild("coins_ui"):setLocalZOrder(3)
    self.m_level_node:upLevel()
end

function HogHustlerMainMap:upRichMainEnd()
    local action_list = {}
    action_list[#action_list + 1] = cc.MoveTo:create(0.5, self.m_levelPos)
    action_list[#action_list + 1] = cc.CallFunc:create(function()
        self.m_curMapItem:showAddCoins()
        self:resetCoinsUIZorder()
    end)
    local sq = cc.Sequence:create(action_list)
    self:findChild("levelprize"):runAction(sq)
    self:waitWithDelay(4, function()
        if self.m_diceNum == 0 then
            self:showOver()
        else
            self:resetBtnClickStates()
        end
    end)
end

function HogHustlerMainMap:changeMapItem()
    -- local mapItem = self.m_curMapItem
    -- mapItem:setLocalZOrder(2)

    
    self:resetData()
    




    -- self:initCurMapItem()
    self.m_diceButton:resetToNormal()
    -- mapItem:runCsbAction("over", false, function()
        -- mapItem:setVisible(false)
        -- mapItem:delItem(function()
            -- if mapItem and not tolua.isnull(mapItem) then
                -- mapItem:removeFromParent()
            -- end
        -- end)
    -- end)

    -- self.m_curMapItem:runCsbAction("start")
end

function HogHustlerMainMap:flyCoins(coinNum)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_toAllWin.mp3")
    
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_allwinappear_1_collect_start)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_levelprize_flycoins2allwin)
    

    local endPos = util_convertToNodeSpace(self.m_allWin_node:findChild("m_lb_coins"), self.m_effectPropNode)
    local startPos = self.m_level_node:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_level_node:findChild("m_lb_coins"):getPosition()))
    local nodeStartPos = self.m_effectPropNode:convertToNodeSpace(startPos)
    local coins = util_createAnimation("HogHustler_levelprize_number.csb")
    coins:setPosition(nodeStartPos)
    coins:findChild("m_lb_coins"):setString(util_formatCoins(coinNum, 40))
    self:updateLabelSize({label=coins:findChild("m_lb_coins"),sx=0.98,sy=0.98},610)
    coins:playAction("actionframe")
    self.m_effectPropNode:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    util_playMoveToAction(coins, 0.5, endPos, function()
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_toAllwinFankui.mp3")
        -- gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_allwinappear_1_collect_end)
        self.m_allWin_node:playAction("actionframe", false, function()
            self.m_allWin_node:playAction("idle2", true)
        end)
        self:updataAllWinNum(coinNum, 120)
        coins:removeFromParent()
    end)
end

function HogHustlerMainMap:getAllWinLabelWorldPos()
    local node = self.m_allWin_node:findChild("m_lb_coins")
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return pos
end

function HogHustlerMainMap:showOver()
    self:findChild("Button_1"):setVisible(false)
    local callFunc = function()
        gLobalNoticManager:postNotification("MAP_HIDE_CLICK_SMELLYRICH")
    end
    if self.m_overTotalWin == 0 then
        callFunc()
    else
        self.m_machine:clearCurMusicBg()
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_richMan_over_show.mp3")
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_popupover_start)
        local ownerlist={}
        ownerlist["m_lb_coins"] = util_formatCoins(self.m_overTotalWin,30)
        local view = self.m_machine:showDialog("DafuwengOver",ownerlist, function()
            callFunc()
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},732)



        self.m_machine:addPopupCommonRole(view, nil, nil, "start_tanban2", "idle_tanban2")
        self.m_machine:checkFeatureOverTriggerBigWin(self.m_overTotalWin, self.m_machine.GAME_MAP_EFFECT)

        view:findChild("root"):setScale(self.m_machine.m_machineRootScale)
        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
            local coinsLabel = view:findChild("m_lb_coins")
            local startPos = coinsLabel:getParent():convertToWorldSpace(cc.p(coinsLabel:getPosition()))
            -- local startPos = cc.p(display.cx , display.cy - 27)
            local endPos = globalData.flyCoinsEndPos
            -- local baseCoins = globalData.userRunData.coinNum - self.m_allWin
            -- gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,self.m_allWin)
            local baseCoins = globalData.userRunData.coinNum - self.m_overTotalWin
            gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,self.m_overTotalWin)

            local params = {self.m_overTotalWin, false, false}
            self.m_machine:setLastWinCoin(self.m_overTotalWin)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

            self.m_allWin = 0
            self.m_overTotalWin = 0
            self:waitWithDelay((205 - 25)/60, function()
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_popupover_over)
            end)
        end)
    end
    -- self.m_allWin = 0


    self.m_diceButton:resetToNormal()
end

function HogHustlerMainMap:runDiceEffect()
    local bao = util_createAnimation("HogHustler_shoujitiao_fankui.csb")
    self.m_diceButton:findChild("bao"):addChild(bao)
    bao:playAction("shouji", false, function()
        bao:removeFromParent()
    end)
    -- self.m_dice_model:playAction("actionframe")
end

function HogHustlerMainMap:initCoinsPos()
    local clickNode = self:findChild("levelprize")
    local changeX = -((display.width/2 )/ self.m_machine.m_machineRootScale - 300) - self.m_machine.m_fixX
    local changeY = (display.height/2) / self.m_machine.m_machineRootScale - 130
    clickNode:setPosition(cc.p(changeX,changeY))

    local clickNode1 = self:findChild("allwin")
    clickNode1:setPosition(cc.p(changeX,changeY - 91))
    self.m_levelPos = cc.p(changeX, changeY) 
end

--获取上ui的高度
function HogHustlerMainMap:getTopUIHeight()
    return self.m_machine:getTopUIHeight()
end

function HogHustlerMainMap:getMapBgNode()
    local node = self:findChild("bgRoot")
    return node
end

function HogHustlerMainMap:setClickType(isClick)
    self.m_clickType = isClick and 1 or 0
end

--改变按钮的父节点
-- function HogHustlerMainMap:changeClickBtnParent()
--     util_changeNodeParent(self.m_machine, self:findChild("Button_1"), GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
--     local pos = cc.p(self:findChild("Button_1"):getPosition())
--     pos = cc.pAdd(pos, display.center)
--     self:findChild("Button_1"):setPosition(pos)
--     self:findChild("Button_1"):setScale(self.m_machine.m_machineRootScale)
--     self:findChild("Button_1"):setVisible(false)
-- end

function HogHustlerMainMap:changeClickBtnParent()
    local tempBtn = self:findChild("Button_1")
    local pos = util_convertToNodeSpace(tempBtn, self.m_machine)
    util_changeNodeParent(self.m_machine, tempBtn, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    -- local pos = cc.p(self:findChild("Button_1"):getPosition())
    -- pos = cc.pAdd(pos, display.center)
    tempBtn:setPosition(pos)
    tempBtn:setScale(self.m_machine.m_machineRootScale)
    tempBtn:setVisible(false)
end


--延时
function HogHustlerMainMap:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

function HogHustlerMainMap:playFireworks()
    self.m_fireworks:setVisible(true)
    self.m_fireworks:playAction("actionframe", false, function()
        self.m_fireworks:playAction("actionframe", false, function()
            self.m_fireworks:setVisible(false)
        end)
    end)
end

function HogHustlerMainMap:runFibonacciCircle(_nodeView, _overFun, _overIdx)
    --设置速度
    local initOriginPos = cc.p(_nodeView:getPosition())
    local initR = 150
    local radInit = {270, 180, 90, 0}
    local initPoint = 1 -- 6 9 12 3  ---- 1 2 3 4
    local isTimeDir = false

    _nodeView:setPosition(initOriginPos)

    local speed = 360
    local acceleration = 5
    local runAngle = radInit[initPoint]

    local getNum = function(_n)
        local a = 0
        local b = 0
        local c = initR
        for i=1,_n-1 do
            a = b
            b = c
            c = a + b
        end
        return c
    end

    local cut90 = 0
    local runidx = 1
    local runDir = initPoint
    local runR = getNum(runidx)
    local runCenterPoint = cc.p(0, 0)
    if initPoint == 1 then
        runCenterPoint = cc.p(initOriginPos.x, initOriginPos.y + runR)
    end
    self.m_circleSchedule = scheduler.scheduleUpdateGlobal(
        function(dt)
            if isTimeDir then
                runAngle = runAngle - dt*speed
            else
                runAngle = runAngle + dt*speed
            end

            cut90 = cut90 + dt*speed
            if cut90 >= 90 then
                --换半径
                cut90 = cut90 - 90

                if isTimeDir then
                    runDir = runDir + 1
                    if runDir > 4 then
                        runDir = 1
                    end
                else
                    runDir = runDir - 1
                    if runDir < 1 then
                        runDir = 4
                    end
                end

                if runidx >= _overIdx then
                    if self.m_circleSchedule ~= nil then
                        scheduler.unscheduleGlobal(self.m_circleSchedule)
                        self.m_circleSchedule = nil
                    end
                    if _overFun then
                        _overFun()
                    end
                    return
                end

                local temprunR = runR
                runidx = runidx + 1
                runR = getNum(runidx)
                if runDir == 1 then
                    runCenterPoint = cc.p(runCenterPoint.x, runCenterPoint.y + (runR - temprunR))
                elseif runDir == 2 then
                    runCenterPoint = cc.p(runCenterPoint.x + (runR - temprunR), runCenterPoint.y)
                elseif runDir == 3 then
                    runCenterPoint = cc.p(runCenterPoint.x, runCenterPoint.y - (runR - temprunR))
                elseif runDir == 4 then
                    runCenterPoint = cc.p(runCenterPoint.x - (runR - temprunR), runCenterPoint.y)
                end

            end

            local x, y = util_getCirclePointPos(runCenterPoint.x, runCenterPoint.y, runR, runAngle)
            _nodeView:setPosition(cc.p(x, y))

        end
    )
end

function HogHustlerMainMap:clearAutoSpinTiming()
    if self.m_timingNode and not tolua.isnull(self.m_timingNode) then
        self.m_timingNode:stopAllActions()
    end
end

return HogHustlerMainMap