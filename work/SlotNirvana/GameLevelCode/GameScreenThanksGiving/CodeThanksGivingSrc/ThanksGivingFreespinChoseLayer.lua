local SendDataManager = require "network.SendDataManager"
local ThanksGivingFreespinChoseLayer = class("ThanksGivingFreespinChoseLayer", util_require("base.BaseGame"))
function ThanksGivingFreespinChoseLayer:initUI(machine)
    self:createCsbNode("ChooseFslayer_dark.csb")
    self.m_machine = machine
    self:initView()
    self:enableBtn(false)
    self:runCsbAction("start",false,function ()
        self:enableBtn(true)

        self.m_dialogNode:setVisible(true)
        self.m_dialogNode:playAction("start",false,function ()
            self.m_dialogNode:playAction("idle",true)
        end)
        self.m_chicken:setVisible(true)
        util_spinePlay(self.m_chicken,"Jackpot4",false)
        self.m_chicken:addAnimation(0,"idleframe8",true)
    end)
end

function ThanksGivingFreespinChoseLayer:initView()
    self.m_kapianNodeTab = {}
    for i = 1,3 do
        local kapian = util_createAnimation("ChooseFslayer_"..i..".csb")
        kapian:playAction("start",false,function ()
            kapian:playAction("idle2",true)
        end)
        self:findChild("ChooseFslayer"):addChild(kapian,-1)
        table.insert(self.m_kapianNodeTab,kapian)
        self:addClick(self:findChild("Panel_"..i))
    end

    --添加火鸡
    self.m_chicken = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
    self:findChild("dialog_Node"):addChild(self.m_chicken)
    self.m_chicken:setVisible(false)
    self.m_chicken:setPositionX(-100)
    --添加对话框
    self.m_dialogNode = util_createAnimation("ChooseFslayer_duihuakuang.csb")
    self:findChild("dialog_Node"):addChild(self.m_dialogNode)
    self.m_dialogNode:setVisible(false)
    

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function ThanksGivingFreespinChoseLayer:onEnter()
    ThanksGivingFreespinChoseLayer.super.onEnter(self)
    
end

function ThanksGivingFreespinChoseLayer:onExit()
    ThanksGivingFreespinChoseLayer.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

function ThanksGivingFreespinChoseLayer:enableBtn(isEnable)
    self:findChild("Panel_1"):setTouchEnabled(isEnable)
    self:findChild("Panel_2"):setTouchEnabled(isEnable)
    self:findChild("Panel_3"):setTouchEnabled(isEnable)
end

function ThanksGivingFreespinChoseLayer:clickFunc(sender)
    local name = sender:getName()
    
    self.m_clickedPos = 0
    if name == "Panel_1" then
        self.m_clickedPos = 1
    elseif name == "Panel_2" then
        self.m_clickedPos = 2
    elseif name == "Panel_3" then
        self.m_clickedPos = 3
    end
    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_choose.mp3")
    self:enableBtn(false)
    self:sendData()

    self.m_clickActionIsEnd = false--点击动画是否播完
    self.m_isGetData = false--消息数据是否接收到
    self:startShowClickedOver()
end
--数据发送
function ThanksGivingFreespinChoseLayer:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT,data = self.m_clickedPos - 1}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
--接收返回消息
function ThanksGivingFreespinChoseLayer:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_WheelWinCoins = spinData.result.bonus.bsWinCoins
        
        self.m_totleWimnCoins = spinData.result.winAmount

        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        self.m_spinDataResult = spinData.result
        self.m_machine:SpinResultParseResultData(spinData)
        -- self.m_data = spinData.result.selfData--服务器传过来的selfData字段
        -- self:startShowClickedOver()
        self.m_isGetData = true
        self:chooseEndToOver()
    else
        -- 处理消息请求错误情况
    end
end
--选择后播点击动画
function ThanksGivingFreespinChoseLayer:startShowClickedOver()
    for i = 1,3 do
        if i == self.m_clickedPos then
            self.m_kapianNodeTab[i]:playAction("actionframe",false,function ()
                self.m_clickActionIsEnd = true
                self:chooseEndToOver()
            end)
        else
            self.m_kapianNodeTab[i]:playAction("dark")
        end
    end
end

function ThanksGivingFreespinChoseLayer:chooseEndToOver()
    if self.m_isGetData == true and self.m_isGetData == true then
        performWithDelay(self,function ()
            self:runCsbAction("over",false,function()
                gLobalNoticManager:postNotification("CodeGameScreenThanksGivingMachine_bonusOverTriggerFreeSpin")
                self:removeFromParent()
            end)
        end,2)
    end
end
return ThanksGivingFreespinChoseLayer