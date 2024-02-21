---
--xcyy
--2018年5月23日
--CashTornadoPickGame.lua

local PublicConfig = require "CashTornadoPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashTornadoPickGame = class("CashTornadoPickGame",util_require("Levels.BaseLevelDialog"))

CashTornadoPickGame.m_curClickBill = nil
CashTornadoPickGame.m_overCallFunc = nil
CashTornadoPickGame.m_isClickForGame = false
CashTornadoPickGame.jackpotList = {0,0,0}

local ACTION_STATE = {
    IDLE = 1,
    PAUSE = 2,
    OVER = 3
}

function CashTornadoPickGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("CashTornado/PickFeature.csb")

    self.m_effectNode1 = cc.Node:create()
    self:addChild(self.m_effectNode1, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)

    self.m_coinbonus = cc.Node:create()
    self:addChild(self.m_coinbonus)

    self.curCoins = 0
    self.curIndex = 0
    self.pickNum = 0
    self.m_ClickResultDataAry = {}
    local offPosY = 0
    local offPosY2 = 0
    local ratio = display.height / display.width
    if ratio == 1530 / 768 then
        offPosY = 65
        offPosY2 = -83
    elseif ratio == 1970 / 768 then
        offPosY = 295
        offPosY2 = -303
    end

    --pick次数
    self.pickNumNode = util_createAnimation("CashTornado_picks.csb")
    self:findChild("Node_picks"):addChild(self.pickNumNode)
    self.pickNumNode:setPositionY(offPosY)

    --jackpot
    -- self.jackpotNode = util_createAnimation("CashTornado_picks.csb")
    -- self:findChild("Node_Jackpot"):addChild(self.jackpotNode)

    --钱数
    self.coinsNode = util_createAnimation("CashTornado_credits.csb")
    self:findChild("Node_credits"):addChild(self.coinsNode)
    self.coinsNode:setPositionY(offPosY)
    local light = util_createAnimation("CashTornado_credits_g2.csb")
    self.coinsNode:findChild("Node_g2"):addChild(light)
    self.coinsNode.light = light
    light:setVisible(false)

    --倒计时
    self.countDown = util_createAnimation("CashTornado_daojishi.csb")
    self:findChild("Node_daojishi"):addChild(self.countDown)
    self.countDown:setPositionY(offPosY2)
    self.countDown:runCsbAction("idle",true)
    self.countDown:findChild("zi_1"):setVisible(true)
    self.countDown:findChild("zi_0"):setVisible(false)

    --旋风
    self.cyclone = util_spineCreate("CashTornado_pick_feng", true, true)
    self:findChild("bg"):addChild(self.cyclone)

    --庆祝
    self.m_celebrate = util_spineCreate("CashTornado_qingzhu", true, true)
    self:findChild("Node_dark"):addChild(self.m_celebrate,100)
    self.m_celebrate:setVisible(false)

    --压黑
    self.blackLayer = util_createAnimation("CashTornado_qingzhu_dark.csb")
    self:findChild("Node_dark"):addChild(self.blackLayer,10)
    self.blackLayer:setVisible(false)

    self.updateNode = cc.Node:create()
    self:addChild(self.updateNode)

    self.clickForGameNode = cc.Node:create()
    self:addChild(self.clickForGameNode)
end

function CashTornadoPickGame:setResultDataAry(data)
    self.m_ClickResultDataAry = data
end

function CashTornadoPickGame:onEnter()
    CashTornadoPickGame.super.onEnter(self)

    -- gLobalNoticManager:addObserver(self,function(self, params)
    --     self:featureResultCallFun(params)
    -- end,
    -- ViewEventType.NOTIFY_GET_SPINRESULT)
end

function CashTornadoPickGame:onExit()
    CashTornadoPickGame.super.onExit(self)
    if self.m_coinbonusUpdateAction then
        self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
        self.m_coinbonusUpdateAction = nil
    end
    if self.m_updatePosHandler ~= nil then
        self:stopAction(self.m_updatePosHandler)
        self.m_updatePosHandler = nil
    end
end

--[[
    显示界面(执行start时间线)
]]
function CashTornadoPickGame:showView(pickNum,func)
    self:resetView(pickNum,func)
    self.m_isClickForGame = false
    self:setVisible(true)
    util_spinePlay(self.cyclone, "pick_start", false)
    self.m_machine:delayCallBack(1,function ()
        util_spinePlay(self.cyclone, "pick", true)
    end)
    self.m_action = ACTION_STATE.PAUSE
    if self.coinsFlySoundId then
        gLobalSoundManager:stopAudio(self.coinsFlySoundId)
        self.coinsFlySoundId = nil
    end
    self.coinsFlySoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_coins_fly,true)
    self:beginBonusEffect()
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        -- self:beginBonusEffect()
        self.m_action = ACTION_STATE.IDLE
        performWithDelay(self.clickForGameNode,function ()
            if self.m_isClickForGame == false then
                --引导显示
                self.m_machine.tishi:setVisible(true)
                util_spinePlay(self.m_machine.tishi, "idleframe",true)
            end
        end,4)
    end)
    
end

--[[
    隐藏界面(执行over时间线)
]]
function CashTornadoPickGame:hideView(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_over_guochange)
    util_spinePlay(self.cyclone, "over")
    self.m_machine:delayCallBack(22/30,function ()
        --切换风的层级
        self.m_machine:changeParentForPick(self.cyclone,true)
        self.m_effectNode1:removeAllChildren()
        self.m_machine.isPickGame = false
        -- self.m_machine:delayCallBack(0.5,function ()
            if self.m_overCallFunc then
                self.m_overCallFunc()
            end
        -- end)
        
        self:setVisible(false)
    end)
    self:runCsbAction("over",false)
    
end

--刷新次数框
function CashTornadoPickGame:updatePickNumView(pickNum,isInit,isAct)
    self.pickNumNode:stopAllActions()
    if isInit then
        self.pickNum = pickNum
        self.pickNumNode:findChild("m_lb_num"):setString(pickNum)
        self.pickNumNode:runCsbAction("idleframe",true)
    else
        if isAct then
            self.pickNumNode:stopAllActions()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_add)
            self.pickNumNode:runCsbAction("actionframe",false,function ()
                self.pickNumNode:runCsbAction("idleframe",true)
            end)
            performWithDelay(self.pickNumNode,function ()
                self.pickNumNode:findChild("m_lb_num"):setString(pickNum)
            end,7/60)
        else
            self.pickNumNode:findChild("m_lb_num"):setString(pickNum)
        end
        -- if pickNum == 102 then
        --     pickNum = 2
        -- elseif pickNum == 103 then
        --     pickNum = 3
        -- elseif pickNum == 105 then
        --     pickNum = 5
        -- end
        -- if pickNum >  self.pickNum then
            
        -- else
            
            
        -- end
        -- self.pickNum = pickNum
    end
end

--刷新钱数
function CashTornadoPickGame:updateCoinsView(coins,isInit)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    coins = coins * lineBet
    self.coinsNode:stopAllActions()
    if isInit then
        self.coinsNode:findChild("m_lb_coins"):setString("")
        local info={label = self.coinsNode:findChild("m_lb_coins"),sx = 0.63,sy = 0.62}
        self:updateLabelSize(info,661)
        self.curCoins = 0
        self.coinsNode:runCsbAction("idleframe",true)
    else
        local ef_lizi1 = self.coinsNode:findChild("ef_lizi1")
        if ef_lizi1 then
            ef_lizi1:resetSystem()
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_coins_credits)
        self.coinsNode:runCsbAction("actionframe_fankui",false,function ()
            -- self.coinsNode:runCsbAction("idleframe",true)
        end)
        performWithDelay(self.coinsNode,function ()
            self.coinsNode:runCsbAction("idleframe",true)
        end,35/60)
        if self.m_coinbonusUpdateAction then
            self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
            self.m_coinbonusUpdateAction = nil
        end
        --0.2秒涨钱
        local curCoins = self.curCoins
        self.curCoins = self.curCoins + coins
        self:updateCoins(self.coinsNode:findChild("m_lb_coins"),self.curCoins,curCoins,0.2)
        
    end
end

function CashTornadoPickGame:updateCoins(_label,_addScore,curCoins,showTime)
    local coinRiseNum = (_addScore - curCoins) / (showTime * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)
    local m_currShowCoins = curCoins

    self.m_coinbonusUpdateAction = schedule(self.m_coinbonus,function()
        m_currShowCoins = m_currShowCoins + coinRiseNum
        
        _label:setString(util_formatCoinsLN(m_currShowCoins,30))
        local info={label = _label,sx = 0.63,sy = 0.62}
        self:updateLabelSize(info,661)
        if m_currShowCoins >= _addScore then
            _label:setString(util_formatCoinsLN(_addScore,30))
            local info={label = _label,sx = 0.63,sy = 0.62}
            self:updateLabelSize(info,661)
            if self.m_coinbonusUpdateAction then
                self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
                self.m_coinbonusUpdateAction = nil
            end
        end
    end,1/60)
end

function CashTornadoPickGame:updateJactpotBarView(type,isInit)
    if isInit then
        self.m_machine.m_jackPotBarView:showIdleActForAllNode()
    else
        if type == 10 then
            type = "mini"
        elseif type == 20 then
            type = "minor"
        elseif type == 50 then
            type = "major"
        elseif type == 100 then
            type = "mega"
        elseif type == 500 then
            type = "grand"
        else
            type = "mega"
        end
        self.m_machine.m_jackPotBarView:showFanKuiAct(type)
    end
end

function CashTornadoPickGame:updateViewData(_data)
    if self:getRewardType(_data) == "coins" then
        self:updateCoinsView(_data,false)
    elseif self:getRewardType(_data) == "jackpot" then
        self:updateJactpotBarView(_data,false)
    elseif self:getRewardType(_data) == "pick" then
        -- local process = self.m_ClickResultDataAry.pick_left_time_list or {}
        -- local processIndex = process[self.curIndex]
        -- self:updatePickNumView(processIndex,false)
    end
end

--[[
    重置界面显示
]]
function CashTornadoPickGame:resetView(func)
    self.pickNum = 0
    if self.m_coinbonusUpdateAction then
        self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
        self.m_coinbonusUpdateAction = nil
    end
    --jackpotBar不显示mini和minor修改
    self.m_machine:changeJackpotBarParent(true)
    self.m_machine:changejackpotBarShow(false)
    self:updateJactpotBarView(nil,true)
    self:updateCoinsView(0,true)
    self:updatePickNumView(10,true)
    if tolua.isnull(self.cyclone) then
        --旋风
        self.cyclone = util_spineCreate("CashTornado_pick_feng", true, true)
        self:findChild("bg"):addChild(self.cyclone)
    end
    self.cyclone:setVisible(true)
    util_spinePlay(self.cyclone, "pick", true)
    self.jackpotList = {0,0,0}
    self.curIndex = 0
    if self.coinsNode.light then
        self.coinsNode.light:setVisible(false)
    end
    self.m_celebrate:setVisible(false)
    self.blackLayer:setVisible(false)
    -- bonus玩法结束之后的回调
    if func then
        self.m_overCallFunc = func
    end
end

--[[
    开始bonus玩法
]]
function CashTornadoPickGame:beginBonusEffect()
    
    self:startBillAction()
end

--[[
    钞票开始移动
]]
function CashTornadoPickGame:startBillAction( )

    self:beginBillAct( true )

    -- self:beginBillAct(nil, true)
    
    self:beginBillAct()
    if self.m_updatePosHandler ~= nil then
        self:stopAction(self.m_updatePosHandler)
        self.m_updatePosHandler = nil
    end
    self.m_updatePosHandler = schedule(self,function( )

        self:beginBillAct()

    end,1.5)
end

function CashTornadoPickGame:beginBillAct( isFirst ,isSecond)
    local createNum = math.random(2,4)
    -- local beginWith = 
    --{200,310,424,543,612}
    ---display.height/3, -display.height/6, 0, display.height/6 - 100, display.height/3 -200
    -- local bill1PosX , bill1PosY = self:findChild("Node_Bill1"):getPosition()
    -- local bill2PosX , bill2PosY = self:findChild("Node_Bill2"):getPosition()
    -- local bill3PosX , bill3PosY = self:findChild("Node_Bill3"):getPosition()
    -- local bill4PosX , bill4PosY = self:findChild("Node_Bill4"):getPosition()
    -- local bill5PosX , bill5PosY = self:findChild("Node_Bill5"):getPosition()
    local bill1PosY = 98
    local bill2PosY = 202
    local bill3PosY = -12
    local bill4PosY = -140
    local bill5PosY = -283
    -- local bill1Pos = util_convertToNodeSpace(self:findChild("Node_Bill1"),self:findChild("Node_Bill"))
    local beginHeight = {bill1PosY,bill2PosY,bill3PosY,bill4PosY,bill5PosY}
    if isFirst then
        createNum = 4
    elseif isSecond then
        createNum = 4
    end
    for i=1,createNum do
        
        local colIndex = math.random( 1 , #beginHeight)
        -- * self.m_machine.m_machineRootScale
        local roundPosY = beginHeight[colIndex]
        table.remove(beginHeight,colIndex)

        local random = math.random(-200,-300)* self.m_machine.m_machineRootScale
        --
        local random2 = math.random(-5,5) * self.m_machine.m_machineRootScale
        
        -- local startPos = cc.p(display.width + 100,roundPosY)   
        local startPos = cc.p( - (display.width) - random -200,(roundPosY + random2))
        if isFirst then
            -- startPos = cc.p(roundPos,display.height/3 - 100)
            startPos = cc.p(-display.width * 3/4 - 100,roundPosY + random2)
        elseif isSecond then
            -- startPos = cc.p(roundPos+random,display.height/3 + 100)
            startPos = cc.p(-display.width * 3/4 + 100,roundPosY + random2)
        end

        -- local random = math.random(-100,100) * self.m_machine.m_machineRootScale
        -- local endPos = cc.p(roundPos+random,-display.height / 2 - 160 +random)
        local endPos = cc.p(((display.width) - random),(roundPosY + random2))
        local scale =  math.random(8,10) / 10
        local speed = math.random(60,110)  
        local time = display.width / speed
        local waitTime = 0.1 --math.random(4,6) * 25 / speed  
        if isFirst then
            time = time/2
        elseif isSecond then
            time = time*(display.height + 320 - (display.height/2 + 160 - 250))/(display.height + 320)
        end

        self:createOneBill(startPos,endPos,scale,time,waitTime )
    end
    
end

--[[
   创建一个钞票
]]
function CashTornadoPickGame:createOneBill(startPos,endPos,scale,time,waitTime )

    local node = util_createView("CodeCashTornadoSrc.CashTornadoPickItem",self) 
    self:findChild("Node_Bill"):addChild(node)
    node:setPosition(startPos)
    node:setScale(scale)
    node:setVisible(false)
    node.endPos = endPos
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(true)
    end)
    actList[#actList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(time,endPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(false)
        node:stopAllActions()
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function CashTornadoPickGame:changeBillMoveSpeed(node)
    local speed = 800
    local startPosX = node:getPositionX()
    local endPos = node.endPos
    if not endPos then
        endPos = cc.p(((display.width) - 300),0)
    end
    local time = (endPos.x - startPosX)/speed
    local actList = {}
    actList[#actList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(time,endPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(false)
        node:stopAllActions()
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function CashTornadoPickGame:setCurClickBillNode(curClickBill)
    self.m_curClickBill = curClickBill
end

function CashTornadoPickGame:showReward(index,billNode)
    --是否结束
    if self:checkPickGameOver(index) then
        self.m_action = ACTION_STATE.OVER
        if self.coinsFlySoundId then
            gLobalSoundManager:stopAudio(self.coinsFlySoundId)
            self.coinsFlySoundId = nil
        end
        if self.m_updatePosHandler ~= nil then
            self:stopAction(self.m_updatePosHandler)
            self.m_updatePosHandler = nil
        end
        -- self.m_machine:delayCallBack(0.5,function ()
            self:stopAllActionForFlower()
        -- end)
    else
        self.m_action = ACTION_STATE.IDLE
    end

    local pick_list = self.m_ClickResultDataAry.pick_list or {}
    local process = self.m_ClickResultDataAry.pick_left_time_list or {}

    

    if not tolua.isnull(billNode) then
        --刷新钞票点击之后的显示
        local rewardNum = pick_list[index]
        local processIndex = process[self.curIndex]
        billNode:setShowNum(rewardNum)
        
        billNode:showClickAction()
        billNode:stopAllActions()
        -- billNode:setLocalZOrder(10000)
        local startPos = util_convertToNodeSpace(billNode,self.m_effectNode1)
        util_changeNodeParent(self.m_effectNode1,billNode,10)
        billNode:setPosition(startPos)
        local isClickPick = self:isClickPick(rewardNum)
        self:updatePickNumView(processIndex,false,isClickPick)      --刷新次数
        billNode:changeLightingShow(rewardNum)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_click)
        billNode:runCsbAction("dianji",false,function(  )

            -- self.m_machine:delayCallBack(0.3,function ()
                
                --刷新ui显示
                self:handleRewardEnd(billNode,rewardNum,function ()
                    self:updateViewData(rewardNum)
                    if self:checkPickGameOver(index) then   --结束
                        self.m_action = ACTION_STATE.OVER
                        -- self.m_machine:delayCallBack(2,function ()
                            self:gameOver()
                        -- end)
                    end
                end)
            -- end)
            
            
        end)
    end
end

function CashTornadoPickGame:handleRewardEnd(billNode,_data,func)
    if self:getRewardType(_data) == "jackpot" then
        self:flyJackpotParticleAni(billNode,_data,func)
    elseif self:getRewardType(_data) == "pick" then
        self:flyBillPickToEndNode(billNode,_data,func)
    elseif self:getRewardType(_data) == "coins" then
        self:flyBillCoinsToEndNode(billNode,_data,func)
    end
end

--10、20、50、100、500为jackpot对应倍数 102、103、105为增加的pick次数 102为+2 103为+3 105为+5
function CashTornadoPickGame:getRewardType(_data)
    if _data == 10 or _data == 20 or _data == 50 or _data == 100 or _data == 500 then
        return "jackpot"
    elseif _data == 102 or _data == 103 or _data == 105 then
        return "pick"
    else
        return "coins"
    end
end

function CashTornadoPickGame:isClickPick(_data)
    if _data == 102 or _data == 103 or _data == 105 then
        return true
    end
    return false
end

function CashTornadoPickGame:flyBillPickToEndNode(billNode,_data,func)
    local endPos = util_convertToNodeSpace(self:findChild("Node_credits"),self.m_effectNode1)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        billNode:runCsbAction("show")
    end)
    actList[#actList + 1] = cc.DelayTime:create(50/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        billNode:removeFromParent()
    end)
    billNode:runAction(cc.Sequence:create( actList))
end

function CashTornadoPickGame:flyBillCoinsToEndNode(billNode,_data,func)
    local endPos = util_convertToNodeSpace(self:findChild("Node_credits"),self.m_effectNode1)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        billNode:setLocalZOrder(1000)
        billNode:runCsbAction("fly")
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.4, endPos)
    -- actList[#actList + 1] = cc.DelayTime:create(15/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        billNode:removeFromParent()
    end)
    billNode:runAction(cc.Sequence:create( actList))
end

--[[
    Jackpot飞粒子动画
]]
function CashTornadoPickGame:flyJackpotParticleAni(billNode,_data,func)
    local jackpotType = self:getJackpotTypeForMul(_data)
    local flyNode = util_createAnimation("CashTornado_pick_twlizi.csb")
    flyNode:findChild("grand"):setVisible(_data == 500)
    flyNode:findChild("mega"):setVisible(_data == 100)
    flyNode:findChild("major"):setVisible(_data == 50)
    local particle1 = flyNode:findChild("Particle1_"..jackpotType)
    local particle2 = flyNode:findChild("Particle2_"..jackpotType)

    if _data == 500 then
        self.jackpotList[1] = self.jackpotList[1] + 1
    elseif _data == 100 then
        self.jackpotList[2] = self.jackpotList[2] + 1
    elseif _data == 50 then
        self.jackpotList[3] = self.jackpotList[3] + 1
    end

    -- local startPos = util_convertToNodeSpace(billNode,self.m_effectNode1)
    local jackpotNode = self.m_machine.m_jackPotBarView:getJackpotDoePick(jackpotType)
    local endPos = util_convertToNodeSpace(jackpotNode,self.m_effectNode1)

    billNode:findChild("Node_particle"):addChild(flyNode)
    -- flyNode:setPosition(startPos)

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        billNode:setLocalZOrder(1000)
        flyNode:runCsbAction("actionframe")
        if particle1 then
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle1:setPositionType(0)   --设置可以拖尾
            particle1:resetSystem()
        end
        if particle2 then
            particle2:setDuration(-1)     --设置拖尾时间(生命周期)
            particle2:setPositionType(0)   --设置可以拖尾
            particle2:resetSystem()
        end
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
        if particle1 then
            particle1:stopSystem()--移动结束后将拖尾停掉
        end
        if particle2 then
            particle2:stopSystem()--移动结束后将拖尾停掉
        end
        billNode:setVisible(false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.3)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
        billNode:removeFromParent()
    end)
    billNode:runAction(cc.Sequence:create( actList))
end

function CashTornadoPickGame:stopAllActionForFlower(func)
    local children = self:findChild("Node_Bill"):getChildren()
    for k,_node in pairs(children) do
        if not tolua.isnull(_node) then
            _node:stopAllActions()
            if _node.endPos then
                self:changeBillMoveSpeed(_node)
            end
        end
    end

    -- self.m_machine:delayCallBack(21/30,function ()
    --     if func then
    --         func()
    --     end
    -- end)
    
end

--[[
    点击函数
]]
function CashTornadoPickGame:clickFunc(bill)

    if self:isTouch() then
        self.curIndex = self.curIndex + 1
        self.m_action = ACTION_STATE.PAUSE
        if self.m_isClickForGame == false then
            self.m_isClickForGame = true
            self.clickForGameNode:stopAllActions()
            if self.m_machine.tishi:isVisible() then
                self.m_machine.tishi:setVisible(false)
            end
        end
        bill:findChild("click_bill"):setTouchEnabled(false)

        bill:findChild("click_bill"):setVisible(false)
        bill:stopAllActions()
        self:showReward(self.curIndex,bill)
    end
end

--[[
    判断是否可以点击
]]
function CashTornadoPickGame:isTouch()

    if self.m_action == ACTION_STATE.PAUSE then
        return false
    end

    if self.m_action == ACTION_STATE.OVER then
        return false
    end

    return true
end

function CashTornadoPickGame:checkHaveJackpot()
    for i, v in ipairs(self.jackpotList) do
        if v > 0 then
            return true
        end
    end
    return false
end

--结束流程
function CashTornadoPickGame:gameOver()
    self.coinsNode:stopAllActions()
    self.m_machine:clearCurMusicBg()
    if self:checkHaveJackpot() then
        self:showPickJackpotWin(1,function ()
            self.m_machine.m_jackPotBarView:showIdleActForAllNode()
            
            self.blackLayer:setVisible(true)
            self.blackLayer:runCsbAction("start",false,function ()
                self.blackLayer:runCsbAction("idle")
            end)
            self.coinsNode:runCsbAction("jiesuan")
            if self.coinsNode.light then
                self.coinsNode.light:setVisible(true)
                self.coinsNode.light:runCsbAction("idleframe",true)
            end
            self:findChild("Node_Bill"):removeAllChildren()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_impressive)
            self:runCsbAction("jiesuan",false,function ()
                self.m_machine:playBottomLight(false,self.curCoins,true,false)
            end)
            self.m_machine:delayCallBack(0.5,function ()
                --庆祝动画
                self.m_celebrate:setVisible(true)
                util_spinePlay(self.m_celebrate, "actionframe_qingzhu")
                --54帧压黑消失
                self.m_machine:delayCallBack(54/30,function ()
                    self.blackLayer:runCsbAction("over",false,function ()
                        self.blackLayer:setVisible(false)
                        self:hideView()
                    end)
                    
                end)
            end)
        end)
    else
        self.m_machine.m_jackPotBarView:showIdleActForAllNode()
            
        self.blackLayer:setVisible(true)
        self.blackLayer:runCsbAction("start",false,function ()
            self.blackLayer:runCsbAction("idle")
        end)
        self.coinsNode:runCsbAction("jiesuan")
        if self.coinsNode.light then
            self.coinsNode.light:setVisible(true)
            self.coinsNode.light:runCsbAction("idleframe",true)
        end
        self:findChild("Node_Bill"):removeAllChildren()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_impressive)
        self:runCsbAction("jiesuan",false,function ()
            self.m_machine:playBottomLight(false,self.curCoins,true,false)
        end)
        self.m_machine:delayCallBack(0.5,function ()
            --庆祝动画
            self.m_celebrate:setVisible(true)
            util_spinePlay(self.m_celebrate, "actionframe_qingzhu")
            --54帧压黑消失
            self.m_machine:delayCallBack(54/30,function ()
                self.blackLayer:runCsbAction("over",false,function ()
                    self.blackLayer:setVisible(false)
                    self:hideView()
                end)
                
            end)
        end)
    end
    
end

--可能有多种jackpot且每种有多个
function CashTornadoPickGame:showPickJackpotWin(index,func)
    if index > #self.jackpotList then
        if func then
            func()
        end
        return
    end
    local jackpotNum = self.jackpotList[index]
    local jackpotType = nil
    if index == 1 then
        jackpotType = "grand"
    elseif index == 2 then
        jackpotType = "mega"
    elseif index == 3 then
        jackpotType = "major"
    end
    if jackpotNum <= 0 then
        index = index + 1
        self:showPickJackpotWin(index,func)
        return
    end
    self.m_machine.m_jackPotBarView:showIdleActForAllNode()
    self.m_machine.m_jackPotBarView:showRewardAct(jackpotType)
    self:showPickJackpotWinIndex(jackpotType,jackpotNum,1,function ()
        --0.4s滚钱
        local coins = self.m_machine:getJackpotCoinsForType(jackpotType)
        
        -- self.m_machine:playBottomLight(coins,true,false)
        local curCoins = self.curCoins
        self.curCoins = self.curCoins + coins
        self:updateCoins(self.coinsNode:findChild("m_lb_coins"),self.curCoins,curCoins,0.4)
        
        self.m_machine:delayCallBack(0.5,function ()
            index = index + 1
            self:showPickJackpotWin(index,func)
        end)
    end)
end

function CashTornadoPickGame:showPickJackpotWinIndex(jackpotType,jackpotNum,index,func)
    if index > jackpotNum then
        if func then
            func()
        end
        return
    end
    if not jackpotType then
        if func then
            func()
        end
        return
    end
    local coins = self.m_machine:getJackpotCoinsForType(jackpotType)
    self.m_machine:showJackpotView(false,coins,jackpotType,function ()
        if func then
            func()
        end
    end)
end

--判断是否结束
function CashTornadoPickGame:checkPickGameOver(index)
    local process = self.m_ClickResultDataAry.pick_left_time_list or {}
    local totalNum = table_length(process) or 0
    if totalNum == 0 then
        return true
    end
    if index >= totalNum then
        return true
    end
    local processIndex = process[index] or 0
    if tonumber(processIndex) == 0 then
        return true
    end

    return false
end

function CashTornadoPickGame:getJackpotTypeForMul(mul)
    if mul == 500 then
        return "grand"
    elseif mul == 100 then
        return "mega"
    else
        return "major"    
    end
end

-- --------------------------------------------倒计时相关、
-- 刷新倒计时
function CashTornadoPickGame:upDataDiscountTime(leftTime)
    
    self.updateNode:stopAllActions()

    if leftTime <= 0 then
        return
    end
    self.m_timeStamp = os.time()
    self.m_discountLeftTime = leftTime
    self:showTimeDown(leftTime)

    

    util_schedule(self.updateNode,function()
        local curTimeStamp = os.time()
        local tempTime = curTimeStamp - self.m_timeStamp
        local leftTime2 = self.m_discountLeftTime - tempTime
        if leftTime2 <= 0 then
            leftTime2 = 0
            self.updateNode:stopAllActions()
            self:showTimeDown(leftTime2)
            
        else
            self:showTimeDown(leftTime2)
        end
    end,1)
end

--[[
    显示倒计时 时间
]]
function CashTornadoPickGame:showTimeDown(_leftTime)
    --util_count_down_str1(_leftTime)
    local str = math.floor(_leftTime)
    self.countDown:findChild("m_lb_num"):setString(str.."S")
    self.countDown:findChild("m_lb_num"):setString(str.."S")
    self.countDown:findChild("m_lb_num_0"):setString(str.."S")
    
    if _leftTime <= 61 then
        self.countDown:findChild("m_lb_num_0"):setVisible(true)
        self.countDown:findChild("m_lb_num"):setVisible(false)
        if _leftTime <= 0 then
            self.countDown:runCsbAction("idle",true)
        else
            self.countDown:runCsbAction("actionframe",true)
        end
    else
        self.countDown:findChild("m_lb_num_0"):setVisible(false)
        self.countDown:findChild("m_lb_num"):setVisible(true)
        self.countDown:runCsbAction("idle",true)
    end
end

return CashTornadoPickGame