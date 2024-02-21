---
--xcyy
--2018年5月23日
--ColorfulCircusChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ColorfulCircusChooseView = class("ColorfulCircusChooseView", BaseGame)

ColorfulCircusChooseView.m_ClickIndex = 1
ColorfulCircusChooseView.m_spinDataResult = {}

function ColorfulCircusChooseView:initUI(machine)

    self:createCsbNode("ColorfulCircus/FreeSpinchoose.csb")

    -- self.People = util_spineCreate("FreeSpinChose",true,true)
    -- self:findChild("Node_spine"):addChild(self.People)

    self.m_machine = machine

    self.m_Click = false

    self.m_isStart_Over_Action = true

    self.m_freeView = util_createAnimation("ColorfulCircus_choosefeature_free.csb")
    self:findChild("Node_free"):addChild(self.m_freeView)
    self.m_respinView = util_createAnimation("ColorfulCircus_choosefeature_respin.csb")
    self:findChild("Node_respin"):addChild(self.m_respinView)

    local light = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    self.m_freeView:findChild("guang"):addChild(light)
    light:playAction("animation0", true)
    light = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    self.m_respinView:findChild("guang"):addChild(light)
    light:playAction("animation0", true)

    local lock = util_createAnimation("ColorfulCircus_tanban_shanshuo2.csb")
    self.m_freeView:findChild("shanshuo"):addChild(lock)
    lock:playAction("animation0", true)
    lock = util_createAnimation("ColorfulCircus_tanban_shanshuo2.csb")
    self.m_respinView:findChild("shanshuo"):addChild(lock)
    lock:playAction("animation0", true)

    --彩带
    self.m_ribbon_free = util_spineCreate("ColorfulCircus_free_caidai",true,true)
    self.m_freeView:findChild("dianji"):addChild(self.m_ribbon_free)
    self.m_ribbon_free:setVisible(false)
    self.m_ribbon_free:setPositionY(70)
    self.m_ribbon_respin = util_spineCreate("ColorfulCircus_free_caidai",true,true)
    self.m_respinView:findChild("dianji"):addChild(self.m_ribbon_respin)
    self.m_ribbon_respin:setVisible(false)
    self.m_ribbon_respin:setPositionY(70)
    self.m_ribbon = util_spineCreate("ColorfulCircus_free_caidai",true,true)
    self:findChild("caidai"):addChild(self.m_ribbon)
    self.m_ribbon:setVisible(false)
    self.m_ribbon:setPositionY(140)

    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_free"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_respin"), true)
    self.m_freeView:runCsbAction("idle", true)
    self.m_respinView:runCsbAction("idle", true)

    self.m_freeView:findChild("m_lb_num"):setString("12")

    


    self.m_ribbon:setVisible(true)
    util_spinePlay(self.m_ribbon,"actionframe",false)
    util_spineEndCallFunc(self.m_ribbon, "actionframe", function()
        self.m_ribbon:setVisible(false)
    end)

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)

        self:addClick(self:findChild("Panel_Free")) -- free
        self:addClick(self:findChild("Panel_Respin")) -- respin

        self.m_isStart_Over_Action = false
    end)
    self.m_freeView:runCsbAction("start", false, function()
        self.m_freeView:runCsbAction("idle", true)
    end)
    self.m_respinView:runCsbAction("start", false, function()
        self.m_respinView:runCsbAction("idle", true)
    end)

    -- util_spinePlay(self.People,"start",false)
    -- util_spineEndCallFunc(self.People,"start",function (  )
        -- util_spinePlay(self.People,"idleframe",true)
        
    -- end)
end


function ColorfulCircusChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function ColorfulCircusChooseView:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    if self.m_Click then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function ColorfulCircusChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    self.m_Click = true
    -- local randomNum = math.random(1,2)
    -- if randomNum == 1 then
    --     gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose1.mp3")
    -- else
    --     gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose2.mp3")
    -- end
    if name == "Panel_Free" then
        -- free
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose_feature_free.mp3")
        self.m_ClickIndex = 2
        self:sendData(1)
  
        self.m_freeView:runCsbAction("actionframe", false, function()
            -- self.m_freeView:runCsbAction("idle", true)
        end)
        self.m_respinView:runCsbAction("yaan", false, function()
            -- self.m_respinView:runCsbAction("idleframe_yaan", true)
        end)

        
        self.m_ribbon_free:setVisible(true)
        util_spinePlay(self.m_ribbon_free,"actionframe2",false)
        util_spineEndCallFunc(self.m_ribbon_free, "actionframe2", function()
            self.m_ribbon_free:setVisible(false)
        end)
    elseif name == "Panel_Respin" then
         -- respin
         gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
         gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose_feature_respin.mp3")
        self.m_ClickIndex = 1
        self:sendData(0)
    

        self.m_respinView:runCsbAction("actionframe", false, function()
            -- self.m_respinView:runCsbAction("idle", true)
        end)
        self.m_freeView:runCsbAction("yaan", false, function()
            -- self.m_freeView:runCsbAction("idleframe_yaan", true)
        end)

        self.m_ribbon_respin:setVisible(true)
        util_spinePlay(self.m_ribbon_respin,"actionframe2",false)
        util_spineEndCallFunc(self.m_ribbon_respin, "actionframe2", function()
            self.m_ribbon_respin:setVisible(false)
        end)

    end
end

--数据接收
function ColorfulCircusChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true
    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_chooseOver.mp3")
    -- if self.m_ClickIndex == 2 then
    --     util_spinePlay(self.People,"actionframe2",false)
    -- elseif self.m_ClickIndex == 1 then
    --     util_spinePlay(self.People,"actionframe1",false)
    -- end
    performWithDelay(
        self,
        function()
            self:showReward()
        end,
        50/30
    )
end

--数据发送
function ColorfulCircusChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function ColorfulCircusChooseView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function ColorfulCircusChooseView:showReward()

    gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_choose_feature_over.mp3")
    self:runCsbAction("over", false, function()
        if self.m_bonusEndCall then
            self.m_bonusEndCall(self.m_ClickIndex)
        end
    end)

    if self.m_ClickIndex == 1 then --respin
        self.m_respinView:runCsbAction("over", false, function()
        end)
        self.m_freeView:runCsbAction("over_yaan", false, function()
        end)
    else
        self.m_respinView:runCsbAction("over_yaan", false, function()
        end)
        self.m_freeView:runCsbAction("over", false, function()
        end)
    end
    
end

function ColorfulCircusChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function ColorfulCircusChooseView:closeUi(func)
    if func then
        func()
    end
end

return ColorfulCircusChooseView
