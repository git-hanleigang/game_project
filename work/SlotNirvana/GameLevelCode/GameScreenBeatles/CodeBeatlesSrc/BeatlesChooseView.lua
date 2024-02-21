
--BeatlesChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local BeatlesChooseView = class("BeatlesChooseView",BaseGame )
local BeatlesBaseData = require "CodeBeatlesSrc.BeatlesBaseData"


BeatlesChooseView.m_spinDataResult = {}

function BeatlesChooseView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
end


function BeatlesChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function BeatlesChooseView:initUI(machine)
    self.m_machine = machine
    -- self:createCsbNode("Beatles/Choose.csb")
    self.chooseViewSpine = util_spineCreate("Beatles_choose", true, true)
    self:addChild(self.chooseViewSpine)
    self.chooseViewSpine:setPosition(display.width * 0.5, display.height * 0.5)

    self.m_chooseLayout = util_createAnimation("Beatles/Choose.csb")
    self:addChild(self.m_chooseLayout, 1000)

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    self.m_ClickIndex = 1

    self.m_Click = false

    self.m_isStart_Over_Action = true

    self.m_number_tab = {}
    self.m_models_tab = {}
    self.m_light_tab = {}
    local freeTimes = selfdata.freetimes or {}
    for i=1,5 do
        local temp_i = i
        local free_num = freeTimes[i] or 10
        local num_bar = util_createAnimation("Beatles_Choose_bao.csb")
        util_spinePushBindNode(self.chooseViewSpine,"zhuzi"..i,num_bar)
        
        self.m_number_tab[i] = num_bar
        num_bar:findChild("m_lb_num"):setString(free_num)
        self.m_models_tab[i] = util_spineCreate("BeatleBeat_juese_"..i, true, true)
        util_spinePushBindNode(self.chooseViewSpine,"juese"..i,self.m_models_tab[i])
        self:playerRoleIdle(self.m_models_tab[i])
    end

    self:addClick(self.m_chooseLayout:findChild("Button_mode1"))
    self:addClick(self.m_chooseLayout:findChild("Button_mode2"))
    self:addClick(self.m_chooseLayout:findChild("Button_mode3"))
    self:addClick(self.m_chooseLayout:findChild("Button_mode4"))
    self:addClick(self.m_chooseLayout:findChild("Button_mode5"))

    self.m_isStart_Over_Action = false

    util_spinePlay(self.chooseViewSpine, "start", false)
    util_spineEndCallFunc(self.chooseViewSpine, "start", function()
        util_spinePlay(self.chooseViewSpine, "idleframe", true)

    end)

end

function BeatlesChooseView:checkAllBtnClickStates( )
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
function BeatlesChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()


    if self:checkAllBtnClickStates( ) then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_chooseView_Click.mp3")

    self.m_Click = true

    if name ==  "Button_mode1" then
        self.m_ClickIndex = 1
    elseif name ==  "Button_mode2" then 
        self.m_ClickIndex = 2 
    elseif name ==  "Button_mode3" then 
        self.m_ClickIndex = 3 
    elseif name ==  "Button_mode4" then 
        self.m_ClickIndex = 4 
    elseif name ==  "Button_mode5" then 
        self.m_ClickIndex = 5 
    end

    self:showRoleTip(self.m_models_tab[self.m_ClickIndex])
    self.m_number_tab[self.m_ClickIndex]:playAction("actionframe7")
    self:sendData(self.m_ClickIndex-1)
    self:waitWithDelay(0.01, function()
        gLobalSoundManager:playSound("BeatlesSounds/sound_Beatles_chooseView_change.mp3")
    end)

    local temp_num = util_random(1, 10)
    local sound_type = temp_num > 5 and 2 or 1
    local sound_tip = string.format("BeatlesSounds/sound_Beatles_choose_models%d_%d.mp3", self.m_ClickIndex, sound_type)
    gLobalSoundManager:playSound(sound_tip)
end



--数据接收
function BeatlesChooseView:recvBaseData(featureData)
    if self.m_bonusEndCall then
        local chooseIndexList = {0, 0, 0, 0, 0}
        for i,v in ipairs(chooseIndexList) do
            if i == self.m_ClickIndex then
                chooseIndexList[i] = 1
            end
        end 
        BeatlesBaseData:getInstance():setDataByKey("choose_index", chooseIndexList)
        self:waitWithDelay(0.1, function()
            
            util_spinePlay(self.chooseViewSpine, "over"..self.m_ClickIndex, false)
            util_spineEndCallFunc(self.chooseViewSpine, "over"..self.m_ClickIndex, function()
                util_spinePlay(self.chooseViewSpine, "guochang"..self.m_ClickIndex, false)

                -- local newRole = util_spineCreate("BeatleBeat_juese_"..self.m_ClickIndex, true, true)
                -- util_spinePushBindNode(self.chooseViewSpine,"juese"..(self.m_ClickIndex+1),newRole)

                util_spineFrameCallFunc(self.chooseViewSpine, "guochang"..self.m_ClickIndex, "switch1", function()
                    self.m_bonusEndCall()
                end)
                
            end)
        end)
    end
end

--数据发送
function BeatlesChooseView:sendData(pos)
    self.m_action=self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

function BeatlesChooseView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            -- dump(spinData.result, "featureResultCallFun data", 8)
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            if spinData.action == "FEATURE" then
                self.m_spinDataResult = spinData.result

                self.m_machine.m_runSpinResultData:parseResultData(spinData.result,self.m_machine.m_lineDataPool)

                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action"..spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
            gLobalViewManager:showReConnect(true)
        end
    end
end

--角色常态spineAni
function BeatlesChooseView:playerRoleIdle(role)
    role:stopAllActions()
    util_spinePlay(role, "idleframe7", true)
end

function BeatlesChooseView:showRoleTip(role)
    role:stopAllActions()
    local ani_str = "actionframe7"
    util_spinePlay(role, ani_str, false)
    util_spineEndCallFunc(
        role,
        ani_str,
        function()
            util_spinePlay(role, "actionframe7", true)
        end
    )
end


function BeatlesChooseView:setEndCall( func)
    self.m_bonusEndCall = func
end

function BeatlesChooseView:waitWithDelay(time, endFunc)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return BeatlesChooseView