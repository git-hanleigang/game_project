---
--xcyy
--2018年5月23日
--HallowinBonusGameView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local HallowinBonusGameView = class("HallowinBonusGameView",BaseGame )

HallowinBonusGameView.m_machine = nil

HallowinBonusGameView.m_bonusStartStates = "timesPick"

local PICK_TOTAL_TIMES_ARRAY = {10, 15, 20}

function HallowinBonusGameView:initUI()

    self:createCsbNode("Hallowin/BonusGameLayer.csb")

    local index = 1
    while true do
        local parent = self:findChild("shibei_"..index)
        if parent ~= nil then
            local graveStone = util_createAnimation("Hallowin_shibei.csb")
            parent:addChild(graveStone)
            self:hidePickTimes(graveStone)
            graveStone:runCsbAction("idle", true)
            self:addClick(self:findChild("click_"..index))
            self["m_graveStone"..index] = graveStone
        else
            break
        end
        index = index + 1
    end

    self.m_labPicksNum = self:findChild("m_lb_num")
    self.m_labCoinsNum = self:findChild("m_lb_coins")
    self.m_labCoinsNum:setString(0)
    self:updateLabelSize({label=self.m_labCoinsNum,sx=1,sy=1}, 420)

    self.m_chooseFlag = false
    self.m_currBonusType = self.m_bonusStartStates -- multiplePick
    self.m_winCoins = 0
    self.m_clickTimes = 0
    self.m_picks = {}
    
    util_setCascadeOpacityEnabledRescursion(self,true)
    self:showBonusStartView()
end

function HallowinBonusGameView:hidePickTimes(graveStone)
    for i = 1, 2, 1 do
        for j = 1, #PICK_TOTAL_TIMES_ARRAY, 1 do
            local labTimes = graveStone:findChild("times_"..i.."_"..PICK_TOTAL_TIMES_ARRAY[j])
            labTimes:setVisible(false)
        end
    end
end

function HallowinBonusGameView:showBonusStartView()
    self:runCsbAction("start", false, function(  )
        -- 按钮可以点击
        self:runCsbAction("idle", true)
        self.m_chooseFlag = true
    end)
end

function HallowinBonusGameView:restView( spinData, featureData )
    
    local bonusdata = featureData.p_bonus or {}
    local choose = bonusdata.choose or {}
    local content = bonusdata.content or {}
    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0
    local winCoins = extra.winCoins or 0
    local pickTimes = extra.pickTimes or 0

    self.m_labCoinsNum:setString(util_formatCoins(totalWinCoins,30))
    self.m_labPicksNum:setString(pickTimes)
    self:updateLabelSize({label=self.m_labCoinsNum,sx=1,sy=1}, 420)
    self.m_picks = {}
end


function HallowinBonusGameView:onEnter()
    BaseGame.onEnter(self)
end

function HallowinBonusGameView:onExit()
    scheduler.unschedulesByTargetName("HallowinBonusGameView")
    BaseGame.onExit(self)
end

--数据发送
function HallowinBonusGameView:sendData(pos)

    -- gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_clickChest.mp3")

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= pos , mermaidVersion = 0 } 
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    
end

--数据接收
function HallowinBonusGameView:recvBaseData(featureData)

    local bonusdata = featureData.p_bonus or {}
    local choose = bonusdata.choose or {}
    local content = bonusdata.content or {}
    local bonusStates = bonusdata.status

    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0
    local winCoins = extra.winCoins or 0
    local pickTimes = extra.pickTimes or 0

    self.m_picks = extra.picks or {}

    if #self.m_picks > 0 then
        self.m_winCoins = 0
        self.m_clickTimes = pickTimes
    end

    if bonusType == self.m_bonusStartStates then

        if #content == 3 then

            local clickPos = self.m_selectedID
            local chooseTimes = content[choose[1] + 1]
            table.remove(content,choose[1] + 1)

            local graveStone = self["m_graveStone"..clickPos]
            self:showPickTimes(graveStone, chooseTimes)
            
            local index = 1
            while true do
                local grave = self["m_graveStone"..index]
                if grave ~= nil then
                    if index ~= clickPos then
                        self:showPickTimes(grave, content[#content])
                        grave:runCsbAction("over")
                        table.remove(content, #content)
                    end
                else
                    break
                end
                index = index + 1
            end

            graveStone:runCsbAction("actionframe",false,function()
                performWithDelay(self, function()
                    self.m_labPicksNum:setString(self.m_clickTimes)
                    self:runCsbAction("over", false, function()
                        self:runCsbAction("start2", false, function()
                            
                        end)
                    end)
                    self.m_clickGhost = true
                    self.m_iGhostNum = 0
                    self:beginGhostAct( true )
                    self.m_addGhostAction = schedule(self,function( )
                        self:beginGhostAct( )
                    end, 2)
                end, 0)
            end)

        end
    end         
end

--开始结束流程
function HallowinBonusGameView:gameOver(isContinue)

end

--弹出结算奖励
function HallowinBonusGameView:showReward()

   
end

function HallowinBonusGameView:featureResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        -- release_print("--" .. cjson.encode(spinData))
        
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_BonusWinCoins = spinData.result.bonus.bsWinCoins

        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if spinData.action == "FEATURE" then
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_spinDataResult = spinData.result

            self:recvBaseData(self.m_featureData)

            
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
end

function HallowinBonusGameView:setOverCallFunc( func )
    self.m_overCallFunc = func
end

--数据接收 
-- 这里才是点泡泡新代码结构
function HallowinBonusGameView:recvPaoPaoViewBaseData(index)

    local bonusdata = self.m_featureData.p_bonus or {}

    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0

    local content = extra.picks or {}

    local coins = content[self.m_clickTimes] or 0

    local winCoins = coins +  self.m_winCoins
    local pickTimes = self.m_clickTimes  - 1
    local actPao = self.m_vecGhost["ghost_"..index]
    
    self.m_winCoins = winCoins
    self.m_clickTimes = pickTimes

    release_print("新的一套自己模拟点击的 剩余次数 :" .. self.m_clickTimes)

    local bonusStates = "OPEN"
    if self.m_clickTimes <= 0 then
        bonusStates = "CLOSED"
    end

    if actPao then
        actPao:setLocalZOrder(10)
        actPao:showParticle()
        if bonusStates == "CLOSED" then

            actPao:runCsbAction("over",false,function(  )
                actPao:removeFromParent()

                self:stopAction(self.m_addGhostAction)
                gLobalSoundManager:stopBgMusic()
                gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_end.mp3")
                performWithDelay(self, function()
                    if self.m_overCallFunc then
                        self.m_overCallFunc(totalWinCoins)
                    end
                    self:removeFromParent()
                end, 2.5)
            end)
        else

            actPao:runCsbAction("over",false,function(  )
                local index = actPao:getGhostID()
                actPao:removeFromParent()
                self.m_vecGhost["ghost_"..index] = nil
            end)
            
            performWithDelay(self,function(  )
                self.m_clickGhost = true
            end,0.2)
            
        end

        actPao:setCoins(coins)
        self.m_labCoinsNum:setString(util_formatCoins(winCoins,30))
        self.m_labPicksNum:setString(pickTimes)
        self:updateLabelSize({label=self.m_labCoinsNum,sx=1,sy=1}, 420)
        self:runCsbAction("actionframe")
        -- self:findChild("Particle_1"):resetSystem()
    end           
end

--[[
    @desc: 
    author:{author}
    time:2020-09-10 17:25:09
    --@graveStone:
	--@times: 
    @return:
]]

function HallowinBonusGameView:beginGhostAct(isFirst)
    local createNum = math.random(2,3)
    local beginWith = {- display.width/4 - 10,0,display.width * 1/4 + 10}
    if isFirst then
        createNum = 3
    end
    if self.m_vecGhost == nil then
        self.m_vecGhost = {}
    end
    for i=1,createNum do
        
        local roIndex = math.random( 1 , #beginWith)
        local roundPos = beginWith[roIndex] 
        table.remove(beginWith,roIndex)

        local startPos = cc.p(roundPos,-display.height/2 - 200)

        if isFirst then
            startPos = cc.p(roundPos,-display.height / 2)
        end

        local endPos = cc.p(roundPos,display.height / 2 + 400)
        local scale = math.random(8,9) / 10
        local speed = math.random(100,110)  
        local time = display.height / speed
        local waitTime = math.random(8,12) * 25 / speed  

        self:createOneGhost(startPos,endPos,scale,time,waitTime )
    end
end

function HallowinBonusGameView:createOneGhost(startPos,endPos,scale,time,waitTime )
    self.m_iGhostNum = self.m_iGhostNum + 1
    local node = util_createView("CodeHallowinSrc.HallowinBonusGhost", self.m_iGhostNum)
    node:initCallFunc(function(index)
        if self.m_clickGhost ~= true then
            return true
        end
        gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_click_ghost.mp3")
        self.m_clickGhost = false
        self:recvPaoPaoViewBaseData(index)
        return false
    end)
    self.m_vecGhost["ghost_"..self.m_iGhostNum] = node
    self:findChild("ghost"):addChild(node)
    node:setPosition(startPos)
    node:setScale(scale)
    node:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(true)
        -- local widthNum = math.round(2,5) 
        -- local actList2 = {}
        -- local widthTimes = time / widthNum
        -- for i=1,widthNum do
        --     local roundWitdh = math.round(1,3) * 50 * scale
        --     actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(-roundWitdh  ,0))
        --     actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(roundWitdh  ,0))
        -- end
        -- local sq_1 = cc.Sequence:create(actList2)
        -- node:findChild("root"):runAction(sq_1)
    end)
    actList[#actList + 1] = cc.MoveTo:create(time,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local index = node:getGhostID()
        node:removeFromParent()
        self.m_vecGhost["ghost_"..index] = nil
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function HallowinBonusGameView:showPickTimes(graveStone, times)
    for i = 1, 2, 1 do
        local labTimes = graveStone:findChild("times_"..i.."_"..times)
        labTimes:setVisible(true)
    end
end

--默认按钮监听回调
function HallowinBonusGameView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_chooseFlag ~= true then
        return
    end
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_click_grave.mp3")
    self:runCsbAction("idleframe")
    self.m_chooseFlag = false
    self.m_selectedID = tag
    self:sendData(tag)
end

return HallowinBonusGameView