---
--xcyy
--2018年5月23日
--CoinManiaFsGameChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local CoinManiaFsGameChooseView = class("CoinManiaFsGameChooseView",BaseGame )

CoinManiaFsGameChooseView.m_machine = nil
CoinManiaFsGameChooseView.m_bonusEndCall = nil

CoinManiaFsGameChooseView.m_MaxChestNum = 9

local PigTimesType = 1
local FsTimesType = 2
local NullType = 3
local endPigType = 4
local endFsType = 5

function CoinManiaFsGameChooseView:getGameType( index )
    
    for i=1,#self.m_ClickData do
        local value = self.m_ClickData[index] 
        if value == -1 then
            return NullType,value
        elseif value == 0 then
            return PigTimesType,self.m_PigTimes
        elseif value > 0 then
            return FsTimesType,value
        end
    end

end

function CoinManiaFsGameChooseView:initUI(machine)

    self.m_machine = machine

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("CoinMania/GameScreenCoinMania_fs.csb")


    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_ClickData = selfdata.rewards or {}
    self.m_PigTimes = selfdata.pigs or 0
    self.m_getFsNums = selfdata.totalFreespinTimes or 0
    self.m_getPigNums = selfdata.totalPigs or 0

    self:initChest( )
    
    self.m_title = util_createAnimation("CoinMania_FS_title.csb")
    self:findChild("Node_8"):addChild(self.m_title)
    self.m_title:findChild("m_lb_num"):setString(self.m_getFsNums)
    self.m_title:findChild("m_lb_num_0"):setString(self.m_getPigNums)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    self.m_bulingPos = 1000

   
    
    
end

function CoinManiaFsGameChooseView:getCsbFromType( gameType )
    

    local name = {"CoinMania_FS_baozhu_cllect_2",
        "CoinMania_FS_baozhu_freegames",
        "CoinMania_FS_baozhu"
        ,"CoinMania_FS_baozhu_cllect",
        "CoinMania_FS_baozhu_freegames_2"}

    return name[gameType] .. ".csb"
end

function CoinManiaFsGameChooseView:initChest( )
    
    for i=1,self.m_MaxChestNum do

        local data = {}
        data.machine = self
        data.index = i - 1
        self["Chest"..i] = util_createView("CodeCoinManiaSrc.CoinManiaBaoZhuView",data) 
        self:findChild("baozhu_"..i - 1):addChild(self["Chest"..i])
        self["Chest"..i]:findChild("click"):setVisible(false)
        local gameType, times = self:getGameType( i )

        if (gameType == PigTimesType) or (gameType == FsTimesType) then
            self["Chest"..i].normal = util_createAnimation(self:getCsbFromType( gameType ))
            self["Chest"..i]:findChild("normalNode"):addChild(self["Chest"..i].normal)
            self["Chest"..i].normal:findChild("m_lb_num"):setString(times)
            self["Chest"..i].normal:findChild("m_lb_num_0"):setString(times)

            
            self["Chest"..i]:runCsbAction("idleframe1",true)
            self["Chest"..i].normal:runCsbAction("Bright")

            util_setCascadeOpacityEnabledRescursion(self["Chest"..i]:findChild("root"),true)
            
        elseif gameType == NullType then
            self["Chest"..i]:findChild("click"):setVisible(true)
            -- self["Chest"..i]:runCsbAction("tishi",false)
        end

    end
end

function CoinManiaFsGameChooseView:runChestTiShiAct( )
    for i=1,self.m_MaxChestNum do


        local gameType, times = self:getGameType( i )
        if gameType == NullType then
            self["Chest"..i]:runCsbAction("tishi",false)
        end

    end
end

function CoinManiaFsGameChooseView:getNextBulingNode( )

    local actList = {}
    local currNode = nil

    for i=1,self.m_MaxChestNum do
       
        if self:getGameType( i ) == NullType then
            table.insert(actList,i)
        end
      
    end

    if #actList  > 0 and #actList == self.m_MaxChestNum then
        local index = math.random(1,#actList) 
        if actList[index] ==  self.m_bulingPos then
            table.remove(actList,index)

            if #actList  > 0 then
                local index_1 = math.random(1,#actList) 
                self.m_bulingPos = actList[index_1]
                currNode = self["Chest"..actList[index_1]]
            end
        else
            self.m_bulingPos = actList[index]
            currNode = self["Chest"..actList[index]]
        end
    end
    

    return currNode
end

function CoinManiaFsGameChooseView:beginBulingAct( )
    
    self.m_actNode:stopAllActions()
    self.m_bulingPos = 1000

    util_schedule(self.m_actNode, function(  )
        local actNode = self:getNextBulingNode( )        
        if actNode then
            actNode:runCsbAction("daixuanze")
        end

    end,1)

end

function CoinManiaFsGameChooseView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function CoinManiaFsGameChooseView:setClickData( pos )
    
    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Click_Baozhu.mp3")

    self:sendData(pos)
end

function CoinManiaFsGameChooseView:onEnter()
    BaseGame.onEnter(self)
end
function CoinManiaFsGameChooseView:onExit()
    scheduler.unschedulesByTargetName("CoinManiaFsGameChooseView")
    BaseGame.onExit(self)

end

--数据发送
function CoinManiaFsGameChooseView:sendData(pos)



    
    self.m_action=self.ACTION_SEND
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else
        
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT , clickPos= pos }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end


--数据接收
function CoinManiaFsGameChooseView:recvBaseData(featureData)


    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_ClickData = selfdata.rewards or {}
    self.m_PigTimes = selfdata.pigs or 0
    self.m_getFsNums = selfdata.totalFreespinTimes or 0
    self.m_getPigNums = selfdata.totalPigs or 0

    local clientPositions = selfdata.clientPositions or {}
    local clickPos = clientPositions[#clientPositions] or 0

    local index = clickPos + 1
    local actNode = self["Chest".. index]

    self:findChild("baozhu_"..index - 1):stopAllActions()

    local gameType, times = self:getGameType( index )
    if self:checkIsOver( ) then
        if gameType == PigTimesType then
            gameType = endPigType
        elseif gameType == FsTimesType then
            gameType = endFsType
        end

    end

    actNode.normal = util_createAnimation(self:getCsbFromType( gameType ))
    actNode:findChild("normalNode"):addChild(actNode.normal)
    actNode.normal:findChild("m_lb_num"):setString(times)
    actNode.normal:findChild("m_lb_num_0"):setString(times)


    -- if self:checkIsOver( ) then
    --     actNode:findChild("CoinMania_baozhu_0"):setVisible(false)
    -- end
  
    actNode:runCsbAction("actionframe",false,function(  )
        
        if gameType == PigTimesType or gameType == endPigType then
            self.m_title:runCsbAction("actionframe1")
        elseif gameType == FsTimesType or gameType == endFsType then
            self.m_title:runCsbAction("actionframe2")
        end
        

        self.m_title:findChild("m_lb_num"):setString(self.m_getFsNums)
        self.m_title:findChild("m_lb_num_0"):setString(self.m_getPigNums)

        if self:checkIsOver( ) then
            performWithDelay(self,function(  )
                self:showOtheChest( )
            end,0.5)
            
        else
            self.m_action=self.ACTION_RECV
        end
        

    end)
    
    
    


end

function CoinManiaFsGameChooseView:showOtheChest( )
    local index = 0
    for i=1,self.m_MaxChestNum do
        local netPos = i - 1
        self:findChild("baozhu_"..i - 1):stopAllActions()

        if self["Chest"..i].normal == nil then
            index = index + 1
            local gameType, times = self:getGameType( i )

            if (gameType == PigTimesType) or (gameType == FsTimesType) then

                local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
                local overPositions = selfdata.overPositions or {}
                local isOverPos = false

                for i=1,#overPositions do
                    if netPos == overPositions[i] then
                        isOverPos = true
                        break
                    end
                end
                if isOverPos then
                    if gameType == PigTimesType then
                        gameType = endPigType
                    elseif gameType == FsTimesType then
                        gameType = endFsType
                    end
                end
                


                self["Chest"..i].Dark = util_createAnimation(self:getCsbFromType( gameType ))
                self["Chest"..i]:findChild("darkNode"):addChild(self["Chest"..i].Dark)
                self["Chest"..i].Dark:findChild("m_lb_num"):setString(times)
                self["Chest"..i].Dark:findChild("m_lb_num_0"):setString(times)
                self["Chest"..i].Dark:runCsbAction("Dark")
                
            end
            util_setCascadeOpacityEnabledRescursion(self["Chest"..i]:findChild("root"),true)

            local index_1 = index
            self["Chest"..i]:runCsbAction("actionframe1",false,function(  )
                if index_1 == 1 then
                    
                    self.m_machine:clearCurMusicBg()
                    gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Fs_Choose_Over.mp3")

                    self.m_title:runCsbAction("actionframe",true)
                    
                    performWithDelay(self,function(  )
                        -- 在这个函数销毁此类
                        if self.m_bonusEndCall then
                            self.m_bonusEndCall()
                        end
                    end,3)
                    
                end
            end)
            
        end
        

    end

end

function CoinManiaFsGameChooseView:checkIsOver( )
    local bonusStatus = self.m_machine.m_runSpinResultData.p_bonusStatus 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function CoinManiaFsGameChooseView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end

function CoinManiaFsGameChooseView:showOtherChest( )
    
    

end


--开始结束流程
function CoinManiaFsGameChooseView:gameOver(isContinue)

end

--弹出结算奖励
function CoinManiaFsGameChooseView:showReward()

   
end

function CoinManiaFsGameChooseView:setEndCall( func)
    self.m_bonusEndCall = function(  )
            
        if func then
            func()
        end 
                

    end 
end



function CoinManiaFsGameChooseView:featureResultCallFun(param)

    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            dump(spinData.result, "featureResultCallFun data", 3)
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
    
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
    
            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result
    
                self.m_machine:SpinResultParseResultData( spinData)
                self:recvBaseData(self.m_featureData)
    
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action"..spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
    
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
    
        end
    end
    
end

 

function CoinManiaFsGameChooseView:runFlyWildActJumpTo(startNode,endNode,csbName,func,times,scale)


    local flytime = times or 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self.m_machine:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
        local sq_1 = cc.Sequence:create(actList_1)
        flyNode:runAction(sq_1)
     end)
    actList[#actList + 1] = cc.JumpTo:create(flytime,cc.p(endPos),-80,1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end
 
    end)
    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end



return CoinManiaFsGameChooseView