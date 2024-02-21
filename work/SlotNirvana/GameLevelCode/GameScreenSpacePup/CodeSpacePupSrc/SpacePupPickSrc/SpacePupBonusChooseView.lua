---
--xcyy
--2018年5月23日
--SpacePupBonusChooseView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "SpacePupPublicConfig"
local SpacePupBonusChooseView = class("SpacePupBonusChooseView",BaseGame)

SpacePupBonusChooseView.m_totalCount = 3
SpacePupBonusChooseView.m_clickPos = 1
SpacePupBonusChooseView.m_isClick = false

function SpacePupBonusChooseView:initUI(machine)

    self:createCsbNode("SpacePup/PickChoose.csb")

    self.m_machine = machine

    -- self:runCsbAction("actionframe") -- 播放时间线

    self.m_tblClickPanel = {}
    self.m_tblChooseAni = {}
    self.m_tblLeftTimesText = {}
    for i=1, self.m_totalCount do
        self.m_tblChooseAni[i] = util_createAnimation("SpacePup_pickchoose.csb")
        self.m_tblClickPanel[i] = self.m_tblChooseAni[i]:findChild("click_Panel")
        self:findChild("Node_choose"..i):addChild(self.m_tblChooseAni[i])
        self.m_tblLeftTimesText[i] = self.m_tblChooseAni[i]:findChild("m_lb_num")
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_particleLoop = self:findChild("Particle")

    self.particleTbl = {}
    for i=1, 6 do
        self.particleTbl[i] = self:findChild("Particle_"..i)
    end

    util_setCascadeOpacityEnabledRescursion(self, true)

    for i=1, self.m_totalCount do
        self.m_tblClickPanel[i]:setTag(i)
        self:addClick(self.m_tblClickPanel[i])
    end
end


function SpacePupBonusChooseView:onEnter()
    SpacePupBonusChooseView.super.onEnter(self)
end

function SpacePupBonusChooseView:onExit()
    SpacePupBonusChooseView.super.onExit(self)
end

function SpacePupBonusChooseView:refreshView()
    for i=1, self.m_totalCount do
        self.m_tblLeftTimesText[i]:setVisible(false)
        self.m_tblChooseAni[i]:runCsbAction("idleframe", true)
    end

    self.m_particleLoop:setPositionType(0)
    self.m_particleLoop:setDuration(-1)
    self.m_particleLoop:resetSystem()
    performWithDelay(self.m_scWaitNode, function()
        for i=1, 6 do
            self.particleTbl[i]:resetSystem()
        end
    end, 10/60)
end

function SpacePupBonusChooseView:refreshData(endCallFunc)
    self.endCallFunc = endCallFunc

    self.m_isClick = true
end

--默认按钮监听回调
function SpacePupBonusChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" and self:isCanTouch() then
        self:choosePlayIndex(tag)
    end
end

function SpacePupBonusChooseView:choosePlayIndex(_index)
    self.m_isClick = false
    self.m_clickPos = _index
    self:sendData(_index)
end

--数据发送(选择次数)
function SpacePupBonusChooseView:sendData(pos)
    local httpSendMgr = SendDataManager:getInstance()
    local strPos = tostring(pos)
    local sendData = {"PICK_TIMES", strPos}
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= sendData , mermaidVersion = 0 } 
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--数据接收
--选择次数返回的数据
function SpacePupBonusChooseView:recvBaseData(featureData)
    gLobalSoundManager:playSound(PublicConfig.Music_PickSelect_FeedBack)
    local bonusdata = featureData.p_bonus or {}
    if bonusdata.extra and bonusdata.extra.pickPhase == "PICK_REWARD" then
        local selectTimes = bonusdata.extra.pickLeftTimes or 0
        local otherTimesTbl = bonusdata.extra.timesOther or {0, 0}
        for i=1, self.m_totalCount do
            local otherTimes = otherTimesTbl[1] or 0
            if i == self.m_clickPos then
                self.m_tblLeftTimesText[self.m_clickPos]:setVisible(true)
                self.m_tblLeftTimesText[self.m_clickPos]:setString(selectTimes)
            else
                table.remove(otherTimesTbl, 1)
                self.m_tblLeftTimesText[i]:setVisible(true)
                self.m_tblLeftTimesText[i]:setString(otherTimes)
            end
        end
        
        for i=1, 3 do
            if i == self.m_clickPos then
                self.m_tblChooseAni[i]:runCsbAction("actionframe", false, function()
                    self.m_tblChooseAni[i]:runCsbAction("idleframe", true)
                    self:hideSelf(bonusdata.extra)
                end)
            else
                self.m_tblChooseAni[i]:runCsbAction("yaan", false, function()
                    self.m_tblChooseAni[i]:runCsbAction("idleframe_yaan", true)
                end)
            end
        end
    end
end

--[[
    接受网络回调
]]

function SpacePupBonusChooseView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_runSpinResultData = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function SpacePupBonusChooseView:isCanTouch()
    return self.m_isClick
end

function SpacePupBonusChooseView:hideSelf(_extra)
    local extraData = _extra
    self.m_particleLoop:stopSystem()
    gLobalSoundManager:playSound(PublicConfig.Music_Pick_StartOver)
    self:runCsbAction("over",false, function()
        self.m_machine:showBonusPickGame(self.endCallFunc, extraData)
        self:setVisible(false)
    end)
end

return SpacePupBonusChooseView
