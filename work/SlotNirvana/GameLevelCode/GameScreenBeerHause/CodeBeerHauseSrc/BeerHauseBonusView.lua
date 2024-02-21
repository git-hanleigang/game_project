---
--xcyy
--2018年5月23日
--BeerHauseBonusView.lua


---
--smy
--2018年4月26日
--BeerHauseBonusView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local BeerHauseBonusView = class("BeerHauseBonusView",BaseGame )
BeerHauseBonusView.m_mainClass = nil
BeerHauseBonusView.isClickNow = nil
BeerHauseBonusView.m_bonusEndCall = nil
BeerHauseBonusView.m_runResultDataCall = nil


BeerHauseBonusView.m_CupNum = 8
BeerHauseBonusView.m_CupNodeList = {}

BeerHauseBonusView.m_actName = {"actionframe1","actionframe2","actionframe3","actionframe4"}
BeerHauseBonusView.m_notChooseActName = {"idle5","idle6","idle7","idle4"}

BeerHauseBonusView.m_CupFSTimes_1 = 1
BeerHauseBonusView.m_CupFSTimes_2 = 2
BeerHauseBonusView.m_CupFSTimes_3 = 3
BeerHauseBonusView.m_CupFSTimes_Start = 99

function BeerHauseBonusView:initUI()

    self.isClickNow = false

    self:createCsbNode("BeerHause/GameMini.csb")

    self:initTittle( )
    self:initCupView( )

    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true

    self:startGameCallFunc()

end



function BeerHauseBonusView:onEnter()
    BaseGame.onEnter(self)
end
function BeerHauseBonusView:onExit()
    scheduler.unschedulesByTargetName("BeerHauseBonusView")
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

-- function BeerHauseBonusView:featureResultCallFun(param)
--     BaseGame.featureResultCallFun(self,param)
-- end


function BeerHauseBonusView:initTittle( )
    local tittleNode1 = self:findChild("ban"..1)
    self.m_tittleView1 = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView","BeerHause_GameMini_ban1" )
    tittleNode1:addChild(self.m_tittleView1)

    local tittleNode2 = self:findChild("ban"..2)
    self.m_tittleView2 = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView", "BeerHause_GameMini_ban2")
    tittleNode2:addChild(self.m_tittleView2)
    self.m_tittleView2:findChild("BitmapFontLabel_1"):setString("0")
    self.m_tittleView2:runCsbAction("idle1")
    
    
end



function BeerHauseBonusView:initCupView( )
    self.m_CupNodeList = {}

    local function itemFunc(pos)
        self.isClickNow = true

        self:sendStep(pos)
    end

    for i=1,self.m_CupNum do
        local cupNode = self:findChild("cup"..i)
        local CupView = util_createView("CodeBeerHauseSrc.BeerHauseCupView" )
        CupView:initItem(self,i,itemFunc)
        CupView:runCsbAction("idle") 
        cupNode:addChild(CupView)
        table.insert( self.m_CupNodeList, CupView)
    end
    
end

--数据发送
function BeerHauseBonusView:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        messageData={msg=MessageDataType.MSG_BONUS_SELECT , clickPos = pos - 1}
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end


function BeerHauseBonusView:initBonusUI(data )
    
    local contents = data.extra.plusSpinTimes or {}

    local chooseIndex = data.choose or {}


    for i=1,#chooseIndex do
        local pos = chooseIndex[i] + 1

        local cup =  self.m_CupNodeList[pos]

        if cup then

            local click = cup:findChild("click")
            if click then
                click:setVisible(false)
            end
            local actId = contents[i]
            if actId == self.m_CupFSTimes_Start then
                actId = 4
            end

            cup:runCsbAction(self.m_actName[actId])
        end
    end

    local rewordFsTimes = 0
    for i=1,#chooseIndex do
        local times = contents[i]
        if times ~= self.m_CupFSTimes_Start then
            rewordFsTimes = rewordFsTimes + times
        end
    end
    if rewordFsTimes > 1 then
        self.m_tittleView2:runCsbAction("idle2")
    else
        self.m_tittleView2:runCsbAction("idle1")
    end

    self.m_tittleView2:findChild("BitmapFontLabel_1"):setString(rewordFsTimes)

end


--数据接收
function BeerHauseBonusView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV

    self.isClickNow = false

    -- "CLOSED"
    -- "OPEN" 

    local status  = "OPEN"
    local contents = {}
    local chooseIndex = {}

    if featureData.p_bonus then
        if featureData.p_bonus.choose  then
                
            chooseIndex = featureData.p_bonus.choose 
        end

        if featureData.p_bonus.extra then
            
            if featureData.p_bonus.extra.plusSpinTimes then
                contents = featureData.p_bonus.extra.plusSpinTimes
            end

            if #chooseIndex > 0 and #contents > 0 then
                if contents[#chooseIndex] == self.m_CupFSTimes_Start  then
                    status = "CLOSED"
                end
                
            end

        end
        
    end




    --数据赋值
    self.p_contents = contents --featureData.p_contents
    self.p_chose = chooseIndex -- featureData.p_chose
    self.p_status = status -- featureData.p_status

    --父类计算出当前用户选择的数据
    local selectData=self:getSelectData(featureData)
    --计算数据
    self:calculateData(selectData)

    
end

--处理数据 子类可以继承改写
function BeerHauseBonusView:getSelectData(featureData)
    --获得选择的数据
    local selectData=nil
    if self:isGameOver() then
        local index = #self.p_chose
        selectData=self.p_contents[index]
    else
        selectData=self.p_contents[#self.p_contents]
    end
    return selectData
end

 --处理数据
 function BeerHauseBonusView:calculateData(selectData)
    
    if self.m_isContinue == true then
        -- body
        self.m_posIndex= self.m_posIndex+1
    end
    
    --交给子类计算其他数据
    self:recvData(selectData,self:isGameOver())



    --交给子类显示数据
    self:showStep(self.m_pos[self.m_posIndex],selectData)
    --借宿步骤判断下一步
    self:overStep()
end

--服务器数据展示(宝箱奖励展示)
function BeerHauseBonusView:showStep(pos,selectData)
    -- 在游戏过程中显示某个
    local cup =  self.m_CupNodeList[pos]

    if cup then

        local click = cup:findChild("click")
        if click then
            click:setVisible(false)
        end

        local actid = selectData
        if actid == self.m_CupFSTimes_Start then
            actid = 4
        end
        cup:runCsbAction(self.m_actName[actid])
    end

    local rewordFsTimes = 0
    for i=1,#self.p_chose do
        local times = self.p_contents[i]
        if times ~= self.m_CupFSTimes_Start then
            rewordFsTimes = rewordFsTimes + times
        end
    end

    if rewordFsTimes > 1 then
        self.m_tittleView2:runCsbAction("idle2")
    else
        self.m_tittleView2:runCsbAction("idle1")
    end

    self.m_tittleView2:findChild("BitmapFontLabel_1"):setString(rewordFsTimes)

end

--开始结束流程
function BeerHauseBonusView:gameOver(isContinue)

    for i=1,8 do
        local cup =self.m_CupNodeList[i]
        if cup then
           local click = cup:findChild("click")
           if click then
                click:setVisible(false)
           end
        end
    end

    --默认1秒后弹出其他箱子内容，子类实现
    performWithDelay(self,function(  )
        self:showOther(isContinue)
    end,1)

    --默认3秒后弹出结算面板，子类实现
    performWithDelay(self,function(  )
        self:showReward(isContinue)
    end,3)

end

--弹出结算界面前展示其他宝箱数据
function BeerHauseBonusView:showOther()

    local itemId = {1,2,3,4,5,6,7,8}

    -- 找出没有打开的
    for i=1,#self.p_chose do
        local choose = self.p_chose[i] + 1
        for k=#itemId,1,-1 do
            local id = itemId[k]
            if choose == id then
                table.remove( itemId, k)
            end
        end
    end

    local notChoose = {}
    for i=1,#self.p_contents do
        if i > #self.p_chose then
            table.insert( notChoose, self.p_contents[i] )
        end
    end

    for i=1,#itemId do
        local id =  itemId[i]
        local itemMul = notChoose[i] 

        local cup =self.m_CupNodeList[id]
        if cup then
            local actid = itemMul
            if actid == self.m_CupFSTimes_Start then
                actid = 4
            end
            cup:runCsbAction(self.m_notChooseActName[actid])
        end
    end

end
--弹出结算奖励
function BeerHauseBonusView:showReward()
   if self.m_bonusEndCall then
        self.m_bonusEndCall()
   end 
end

function BeerHauseBonusView:setEndCall( func)
    self.m_bonusEndCall = func
end


function BeerHauseBonusView:setRunResultDataCall(func )
    self.m_runResultDataCall =  func
end

function BeerHauseBonusView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        -- print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        
        if self.m_runResultDataCall then
            self.m_runResultDataCall(spinData)
        end
        

        if spinData.action == "FEATURE" then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

return BeerHauseBonusView









