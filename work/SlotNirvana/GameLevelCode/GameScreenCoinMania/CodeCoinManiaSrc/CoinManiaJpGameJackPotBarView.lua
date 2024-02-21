---
--xcyy
--2018年5月23日
--CoinManiaJpGameJackPotBarView.lua

local CoinManiaJpGameJackPotBarView = class("CoinManiaJpGameJackPotBarView",util_require("base.BaseView"))

local MegaName = "ml_b_coins1"
local GrandName = "ml_b_coins2"
local MajorName = "ml_b_coins3"
local MinorName = "ml_b_coins4"
local MiniName = "ml_b_coins5" 

CoinManiaJpGameJackPotBarView.m_isPlayLabJump = false

CoinManiaJpGameJackPotBarView.m_JackPotBarMultiply = 1

CoinManiaJpGameJackPotBarView.m_LastCoinsNum = {}

function CoinManiaJpGameJackPotBarView:initUI()

    self:createCsbNode("CoinMania_JackPot_wanfa_jp.csb")

    self:runCsbAction("idleframe",true)
    self.m_JackPotBarMultiply = 1

    self.m_JackPotBarMultiply = self.m_OldJPBarMultiply

    self.m_isPlayLabJump = false

    self.m_LastCoinsNum = {}
end

function CoinManiaJpGameJackPotBarView:onExit()
 
end

function CoinManiaJpGameJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CoinManiaJpGameJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CoinManiaJpGameJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local data=self.m_csbOwner


    self:changeNode(self:findChild(MegaName),1,true)
    self:changeNode(self:findChild(GrandName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4,true)
    self:changeNode(self:findChild(MiniName),5,true)

    self:updateSize()
end

function CoinManiaJpGameJackPotBarView:updateSize()

    local label5=self.m_csbOwner[MegaName]
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]

    local info5={label=label5,sx=1,sy=1}
    local info1={label=label1,sx=0.96,sy=0.96}
    local info2={label=label2,sx=0.85,sy=0.85}
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=0.85,sy=0.85}

    self:updateLabelSize(info5,453)
    self:updateLabelSize(info1,271)
    self:updateLabelSize(info2,249)
    self:updateLabelSize(info3,155)
    self:updateLabelSize(info4,156)
end

function CoinManiaJpGameJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)


    if index ~= 1 then
        if self.m_isPlayLabJump then
        
            return
        end 
    end

    

    if index ~= 1 then
        value = self.m_JackPotBarMultiply * value
    end
    


    label:setString(util_formatCoins(value,50,nil,nil,true))
end



function CoinManiaJpGameJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


function CoinManiaJpGameJackPotBarView:jpLabAction( time )
    

    self.m_isPlayLabJump = true

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]

    local startValue1 = self.m_machine:BaseMania_updateJackpotScore(2) * self.m_OldJPBarMultiply
    local startValue2 = self.m_machine:BaseMania_updateJackpotScore(3) * self.m_OldJPBarMultiply
    local startValue3 = self.m_machine:BaseMania_updateJackpotScore(4) * self.m_OldJPBarMultiply
    local startValue4 = self.m_machine:BaseMania_updateJackpotScore(5) * self.m_OldJPBarMultiply

    local endValue1 = self:getAfterSecondJpValue( 5 ,2 ) * self.m_JackPotBarMultiply 
    local endValue2 = self:getAfterSecondJpValue( 5 ,3 ) * self.m_JackPotBarMultiply
    local endValue3 = self:getAfterSecondJpValue( 5 ,4 ) * self.m_JackPotBarMultiply
    local endValue4 = self:getAfterSecondJpValue( 5 ,5 ) * self.m_JackPotBarMultiply

    local addValue1 = endValue1 - startValue1
    local addValue2 = endValue2 - startValue2
    local addValue3 = endValue3 - startValue3
    local addValue4 = endValue4 - startValue4

    self.m_LastCoinsNum[1] = endValue1
    self.m_LastCoinsNum[2] = endValue2
    self.m_LastCoinsNum[3] = endValue3
    self.m_LastCoinsNum[4] = endValue4

    util_jumpNum(label1,startValue1,endValue1,addValue1 / 10,time/10 ,{50},nil,nil,function(  )
        self.m_isPlayLabJump = false
    end,nil)
    util_jumpNum(label2,startValue2,endValue2,addValue2 / 10,time/10,{50},nil,nil,nil,nil)
    util_jumpNum(label3,startValue3,endValue3,addValue3 / 10,time/10,{50},nil,nil,nil,nil)
    util_jumpNum(label4,startValue4,endValue4,addValue4 / 10,time/10,{50},nil,nil,nil,nil)

end

function CoinManiaJpGameJackPotBarView:stopJumplab( )
    
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]

    label1:unscheduleUpdate()
    label2:unscheduleUpdate()
    label3:unscheduleUpdate()
    label4:unscheduleUpdate()

    label1:setString(self.m_LastCoinsNum[1])
    label2:setString(self.m_LastCoinsNum[2])
    label3:setString(self.m_LastCoinsNum[3])
    label4:setString(self.m_LastCoinsNum[4])

    self.m_isPlayLabJump = false

    self:runCsbAction("idleframe")

end

function CoinManiaJpGameJackPotBarView:getAfterSecondJpValue( second ,posIndex )
    
    local totalScore,baseScore,jpAddCoins = 0,0,0
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index ,poolData in pairs(jackpotPools) do 
            if posIndex == index then
                totalScore,baseScore = self:getAfterSecondsJackpotPool(poolData,false,globalData.slotRunData:getCurTotalBet(),second)
                jpAddCoins =totalScore-baseScore
            end
            
        end
    end

    return totalScore,baseScore,jpAddCoins
end

function CoinManiaJpGameJackPotBarView:getAfterSecondsJackpotPool(poolData,isNotify,totalBet,second)
    if not poolData then
        return 0
    end
    local configData = poolData.p_configData

    if type(configData) == "number" then
        return 0
    end

    local currentPool,extraPool =self:getAfterSecondsJackpotMultiple(poolData,second)
    local totalReward = 0
    local baseReward = 0
    local extraPool = 0
    if not totalBet then
        --大厅显示totalbet
        totalReward= globalData.jackpotRunData:getTotalPool(configData.p_gameID,currentPool)
    else
        --游戏中根据当前totalbet刷新
        totalReward = math.floor(currentPool*totalBet)
        baseReward= math.floor(configData.p_multiple*totalBet)
        extraPool = math.floor(extraPool*totalBet)
    end
    return totalReward,baseReward,extraPool
end

function CoinManiaJpGameJackPotBarView:getAfterSecondsJackpotMultiple(poolData , second  )
    local currentPool = 0
    local extraPool = 0
    local configData = poolData.p_configData
    --根据时间和增量刷新
    if poolData.p_isFresh then
        --间隔时间
        local spanTime = (socket.gettime()-poolData.p_initTime) + second
        --根据时间计算jackpot奖池
        currentPool = poolData.p_initPool+spanTime*configData.p_increase
        if currentPool<0 or currentPool>poolData.p_resetPool then
            currentPool =  poolData.p_initPool
        end
        extraPool = currentPool-configData.p_multiple
    else
        --不刷新使用基础倍率
        currentPool = configData.p_multiple
    end
    return currentPool,extraPool
end

return CoinManiaJpGameJackPotBarView