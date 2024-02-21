---
--xcyy
--2018年5月23日
--TripletroveJackPotBarView.lua

local TripletroveJackPotBarView = class("TripletroveJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins"
local SuperName = "m_lb_coins_0"
local MegaName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4" 

local baseList = {
    "Node_base",
    "Node_base_0",
    "Node_base_1",
    "Node_base_2",
    "Node_base_3",
    "Node_base_4"
}

local freeList = {
    "Node_free",
    "Node_free_0",
    "Node_free_1",
    "Node_free_2",
    "Node_free_3",
    "Node_free_4"
}

function TripletroveJackPotBarView:initUI()

    self:createCsbNode("Tripletrove_jackpot.csb")

    self.megaCurCoins = 0       --储存上一次mega的钱数
    self.majorCurCoins = 0      --储存上次一major的钱数
    self.minorCurCoins = 0
    self.miniCurCoins = 0
    self.grandSpots = {}    --保存jackpot点
    self.superSpots = {}
    self.megaSpots = {}
    self.majorSpots = {}
    self.minorSpots = {}
    self.miniSpots = {}
    self.jackpotFinishList = {}
    self.jackpotBulingList = {}         --底的收集和触发显示
    self.jackpotBulingList2 = {}        --字的触发显示
    self.jackpotBulingList3 = {}        --飞金币反馈（base收集后额外触发在宝箱上飞一个金币到jackpot上，改变钱数）
    self.jackpotBulingList4 = {}        --飞金币反馈2（金色宝箱玩法，收集jackpot小块）
    self.boomBulingList = {}            --储存金色宝箱玩法飞金币爆点
    self:setjackpotBarSpot()
    self:setjackpotBarSpotFinish()
    self:showCollectJackpotEffect()
    self:showCollectJackpotEffect2()
    self:showCollectJackpotEffect3()
    self:addFlyGoldEffect()
end

function TripletroveJackPotBarView:onEnter()

    TripletroveJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function TripletroveJackPotBarView:onExit()
    TripletroveJackPotBarView.super.onExit(self)
end

function TripletroveJackPotBarView:initMachine(machine)
    self.m_machine = machine
end


-- 更新jackpot 数值信息
--
function TripletroveJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(SuperName),2,true)
    

    self:updateSize()
end

function TripletroveJackPotBarView:updateSize()
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[SuperName]
    local info1={label=label1,sx=0.51,sy=0.51}
    local info2={label=label2,sx=0.353,sy=0.353}
    
    self:updateLabelSize(info1,834)
    self:updateLabelSize(info2,834)
    
end

function TripletroveJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50,nil,nil,true))
end


function TripletroveJackPotBarView:resetJackpotScore( )
    self:changeNode(self:findChild(MegaName),3)
    self:changeNode(self:findChild(MajorName),4)
    self:changeNode(self:findChild(MinorName),5)
    self:changeNode(self:findChild(MiniName),6)

    local label3=self.m_csbOwner[MegaName]
    local info3={label=label3,sx=0.29,sy=0.31}
    local label4=self.m_csbOwner[MajorName]
    local info4={label=label4,sx=0.29,sy=0.31}
    local label5=self.m_csbOwner[MinorName]
    local info5={label=label5,sx=0.28,sy=0.31}
    local label6=self.m_csbOwner[MiniName]
    local info6={label=label6,sx=0.28,sy=0.31}

    self:updateLabelSize(info3,562)
    self:updateLabelSize(info4,562)
    self:updateLabelSize(info5,562)
    self:updateLabelSize(info6,562)
end

function TripletroveJackPotBarView:showJackpotBarBigger(index)
    if not index then return end
    if index == 1 then
        self:runCsbAction("actionframe4")
    elseif index == 2 then
        self:runCsbAction("actionframe3")
    elseif index == 3 then
        self:runCsbAction("actionframe2")
    elseif index == 4 then
        self:runCsbAction("actionframe")
    end
end

function TripletroveJackPotBarView:getJackpotBarName(index)
    if index == 3 then
        return self:findChild(MegaName)
    elseif index == 4 then
        return self:findChild(MajorName)
    elseif index == 5 then
        return self:findChild(MinorName)
    elseif index == 6 then
        return self:findChild(MiniName)
    end
end

--label_index,
function TripletroveJackPotBarView:changeNode2(index,changeNum,totalBet,isJump,isAddition,additionIndex)
    local label_index = self:getJackpotBarName(index)
    local value=self.m_machine:BaseMania_updateJackpotScore(index) + changeNum * totalBet
    if isJump then
        local startCoins_index = self.megaCurCoins
        if index == 3 then
            startCoins_index = self.megaCurCoins
        elseif index == 4 then
            startCoins_index = self.majorCurCoins
        elseif index == 5 then
            startCoins_index = self.minorCurCoins
        elseif index == 6 then
            startCoins_index = self.miniCurCoins
        end
        if isAddition then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_base_flyOne_gold.mp3")
            self:showJackpotBarBigger(additionIndex)
            self:delayCallBack(1,function (  )
                if label_index then
                    label_index:stopAllActions()
                    label_index:setString(util_formatCoins(value,50))

                    local info={label = label_index,sx = 0.29,sy = 0.31}
                    if index == 5 or index == 6 then
                        info={label = label_index,sx = 0.28,sy = 0.31}
                    end
                    self:updateLabelSize(info,562)
                end
            end)
        end
        self:jumpCoins({
            label = label_index,
            startCoins = startCoins_index ,
            endCoins = value,
            duration = 0.6,
            maxWidth = 562,
            jackpotIndex = index,
        })
    else
        label_index:setString(util_formatCoins(value,50,nil,nil,true))
    end
    if index == 3 then
        self.megaCurCoins = value
    elseif index == 4 then
        self.majorCurCoins = value
    elseif index == 5 then
        self.minorCurCoins = value
    elseif index == 6 then
        self.miniCurCoins = value
    end
end

--除了grand和super之外，其他的jackpot根据spin次数增长
function TripletroveJackPotBarView:changeNodeForSpin(info,totalBet,isJump,isAddition,additionIndex)
    --self:findChild(MegaName),self:findChild(MajorName),self:findChild(MinorName),self:findChild(MiniName),
    --加钱时需要滚动
    self:changeNode2(3,info[1],totalBet,isJump,isAddition,additionIndex)
    self:changeNode2(4,info[2],totalBet,isJump,isAddition,additionIndex)
    self:changeNode2(5,info[3],totalBet,isJump,isAddition,additionIndex)
    self:changeNode2(6,info[4],totalBet,isJump,isAddition,additionIndex)

    local label3=self.m_csbOwner[MegaName]
    local info3={label=label3,sx=0.29,sy=0.31}
    local label4=self.m_csbOwner[MajorName]
    local info4={label=label4,sx=0.29,sy=0.31}
    local label3=self.m_csbOwner[MinorName]
    local info5={label=label3,sx=0.28,sy=0.31}
    local label4=self.m_csbOwner[MiniName]
    local info6={label=label4,sx=0.28,sy=0.31}
    self:updateLabelSize(info3,562)
    self:updateLabelSize(info4,562)
    self:updateLabelSize(info5,562)
    self:updateLabelSize(info6,562)
end

--jackpot是否展示小圆点
function TripletroveJackPotBarView:isShowSpot(isGoldFeature)
    if isGoldFeature then
        for i=1,6 do
            self:findChild(baseList[i]):setVisible(false)
            self:findChild(freeList[i]):setVisible(true)
        end
        self:resetSpotNum()
    else
        for i=1,6 do
            self:findChild(baseList[i]):setVisible(true)
            self:findChild(freeList[i]):setVisible(false)
        end

    end
end

--重置点的显示
function TripletroveJackPotBarView:resetSpotNum( )
    for i,v in ipairs(self.grandSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.superSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.megaSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.majorSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.minorSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.miniSpots) do
        v:setJackpotSpotHideEffect()
    end
    for i,v in ipairs(self.jackpotFinishList) do
        v:setVisible(false)
    end

end

--获取点不同类型的点的数量
function TripletroveJackPotBarView:getJackpotSpotNum(jackpotType)
    if jackpotType == 1 then
        return 6
    elseif jackpotType == 2 then
        return 5
    elseif jackpotType == 3 then
        return 4
    elseif jackpotType == 4 then
        return 3
    elseif jackpotType == 5 then
        return 2
    elseif jackpotType == 6 then
        return 2
    end
end

function TripletroveJackPotBarView:setjackpotBarSpotFinish( )
    for i=1,6 do
        local num = self:getJackpotSpotNum(i)
        local finishSpot = util_createView("CodeTripletroveSrc.TripletroveJackpotSpotFinishView")
        self:findChild("Tripletrove_" .. i .. "_" .. num):addChild(finishSpot)
        finishSpot.jackpotType = i
        finishSpot:setVisible(false)
        table.insert( self.jackpotFinishList,finishSpot)
    end
end

function TripletroveJackPotBarView:setjackpotBarSpot( )
    for i=1,6 do
        local num = self:getJackpotSpotNum(i)
        for j=1,num do
            local spot = util_createView("CodeTripletroveSrc.TripletroveJackpotSpotView",i)
            self:findChild("Tripletrove_" .. i .. "_" .. j):addChild(spot)
            spot.jackpotType = i
            spot.spotIndex = j
            self:conserveSpotForList(spot)
        end
    end
end

function TripletroveJackPotBarView:conserveSpotForList(spot)
    if spot.jackpotType == 1 then
        table.insert( self.grandSpots, spot)
    elseif spot.jackpotType == 2 then
        table.insert( self.superSpots, spot)
    elseif spot.jackpotType == 3 then
        table.insert( self.megaSpots, spot)
    elseif spot.jackpotType == 4 then
        table.insert( self.majorSpots, spot)
    elseif spot.jackpotType == 5 then
        table.insert( self.minorSpots, spot)
    elseif spot.jackpotType == 6 then
        table.insert( self.miniSpots, spot)
    end
end

function TripletroveJackPotBarView:getJackpotList(jackpotType)
    if jackpotType == 1 then
        return self.grandSpots
    elseif jackpotType == 2 then
        return self.superSpots
    elseif jackpotType == 3 then
        return self.megaSpots
    elseif jackpotType == 4 then
        return self.majorSpots
    elseif jackpotType == 5 then
        return self.minorSpots
    elseif jackpotType == 6 then
        return self.miniSpots
    end
end

--[[
    @desc: 触发金色宝箱玩法，点击spin收集jackpot图标，集满获得jackpot
    author:{author}
    time:2022-01-12 10:11:12
    @return:根据服务器给的类型和数量更新金色宝箱玩法中jackpot点的显示
]]
function TripletroveJackPotBarView:updateJackpotSpotShow(jackpotType,num,isUpdate)
    if isUpdate then
        self:showJackpotBulingEffect(jackpotType,true)
    end

    local jackpotList = self:getJackpotList(jackpotType)
    for i,v in ipairs(jackpotList) do
        if v.spotIndex <= num then
            v:showJackpotSpotEffect(isUpdate)
        end
    end

    

    local totalNum = self:getJackpotSpotNum(jackpotType)
    if totalNum == num + 1 then     --差一个完成集满，循环特效
        for i,v in ipairs(self.jackpotFinishList) do
            if v.jackpotType == jackpotType then
                v:setVisible(true)
                v:showSpotEffect()
            end
        end
    elseif totalNum == num then     --集满就隐藏掉循环特效
        self:collectFullEffect(jackpotType)
    end

end

--集满之后隐藏即将集满的效果
function TripletroveJackPotBarView:collectFullEffect(jackpotType)
    for i,v in ipairs(self.jackpotFinishList) do
        if v.jackpotType == jackpotType then
            v:setVisible(false)
        end
    end
end

--中了jackpot后清空集满的点
function TripletroveJackPotBarView:clearCollectFullEffect(jackpotType)
    local jackpotList = self:getJackpotList(jackpotType)
    for i,v in ipairs(jackpotList) do
        v:setJackpotSpotHideEffect()
    end
end

--***********************收集反馈和触发jackpot反馈
function TripletroveJackPotBarView:showCollectJackpotEffect2( )
    for i=1,6 do
        local bulingEffect = util_createAnimation("Tripletrove_jackpot_zj_zi.csb")
        self:findChild("Node_" .. i .. "_zi"):addChild(bulingEffect)
        bulingEffect.jackpotType = i
        self:changeCollectJackpot(bulingEffect)
        table.insert( self.jackpotBulingList2,bulingEffect)
    end
end

function TripletroveJackPotBarView:showCollectJackpotEffect( )
    for i=1,6 do
        local bulingEffect = util_createAnimation("Tripletrove_jackpot_zj.csb")
        self:findChild("Node_jackpot_" .. i):addChild(bulingEffect)
        bulingEffect.jackpotType = i
        self:changeCollectJackpot(bulingEffect)
        table.insert( self.jackpotBulingList,bulingEffect)

        --爆点
        local boomEffect = util_createAnimation("Tripletrove_jackpot_zj_bg.csb")
        self:findChild("Node_jackpot_" .. i):addChild(boomEffect,10)
        boomEffect.jackpotType = i
        self:changeBoomCollectJackpot(boomEffect)
        table.insert( self.boomBulingList,boomEffect)
    end
end

function TripletroveJackPotBarView:changeCollectJackpot(bulingEffect)
    for i=1,6 do
        if bulingEffect.jackpotType == i then
            bulingEffect:findChild("jackpot_" .. i):setVisible(true)
        else
            bulingEffect:findChild("jackpot_" .. i):setVisible(false)
        end
    end
end

function TripletroveJackPotBarView:showCollectJackpotEffect3( )
    for i=1,6 do
        local bulingEffect = util_createAnimation("Tripletrove_jackpot_zj_jd.csb")
        self:findChild("shanguang" .. i):addChild(bulingEffect)
        bulingEffect.jackpotType = i
        self:changeFlyGoldCollectJackpot2(bulingEffect)
        table.insert( self.jackpotBulingList4,bulingEffect)
        
    end
end

function TripletroveJackPotBarView:changeBoomCollectJackpot(bulingEffect)
    if bulingEffect.jackpotType == 1 then
        bulingEffect:findChild("qita"):setVisible(false)
        bulingEffect:findChild("Grand"):setVisible(true)
    else
        bulingEffect:findChild("qita"):setVisible(true)
        bulingEffect:findChild("Grand"):setVisible(false)
    end
end

function TripletroveJackPotBarView:changeFlyGoldCollectJackpot2(bulingEffect)
    for i=1,6 do
        if bulingEffect.jackpotType == i then
            bulingEffect:findChild("jackpot_" .. i):setVisible(true)
        else
            bulingEffect:findChild("jackpot_" .. i):setVisible(false)
        end
    end
end

--jackpot收集反馈
function TripletroveJackPotBarView:showJackpotBulingEffect(jackpotType,isFree)
    --jackpot框闪烁
    for i,v in ipairs(self.jackpotBulingList) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("shouji")
        end
    end    
end

function TripletroveJackPotBarView:showBoomEffect(jackpotType)
    --爆点
    for i,v in ipairs(self.boomBulingList) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("shouji")
        end
    end
end

--触发jackpot
function TripletroveJackPotBarView:showTriggerJackpotEffect(jackpotType)
    gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_jiMan.mp3")
    for i,v in ipairs(self.jackpotBulingList) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("actionframe",false)
        end
    end
    for i,v in ipairs(self.jackpotBulingList2) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("actionframe",false)
        end
    end
    for i,v in ipairs(self.jackpotBulingList4) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("actionframe")
        end
    end

end

--*************************base飞金币反馈
function TripletroveJackPotBarView:addFlyGoldEffect( )
    for i=1,6 do
        -- if i > 2 then
            local bulingEffect = util_createAnimation("Tripletrove_jackpot_zj_g.csb")
            self:findChild("Node_jackpot_" .. i):addChild(bulingEffect,10)
            bulingEffect.jackpotType = i
            self:changeFlyGoldCollectJackpot(bulingEffect)
            table.insert( self.jackpotBulingList3,bulingEffect)
        -- end
    end
end

function TripletroveJackPotBarView:changeFlyGoldCollectJackpot(bulingEffect)
    if bulingEffect.jackpotType == 3 or bulingEffect.jackpotType == 4 then
        bulingEffect:findChild("jackpot1"):setVisible(false)
        bulingEffect:findChild("jackpot2"):setVisible(false)
        bulingEffect:findChild("jackpot5"):setVisible(false)
        bulingEffect:findChild("jackpot3"):setVisible(true)
    elseif bulingEffect.jackpotType == 5 or bulingEffect.jackpotType == 6 then
        bulingEffect:findChild("jackpot1"):setVisible(false)
        bulingEffect:findChild("jackpot2"):setVisible(false)
        bulingEffect:findChild("jackpot5"):setVisible(true)
        bulingEffect:findChild("jackpot3"):setVisible(false)
    elseif bulingEffect.jackpotType == 1 then
        bulingEffect:findChild("jackpot1"):setVisible(true)
        bulingEffect:findChild("jackpot2"):setVisible(false)
        bulingEffect:findChild("jackpot5"):setVisible(false)
        bulingEffect:findChild("jackpot3"):setVisible(false)
    elseif bulingEffect.jackpotType == 2 then
        bulingEffect:findChild("jackpot1"):setVisible(false)
        bulingEffect:findChild("jackpot2"):setVisible(true)
        bulingEffect:findChild("jackpot5"):setVisible(false)
        bulingEffect:findChild("jackpot3"):setVisible(false)
    end
end

function TripletroveJackPotBarView:flyGoldFeedback(jackpotType)
    for i,v in ipairs(self.jackpotBulingList3) do
        if v.jackpotType == jackpotType then
            v:runCsbAction("shouji",false)
        end
    end
end

--延迟回调
function TripletroveJackPotBarView:delayCallBack(time, func)
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

--[[
    金币跳动，用于spin增加钱数
]]
function TripletroveJackPotBarView:jumpCoins(params)
    local label_index = params.label
    if not label_index then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 562 --lable最大宽度
    local jackpotIndex = params.jackpotIndex or 3

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120* duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 9 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label_index:stopAllActions()

    label_index:setString(util_formatCoins(startCoins,50))
    if jackpotIndex == 5 or jackpotIndex == 6 then
        self:updateLabelSize({label = label_index,sx = 0.28,sy = 0.31},562)
    else
        self:updateLabelSize({label = label_index,sx = 0.29,sy = 0.31},562)
    end
    
    util_schedule(label_index,function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= endCoins then

            curCoins = endCoins
            label_index:setString(util_formatCoins(curCoins,50))
            
            local info={label = label_index,sx = 0.29,sy = 0.31}
            if jackpotIndex == 5 or jackpotIndex == 6 then
                info={label = label_index,sx = 0.28,sy = 0.31}
            end
            self:updateLabelSize(info,maxWidth)
            label_index:stopAllActions()
        else
            label_index:setString(util_formatCoins(curCoins,50))

            local info={label = label_index,sx = 0.29,sy = 0.31}
            if jackpotIndex == 5 or jackpotIndex == 6 then
                info={label = label_index,sx = 0.28,sy = 0.31}
            end
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

return TripletroveJackPotBarView