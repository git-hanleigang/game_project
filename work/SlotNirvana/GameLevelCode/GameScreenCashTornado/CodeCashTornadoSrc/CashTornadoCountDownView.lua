---
--xcyy
--2018年5月23日
--CashTornadoCountDownView.lua
local PublicConfig = require "CashTornadoPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashTornadoCountDownView = class("CashTornadoCountDownView",util_require("Levels.BaseLevelDialog"))
CashTornadoCountDownView.m_featureData = nil --网络消息返回的数据

function CashTornadoCountDownView:onExit()
    CashTornadoCountDownView.super.onExit(self)      -- 必须调用不予许删除
    if self.m_timeCutDown then
        self:stopAction(self.m_timeCutDown)
        self.m_timeCutDown = nil
    end
end

function CashTornadoCountDownView:onEnter()
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- if self.m_machine.isSpecialBase then
                self:featureResultCallFun(params)
            -- end
            
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function CashTornadoCountDownView:ctor(params)
    CashTornadoCountDownView.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()
end

function CashTornadoCountDownView:initUI(params)

    self:createCsbNode("CashTornado_daojishi.csb")
    self.m_machine = params.machine
    
    self.updateNode = cc.Node:create()
    self:addChild(self.updateNode)
    self.updateNode1 = cc.Node:create()
    self:addChild(self.updateNode1)

    self:findChild("zi_1"):setVisible(false)
    self:findChild("zi_0"):setVisible(true)

    --当前本地时间戳
    self.m_timeStamp = 0
    self.m_discountLeftTime = 0 --剩余时间

    --当前本地时间戳
    self.m_timeStamp1 = 0
    self.m_discountLeftTime1 = 0 --剩余时间

    self.curTime = 0
end

--收到数据后赋值时间戳
function CashTornadoCountDownView:setTime(time1,time2,time3,time4)
    self.startTime = time1
    self.middleTime = time2
    self.endTime = time3
    self.nowTime = time4
end

function CashTornadoCountDownView:showIdleAct()
    self:runCsbAction("idle",true)
end

-- 刷新倒计时
function CashTornadoCountDownView:upDataDiscountTime(leftTime)
    -- if self.m_machine.isShowFree then
    --     return
    -- end
    self.updateNode:stopAllActions()
    self.updateNode1:stopAllActions()

    if leftTime <= 0 then
        -- self.m_machine.isOverSpecialBase = true
        --倒计时结束时通知服务器
        -- self:sendData(2)
        return
    end
    self.m_timeStamp = os.time()
    self.m_discountLeftTime = leftTime
    self:showTimeDown(leftTime)

    util_schedule(self.updateNode,function()
        local curTimeStamp = os.time()
        local tempTime = curTimeStamp - self.m_timeStamp
        local leftTime2 = self.m_discountLeftTime - tempTime
        if leftTime2 <= 0 then
            leftTime2 = 0
            self:showTimeDown(leftTime2)
            if self.m_machine.isShowFree then
                self.updateNode:stopAllActions()
                self.m_machine.isOverSpecialBase = true
            elseif self.m_machine.isPickGame then
                self.updateNode:stopAllActions()
                self.m_machine.isOverSpecialBase = true
            else
                self.updateNode:stopAllActions()
                self.m_machine.isOverSpecialBase = true
                --倒计时结束时通知服务器

                self:sendData(2)
            end
            
            
        else
            self:showTimeDown(leftTime2)
        end
    end,1)
end

-- 刷新倒计时
function CashTornadoCountDownView:upDataDiscountTime1(leftTime)
    -- if self.m_machine.isShowFree then
    --     return
    -- end
    self.updateNode:stopAllActions()
    self.updateNode1:stopAllActions()

    if leftTime <= 0 then
        -- self:sendData(1)
        return
    end
    self.m_timeStamp1 = os.time()
    self.m_discountLeftTime1 = leftTime
    -- self:showTimeDown(leftTime)

    util_schedule(self.updateNode1,function()
        local curTimeStamp = os.time()
        local tempTime = curTimeStamp - self.m_timeStamp1
        local leftTime2 = self.m_discountLeftTime1 - tempTime
        print("leftTime2 == "..leftTime2)
        if leftTime2 <= 0 then
            leftTime2 = 0
            if self.m_machine.isShowFree then
                self.updateNode1:stopAllActions()
            elseif self.m_machine.isPickGame then
                self.updateNode1:stopAllActions()
            else
                self.updateNode1:stopAllActions()
                self:sendData(1)
            end
            
        else
            -- self:showTimeDown(leftTime2)
        end
    end,1)
end

--[[
    显示倒计时 时间
]]
function CashTornadoCountDownView:showTimeDown(_leftTime)
    -- local str = util_count_down_str1(_leftTime)
    local str = math.floor(_leftTime)
    self:findChild("m_lb_num"):setString(str.."S")
    self:findChild("m_lb_num_0"):setString(str.."S")
    
    if _leftTime <= 61 then
        if self.curTime ~= 0 then
            if self.curTime > 61 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_daojishi)
            end
        end
        self.curTime = _leftTime
        self:findChild("m_lb_num_0"):setVisible(true)
        self:findChild("m_lb_num"):setVisible(false)
        if _leftTime <= 0 then
            self:runCsbAction("idle",true)
        else
            self:runCsbAction("actionframe",true)
        end
    else
        self.curTime = _leftTime
        self:findChild("m_lb_num_0"):setVisible(false)
        self:findChild("m_lb_num"):setVisible(true)
        self:runCsbAction("idle",true)
    end
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function CashTornadoCountDownView:sendData(selectIndex)
    if self.m_machine.isShowFree then
        return
    end
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = selectIndex, clickPos = nil}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    解析返回的数据
]]
function CashTornadoCountDownView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        --防止其他类型消息传到这里
        if spinData.action == "SPECIAL" then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            --bonus中需要带回status字段才会有最新钱数回来
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self.m_featureData:parseFeatureData(spinData.result)
            if self.m_machine.isSpecialBase then       
                self:recvBaseData(self.m_featureData)
            else
                self:recvBaseData1(self.m_featureData)
            end
            
        end
    end
end

--[[
    网络消息返回
]]
function CashTornadoCountDownView:recvBaseData(featureData)
    local p_data = featureData.p_data or {}
    local selfData = p_data.selfData or {}
    local start_time = selfData.start_time or nil         --一阶段开始时间戳
    local middle_time = selfData.middle_time or nil      --一阶段结束时间戳/二阶段开始时间戳
    local end_time = selfData.end_time or nil            --二阶段结束时间戳
    local time_now = selfData.time_now or nil           --服务器当前时间戳
    local base_status = selfData.base_status or 1       --当前base状态
    local extra = {start_time = start_time,middle_time = middle_time,end_time = end_time,time_now = time_now,base_status = base_status}
    if base_status == 1 then
        self.m_machine:updateSpecialBaseData(extra)
        self.m_machine:updataSpecialBaseTime2()
        self.m_machine:checkAddSpecialEffect()          --退出限时base
    else
        self.m_machine.isOverSpecialBase = false        --刷新时间
        self.m_machine:updateSpecialBaseData(extra)
        self.m_machine:updataSpecialBaseTime()
        self.m_machine:updateSpecialTimeForInfo()
    end
end

--[[
    网络消息返回
]]
function CashTornadoCountDownView:recvBaseData1(featureData)
    local p_data = featureData.p_data or {}
    local selfData = p_data.selfData or {}
    local start_time = selfData.start_time or nil         --一阶段开始时间戳
    local middle_time = selfData.middle_time or nil      --一阶段结束时间戳/二阶段开始时间戳
    local end_time = selfData.end_time or nil            --二阶段结束时间戳
    local time_now = selfData.time_now or nil           --服务器当前时间戳
    local base_status = selfData.base_status or 1       --当前base状态
    local extra = {start_time = start_time,middle_time = middle_time,end_time = end_time,time_now = time_now,base_status = base_status}
    if base_status == 2 then
        self.m_machine:updateSpecialBaseData(extra)     --进入限时base
        self.m_machine:updateSpecialTimeForInfo()
        self.m_machine:checkAddSpecialEffect1()
    else
        self.m_machine:updateSpecialBaseData(extra)     --刷新时间
        self.m_machine:updataSpecialBaseTime2()
    end
end


return CashTornadoCountDownView