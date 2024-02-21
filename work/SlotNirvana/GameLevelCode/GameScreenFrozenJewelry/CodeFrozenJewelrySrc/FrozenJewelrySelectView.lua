---
--smy
--2018年4月26日
--FrozenJewelrySelectView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local FrozenJewelrySelectView = class("FrozenJewelrySelectView",BaseGame )

local BTN_TAG_FREESPIN              =       1           --freespin按钮
local BTN_TAG_FREESPIN_SUPER        =       2           --超级freespin按钮
local BTN_TAG_MYSTERY               =       3           --mystery按钮

function FrozenJewelrySelectView:initUI(params)
    self:createCsbNode("FrozenJewelry/Choose.csb")

    for index = 1,3 do
        local panel = self:findChild("Panel_"..index)
        panel:setTag(index)
        self:addClick(panel)

        local light = util_createAnimation("FrozenJewelry_choose_g.csb")
        light:runCsbAction("idle",true)
        self:findChild("lighe"..index):addChild(light)
        util_setCascadeOpacityEnabledRescursion(self:findChild("lighe"..index),true)
    end
    self.m_callBack = params.callBack
    self.m_startFunc = params.startFunc
    self.m_machine = params.machine
    self.m_isWaiting = false

    local fsCount = self.m_machine.m_runSpinResultData.p_freeSpinsLeftCount
    local superFsCount = self.m_machine.m_runSpinResultData.p_selfMakeData.superleftcount or math.floor(fsCount / 4) 
    local minCoin = self.m_machine.m_runSpinResultData.p_selfMakeData.mysterymin
    local maxCoin = self.m_machine.m_runSpinResultData.p_selfMakeData.mysterymax

    self:findChild("m_lb_num_free"):setString(fsCount)
    self:findChild("m_lb_num_superfree"):setString(superFsCount)
    self:findChild("m_lb_coins_least"):setString(util_formatCoins(minCoin,30))
    self:findChild("m_lb_coins_most"):setString(util_formatCoins(maxCoin,30))
    self:updateLabelSize({label=self:findChild("m_lb_coins_least"),sx=0.8,sy=0.8},220)
    self:updateLabelSize({label=self:findChild("m_lb_coins_most"),sx=1,sy=1},220)

    self:findChild("Particle_3"):setVisible(false)
    self:findChild("ef_xuelizi"):setVisible(false)
    self:findChild("ef_xuelizi2"):setVisible(false)

    self.m_isWaiting = true
    self:runCsbAction("start",false,function()
        self.m_isWaiting = false
        self:runCsbAction("idle",true)
    end)

    self.m_machine:delayCallBack(128 / 60,function()
        self:findChild("Particle_3"):setVisible(true)
        self:findChild("ef_xuelizi"):setVisible(true)
        self:findChild("ef_xuelizi2"):setVisible(true)

        self:findChild("Particle_3"):resetSystem()
        self:findChild("ef_xuelizi"):resetSystem()
        self:findChild("ef_xuelizi2"):resetSystem()
    end)
end

function FrozenJewelrySelectView:onEnter()
    BaseGame.onEnter(self)
end

function FrozenJewelrySelectView:onExit()
    BaseGame.onExit(self)
end

--[[
    按钮回调
]]
function FrozenJewelrySelectView:clickFunc(sender)
    if self.m_isWaiting then
        return
    end

    --防止连续点击
    self.m_isWaiting = true
    
    local btn_tag = sender:getTag()
    local func = function()
        self.m_curChoose = btn_tag
        self:sendData(btn_tag)
    end

    func()
    if btn_tag == BTN_TAG_FREESPIN then
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_click_free.mp3")
    elseif btn_tag == BTN_TAG_FREESPIN_SUPER then
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_click_super_free.mp3")
    else
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_click_mystery.mp3")
    end

    
    
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function FrozenJewelrySelectView:initViewData(callBackFun, gameSecen)
    self:initData()
    
end


function FrozenJewelrySelectView:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function FrozenJewelrySelectView:initData()
    self:initItem()
end

function FrozenJewelrySelectView:initItem()
    
end

--数据发送
function FrozenJewelrySelectView:sendData(choose)
    self.m_action=self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT , data = choose}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

    self.m_curChoose = choose
end


function FrozenJewelrySelectView:uploadCoins(featureData)
    
end

--数据接收
function FrozenJewelrySelectView:recvBaseData(featureData)
    self.m_action=self.ACTION_RECV

    if type(self.m_startFunc) == "function" then
        self.m_startFunc(self.m_curChoose)
    end
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_change_scene_select_over.mp3")
    self:runCsbAction("actionframe"..self.m_curChoose,false,function()
        if self.m_curChoose == BTN_TAG_MYSTERY then
            if type(self.m_callBack) == "function" then
                self.m_callBack(self.m_curChoose,featureData)
            end
        end
        
        self:removeFromParent()
    end)
    --fg弹版要提前出现
    if self.m_curChoose < BTN_TAG_MYSTERY then
        self.m_machine:delayCallBack(112 / 60,function()
            if type(self.m_callBack) == "function" then
                self.m_callBack(self.m_curChoose,featureData)
            end
        end)
    end

    local light = util_createAnimation("FrozenJewelry_choose_dianji.csb")
    self:findChild("ef_dianji"..self.m_curChoose):addChild(light)
    light:runCsbAction("actionframe",false,function()
        light:removeFromParent()
    end)
end

function FrozenJewelrySelectView:sortNetData(data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 


    localdata = data

    return localdata
end

--[[
    接受网络回调
]]

function FrozenJewelrySelectView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        
        -- local userMoneyInfo = param[3]
        -- self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        -- self.m_totleWimnCoins = spinData.result.winAmount
        -- print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        -- globalData.userRate:pushCoins(self.m_serverWinCoins)
        -- globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" or self.m_machine.m_isShowSelectView then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        
    end
end
return FrozenJewelrySelectView