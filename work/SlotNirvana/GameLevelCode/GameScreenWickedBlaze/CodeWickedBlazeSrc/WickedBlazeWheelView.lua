local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WickedBlazeWheelView = class("WickedBlazeWheelView",BaseGame)

function WickedBlazeWheelView:initUI(machine)
    self:createCsbNode("WickedBlaze_wheel.csb")
    self.m_machine = machine
    self.m_wheel = require("CodeWickedBlazeSrc.WickedBlazeWheelAction"):create(self:findChild("wheelNode"),18,function()
        -- 滚动结束调用
        self:wheelOver()
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
    end)
    self:addChild(self.m_wheel)

    self:addClick(self:findChild("clickNode"))
    self:findChild("clickNode"):setTouchEnabled(false)
    self:runCsbAction("idlestart",false,function ()
        self:runCsbAction("idle1",true)
        self:findChild("clickNode"):setTouchEnabled(true)
    end)
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wheelUp.mp3")
end

function WickedBlazeWheelView:onEnter()
    WickedBlazeWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:closeView()
    end,"WickedBlazeWheelView_closeView")
end
--接收返回消息
function WickedBlazeWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_WheelWinCoins = spinData.result.bonus.bsWinCoins
        
        self.m_totleWimnCoins = spinData.result.winAmount

        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        self.m_spinDataResult = spinData.result
        self.m_machine:SpinResultParseResultData( spinData)
        self.m_data = spinData.result.selfData--服务器传过来的selfData字段
        self:wheelStart()
    else
        -- 处理消息请求错误情况
    end
end
function WickedBlazeWheelView:onExit()
    WickedBlazeWheelView.super.onExit(self)
end
--点击回调
function WickedBlazeWheelView:clickFunc(sender)
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wheelClick.mp3")
    self:findChild("clickNode"):setTouchEnabled(false)
    self:sendData()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle2",true)
    end)
end
--数据发送
function WickedBlazeWheelView:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
--开始转动
function WickedBlazeWheelView:wheelStart()
    local endidx = self:getWheelResultIdx()
    self.m_wheel:recvData(endidx)
    self.m_wheel:beginWheel()
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wheelRun.mp3")
end
--计算轮盘结果的id
function WickedBlazeWheelView:getWheelResultIdx()
    local wheelType = {"Grand",12,15,"Mini",10,25,"Minor",8,20,"Major",12,15,"Mini",10,25,"Minor",8,20}
    -- local wheelType = {"Grand",20,8,"Minor",25,10,"Mini",15,12,"Major",20,8,"Minor",25,10,"Mini",15,12}
    local idxTab = {}
    if self.m_data.turnType == 1 then--freespin次数
        -- self.m_data.turnValue--赢的freespin次数
        for i,v in ipairs(wheelType) do
            if type(v) == "number" then
                if v == self.m_data.turnValue then
                    table.insert(idxTab,i)
                end
            end
        end
    elseif self.m_data.turnType == 2 then--jackpot
        -- self.m_data.turn--jackpot类型
        -- self.m_data.turnCoins--赢的钱数
        for i,v in ipairs(wheelType) do
            if type(v) == "string" then
                if v == self.m_data.turn then
                    table.insert(idxTab,i)
                end
            end
        end
    end
    return idxTab[math.random(1,#idxTab)]
end
--转动结束
function WickedBlazeWheelView:wheelOver()
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wheelWin.mp3")
    self:runCsbAction("over1",false,function ()
        self:runCsbAction("actionframe",true)
    end)
    
    performWithDelay(self,function ()
        if self.m_data.turnType == 1 then--freespin次数
            gLobalNoticManager:postNotification("CodeGameScreenWickedBlazeMachine_wheelOverTriggerFreeSpin")
        elseif self.m_data.turnType == 2 then--jackpot
            gLobalNoticManager:postNotification("CodeGameScreenWickedBlazeMachine_showJackpotLayer")
        end
    end,2.5)
end

--关闭界面
function WickedBlazeWheelView:closeView()
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wheelDown.mp3")
    self:runCsbAction("over2",false,function ()
        self:removeFromParent()
    end)
end

return WickedBlazeWheelView