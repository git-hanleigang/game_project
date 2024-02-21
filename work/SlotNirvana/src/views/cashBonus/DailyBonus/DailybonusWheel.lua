--[[
    转盘的操作
    轮盘的代理 脚本
]]
local DailybonusWheel = class("DailybonusWheel", util_require("base.BaseView"))

DailybonusWheel.m_nodeWheel = nil --轮盘指针
DailybonusWheel.m_bonusNode = nil --主界面指针
DailybonusWheel.m_wheelRotation = nil --轮盘角度
DailybonusWheel.m_addJpIndex = nil
DailybonusWheel.distance_pre = nil
DailybonusWheel.distance_now = nil
DailybonusWheel.m_runIndex = nil
DailybonusWheel.m_mulitip = nil

--记录jackpotlist
DailybonusWheel.m_jackpotList = nil

function DailybonusWheel:setWheelNode(bonusNode, wheel)
    self.m_nodeWheel = wheel
    self.m_bonusNode = bonusNode
    self.m_wheelRotation = 0
    self.m_addJpIndex = 0
    self.distance_pre = 0
    self.distance_now = 0
    self.m_jackpotList = {}
    self.isPayWheel = false
    --绑定节点到DailybonusWheel
    self:bindingEvent(wheel)

    --初始化数据
    self.m_wheelData = G_GetMgr(G_REF.CashBonus):getWheelData() --普通轮盘数据
    self:setValues()
    self:initRunInfo()
    local mulitipValue = self.m_mulitip * self.m_wheelData.p_vipMultiple --普通轮盘倍数
    self:initWheelData(mulitipValue)

    for k, v in pairs(G_GetMgr(G_REF.CashBonus):getPayWheelData().p_JackpotList) do
        self.m_jackpotList[k] = v
    end

    --一些节点的操作 如绑定等
    self:initUINomarlWheel()
end

function DailybonusWheel:setValues(isPayWheel)
    if isPayWheel == nil then
        isPayWheel = false
    end
    self.m_runIndex = self.m_wheelData:getResultCoinIndex()
    self.m_runReward = self.m_wheelData:getResultCoinReward()
    local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    self.m_mulitip = multipleData.p_value
    local mulitipValue
    if isPayWheel then
        mulitipValue = 1 --付费轮盘倍数
    else
        mulitipValue = self.m_mulitip * self.m_wheelData.p_vipMultiple --普通轮盘倍数
    end
end

function DailybonusWheel:getNormalPayPro()
    local payWheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if payWheelData then
        local multiple = payWheelData:getMultiple()
        return math.floor(multiple + 0.5)
    end
    return 1
end

function DailybonusWheel:getJackpotList()
    return self.m_jackpotList
end

function DailybonusWheel:getNormalPayProShow()
    local payWheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if payWheelData then
        local multiple = payWheelData:getMultiple()
        return multiple
    end
    return 1
end

--滚动参数
function DailybonusWheel:initRunInfo()
    self.m_nodeWheelControl =
        util_require("views.cashBonus.DailyBonus.DailybonusWheelControl"):create(
        self:findChild("Wheel"),
        15,
        function()
            -- 滚动结束调用
            self:wheelRotateEnd()
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
            self:setRotionWheel(distance, targetStep)
        end,
        nil,
        nil
    )
    self:addChild(self.m_nodeWheelControl)
end

--获取增倍器倍数 这里规则领完轮盘增倍器重置
function DailybonusWheel:getRewardMulitip()
    return self.m_mulitip
end

function DailybonusWheel:setRotionWheel(distance, targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusWheelRun.mp3")
    end
end

--初始化轮盘数据
function DailybonusWheel:initWheelData(mulitipValue)
    if not mulitipValue or tonumber(mulitipValue) < 1 then
        mulitipValue = 1
    end
    for i = 2, 15 do
        local node_coin1 = self:findChild("LabelCoin1_" .. i - 1)
        local node_coin2 = self:findChild("LabelCoin2_" .. i - 1)
        local baseValue = tonumber(self.m_wheelData.p_values[i] or 0)
        local number1 = baseValue
        local number2 = baseValue * mulitipValue

        node_coin1:setString(util_getFromatMoneyStr(number1))
        node_coin2:setString(util_getFromatMoneyStr(number2))
        util_scaleCoinLabGameLayerFromBgWidth(node_coin1, 190)
        util_scaleCoinLabGameLayerFromBgWidth(node_coin2, 190)
    end

    --添加jp
    if self.m_wheelData.p_JackpotList then
        for i = 1, #self.m_wheelData.p_JackpotList do
            local item = self.m_wheelData.p_JackpotList[i]
            -- if item.isNewJackpot == false then
            local newJpItem = util_createView("views.cashBonus.DailyBonus.DailybonusNewJpItem")
            self:findChild("nodeJp_" .. (item.index - 1)):addChild(newJpItem)
            newJpItem:playIdleAnimation()
            -- end
        end
    end
end

function DailybonusWheel:initUINomarlWheel()
    -- local spinBtn = self:findChild("tempCloseBtn")
    -- self:addClick(spinBtn)
    self.distance_pre = 0
    self.distance_now = 0

    --添加增倍器
    self.m_rewardX = util_createView("views.cashBonus.DailyBonus.DailybonusRewardX")
    self:findChild("NodeRward"):addChild(self.m_rewardX)

    --闪电
    self:createLightNode()
    --点击按钮layout注册
    self:addSpinBtnClick()

    --
    self:addSpinEndLight()
    self:addBtnLight()
end

function DailybonusWheel:addSpinBtnClick()
    if self.m_touchLayout then
        self.m_touchLayout:setVisible(false)
    end
    self.m_touchLayout = self:findChild("BtnSpin")
    self:addClick(self.m_touchLayout)
    self:setSpinTouchState(false)
end

function DailybonusWheel:addSpinEndLight()
    --轮盘停止特效、
    self.m_resultLight = util_createView("views.cashBonus.DailyBonus.DailybonusResultLight1")
    self:findChild("zhongjiang"):addChild(self.m_resultLight)
    self.m_resultLight:showState(false)
end

function DailybonusWheel:addBtnLight()
    --spinGuang
    self.m_spinLight = util_createAnimation("Hourbonus_new3/DailybonusBtnLight.csb")
    self.m_spinLight:playAction("idle", true)
    self:findChild("NodeSpinBtnLight"):addChild(self.m_spinLight)
end

function DailybonusWheel:addMulitipLabel()
    local labelMulitip = util_createView("views.cashBonus.DailyBonus.DailybonusMultipLabel")
    self:findChild("NodeRewardVip"):addChild(labelMulitip)
    labelMulitip:setPosition(cc.p(0, 0))
    labelMulitip:runCsbAction("idle2", false)
    return labelMulitip
end

function DailybonusWheel:playSpinLightTouch()
    self.m_spinLight:playAction(
        "saoguang",
        true,
        function()
            self.m_spinLight:playAction("idle", true)
        end
    )
end

function DailybonusWheel:setSpinTouchState(bState)
    self.m_touchLayout:setTouchEnabled(bState)
end

function DailybonusWheel:wheelRotateEnd()
    -- local rotate =  self:findChild("Wheel"):getRotation()
    -- self:findChild("zhongjiang"):setRotation(rotate)
    if self.m_bonusNode:getRunWheelState() ~= WHEELTYPE.WHEELTYPE_NewJp then
        self.m_resultLight:showState(true)
        self.m_resultLight:playIdleAction()
        performWithDelay(
            self,
            function()
                self.m_bonusNode:wheelRotateEnd() --回调主界面
            end,
            2
        )
    else
        self.m_bonusNode:wheelRotateEnd() --回调主界面
    end
end

--创建闪电
function DailybonusWheel:createLightNode()
    self.m_lightView = util_createView("views.cashBonus.DailyBonus.DailybonusLight")
    self:findChild("NodeRward"):addChild(self.m_lightView, -1)
    local rewardPos = cc.p(0, 0)
    local btnPos = self.m_bonusNode:getNodePos(self:findChild("NormalWheelNode"), self:findChild("NodeRward"))
    self.m_lightView:setLightInfo(rewardPos, btnPos)
    self.m_lightView:setVisible(false)
end

--视频轮盘数据
function DailybonusWheel:initAdsWheel()
    self.distance_pre = 0
    self.distance_now = 0
    --隐藏结算框
    self.m_resultLight:showState(false)

    --保留下普通轮盘信息
    self.m_wheelRotation = self:findChild("Wheel"):getRotation()

    self.m_wheelData = G_GetMgr(G_REF.CashBonus):getWheelData() --普通轮盘数据

    local mulitipValue = self.m_mulitip * self.m_wheelData.p_vipMultiple --普通轮盘倍数
    self.m_wheelRotation = self:findChild("Wheel"):getRotation()
    self.m_runIndex = self.m_wheelData:getResultCoinIndex()

    self:initWheelData(mulitipValue)
end

--付费轮盘
function DailybonusWheel:switchToPayWheel(wheel)
    self.distance_pre = 0
    self.distance_now = 0

    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if wheel_data then
        local price_data = wheel_data:getPayData()
        if price_data and table.nums(price_data) > 0 then
            self.isPayWheel = true
        end
    end

    --隐藏结算框
    self.m_resultLight:showState(false)

    --保留下普通轮盘信息
    self.m_wheelRotation = self:findChild("Wheel"):getRotation()

    self.m_nodeWheel = wheel
    --重新绑定节点
    self.m_csbOwner = {}
    self:bindingEvent(wheel)
    --初始化数据
    self.m_wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData() --付费轮盘数据
    self:setValues(true)
    self:initUIPayWheel()
end

function DailybonusWheel:initUIPayWheel()
    --获取普通轮盘 角度
    self:findChild("Wheel"):setRotation(self.m_wheelRotation)

    self:addSpinBtnClick()
    self:addSpinEndLight()
    self:addBtnLight()

    self:addJpItem()

    self:initRunInfo()

    self:initWheelData(1)

    local wheel_data = G_GetMgr(G_REF.CashBonus):getWheelData()
    local mulitipValue = self.m_mulitip * wheel_data.p_vipMultiple --普通轮盘倍数
    local data = {}
    for k, v in pairs(wheel_data.p_values) do
        data[k] = v * mulitipValue
    end
    self:changeBuyWheelCoinLabel(data)

    --记录下 pay轮盘必要数值
    self.m_runIndex = self.m_wheelData:getResultCoinIndex()
end

function DailybonusWheel:getPayTotleCoin()
    return self.m_runReward
end

--添加jp选项
function DailybonusWheel:addJpItem()
end
--补丁
function DailybonusWheel:changeBuyWheelCoinLabel(data)
    if not data or table.nums(data) <= 0 then
        return
    end
    for i = 2, 15 do
        local node_coin1 = self:findChild("LabelCoin1_" .. i - 1)
        local node_coin2 = self:findChild("LabelCoin2_" .. i - 1)
        local number1 = data[i]
        local number2 = data[i]

        node_coin1:setString(util_getFromatMoneyStr(number1))
        node_coin2:setString(util_getFromatMoneyStr(number2))
        util_scaleCoinLabGameLayerFromBgWidth(node_coin1, 179)
        util_scaleCoinLabGameLayerFromBgWidth(node_coin2, 179)
    end
end

function DailybonusWheel:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "BtnSpin" then
        if self.isPayWheel then
            return
        end
        self:setSpinTouchState(false)
        self.m_bonusNode:playSpinAction()
    end
end

function DailybonusWheel:rotateWheel()
    self:setSpinTouchState(false)
    self:resetWheelStopCb()
    self:beginWheel(self.m_runIndex)
    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if wheel_data then
        wheel_data:clearWheelIdx()
        wheel_data:clearWheelReward()
        wheel_data:clearJackpotIdx()
    end
end

function DailybonusWheel:beginWheel(endIndex)
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500
    --匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 50 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 50
    self.m_nodeWheelControl.m_currentDistance = self.m_wheelRotation
    self.m_nodeWheelControl:changeWheelRunData(wheelData)
    self.m_nodeWheelControl:recvData(endIndex)

    self.m_nodeWheelControl:beginWheel()
    self.m_wheelRotation = 0
end

function DailybonusWheel:beginWheelJp(endIndex)
    local wheelData = {}
    wheelData.m_startA = 1000 --加速度
    wheelData.m_runV = 500
    --匀速
    wheelData.m_runTime = 0 --匀速时间
    wheelData.m_slowA = 1500 --动态减速度
    wheelData.m_slowQ = 0 --减速圈数
    wheelData.m_stopV = 50 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 50
    self.m_nodeWheelControl.m_currentDistance = self.m_wheelRotation
    self.m_nodeWheelControl:changeWheelRunData(wheelData)
    self.m_nodeWheelControl:recvData(endIndex)

    self.m_nodeWheelControl:beginWheel()
    self.m_wheelRotation = 0
end

--播放倍增器idle
function DailybonusWheel:playRewardXAction()
    self.m_rewardX:playIdleAction()
end

--播放倍增器释放闪电时动画
function DailybonusWheel:playLightHit(hitCallFunc)
    self.m_lightView:setVisible(true)
    self.m_lightView:playLightAction(hitCallFunc)
end

function DailybonusWheel:playCollectAction(hitCallFunc, endFunc)
    self.m_rewardX:playCollectAction(
        function()
            self:playLightHit(hitCallFunc)
        end,
        function()
            endFunc()
        end
    )
end

--自动播放添加jp选项的动画
function DailybonusWheel:playAddJpAction(newJpIndex)
    --隐藏结算特效框
    self.m_resultLight:showState(false)

    --跟新滚轮角度
    self.m_wheelRotation = self:findChild("Wheel"):getRotation()

    --开转
    self.m_addJpIndex = newJpIndex
    self:beginWheelJp(self.m_addJpIndex)
end

--播放
function DailybonusWheel:playNewJpAnimation()
    --轮盘停止特效、
    local newJpItem = util_createView("views.cashBonus.DailyBonus.DailybonusNewJpItem")
    self:findChild("nodeJp_" .. (self.m_addJpIndex - 1)):addChild(newJpItem)
    newJpItem:playNewJpAnimation()
end

--获取添加jp的index
function DailybonusWheel:getNewJpIndex()
    local weelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local jpList = weelData:getJackpotList()
    for i = 1, #jpList do
        local jpInfo = jpList[i]
        if jpInfo.isNewJackpot then
            return jpInfo.index
        end
    end
    return 0
end

function DailybonusWheel:resetWheelStopCb()
    if self.m_nodeWheelControl:getEndFunc() == nil then
        self.m_nodeWheelControl:setEndFunc(
            function()
                self:wheelRotateEnd()
            end
        )
    end
end

function DailybonusWheel:imdStopWheel()
    --轮盘滚动回调置为空
    self.m_nodeWheelControl:setEndFunc(nil)
    self.m_nodeWheelControl:overWheel()

    self.m_resultLight:showState(true)
    self.m_resultLight:playIdleAction()
    performWithDelay(self, function()
        self.m_bonusNode:showResultLayerSpeedMode()
    end, 2)
end

function DailybonusWheel:pauseAllEffect()
    self.m_bonusNode:stopViewAciton(self.m_rewardX)
    self.m_bonusNode:stopViewAciton(self.m_resultLight)
    self.m_bonusNode:stopViewAciton(self.m_lightView)
end
return DailybonusWheel
