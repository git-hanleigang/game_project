---
--xcyy
--2018年5月23日
--ChameleonRichesBonusGame.lua
--bonus基础玩法模板(纯净版,带网络回调)
--[[
    使用方式

    --在调用showView之前需重置界面显示
    local endFunc = function()
    
    end
    self.m_bonusGameView:resetView(self.m_initFeatureData,endFunc)
    self.m_bonusGameView:showView()

    --断线重连时,需在主类实现以下方法
    function CodeGameScreenChameleonRichesMachine:initFeatureInfo(spinData,featureData)
        --若服务器返回数据中没有status字段必须要求服务器加上,触发时可不返回
        if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
            self:addBonusEffect()
        end
    end

    --添加bonus事件
    function CodeGameScreenChameleonRichesMachine:addBonusEffect( )
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

    end
]]
local PublicConfig = require "ChameleonRichesPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local ChameleonRichesBonusGame = class("ChameleonRichesBonusGame",util_require("Levels.BaseLevelDialog"))

ChameleonRichesBonusGame.m_endFunc = nil     --结束回调
ChameleonRichesBonusGame.m_isWaiting = false --是否等待网络消息回来
ChameleonRichesBonusGame.m_featureData = nil --网络消息返回的数据
ChameleonRichesBonusGame.m_serverWinCoins = 0   --赢钱数

local BTN_TAG_SURE      =       1001        --确定
local BTN_TAG_CANCEL    =       1002        --取消

-- 构造函数
function ChameleonRichesBonusGame:ctor(params)
    ChameleonRichesBonusGame.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()
end

function ChameleonRichesBonusGame:initUI(params)
    self.m_machine = params.machine
    self.m_fsTotalCount = params.fsTotalCount
    self.m_fsLeftCount = params.fsLeftCount
    self.m_isFirst = params.isFirst
    self.m_costGems = params.costGems
    self.m_addFreeCounts = params.addFreeCounts

    --free触发时购买
    if self.m_fsTotalCount == self.m_fsLeftCount then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_show_free_start)
        if self.m_isFirst then -- 第一次触发
            self:createCsbNode("ChameleonRiches/FreeSpinStart_A_FirstTrigger.csb")
            self:findChild("m_lb_num"):setString(self.m_fsTotalCount)
        else
            self:createCsbNode("ChameleonRiches/FreeSpinStart_A.csb")
            self:findChild("Button_1"):setTag(BTN_TAG_CANCEL)
            

            self:findChild("m_lb_num1"):setString(self.m_fsTotalCount)
            self:findChild("m_lb_num2"):setString(self.m_fsTotalCount + self.m_addFreeCounts)

            self:updateLabelSize({label=self:findChild("m_lb_num1"),sx=0.7,sy=0.7},390)   
            self:updateLabelSize({label=self:findChild("m_lb_num2"),sx=0.7,sy=0.7},390)   
        end

        
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_show_buy_free_count_view_B)
        if self.m_isFirst then -- 第一次触发
            self:createCsbNode("ChameleonRiches/FreeSpinOver_B_FirstTrigger.csb")
        else
            self:createCsbNode("ChameleonRiches/FreeSpinOver_B.csb")
            self:findChild("Button_Collect"):setTag(BTN_TAG_CANCEL)
        end
        self:findChild("m_lb_num"):setString(self.m_fsTotalCount)
        local m_lb_coins=self:findChild("m_lb_coins")
        m_lb_coins:setString(params.winCoins)
        self:updateLabelSize({label=m_lb_coins,sx=1,sy=1},700)    
    end

    self:findChild("Button_Sure"):setTag(BTN_TAG_SURE)

    local m_lb_gems = self:findChild("m_lb_gems")
    local m_lb_gems_dark = self:findChild("m_lb_gems_dark")

    if m_lb_gems_dark then
        m_lb_gems_dark:setString(self.m_costGems)
        m_lb_gems_dark:setVisible(globalData.userRunData.gemNum < self.m_costGems)
    end

    if m_lb_gems then
        m_lb_gems:setString(self.m_costGems)
        m_lb_gems:setVisible(globalData.userRunData.gemNum >= self.m_costGems)
    end
end

--[[
    初始化spine动画
]]
function ChameleonRichesBonusGame:initSpineUI()
    self.m_spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
    self:findChild("Node_spine"):addChild(self.m_spine)
end

function ChameleonRichesBonusGame:onEnter()
    ChameleonRichesBonusGame.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:featureResultCallFun(params)
    end,
    ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    设置bonus数据
]]
function ChameleonRichesBonusGame:setBonusData(featureData,endFunc)
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
function ChameleonRichesBonusGame:resetView(featureData,endFunc)
    self:setBonusData(featureData,endFunc)
end

--[[
    显示界面(执行start时间线)
]]
function ChameleonRichesBonusGame:showView(func)
    self.m_isWaiting = true
    self:runCsbAction("start",false,function()
        self.m_isWaiting = false
        if type(func) == "function" then
            func()
        end
    end)

    util_spinePlay(self.m_spine,"start")
    
end

--[[
    隐藏界面(执行over时间线)
]]
function ChameleonRichesBonusGame:hideView(func)
    if self.m_fsTotalCount == self.m_fsLeftCount then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_hide_free_start)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_hide_buy_free_count_view_B)
    end
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
function ChameleonRichesBonusGame:clickFunc(sender)
    if self.m_isEnd or self.m_isWaiting then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_btn_click)
    
    local isBuy = 0
    local tag = sender:getTag()
    if tag == BTN_TAG_SURE then
        isBuy = 1
    end

    if isBuy == 1 and globalData.userRunData.gemNum < self.m_costGems and not self.m_isFirst then
        self.m_machine.m_topUI:clickFunc(self.m_machine.m_topUI.btn_layout_buy_gem)
        return
    end

    self.m_isBuy = (isBuy == 1)

    --防止连续点击
    self.m_isWaiting = true

    self:sendData(isBuy)
end

--[[
    显示点击结果
]]
function ChameleonRichesBonusGame:showClickResult()

    
    self:hideView(function()
        local freeSpin = self.m_featureData.p_data.freespin
        if type(self.m_endFunc) == "function" then
            self.m_endFunc(freeSpin,self.m_isBuy)
        end
    end)
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function ChameleonRichesBonusGame:sendData(data)
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接数据，data对应发给服务器的select字段
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = data}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


--[[
    解析返回的数据
]]
function ChameleonRichesBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        --防止其他类型消息传到这里
        if spinData.action == "FEATURE" and not self.m_isEnd then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            --bonus中需要带回status字段才会有最新钱数回来
            -- globalData.userRunData.coinNum = userMoneyInfo.resultCoins
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            -- globalData.userRunData.gemNum = userMoneyInfo.resultGems
            globalData.userRunData:setGems(userMoneyInfo.resultGems)
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
function ChameleonRichesBonusGame:recvBaseData(featureData)
    self.m_isWaiting = false
    self.m_isEnd = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_featureData.p_data.selfData
    local betData = selfData.betData
    if betData[tostring(lineBet)] then
        self.m_machine.m_betData[tostring(lineBet)] = betData[tostring(lineBet)]
    end

    --显示点击的结果
    self:showClickResult()
end

------------------------------------网络数据相关  end------------------------------------------------------------


return ChameleonRichesBonusGame