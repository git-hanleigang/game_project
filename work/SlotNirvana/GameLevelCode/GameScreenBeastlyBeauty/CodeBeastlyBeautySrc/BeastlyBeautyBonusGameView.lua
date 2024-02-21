---
--xcyy
--2018年5月23日
--BeastlyBeautyBonusGameView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseGame = util_require("base.BaseGame")
local BeastlyBeautyBonusGameView = class("BeastlyBeautyBonusGameView",BaseGame )

function BeastlyBeautyBonusGameView:initUI(machine)
    self.m_selectNumId = {}

    self.m_machine = machine

    self:createCsbNode("BeastlyBeauty/BeastlyBeauty_pick.csb")

    -- 剩余pick次数
    self.m_pickNumNode = util_createAnimation("BeastlyBeauty_pick.csb")
    self:findChild("Node_pick"):addChild(self.m_pickNumNode)

    -- pick赢钱
    self.m_winCoinsNode = util_createAnimation("BeastlyBeauty_pick_winner.csb")
    self:findChild("Node_winner"):addChild(self.m_winCoinsNode)

    -- pick开始前的说明
    self.m_pickBeginShuoMingNode = util_createAnimation("BeastlyBeauty_pick_shuoming.csb")
    self:findChild("Node_shuoming"):addChild(self.m_pickBeginShuoMingNode)

    --主要会挂载一些动效相关的节点
    self.m_effect_node = cc.Node:create()
    self.m_effect_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:addChild(self.m_effect_node, GAME_LAYER_ORDER.LAYER_ORDER_TOP)

end

--[[
    开始bonus玩法
]]
function BeastlyBeautyBonusGameView:beginBonusEffect(bonusWinCoins, bonusTimes, func)
    self.m_action = self.ACTION_ILDE
    -- bonus玩法结束之后的回调
    if func then
        self.m_overCallFunc = func
    end

    self.m_machine.m_bottomUI:checkClearWinLabel()

    -- 连续点击 保存返回的数据
    self.m_ClickResultDataAry = {}

    self:updataUIData(bonusWinCoins, bonusTimes)

    self.m_clickedPaoAry = {}

    self.featureData = nil

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickShuoMingAuto)

    self.m_pickBeginShuoMingNode:runCsbAction("auto",false,function(  )
        
        self:startPaoPaoAction()

        self.m_pickNumNode:runCsbAction("start",false,function(  )
            self.m_pickNumNode:runCsbAction("idle",true)
        end)
    
        self.m_winCoinsNode:runCsbAction("start",false,function(  )
            self.m_winCoinsNode:runCsbAction("idle",true)
        end)
    end)

end

--[[
    刷新界面 钱数 次数
]]
function BeastlyBeautyBonusGameView:updataUIData(bonusWinCoins, bonusTimes, isAgainPlay)
    if bonusWinCoins == 0 then
        self.m_winCoinsNode:findChild("m_lb_coin"):setString("")
    else
        self.m_winCoinsNode:findChild("m_lb_coin"):setString(util_formatCoins(bonusWinCoins,30))
        local node = self.m_winCoinsNode:findChild("m_lb_coin")
        self.m_winCoinsNode:updateLabelSize({label = node,sx = 1,sy = 1},370)
    end

    if not isAgainPlay then
        self.m_pickNumNode:findChild("m_lb_num"):setString(bonusTimes)
    end
end

--[[
    花开始移动
]]
function BeastlyBeautyBonusGameView:startPaoPaoAction( )

    self:beginPaoAct( true )

    self:beginPaoAct(nil, true)
    
    self:beginPaoAct()
    schedule(self.m_effect_node,function( )

        self:beginPaoAct()

    end,2)
end

function BeastlyBeautyBonusGameView:beginPaoAct( isFirst ,isSecond)
    local createNum = math.random(4,5)
    local beginWith = {-display.width/3, -display.width/6, 0, display.width/6, display.width/3}
    if isFirst then
        createNum = 5
    end
    for i=1,createNum do
        
        local roIndex = math.random( 1 , #beginWith)
        local roundPos = beginWith[roIndex] 
        table.remove(beginWith,roIndex)

        local random = math.random(-100,100) * self.m_machine.m_machineRootScale
        
        local startPos = cc.p(roundPos+random,display.height/2 + 160 + random)

        if isFirst then
            startPos = cc.p(roundPos,-50+random)
        elseif isSecond then
            startPos = cc.p(roundPos+random,250+random)
        end

        local random = math.random(-100,100) * self.m_machine.m_machineRootScale
        local endPos = cc.p(roundPos+random,-display.height / 2 - 160 +random)
        local scale = 1 --math.random(8,9) / 10
        local speed = math.random(100,110)  
        local time = display.height / speed
        local waitTime = 0.1 --math.random(4,6) * 25 / speed  
        if isFirst then
            time = time/2
        elseif isSecond then
            time = time*(display.height + 320 - (display.height/2 + 160 - 250))/(display.height + 320)
        end

        self:createOnePao(startPos,endPos,scale,time,waitTime )
    end
end

--[[
   创建一个花
]]
function BeastlyBeautyBonusGameView:createOnePao(startPos,endPos,scale,time,waitTime )

    local node = util_createView("CodeBeastlyBeautySrc.BeastlyBeautyBonusGameQiPaoBtn",self) 
    self:findChild("Node_hua"):addChild(node)
    node:setPosition(startPos)
    node:setScale(scale)
    node:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(true)

        local widthNum = math.round(2,5) 
        local actList2 = {}
        local widthTimes = time / widthNum
        for i=1,widthNum do
            local roundWitdh = math.round(1,3) * 50 * scale
            actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(-roundWitdh  ,0))
            actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(roundWitdh  ,0))
        end
        local sq_1 = cc.Sequence:create(actList2)

        -- node:findChild("Node_spine"):runAction(sq_1)
    end)
    actList[#actList + 1] = cc.MoveTo:create(time,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(false)
        node:stopAllActions()
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

--[[
    点击函数
]]
function BeastlyBeautyBonusGameView:clickFunc(pao)

    if self:isTouch() then
        pao:findChild("click_pao"):setTouchEnabled(false)

        pao:findChild("click_pao"):setVisible(false)
        pao:stopAllActions()
        pao:findChild("Node_2"):stopAllActions()
        self.m_clickedPaoAry[#self.m_clickedPaoAry + 1] = pao
        
        -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_click)

        self:sendData()
    end
end

--[[
    判断是否可以点击
]]
function BeastlyBeautyBonusGameView:isTouch()

    if self.m_action == self.ACTION_SEND then
        return false
    end

    if self.m_action == self.ACTION_OVER then
        return false
    end

    return true
end

function BeastlyBeautyBonusGameView:onEnter()
    BaseGame.onEnter(self)
    
end
function BeastlyBeautyBonusGameView:onExit()
    scheduler.unschedulesByTargetName("BeastlyBeautyBonusGameView")
    BaseGame.onExit(self)

end

--[[
    数据发送
]]
function BeastlyBeautyBonusGameView:sendData()

    self.m_action=self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--[[
    数据接收
]]
function BeastlyBeautyBonusGameView:recvBaseData(featureData)
    if not self:isVisible() then
        return
    end

    local bonus = clone(featureData.bonus)
    self.featureData = clone(featureData)
    
    local clickedPao = self.m_clickedPaoAry[1]
    table.remove(self.m_clickedPaoAry, 1)

    if clickedPao and clickedPao.m_bonusHua then
        -- 刷新剩余点击次数
        self.m_pickNumNode:findChild("m_lb_num"):setString(bonus.extra.times)

        util_spinePlay(clickedPao.m_bonusHua, "actionframe", false)
        self.m_machine:waitWithDelay(function()
            if clickedPao and clickedPao.m_bonusHua and not tolua.isnull(clickedPao) then
                clickedPao.m_bonusHua:removeFromParent()
                clickedPao.m_bonusHua = nil
            end
        end,17/30)
        
        clickedPao:findChild("m_lb_coins"):setString(util_formatCoins(tonumber(self.featureData.winAmount) or 0, 3))

        if bonus.status ~= "CLOSED" then
            self.m_action=self.ACTION_RECV
        end
        self.m_ClickResultDataAry[#self.m_ClickResultDataAry + 1] = bonus

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickCoinsFly)
        
        clickedPao:runCsbAction("actionframe",false,function(  )
            self.m_winCoinsNode:runCsbAction("idle",true)

            local bonus = self.m_ClickResultDataAry[1]
            table.remove(self.m_ClickResultDataAry, 1)

            self:winCoinsFly(clickedPao, function()
                self:updataUIData(bonus.bsWinCoins, bonus.extra.times, true)

                self.m_machine:waitWithDelay(function()
                    -- 结束玩法
                    if bonus.status == "CLOSED" then
                        self.m_effect_node:stopAllActions()
                        self:findChild("Node_hua"):removeAllChildren()

                        self.m_machine:showBonusGameOverView(util_formatCoins(bonus.bsWinCoins,50),function()
                            self:bonusOverCallBack(bonus)
                        end, function()
                            if self.m_overCallFunc then
                                self.m_overCallFunc()
                                self.m_machine:checkTriggerOrInSpecialGame(function(  )
                                    self.m_machine:reelsDownDelaySetMusicBGVolume( ) 
                                end)
                            end
                        end)
                    end
                end,1)
            end)

            if bonus.status == "CLOSED" then
                self.m_action=self.ACTION_OVER 
                self.m_machine:featuresOverAddFreespinEffect(self.featureData)
            else
                -- self.m_action=self.ACTION_RECV
            end
        end)
    end
end

function BeastlyBeautyBonusGameView:bonusOverCallBack(bonus)
    self.m_machine:resetMusicBg()
                                
    local oldCoins = globalData.slotRunData.lastWinCoin 
    globalData.slotRunData.lastWinCoin = 0
    if self.m_machine.m_bProduceSlots_InFreeSpin then
        self.m_machine.m_runSpinResultData.p_fsWinCoins = self.featureData.freespin.fsWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.featureData.freespin.fsWinCoins,false,true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{bonus.bsWinCoins,true,true})
    end
    globalData.slotRunData.lastWinCoin = oldCoins

    
    -- 更新游戏内每日任务进度条
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    -- 通知bonus 结束， 以及赢钱多少
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{bonus.bsWinCoins, GameEffect.EFFECT_BONUS})

    self.m_machine.m_pregress:updateLoadingbar(0,false)
    util_spinePlay(self.m_machine.m_pregress.m_jiManNode, "idle", true)

    self:setVisible(false)

    self.m_pickNumNode:runCsbAction("over",false)

    self.m_winCoinsNode:runCsbAction("over",false)
end

--[[
    点击完成之后 获得的 钱飞
]]
function BeastlyBeautyBonusGameView:winCoinsFly(node, func)

    local startPos = util_convertToNodeSpace(node,self:findChild("Node_fly"))
    local endPos = util_convertToNodeSpace(self:findChild("Node_winner"),self:findChild("Node_fly"))

    util_changeNodeParent(self:findChild("Node_fly"), node)
    node:setPosition(startPos)

    local tuoWeiFlyNode = util_createAnimation("BeastlyBeauty_shouji_tw.csb")
    node:addChild(tuoWeiFlyNode, -1)

    for i=1,4 do
        tuoWeiFlyNode:findChild("Particle_"..i):setDuration(1)     --设置拖尾时间(生命周期)
        tuoWeiFlyNode:findChild("Particle_"..i):setPositionType(0)   --设置可以拖尾
    end

    node:runCsbAction("fly",false)

    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(24/60,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        for i=1,4 do
            tuoWeiFlyNode:findChild("Particle_"..i):stopSystem()
        end

        self.m_winCoinsNode:runCsbAction("actionframe",false)
        self.m_winCoinsNode:findChild("Particle_1"):resetSystem()
        self.m_winCoinsNode:findChild("Particle_1_0"):resetSystem()

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_pickCoinsFlyFanKui)
        
        if func then
            func()
        end

        self.m_machine:waitWithDelay(function()
            node:removeFromParent()
        end,36/60)
        
    end)

    node:runAction(cc.Sequence:create(actList))
end

--开始结束流程
function BeastlyBeautyBonusGameView:gameOver(isContinue)

end

--弹出结算奖励
function BeastlyBeautyBonusGameView:showReward()

end

function BeastlyBeautyBonusGameView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            if param[2] and param[2].result then
                local spinData = param[2]
                dump(spinData.result, "featureResultCallFun data", 3)
                self:recvBaseData(spinData.result)
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
    end 
end

return BeastlyBeautyBonusGameView