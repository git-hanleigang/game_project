local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WheelOfRhinoWheelView = class("WheelOfRhinoWheelView",BaseGame)
WheelOfRhinoWheelView.m_OpenZhizhenNum = -1
function WheelOfRhinoWheelView:getScatterNum()
    local scatterNum = 5
    if self.m_spinDataResult and self.m_spinDataResult.bonus and self.m_spinDataResult.bonus.extra then
        scatterNum = self.m_spinDataResult.bonus.extra.triggerSignalCount
    elseif self.m_machine.m_runSpinResultData and self.m_machine.m_runSpinResultData.p_bonusExtra then
        scatterNum = self.m_machine.m_runSpinResultData.p_bonusExtra.triggerSignalCount
    elseif self.m_machine.m_feature and self.m_machine.m_feature.bonus and self.m_machine.m_feature.bonus.extra then
        scatterNum = self.m_machine.m_feature.bonus.extra.triggerSignalCount
    end
    if scatterNum > 9 then
        scatterNum = 9
    end
    return scatterNum
end
function WheelOfRhinoWheelView:getJackpotTypeName()
    local jackpotName = {
        ["5"] = "mini",
        ["6"] = "minor",
        ["7"] = "maxi",
        ["8"] = "major",
        ["9"] = "grand",
    }
    return jackpotName[""..self:getScatterNum()]
end
--添加上轮盘盘面
function WheelOfRhinoWheelView:addUpWheelItems()

    local currOpenNum = self:getOpenZhizhenNum()
    if currOpenNum == self.m_OpenZhizhenNum  then
        return
    end

    self.m_OpenZhizhenNum = currOpenNum

    local wheelTypeTab = self["m_upWheelTypes" .. currOpenNum][""..self:getScatterNum()]
    if wheelTypeTab then
        for i,typeString in ipairs(wheelTypeTab) do

            local itemNode = self:findChild("itemNode"..i)
            local item = itemNode:getChildByName("item")
            if item then
                item:removeFromParent()
            end
            
            if tonumber(typeString) then --数字
                -- local totalBet = globalData.slotRunData:getCurTotalBet()
                -- local coin = tonumber(typeString)/100 * totalBet
                local item = util_createAnimation("WheelOfRhino_wheel1_coins.csb")
                itemNode:addChild(item)
                item:setName("item")
                -- local coinString = util_formatCoins(coin, 3)
                local len = string.len(typeString)
                for j = 1,len do
                    local numChar = string.sub(typeString,j,j)
                    item:findChild("BitmapFontLabel_"..j):setString(numChar)
                end
                for j = len + 1,5 do
                    item:findChild("BitmapFontLabel_"..j):setVisible(false)
                end
                -- item:findChild("BitmapFontLabel_1_1"):setString(util_formatCoins(coin, 3))
            elseif string.find(typeString,"WHEEL") then--加倍jackpot
                local item = util_createAnimation("WheelOfRhino_wheel1_"..self:getJackpotTypeName().."bonus.csb")
                itemNode:addChild(item)
                item:setName("item")
            elseif string.find(typeString,"FREE") then--freespin
                local item = util_createAnimation("WheelOfRhino_wheel1_fs.csb")
                itemNode:addChild(item)
                item:setName("item")

                local index = string.find(typeString,"FREE")
                item:findChild("BitmapFontLabel_1"):setString(string.sub(typeString,1,index - 1))
            elseif string.find(typeString,"UP") then-- up
                local item = util_createAnimation("WheelOfRhino_wheel_upgrand.csb")
                itemNode:addChild(item)
                item:setName("item")
            else--jackpot
                local item = util_createAnimation("WheelOfRhino_wheel1_"..self:getJackpotTypeName()..".csb")
                itemNode:addChild(item)
                item:setName("item")
            end
        end
    end
end

function WheelOfRhinoWheelView:initUI(machine)
    self:createCsbNode("WheelOfRhino_wheel1.csb")
    self.m_machine = machine

    self.m_spinDataResult = nil
    self.m_OpenZhizhenNum = -1
    --
    self.m_upWheelTypes1 = {    
        ["5"] = {"UP",   "MINIWHEEL", "200","800","MINIWHEEL","10FREE","300","500","10FREE","UP",  "MINIWHEEL","200","800","MINIWHEEL","10FREE","300","500","10FREE"},
        ["6"] = {"UP","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE","UP","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE"},
        ["7"] = {"UP","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE","UP","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE"},
        ["8"] = {"UP","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE","UP","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE"},
        ["9"] = {"UP","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE","UP","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE"}
    }

    self.m_upWheelTypes2 = {        

        ["5"] = {"UP","MINIWHEEL","200","800","MINIWHEEL","10FREE","300","500","10FREE","10000","MINIWHEEL","200","800","MINIWHEEL","10FREE","300","500","10FREE"},
        ["6"] = {"UP","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE","10000","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE"},
        ["7"] = {"UP","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE","10000","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE"},
        ["8"] = {"UP","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE","10000","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE"},
        ["9"] = {"UP","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE","10000","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE"}
    }


    self.m_upWheelTypes3 = {      

        ["5"] = {"10000","MINIWHEEL","200","800","MINIWHEEL","10FREE","300","500","10FREE","10000","MINIWHEEL","200","800","MINIWHEEL","10FREE","300","500","10FREE"},
        ["6"] = {"10000","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE","10000","MINORWHEEL","300","1000","MINORWHEEL","15FREE","500","800","15FREE"},
        ["7"] = {"10000","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE","10000","MAXIWHEEL","500","1500","MAXIWHEEL","20FREE","800","1000","20FREE"},
        ["8"] = {"10000","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE","10000","MAJORWHEEL","800","2500","MAJORWHEEL","25FREE","1000","1500","25FREE"},
        ["9"] = {"10000","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE","10000","GRANDWHEEL","1000","5000","GRANDWHEEL","30FREE","1500","2500","30FREE"}
    }

    --添加上轮盘盘面
    self:addUpWheelItems()
    --添加指针
    self.m_zhizhenNodeTab = {}
    self:findChild("zhizhen1").isOpen = true
    table.insert(self.m_zhizhenNodeTab,self:findChild("zhizhen1"))
    for i = 2,3 do
        local zhizhenNode = util_createAnimation("WheelOfRhino_wheel_zhishi.csb")
        self:findChild("zhizhen"..i):addChild(zhizhenNode)
        zhizhenNode:playAction("idle")
        zhizhenNode.isOpen = false--这个指针是否打开
        table.insert(self.m_zhizhenNodeTab,zhizhenNode)
        zhizhenNode:setVisible(false)
    end
    --添加上轮盘中奖框
    self.m_upRewardFrameTab = {}
    for i = 1,3 do
        local upRewardFrame = util_createAnimation("WheelOfRhino_Wheel_zhongjiangkuang.csb")
        self:findChild("rewardFrame"..i):addChild(upRewardFrame)
        if i > 1 then
            upRewardFrame:setPosition(cc.p(self:findChild("rewardFrame1"):getPosition()))
        end
        upRewardFrame:playAction("actionframe",true)
        upRewardFrame:findChild("Wheel2"):setVisible(false)
        table.insert(self.m_upRewardFrameTab,upRewardFrame)
        upRewardFrame:setVisible(false)
    end
    --添加下轮盘
    self.m_bottomWheelNode = util_createAnimation("WheelOfRhino_wheel2.csb")
    self:addChild(self.m_bottomWheelNode)
    -- if display.height > DESIGN_SIZE.height then
    --     self.m_bottomWheelNode:setPositionY(display.height/2 - DESIGN_SIZE.height/2) 
    -- end
    --添加下轮盘中奖框
    self.m_bottomRewardFrame = util_createAnimation("WheelOfRhino_Wheel_zhongjiangkuang.csb")
    self.m_bottomWheelNode:findChild("rewardFrame"):addChild(self.m_bottomRewardFrame)
    self.m_bottomRewardFrame:playAction("actionframe",true)
    self.m_bottomRewardFrame:setVisible(false)
    self.m_bottomRewardFrame:findChild("Wheel"):setVisible(false)

    self.distance_now = 0
    self.distance_pre = 0
    --添加转动盘
    self.m_upWheel = require("CodeWheelOfRhinoSrc.WheelOfRhinoWheelAction"):create(self:findChild("wheelNode"),18,function()
        self.distance_now = 0
        self.distance_pre = 0
        -- 滚动结束调用
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_wheelRollend.mp3")
        self:upWheelOver()
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
        self:setRotionWheel(distance,targetStep)
    end)
    self:addChild(self.m_upWheel)

    self.m_bottomWheel = require("CodeWheelOfRhinoSrc.WheelOfRhinoWheelAction"):create(self.m_bottomWheelNode:findChild("wheelNode"),18,function()
        self.distance_now = 0
        self.distance_pre = 0
        -- 滚动结束调用
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_wheelRollend.mp3")
        self:bottomWheelOver()
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
        self:setRotionWheel(distance,targetStep)
    end)
    self:addChild(self.m_bottomWheel)

    self:addClick(self:findChild("clickNode"))
    self:addClick(self:findChild("showViewClick"))
    self:findChild("clickNode"):setTouchEnabled(false)
    self:findChild("showViewClick"):setTouchEnabled(false)

    self:runCsbAction("idleframe1",true)
end
function WheelOfRhinoWheelView:setRotionWheel(distance,targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_wheelRoll1.mp3")
    end
end

--添加bonus开始弹框
function WheelOfRhinoWheelView:showBonusStartView()
    local bonusStartView = util_createAnimation("WheelOfRhino_text.csb")
    bonusStartView:findChild("WheelOfRhino_text_"..self:getJackpotTypeName()):setVisible(true)
    self:addChild(bonusStartView)
    bonusStartView:playAction("actionframe",false,function ()
        self:findChild("clickNode"):setTouchEnabled(true)
        bonusStartView:removeFromParent()
    end)
end
--重连
function WheelOfRhinoWheelView:reconnection()
    self:findChild("clickNode"):setTouchEnabled(true)
    self:updateUpWheelState(false)
    self:addUpWheelItems()
end

--通过数据获得当前开了几个指针
function WheelOfRhinoWheelView:getOpenZhizhenNum()
    local num = 1
    if self.m_spinDataResult and self.m_spinDataResult.bonus and self.m_spinDataResult.bonus.content then
        for i = 1,#self.m_spinDataResult.bonus.content do
            if self.m_spinDataResult.bonus.content[i] == "UP" then
                num = num + 1
            end
        end
    else
        if self.m_machine.m_feature and self.m_machine.m_feature.bonus and self.m_machine.m_feature.bonus.content then
            for i = 1,#self.m_machine.m_feature.bonus.content do
                if self.m_machine.m_feature.bonus.content[i] == "UP" then
                    num = num + 1
                end
            end
        end
    end
    return num
end
--更新上轮盘指针状态
function WheelOfRhinoWheelView:updateUpWheelState(isPlayAni)
    local currOpenNum = self:getOpenZhizhenNum()

    if isPlayAni then
        for i = 1,currOpenNum do
            if self.m_zhizhenNodeTab[i].isOpen == false then
                self.m_zhizhenNodeTab[i].isOpen = true
                self.m_zhizhenNodeTab[i]:setVisible(true)
                self.m_zhizhenNodeTab[i]:playAction("actionframe",false,function ()
                    self.m_zhizhenNodeTab[i]:playAction("idle2")
                end)
            end
        end
        for i = currOpenNum + 1,#self.m_zhizhenNodeTab do
            self.m_zhizhenNodeTab[i].isOpen = false
            self.m_zhizhenNodeTab[i]:setVisible(false)
            self.m_zhizhenNodeTab[i]:playAction("idle")
        end
    else
        for i = 1,currOpenNum do
            if self.m_zhizhenNodeTab[i].isOpen == false then
                self.m_zhizhenNodeTab[i].isOpen = true
                self.m_zhizhenNodeTab[i]:setVisible(true)
                self.m_zhizhenNodeTab[i]:playAction("idle2")
            end
        end
        for i = currOpenNum + 1,#self.m_zhizhenNodeTab do
            self.m_zhizhenNodeTab[i].isOpen = false
            self.m_zhizhenNodeTab[i]:setVisible(false)
            self.m_zhizhenNodeTab[i]:playAction("idle")
        end
    end
end
function WheelOfRhinoWheelView:onEnter()
    WheelOfRhinoWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:closeView()
    end,"WheelOfRhinoWheelView_closeView")
end
--接收返回消息
function WheelOfRhinoWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]

        if spinData.action == "FEATURE" then
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

            self.m_totleWimnCoins = spinData.result.winAmount

            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            self.m_spinDataResult = spinData.result
            self.m_machine:SpinResultParseResultData(spinData)
            self:upWheelStart()
        end
    else
        -- 处理消息请求错误情况
    end
end
function WheelOfRhinoWheelView:onExit()
    WheelOfRhinoWheelView.super.onExit(self)
end
--点击回调
function WheelOfRhinoWheelView:clickFunc(sender)
    local name = sender:getName()
    if name == "clickNode" then
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_clickedWheelSpin.mp3")
        self:findChild("clickNode"):setTouchEnabled(false)
        self:sendData()
        self:runCsbAction("open",false,function ()
            self:runCsbAction("idleframe2",true)
        end)
    elseif name == "showViewClick" then
        self:showViewClick()
    end
end
function WheelOfRhinoWheelView:showViewClick()
    if self.m_showViewDelayAni then
        self:stopAction(self.m_showViewDelayAni)
        self.m_showViewDelayAni = nil
    end

    self:findChild("showViewClick"):setTouchEnabled(false)
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showViewOver.mp3")
    if  #self.m_settlementData > 1 and self:getType(self.m_settlementData[1]) == 1 and self:isHaveJackpotWheel(self.m_settlementData) then
        self:toNextView()
    else
        self.m_showView:playAction("over_1_2_3",false,function ()
            self.m_showView:removeFromParent()
            self:toNextView()
        end)
    end
end
function WheelOfRhinoWheelView:isHaveJackpotWheel(dataTab)
    for i,v in ipairs(dataTab) do
        if self:getType(v) == 3 then
            return true
        end
    end
    return false
end
--数据发送
function WheelOfRhinoWheelView:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
--上轮盘开始转动
function WheelOfRhinoWheelView:upWheelStart()
    local endidx = self:getUpWheelResultIdx()
    self.m_upWheel:recvData(endidx)
    self.m_upWheel:beginWheel()
end

--计算上轮盘结果的id
function WheelOfRhinoWheelView:getUpWheelResultIdx()
    local idxTab = {}
    if self.m_spinDataResult and self.m_spinDataResult.bonus and self.m_spinDataResult.bonus.content then
        local scatterNum = self.m_spinDataResult.bonus.extra.triggerSignalCount
        if scatterNum > 9 then
            scatterNum = 9
        end


        local wheelTypeTab = self["m_upWheelTypes" .. self.m_OpenZhizhenNum][""..scatterNum]


        local resultTypeTab = {}
        if #self.m_spinDataResult.bonus.content == 1 then
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[1])
        elseif #self.m_spinDataResult.bonus.content == 3 then
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[2])
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[3])
        elseif #self.m_spinDataResult.bonus.content == 6 then
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[4])
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[5])
            table.insert(resultTypeTab,self.m_spinDataResult.bonus.content[6])
        end

        for i,resultType in ipairs(resultTypeTab) do
            for j,wheelType in ipairs(wheelTypeTab) do
                if wheelType == resultType then
                    local wheel = {}
                    table.insert(wheel,wheelType)
                    if #resultTypeTab > 1 then
                        local index = j - 2
                        if index <= 0 then
                            index = #wheelTypeTab + index
                        end
                        table.insert(wheel,wheelTypeTab[index])
                    end
                    if #resultTypeTab > 2 then
                        local index = j + 2
                        if index > #wheelTypeTab then
                            index = index - #wheelTypeTab
                        end
                        table.insert(wheel,wheelTypeTab[index])
                    end
                    if self:bothTabContIsSame(resultTypeTab,wheel) then
                        table.insert(idxTab,j)
                    end
                end
            end
        end
    end
    return idxTab[math.random(1,#idxTab)]
end
--判断两个tab的内容是否一样（顺序可能不同）
function WheelOfRhinoWheelView:bothTabContIsSame(tab1,tab2)
    local iTab1 = clone(tab1)
    local iTab2 = clone(tab2)
    for i1,v1 in ipairs(iTab1) do
        for i2,v2 in ipairs(iTab2) do
            if v1 == v2 then
                table.remove(iTab1,i1)
                table.remove(iTab2,i2)
                if #iTab1 == 0 and #iTab2 == 0 then
                    return true
                else
                    return self:bothTabContIsSame(iTab1,iTab2)
                end
            end
        end
    end
    return false
end
--上轮盘转动结束
function WheelOfRhinoWheelView:upWheelOver()
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_wheelShowReward.mp3")
    for i,zhizhenNode in ipairs(self.m_zhizhenNodeTab) do
        if zhizhenNode.isOpen == true then
            self.m_upRewardFrameTab[i]:setVisible(true)
            if i > 1 then
                self:findChild("andi"..i):setVisible(false)
            end
        end
    end
    self:runCsbAction("actionframe1",false,function ()
        for i,upRewardFrame in ipairs(self.m_upRewardFrameTab) do
            upRewardFrame:setVisible(false)
            if i > 1 then
                self:findChild("andi"..i):setVisible(true)
            end
        end
    end)
    performWithDelay(self,function ()
        self:startSettlement()
    end,2)
end
--获取奖励类型
function WheelOfRhinoWheelView:getType(data)
    local typeString = data[1]
    if tonumber(typeString) then
        return 1
    end
    if string.find(typeString,"WHEEL") then
        return 3
    end
    if string.find(typeString,"FREE") then
        return 4
    end
    if string.find(typeString,"UP") then
        return 5
    end
    return 2
end
--开始本轮结算
function WheelOfRhinoWheelView:startSettlement()
    --获取奖励数据
    self.m_settlementData = clone(self.m_spinDataResult.selfData.wheelResult)
    if self.m_settlementData and #self.m_settlementData > 1 then
        --对数据进行排序
        table.sort( self.m_settlementData, function (data1,data2)
            local rewardType1 = self:getType(data1)
            local rewardType2 = self:getType(data2)
            return rewardType1 < rewardType2
        end )

        --将所有直接奖励钱得奖励合成一个奖励
        local i = 1
        while true do
            if i > #self.m_settlementData then
                break
            end
            if self:getType(self.m_settlementData[i]) > 1 then
                break
            end
            if i > 1 then
                self.m_settlementData[1][2] = ""..(tonumber(self.m_settlementData[1][2]) + tonumber(self.m_settlementData[i][2]))
                self.m_settlementData[1][3] = ""..(tonumber(self.m_settlementData[1][3]) + tonumber(self.m_settlementData[i][3]))
                table.remove(self.m_settlementData,i)
            else
                i = i + 1
            end
        end
    end
    
    self:showView()
end
--弹出结算框
function WheelOfRhinoWheelView:showView()
    if self.m_settlementData == nil or #self.m_settlementData == 0 then
        --结算完
        self:allSettlementOver()
        return
    end
    
    local rewardType = self:getType(self.m_settlementData[1])
    if rewardType == 1 then--直接奖励钱
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_WheelShowSettlementLayer.mp3")
        self.m_showView = util_createAnimation("WheelOfRhino_text_1.csb")
        self.m_showView:findChild("normalNode"):setVisible(false)
        self.m_showView:findChild("jackpotNode"):setVisible(false)
        self.m_showView:findChild("jackpotWheelNode"):setVisible(false)
        self.m_showView:findChild("normalNode"):setVisible(true)
        self.m_showView:findChild("jiahao"):setVisible(false)
        for i = 1,3 do
            self.m_showView:findChild(self:getJackpotTypeName()..i):setVisible(true)
            -- self.m_showView:findChild("jackpot"..i):setTexture("Common/WheelOfRhino_text"..self:getJackpotTypeName()..".png")
        end

        local winCoin = tonumber(self.m_settlementData[1][3])

        self.m_showView:findChild("m_lb_coins1"):setString(util_formatCoins(winCoin,50))
        local info = {label = self.m_showView:findChild("m_lb_coins1"),sx = 1.1,sy = 1.1}
        self:updateLabelSize(info,586)
        
        self.m_showView:playAction("start",false,function ()
            self:findChild("showViewClick"):setTouchEnabled(true)
            self.m_showViewDelayAni = performWithDelay(self,function ()
                self:showViewClick()
            end,4)
        end)
        -- self:addChild(self.m_showView)
        self.m_bottomWheelNode:findChild("text_TB"):addChild(self.m_showView)

        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winCoin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoin,false,true})
    elseif rewardType == 2 then--中jackpot
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_WheelShowSettlementLayer.mp3")
        self.m_showView = util_createAnimation("WheelOfRhino_text_1.csb")
        self.m_showView:findChild("normalNode"):setVisible(false)
        self.m_showView:findChild("jackpotNode"):setVisible(false)
        self.m_showView:findChild("jackpotWheelNode"):setVisible(false)
        self.m_showView:findChild("jackpotNode"):setVisible(true)
        self.m_showView:findChild("jiahao"):setVisible(false)
        for i = 1,3 do
            -- self.m_showView:findChild("jackpot"..i):setTexture("Common/WheelOfRhino_text"..self:getJackpotTypeName()..".png")
            self.m_showView:findChild(self:getJackpotTypeName()..i):setVisible(true)
        end

        local winCoin = tonumber(self.m_settlementData[1][3])
        self.m_showView:findChild("m_lb_coins2"):setString(util_formatCoins(winCoin,50))
        local info = {label = self.m_showView:findChild("m_lb_coins2"),sx = 1.1,sy = 1.1}
        self:updateLabelSize(info,586)

        self.m_showView:playAction("start",false,function ()
            self:findChild("showViewClick"):setTouchEnabled(true)
            self.m_showViewDelayAni = performWithDelay(self,function ()
                self:showViewClick()
            end,4)
        end)
        self:addChild(self.m_showView)

        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winCoin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoin,false,true})
    elseif rewardType == 3 then--中jackpot加倍
        if self.m_showView == nil then
            gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_WheelShowSettlementLayer.mp3")
            self.m_showView = util_createAnimation("WheelOfRhino_text_1.csb")
            self.m_showView:findChild("normalNode"):setVisible(false)
            self.m_showView:findChild("jackpotNode"):setVisible(false)
            self.m_showView:findChild("jackpotWheelNode"):setVisible(true)
            self.m_showView:findChild("jiahao"):setVisible(false)
            for i = 1,3 do
                -- self.m_showView:findChild("jackpot"..i):setTexture("Common/WheelOfRhino_text"..self:getJackpotTypeName()..".png")
                self.m_showView:findChild(self:getJackpotTypeName()..i):setVisible(true)
            end
            self.m_bottomWheelNode:findChild("text_TB"):addChild(self.m_showView)
            self.m_showView:playAction("start",false,function ()
                self:startBottom()
            end)
        else
            self.m_showView.isMixView = true
            self.m_showView:findChild("jiahao"):setVisible(true)
            self.m_showView:findChild("jackpotWheelNode"):setVisible(true)
            self.m_showView:playAction("actionframe_13",false,function ()
                self:startBottom()
            end)
        end

        local winCoin = tonumber(self.m_settlementData[1][3] + tonumber(self.m_spinDataResult.bonus.extra.triggerWin))/tonumber(self.m_settlementData[1][2])
        self.m_showView:findChild("m_lb_coins3"):setString(util_formatCoins(winCoin,50))
        local info = {label = self.m_showView:findChild("m_lb_coins3"),sx = 1.1,sy = 1.1}
        self:updateLabelSize(info,586)
    end
end
--一个奖励结束，进行下一个奖励
function WheelOfRhinoWheelView:toNextView()
    table.remove(self.m_settlementData,1)
    self:showView()
end
--开始下轮盘流程
function WheelOfRhinoWheelView:startBottom()
    self.m_showView:playAction("actionframe_13_1",false)

    local worldPos = self:convertToWorldSpace(cc.p(0,-300))
    local pos = self.m_bottomWheelNode:findChild("Node_2"):getParent():convertToNodeSpace(worldPos)
    local time = util_csbGetAnimTimes(self.m_bottomWheelNode.m_csbAct,"start")
    local moveto = cc.MoveTo:create(time,pos)
    local action = cc.EaseQuadraticActionInOut:create(moveto)
    self.m_bottomWheelNode:findChild("Node_2"):runAction(action)
    self.m_bottomWheelNode:playAction("start",false,function ()
        self:bottomWheelStart()
    end)
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_BottomWheelUp.mp3")
end
--下轮盘开始转动
function WheelOfRhinoWheelView:bottomWheelStart()
    self.m_bottomWheelNode:playAction("open")
    local endidx = self:getBottomWheelResultIdx()
    self.m_bottomWheel:recvData(endidx)
    self.m_bottomWheel:beginWheel()
end
--计算下轮盘结果的id
function WheelOfRhinoWheelView:getBottomWheelResultIdx()
    local wheelType = {10,3,2,8,3,5,10,3,2,8,3,5,10,3,2,8,3,5}
    local mul = tonumber(self.m_settlementData[1][2])

    local idxTab = {}
    for i,v in ipairs(wheelType) do
        if v == mul then
            table.insert(idxTab,i)
        end
    end

    return idxTab[math.random(1,#idxTab)]
end
-- 下轮盘转动结束
function WheelOfRhinoWheelView:bottomWheelOver()

    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_wheelShowReward.mp3")
    self.m_bottomWheelNode:playAction("actionframe")
    self.m_bottomRewardFrame:setVisible(true)

    -- 下轮盘上显示数字
    local shuziLabel = util_createAnimation("WheelOfRhino_Wheel2_shuzi.csb")
    self.m_bottomWheelNode:findChild("WheelOfRhino_Wheel2_shuzi"):addChild(shuziLabel)
    shuziLabel:findChild("x"..self.m_settlementData[1][2]):setVisible(true)
    shuziLabel:playAction("idle",true)

    -- 弹框上显示数字
    local shuziLabel1 = util_createAnimation("WheelOfRhino_Wheel2_shuzi.csb")
    self.m_showView:findChild("WheelOfRhino_Wheel2_shuzi"):addChild(shuziLabel1)
    shuziLabel1:findChild("x"..self.m_settlementData[1][2]):setVisible(true)
    shuziLabel1:playAction("idle",true)

    -- self.m_showView:findChild("BitmapFontLabel_3"):setString("X"..self.m_settlementData[1][2])
    local winCoin = tonumber(self.m_settlementData[1][3] + self.m_spinDataResult.bonus.extra.triggerWin)
    self.m_showView:findChild("m_lb_coins3"):setString(util_formatCoins(winCoin,50))
    local info = {label = self.m_showView:findChild("m_lb_coins3"),sx = 1.1,sy = 1.1}
    self:updateLabelSize(info,586)

    self.m_showView:playAction("actionframe_3",false,function ()
        performWithDelay(self,function ()
            shuziLabel:removeFromParent()
            self.m_bottomRewardFrame:setVisible(false)
            local time = util_csbGetAnimTimes(self.m_bottomWheelNode.m_csbAct,"over")
            local moveto = cc.MoveTo:create(time,cc.p(0,-500))
            local action = cc.EaseQuadraticActionInOut:create(moveto)
            self.m_bottomWheelNode:findChild("Node_2"):runAction(action)
            gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_bottomWheelDown.mp3")
            if self.m_showView.isMixView == true then
                self.m_bottomWheelNode:playAction("over",false,function ()
                    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showViewOver.mp3")
                end)
                self.m_showView:playAction("actionframe_13_2",false,function ()
                    self.m_showView:findChild("jiahao"):setVisible(false)
                    self.m_showView:playAction("over_13",false,function ()
                        self.m_showView:removeFromParent()
                        self:toNextView()
                    end)
                end)
            else
                self.m_bottomWheelNode:playAction("over",false,function ()
                    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showViewOver.mp3")
                    self.m_showView:playAction("over_1_2_3",false,function ()
                        self.m_showView:removeFromParent()
                        self:toNextView()
                    end)
                end)
            end
            
        end,2)
    end)

    globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + tonumber(self.m_settlementData[1][3])
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0,false,true})
end

--这一轮转动、结算什么的都结束后调用
function WheelOfRhinoWheelView:allSettlementOver()
    if self.m_spinDataResult.bonus.status == "OPEN" then
        gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_upgrand.mp3")
        self:runCsbAction("actionframe",false,function ()
            self:updateUpWheelState(true)
            performWithDelay(self,function ()
                for i,upRewardFrame in ipairs(self.m_upRewardFrameTab) do
                    upRewardFrame:setVisible(false)
                end
                self:runCsbAction("idleframe1",true)
                self:findChild("clickNode"):setTouchEnabled(true)
            end,62/30)
        end)
        performWithDelay(self,function ()
            self:addUpWheelItems()
        end,16/30)
    else
        -- self:closeView()
        gLobalNoticManager:postNotification("CodeGameScreenWheelOfRhinoMachine_bonusOver")
    end
end

--关闭界面
function WheelOfRhinoWheelView:closeView()
    -- self:runCsbAction("actionframe2",false,function ()
        self:removeFromParent()
    -- end)
end
return WheelOfRhinoWheelView