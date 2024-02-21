---
--xcyy
--2018年5月23日
--AfricaRiseBonusMap.lua

local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local AfricaRiseBonusMap = class("AfricaRiseBonusMap", BaseGame)

function AfricaRiseBonusMap:initUI()
    self:createCsbNode("AfricaRise/GameScreenAfricaRise_Map.csb")
    self.m_touchFlag = false
    self.m_bIsShow = false
    if display.height / display.width == 1024 / 768 then
        local node = self:findChild("root")
        node:setScale(0.8)
    end
    self:InitMapData()
end

function AfricaRiseBonusMap:setMachine(machine)
    self.m_machine = machine
end

-- function AfricaRiseBonusMap:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function AfricaRiseBonusMap:InitMapData()
    self.m_Levels = {}
    for i = 1, 25 do
        local level = nil
        if i == 3 then
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseAnimalIcon", 1)
        elseif i == 7 then
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseAnimalIcon", 2)
        elseif i == 12 then
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseAnimalIcon", 3)
        elseif i == 18 then
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseAnimalIcon", 4)
        elseif i == 25 then
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseAnimalIcon", 5)
        else
            level = util_createView("CodeAfricaRiseSrc.AfricaRiseDiamond")
        end
        level:runLock()
        self:findChild("dian_" .. i):addChild(level)
        table.insert(self.m_Levels, level)
    end
end

function AfricaRiseBonusMap:showAdd()
    self:runCsbAction("actionframe")
end

function AfricaRiseBonusMap:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--显示打开到第几个了
function AfricaRiseBonusMap:showBoxView(_data)
    local _num = 0
    local type = 0
    if _data then
        _num = _data.position
        type = _data.type
        if self.m_OpenFlag == true and _num ~= nil then
            _num = _num + 1
        elseif self.m_OpenFlag == false and _num ~= nil then
            -- _num = _num
        elseif _num == nil then
            _num = 0
        end
    end

    for i = 1, 25 do
        local level = self.m_Levels[i]
        if i <= _num then
            level:runIdle()
        else
            level:runLock()
        end
    end

    self:runCsbAction(
        "show",
        false,
        function()
            if self.m_OpenFlag == false then
                local num = _num + 1
                local level = self.m_Levels[num]
                local delayTime = self:getDelayTime(num)
                level:runOpen(
                    function()
                        performWithDelay(
                            self,
                            function()
                                if type == 0 then
                                    self:sendData()
                                elseif type == 1 then
                                    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_hide_map.mp3")
                                    self.m_machine:showBonusReel(false)
                                    self:runCsbAction(
                                        "over",
                                        false,
                                        function()
                                            self.m_machine.m_map = nil
                                            self:removeFromParent()
                                        end
                                    )
                                    for i = 1, 25 do
                                        local level = self.m_Levels[i]
                                        level:runOver()
                                    end
                                end
                            end,
                            delayTime
                        )
                    end
                )
            else
                self.m_touchFlag = true
            end
        end
    )
end

--动物和钻石 打开的时候延时处理
function AfricaRiseBonusMap:getDelayTime(_num)
    local delayTime = 1
    if _num == 3 or _num == 7 or _num == 12 or _num == 18 or _num == 25 then
        delayTime = 2
    else
        delayTime = 0.5
    end
    return delayTime
end

--默认按钮监听回调
function AfricaRiseBonusMap:clickFunc(sender)
    if self.m_touchFlag == false then
        return
    end
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_click.mp3")
    self.m_touchFlag = false
    self:closeMapView()
end

function AfricaRiseBonusMap:closeMapView()
    if self.m_machine.m_map then
        for i = 1, 25 do
            local level = self.m_Levels[i]
            level:runOver()
        end
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_hide_map.mp3")
        self:runCsbAction(
            "over",
            false,
            function()
                self.m_func()
                self.m_machine.m_map = nil
                self:removeFromParent()
            end
        )
    end
end

function AfricaRiseBonusMap:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

function AfricaRiseBonusMap:setOpenBonusFlag(_flag)
    self.m_OpenFlag = _flag
    if self.m_OpenFlag == false then
        self.m_csbOwner["Button_1"]:setVisible(false)
        self.m_csbOwner["Button_1"]:setTouchEnabled(_enabled)
    end
end

--数据发送
function AfricaRiseBonusMap:sendData()
    self.m_action = self.ACTION_SEND
    self.m_isBonusCollect = true
    local httpSendMgr = SendDataManager:getInstance()

    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function AfricaRiseBonusMap:featureResultCallFun(param)
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
            -- self.m_featureData = self.m_featureData
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function AfricaRiseBonusMap:getMapIsShow()
    return self.m_bIsShow
end

function AfricaRiseBonusMap:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    self.m_featureData = featureData
    if featureData.p_status == "CLOSED" then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_bsWinCoins, GameEffect.EFFECT_BONUS})
    else
        local winCoins = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusWinCoins
        self:showCollectView(winCoins)
        self.m_touchFlag = false
    end
end

function AfricaRiseBonusMap:showCollectView(_winCoins)
    self.m_machine:showSmallBonusCollect(_winCoins, self)
end

function AfricaRiseBonusMap:hideMapView()
    self:closeMapView()
end

return AfricaRiseBonusMap
