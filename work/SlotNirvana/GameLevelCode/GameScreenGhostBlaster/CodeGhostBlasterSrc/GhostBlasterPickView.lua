---
--xcyy
--2018年5月23日
--GhostBlasterPickView.lua
--bonus基础玩法模板(纯净版,带网络回调)
--[[
    使用方式

    --在调用showView之前需重置界面显示
    local endFunc = function()
    
    end
    self.m_bonusGameView:resetView(self.m_initFeatureData,endFunc)
    self.m_bonusGameView:showView()

    --断线重连时,需在主类实现以下方法
    function CodeGameScreenlevelsTempleMachine:initFeatureInfo(spinData,featureData)
        --若服务器返回数据中没有status字段必须要求服务器加上,触发时可不返回
        if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
            self:addBonusEffect()
        end
    end

    --添加bonus事件
    function CodeGameScreenlevelsTempleMachine:addBonusEffect( )
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

    end
]]
local PublicConfig = require "GhostBlasterPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local GhostBlasterPickView = class("GhostBlasterPickView",util_require("Levels.BaseLevelDialog"))

GhostBlasterPickView.m_endFunc = nil     --结束回调
GhostBlasterPickView.m_isWaiting = false --是否等待网络消息回来
GhostBlasterPickView.m_featureData = nil --网络消息返回的数据
GhostBlasterPickView.m_serverWinCoins = 0   --赢钱数

-- 构造函数
function GhostBlasterPickView:ctor(params)
    GhostBlasterPickView.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()
end

function GhostBlasterPickView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("GhostBlaster/PickView.csb")

    -- self:findChild("root"):setScale(self.m_machine.m_machineRootScale)

    self.m_title = util_spineCreate("GhostBlaster_wenben",true,true)
    self:findChild("root"):addChild(self.m_title)

    self.m_items = {}
    for index = 1,3 do
        local item = util_createView("CodeGhostBlasterSrc.GhostBlasterPickItem",{parentView = self,index = index})
        self:findChild("Node_"..index):addChild(item)
        self.m_items[#self.m_items + 1] = item
        item:setVisible(false)

    end
    
end

function GhostBlasterPickView:onEnter()
    GhostBlasterPickView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:featureResultCallFun(params)
    end,
    ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    设置bonus数据
]]
function GhostBlasterPickView:setBonusData(featureData,endFunc)
    --解析数据(触发时传进来的数据为空)
    if featureData then
        self.m_featureData:parseFeatureData(featureData.result)
    end
    
    self.m_endFunc = endFunc
    --当前是否结束
    self.m_isEnd = false
end

--[[
    重置界面显示
]]
function GhostBlasterPickView:resetView(featureData,endFunc)
    self:setBonusData(featureData,endFunc)
end

--[[
    显示界面(执行start时间线)
]]
function GhostBlasterPickView:showView(func)
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.Music_Pick_Choose_Start)
    local titlePos = util_convertToNodeSpace(self.m_machine.m_pickTip,self:findChild("root"))
    self.m_title:setPosition(titlePos)

    util_spinePlay(self.m_title,"switch")
    util_spineEndCallFunc(self.m_title,"switch",function()
        self:runCsbAction("start",false,function()
            self:runIdleAni()
            if type(func) == "function" then
                func()
            end
        end)
        
        local delayTime = 0
        for index = 1,#self.m_items do
            local item = self.m_items[index]
            performWithDelay(self,function()
                item:setVisible(true)
                item:showAni()
            end,delayTime)
            delayTime  = delayTime + 4 / 30
        end
    end)
    
end

--[[
    idle
]]
function GhostBlasterPickView:runIdleAni()
    self:runCsbAction("idle",true)
end

--[[
    隐藏界面(执行over时间线)
]]
function GhostBlasterPickView:hideView(func)
    gLobalSoundManager:playSound(PublicConfig.Music_Pick_Choose_Over)
    self:runCsbAction("over",false,function()
        
        if type(func) == "function" then
            func()
        end
        self:removeFromParent()
    end)
    
end

--[[
    默认点击回调
]]
function GhostBlasterPickView:clickFunc(clickItem)
    if self.m_isEnd or self.m_isWaiting then
        return
    end

    --防止连续点击
    self.m_isWaiting = true

    self.m_clickItem = clickItem
    local clickIndex = clickItem.m_index
    self:sendData(clickIndex - 1)
end

--[[
    显示点击结果
]]
function GhostBlasterPickView:showClickResult()
    local selfData = self.m_featureData.p_data.selfData
    --获取点击位置
    local clickIndex
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        if item.m_isClicked then
            clickIndex = index
            break
        end
    end
    if selfData then
        local pickAll = clone(selfData.pickall)
        -- for index = 1,#pickAll do
        --     if pickAll[index] == selfData.pick then
        --         table.remove(pickAll,index)
        --         break
        --     end
        -- end

        local tempIndex = 1
        
        local pick_freetimes = selfData.pick_freetimes or 8
        gLobalSoundManager:playSound(PublicConfig.Music_Pick_Choose_Reward)
        for index = 1,#self.m_items do
            local item = self.m_items[index]
            if item.m_index ~= clickIndex then
                item:showRewardAni(pickAll[tempIndex],clickIndex,pick_freetimes)
            else
                item:showRewardAni(selfData.pick,clickIndex,pick_freetimes)
            end

            tempIndex  = tempIndex + 1
            
        end
    end

    self.m_machine:delayCallBack(1.5,function()

        local endNode = self.m_machine.m_bottomUI.coinWinNode
        self.m_machine.m_upReel:addTotalWin(self.m_serverWinCoins)
        local totalWin = self.m_machine.m_upReel:getTotalWin()

        if selfData.pick == "free" then
            self:hideView(function()
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc(true)
                end
            end)
        else
            self.m_machine.m_iOnceSpinLastWin  = self.m_machine.m_iOnceSpinLastWin + self.m_serverWinCoins
            self.m_items[clickIndex]:runFlyAni()
            self.m_machine:flyPickCoinsToTotalWin(self.m_serverWinCoins,self.m_items[clickIndex],endNode,function()
                
                
            end)

            self:hideView(function()
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                end
            end)
        end

        
    end)
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function GhostBlasterPickView:sendData(data)
    
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接数据，data对应发给服务器的select字段
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = data}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


--[[
    解析返回的数据
]]
function GhostBlasterPickView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        --防止其他类型消息传到这里
        if spinData.action == "FEATURE" and not self.m_isEnd then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            --bonus中需要带回status字段才会有最新钱数回来
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end

--[[
    网络消息返回
]]
function GhostBlasterPickView:recvBaseData(featureData)
    self.m_isWaiting = false
    self.m_isEnd = true

    local selfData = self.m_featureData.p_data.selfData
    if selfData and selfData.pick == "free" then
        local freespin = self.m_featureData.p_data.freespin
        self.m_machine.m_runSpinResultData.p_freeSpinsLeftCount = freespin.freeSpinsLeftCount
        self.m_machine.m_runSpinResultData.p_freeSpinsTotalCount = freespin.freeSpinsTotalCount
        self.m_machine.m_runSpinResultData.p_fsExtraData = freespin.extra

    end
    

    --显示点击的结果
    self:showClickResult()
end

------------------------------------网络数据相关  end------------------------------------------------------------


return GhostBlasterPickView