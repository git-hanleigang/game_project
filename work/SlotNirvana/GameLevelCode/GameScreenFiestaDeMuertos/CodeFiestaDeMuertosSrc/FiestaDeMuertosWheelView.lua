---
--smy
--2018年4月18日
--FiestaDeMuertosWheelView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local FiestaDeMuertosWheelView = class("FiestaDeMuertosWheelView", BaseGame)

FiestaDeMuertosWheelView.m_randWheelIndex = nil
FiestaDeMuertosWheelView.m_wheelSumIndex = 22 -- 轮盘有多少块
FiestaDeMuertosWheelView.m_wheelData = {} -- 大轮盘信息
FiestaDeMuertosWheelView.m_wheelNode = {} -- 大轮盘Node
FiestaDeMuertosWheelView.m_bIsTouch = nil
--转盘顺序

local wheelData = {
    "Minor",
    35,
    60,
    25,
    "Grand",
    35,
    55,
    20,
    "Major",
    25,
    20,
    "2X",
    30,
    20,
    45,
    "3X",
    35,
    20,
    25,
    "5X",
    15,
    50
}

function FiestaDeMuertosWheelView:initUI(data)
    self:createCsbNode("FiestaDeMuertos_wheel.csb")

    self:changeBtnEnabled(false)
    self.m_bIsTouchEnabled = false

    self.m_wheel =
        require("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelAction"):create(
        self:findChild("wheel"),
        self.m_wheelSumIndex,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel) -- 设置轮盘信息
    self.m_randWheelIndex = data.select -- 设置轮盘滚动位置

    self:getWheelSymbol()
    self:InitWheel()
    -- 点击layer
    -- self:setTouchLayer()
end

function FiestaDeMuertosWheelView:InitWheel()
    self.m_wheelLabList = {}
    for i = 1, #wheelData do
        local data = wheelData[i]
        local lab = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelLab", data)
        self:findChild("FiestaDeMuertos_node" .. i):addChild(lab)
        lab:setLab(data, i)
        table.insert(self.m_wheelLabList, lab)
    end
end

function FiestaDeMuertosWheelView:initMachine(machine)
    self.m_machine = machine
end

function FiestaDeMuertosWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function FiestaDeMuertosWheelView:clickFunc()
    if not self.m_bIsTouchEnabled then
        return
    end
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_click_wheel.mp3")
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_bIsTouchEnabled = false
    self:runCsbAction("actionframe", false)
    self:removeWheelFinger()
    self:sendData()
end

-- 转盘转动结束调用
function FiestaDeMuertosWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        callBackFun()
    end
end

-- function FiestaDeMuertosWheelView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function FiestaDeMuertosWheelView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function FiestaDeMuertosWheelView:changeBtnEnabled(isCanTouch)
    -- self.m_csbOwner("FiestaDeMuertos_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function FiestaDeMuertosWheelView:beginWheelAction()
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500
    --匀速
    wheelData.m_runTime = 3 --匀速时间
    wheelData.m_slowA = 120 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0.5 --回弹前停顿时间
    wheelData.m_stopNum = 1 --停止圈数
    wheelData.m_randomDistance = 10
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置

    self.m_wheel:recvData(self.m_randWheelIndex)
end

-- 返回上轮轮盘的停止位置
function FiestaDeMuertosWheelView:getLastEndIndex()
    return self.m_randWheelIndex
end

-- 设置轮盘实时滚动调用
function FiestaDeMuertosWheelView:setWheelRotModel()
    self.m_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function FiestaDeMuertosWheelView:createWheelFinger()
    if not self.m_Finger then
        self.m_Finger = util_spineCreate("FiestaDeMuertos_wheel_shouzhi", true, true)
        self:findChild("Node_Finger"):addChild(self.m_Finger)
        util_spinePlay(self.m_Finger, "idleframe", true)
    end
end

function FiestaDeMuertosWheelView:removeWheelFinger()
    if self.m_Finger then
        self.m_Finger:removeFromParent()
        self.m_Finger = nil
    end
end

function FiestaDeMuertosWheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_wheel.mp3")
    end
end

-- 设置轮盘网络消息
function FiestaDeMuertosWheelView:setWheelData(data)
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function FiestaDeMuertosWheelView:getWheelSymbol()
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点" .. i)
    end
end

--数据发送
function FiestaDeMuertosWheelView:sendData()
    self.m_action = self.ACTION_SEND
    self.m_isBonusCollect = true
    local httpSendMgr = SendDataManager:getInstance()
    local jpData = nil
    if self.m_machine then
        jpData = self.m_machine:getWheelJackpotList()
        if type(jpData) == "table" and #jpData == 0 then
            jpData = nil
        end
    end
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, jackpot = jpData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function FiestaDeMuertosWheelView:featureResultCallFun(param)
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
        end
    else
        -- 处理消息请求错误情况
    end
end

function FiestaDeMuertosWheelView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    self.m_randWheelIndex = self:getRandWheelIndex()
    self:beginWheelAction()
end

function FiestaDeMuertosWheelView:getRandWheelIndex()
    local data = self.m_machine.m_runSpinResultData.p_selfMakeData
    local index = 0
    if data and data.hits then
        index = data.hits[3].position
        for i, v in ipairs(data.hits) do
            local value = v.value
            print("中奖的index === " .. v.position .. "  = 值 =====" .. value)
        end
    end

    -- print("需要摇到的位置  === " .. (index+1))
    if index > 3 then
        index = index - 3
    else
        index = 19 + index
    end
    -- print("需要摇到的位置2222  === " .. index)
    return index
end

function FiestaDeMuertosWheelView:getWheelLabByIndex(_index)
    return self.m_wheelLabList[_index]
end

function FiestaDeMuertosWheelView:getWheelMidPosNode()
    return self:findChild("MidNode")
end

return FiestaDeMuertosWheelView
