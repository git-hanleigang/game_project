---
--xcyy
--2018年5月23日
--PandaDeluxeChooseFreespin.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PandaDeluxeChooseFreespin = class("PandaDeluxeChooseFreespin",BaseGame )
local clickPosIndexList = {4,3,2,1,0,5}

function PandaDeluxeChooseFreespin:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("PandaDeluxe/ChooseFsLayer.csb")

    gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_showFreeSpinCHooseView.mp3")

    self:runCsbAction("start") -- 播放时间线

    

    self.m_vecItems = {}
    local index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local data = {}
            data.index = index
            data.clickIndex = clickPosIndexList[index] 
            data.parent = self
            local item = util_createView("CodePandaDeluxeSrc.PandaDeluxeChooseFsItem", data)
            node:addChild(item)
            item:runIdle()
            self.m_vecItems[#self.m_vecItems + 1] = item
        else
            break
        end
        index = index + 1
    end
  

    for i=1,#self.m_vecItems do
        local item = self.m_vecItems[i]
        if self.m_machine.m_iBetLevel == 1 then
            if item.m_clickIndex <= 3 or item.m_clickIndex == 5  then
                item:unselected()
            end
        elseif  self.m_machine.m_iBetLevel == 2 then
            if item.m_clickIndex <= 2 then
                item:unselected()
            end
        elseif  self.m_machine.m_iBetLevel == 3 then
            if item.m_clickIndex <= 1 then
                item:unselected()
            end
        elseif  self.m_machine.m_iBetLevel == 4 then
            if item.m_clickIndex <= 0 then
                item:unselected()
            end
        end

    end

    
    

    util_setCascadeOpacityEnabledRescursion(self, true)
end



function PandaDeluxeChooseFreespin:unselectOther(index)
    for i = 1, #self.m_vecItems, 1 do 
        if self.m_vecItems[i].m_index ~= index then 
            self.m_vecItems[i]:unselected()
        end
    end
end


function PandaDeluxeChooseFreespin:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function PandaDeluxeChooseFreespin:setClickData( pos,index )
    self.m_index = index
    self.m_clickPos = pos
    self:unselectOther(index)
    self:sendData(pos)
 
end

function PandaDeluxeChooseFreespin:onEnter()
    BaseGame.onEnter(self)
end
function PandaDeluxeChooseFreespin:onExit()
    scheduler.unschedulesByTargetName("PandaDeluxeChooseFreespin")
    BaseGame.onExit(self)

end

--数据发送
function PandaDeluxeChooseFreespin:sendData(pos)

    self.m_action=self.ACTION_SEND
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else
        
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= pos }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end


--数据接收
function PandaDeluxeChooseFreespin:recvBaseData(featureData)


    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinTimes = selfdata.freeSpinTimes
    local freeSpinType = selfdata.freeSpinType 
    local item = self.m_vecItems[self.m_index]

    if self.m_index == 6 then
        
    
        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxeSounds_Click_radom.mp3")

        local nodeList = {"xiongmao_rell","he_rell","wugui_rell","yu_rell" , "shu_rell",}
        
        if item then

            for i=1,#nodeList do
                if  i == ( freeSpinType + 1) then
                    item:findChild(nodeList[i]):setVisible(true)
                    item:findChild("m_lb_num_"..i.."_rell"):setString(freeSpinTimes)
                else
                    item:findChild(nodeList[i]):setVisible(false) 
                    
                    
                end

            end

            item:runCsbAction("actionframe",false,function(  )
                if self.m_bonusEndCall then
                    self.m_bonusEndCall()
                end
            end)
        end
        

    else
        

        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_FreeSpinCHooseViewClick.mp3") 
       

        item:runCsbAction("actionframe1",false,function(  )

            if self.m_bonusEndCall then
                self.m_bonusEndCall()
            end
        end)

        
    end

    

    

end

function PandaDeluxeChooseFreespin:showOtheChest( )
   

end

function PandaDeluxeChooseFreespin:checkIsOver( )
    local bonusStatus = self.m_machine.m_runSpinResultData.p_bonusStatus 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function PandaDeluxeChooseFreespin:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end




--开始结束流程
function PandaDeluxeChooseFreespin:gameOver(isContinue)

end

--弹出结算奖励
function PandaDeluxeChooseFreespin:showReward()

   
end

function PandaDeluxeChooseFreespin:setEndCall( func)
    self.m_bonusEndCall = function(  )
            
        performWithDelay(self,function(  )
            gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_FreeSpinCHooseViewOver.mp3")
            self:runCsbAction("over", false, function()
                if func then
                    func()
                end
            end)
                 
        end,1.5)

        

    end 
end



function PandaDeluxeChooseFreespin:featureResultCallFun(param)

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

 

return PandaDeluxeChooseFreespin