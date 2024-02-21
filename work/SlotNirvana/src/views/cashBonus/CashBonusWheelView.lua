---
-- cash bonus 轮盘功能
--
--
local CashBonusWheelMultipilerBarView = require "views.cashBonus.CashBonusWheelMultipilerBarView"
local CashBonusWheelView = class("CashBonusWheelView", util_require("base.BaseView"))

-----  滚动参数相关
CashBonusWheelView.distance_pre = nil
CashBonusWheelView.distance_now = nil
CashBonusWheelView.m_isRotPointer = nil --原先用于判断是否自动旋转指针  现在用判断指针和轮盘的接触和分离状态
CashBonusWheelView.m_isCollide = nil
CashBonusWheelView.m_rotPointerPam = nil --指针走向系数
CashBonusWheelView.m_pointerLimit = nil --指针惯性限制值
CashBonusWheelView.m_pointerTation = nil --指针走向 1 逆时针 0 顺时针
CashBonusWheelView.m_angDistance = nil --轮盘转过的距离
CashBonusWheelView.m_pointerSpeed = nil
CashBonusWheelView.m_accelerated = nil --重力加速度 原先0.35  1
CashBonusWheelView.m_deceleration = nil --阻力  原先0.08  0.4

CashBonusWheelView.isNewPlayer = nil --是否是新玩家
CashBonusWheelView.p_multiplier = nil
CashBonusWheelView.m_multipilerBar = nil -- 增倍器进度条

CashBonusWheelView.p_baseCoinLabels = nil -- 基础金币lb 列表
CashBonusWheelView.p_payJackpots = nil -- 支付金币 jackpot列表

CashBonusWheelView.m_jackpotCurCoin = nil
CashBonusWheelView.p_baseJackpotLb = nil --
CashBonusWheelView.p_payJackpotLb = nil --

CashBonusWheelView.m_btn_collect = nil
CashBonusWheelView.m_baseRewardLb = nil
CashBonusWheelView.m_baseMutilLb = nil
CashBonusWheelView.m_baseVipLb = nil
CashBonusWheelView.m_baseTotalLb = nil

CashBonusWheelView.m_randomIndex = nil -- 滚动结果索引

CashBonusWheelView.m_lunpan = nil
CashBonusWheelView.m_buyResultLb = nil
CashBonusWheelView.m_buyCoinSp = nil
CashBonusWheelView.m_coinSpineNode = nil
CashBonusWheelView.m_buyTipView = nil

CashBonusWheelView.m_wheelSpinBtn = nil
CashBonusWheelView.m_wheelPointerSp = nil -- 轮盘指针
CashBonusWheelView.m_wheelControl = nil -- 轮盘滚动控制器
CashBonusWheelView.m_wheelPayControl = nil -- 轮盘滚动控制器
CashBonusWheelView.m_wheelBaseNode = nil -- 基础轮盘滚动节点
CashBonusWheelView.m_wheelPayNode = nil -- 支付轮盘滚动结点
CashBonusWheelView.m_wheelFlashNode = nil
CashBonusWheelView.m_wheelFash = nil

CashBonusWheelView.m_showResultAction = nil -- 侠士结果 action

CashBonusWheelView.m_isInAniTwoIdle = nil
CashBonusWheelView.m_btnClose = nil
CashBonusWheelView.m_touchPayNode = nil -- 承载付费轮盘点击区域的节点
CashBonusWheelView.m_changePayCoinAction = nil

CashBonusWheelView.m_payMulLb = nil -- 支付轮盘翻倍lb
CashBonusWheelView.m_wheelPayJackpotEffect = nil
CashBonusWheelView.m_wheelPayDiamondEffect = nil

CashBonusWheelView.m_touchLayer = nil

CashBonusWheelView.m_videoReward = nil
-- 粒子
CashBonusWheelView.m_Particle_1 = nil
CashBonusWheelView.m_ParticleToPlayInOver = nil

CashBonusWheelView.m_logMul = nil
CashBonusWheelView.m_logExp = nil

CashBonusWheelView.m_usingPointerSp = nil -- 当前正在使用的转盘的指针节点
CashBonusWheelView.m_payWheelBuySuccess = nil
CashBonusWheelView.m_stopPayWheelJackpotTimer = nil
CashBonusWheelView.m_stopFreeWheelJackpotTimer = nil

local WHEELTYPE = {
    WHEELTYPE_BASE = 1, -- 基础轮盘
    WHEELTYPE_PAY = 2 -- 支付轮盘
}

function CashBonusWheelView:initUI()
    self.isNewPlayer = false
    self:initViewCsb()
    self:initMultiplierBar()

    self.p_baseCoinLabels = {}
    self.p_payJackpots = {}
    self.m_isCloseClicked = true --锁定返回功能
    self.isToSpin = false
    self.m_isToSpinTwo = false
    self.m_isCollectBtnClicked = false
    self.m_isInAniTwoIdle = false
    self.m_videoReward = false

    self.m_payWheelBuySuccess = false
    self.m_stopPayWheelJackpotTimer = false
    self.m_stopFreeWheelJackpotTimer = false

    self:initWheelRoolInfo()
    self:updateJackpot(WHEELTYPE.WHEELTYPE_BASE)
    self:initWheelCoinList()
end

function CashBonusWheelView:initViewCsb()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("Hourbonus_new/DailyBonusLayer.csb", isAutoScale)
    if globalNoviceGuideManager:isNoobUsera() then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.dallyWhell)
    end
    if globalPlatformManager.sendFireBaseLogDirect then
        globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.Free_Wheel)
    end
    --递归使能透明度，不然cc.FadeOut不会生效
    util_setCascadeOpacityEnabledRescursion(self, true)

    self.m_payMulLb = self.m_csbOwner["lb_mul"]
    self.m_baseRewardLb = self.m_csbOwner["m_lb_base_reward"]
    self.m_baseMutilLb = self.m_csbOwner["m_lb_mutil_reward"]
    self.m_baseVipLb = self.m_csbOwner["m_lb_vip_reward"]
    self.m_baseTotalLb = self.m_csbOwner["m_lb_total_reward"]
    self.m_btn_collect = self:findChild("btn_collect")
    self.m_btn_collect:setVisible(false)
    self.p_multiplier = self.m_csbOwner["multiplier"]
    -- 读取轮盘 Node_2里面的节点
    local Node_2 = util_findChildByNameTraverse(self, {"Layer", "Node_2"}, 1)

    self.p_baseJackpotLb = self.m_csbOwner["BitmapFontLabel_31"]
    self.p_payJackpotLb = util_findChildByNameTraverse(Node_2, {"Node_53", "Node_1", "BitmapFontLabel_1"}, 1)

    self.m_lunpan = util_findChildByNameTraverse(Node_2, {"lunpan"}, 1)
    self.m_buyResultLb = util_findChildByNameTraverse(Node_2, {"two_jiesuan", "BitmapFontLabel_6"}, 1)
    self.m_buyCoinSp = util_findChildByNameTraverse(Node_2, {"two_jiesuan", "Image_19"}, 1)
    self.m_coinSpineNode = util_findChildByNameTraverse(Node_2, {"two_jiesuan", "Node_Jinbi_Spine"}, 1)

    self.m_twojiesuan = self:findChild("two_jiesuan")

    self.m_spin_wenzi = util_findChildByNameTraverse(Node_2, {"Node_53", "spin", "spin_wenzi"}, 1)
    self.m_spin_added = util_findChildByNameTraverse(Node_2, {"Node_53", "spin", "spin_added"}, 1)
    self.m_spin_added:setVisible(false)
    self.m_paySpinText = util_findChildByNameTraverse(Node_2, {"Node_53", "spin", "spin_wenzi", "Node_paySpinText"}, 1)
    self.m_paySpinCoin = util_findChildByNameTraverse(Node_2, {"Node_53", "spin", "spin_wenzi", "Node_paySpinCoin"}, 1)

    self.m_wheelPointerSp = util_findChildByNameTraverse(Node_2, {"lunpan", "Other", "Image_8"}, 1)
    self.m_wheelBaseNode = util_findChildByNameTraverse(Node_2, {"lunpan", "Wheel"}, 1)
    self.m_wheelPayNode = util_findChildByNameTraverse(Node_2, {"Node_53", "Node_1", "lunpan"}, 1)
    self.m_wheelFlashNode = util_findChildByNameTraverse(Node_2, {"lunpan", "Flash"}, 1)
    self.m_wheelSpinBtn = util_findChildByNameTraverse(Node_2, {"lunpan", "Other", "touch"}, 1)

    self.m_btnClose = util_findChildByNameTraverse(Node_2, {"Node_53", "Menu", "btn_close"}, 1)
    self:setTouchEnabled(self.m_btnClose, false)
    self.m_btnClose:setVisible(false)

    self.m_touchPayNode = util_findChildByNameTraverse(Node_2, {"Node_53", "Node_Touch_To_Spin_Twice"}, 1)

    self.m_ParticleToPlayInOver = util_findChildByNameTraverse(Node_2, {"Node_53", "Effect", "Particle_1"}, 1)
    self.m_ParticleToPlayInOver:setVisible(false)

    -- 初始化付费轮盘 jackpot 效果
    local jackpotNode = util_findChildByNameTraverse(Node_2, {"Node_53", "Node_1", "dailyjackpot"}, 1)
    self.m_wheelPayJackpotEffect = util_createView("views.cashBonus.CashBonusWheelJackpotEffect")
    jackpotNode:addChild(self.m_wheelPayJackpotEffect)
    self.m_wheelPayJackpotEffect:setPositionNormalized(cc.p(0.5, 0.5))
    self.m_wheelPayJackpotEffect:Hide()

    self.m_payWheelPointerSp = util_findChildByNameTraverse(Node_2, {"Node_53", "Node_1", "zhizheng"}, 1)
    -- self.m_wheelPayDiamondEffect = util_createView("views.cashBonus.CashBonusWheelDiamondEffect")
    -- diamondNode:addChild(self.m_wheelPayDiamondEffect)
    -- self.m_wheelPayDiamondEffect:setPositionNormalized(cc.p(0.5, 0.5))
    -- self.m_wheelPayDiamondEffect:Hide()

    self.m_sp_deluxe = self:findChild("deluxe_extra")
    if globalData.deluexeClubData:getDeluexeClubStatus() ~= true then
        self.m_sp_deluxe:setVisible(false)
    else
        local labExtra = self:findChild("labExra")
        if labExtra ~= nil then
            labExtra:setString(globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD .. "%")
            self:updateLabelSize({label = labExtra}, 54)
        end
    end
    local sp_vipBoostTip = self:findChild("sp_vipBoostTip")
    if sp_vipBoostTip then
        sp_vipBoostTip:setVisible(false)
        if globalData.saleRunData:isOpenBoost() then
            sp_vipBoostTip:setVisible(true)
        end
    end
end
--[[
    @desc: 初始化增倍器
    time:2019-04-18 21:25:44
    @return:
]]
function CashBonusWheelView:initMultiplierBar()
    local multipilerBar = util_createView("views.cashBonus.CashBonusWheelMultipilerBarView", "wheel") --CashBonusWheelMultipilerBarView:create()
    -- multipilerBar:initUI("wheel")

    self.p_multiplier:addChild(multipilerBar)
    self.m_multipilerBar = multipilerBar
end

--[[
    @desc: 设置滚动轮盘 旋转数据
    time:2019-04-18 11:48:33
    @return:
]]
function CashBonusWheelView:initWheelRoolInfo()
    self.distance_pre = 0
    self.distance_now = 0
    self.m_isRotPointer = false --原先用于判断是否自动旋转指针  现在用判断指针和轮盘的接触和分离状态
    self.m_isCollide = false
    self.m_rotPointerPam = -1 --指针走向系数
    self.m_pointerLimit = -70 --指针惯性限制值
    self.m_pointerTation = 1 --指针走向 1 逆时针 0 顺时针
    self.m_angDistance = 0 --轮盘转过的距离
    self.m_pointerSpeed = 180
    self.m_accelerated = 1 --重力加速度 原先0.35  1
    self.m_deceleration = 0.4 --阻力  原先0.08  0.4
end
--[[
    @desc: 开始旋转轮盘
    time:2019-04-18 12:00:18
    @return:
]]
function CashBonusWheelView:startRoolWheel()
    self.m_isRotPointer = true
    local function update(dt)
        self:updateFunc(dt)
    end
    if self.m_usingPointerSp then
        self.m_usingPointerSp:onUpdate(update)
    end
end

function CashBonusWheelView:updateFunc(dt)
    if self.m_isRotPointer == true then
        local pointerRot = self.m_usingPointerSp:getRotation()
        pointerRot = pointerRot + self.m_pointerSpeed * dt
        if pointerRot >= 0 then
            pointerRot = 0
            self.m_isRotPointer = false
        end
        self.m_usingPointerSp:setRotation(pointerRot)
    end
end

function CashBonusWheelView:onEnter()
    gLobalSoundManager:playSubmodBgm("Sounds/cashlink_bg.mp3", self.__cname, self:getZorder())
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "show",
                false,
                function()
                    self:playProcessBarAni()
                end
            )
        end,
        0.2
    )
    local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    self.m_logMul = multipleData.p_value
    self.m_logExp = multipleData.p_exp
    gLobalSendDataManager:getLogFeature():sendCashBonusWheelLog(LOG_ENUM_TYPE.Wheel_Open, nil, self.m_logMul, self.m_logExp)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            release_print("Mopub    " .. params[1])
            if params[1] == "success" then
                self:initVideoWheel()
                local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
                local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
                local totalCoins = wheelData.p_value * wheelData.p_vipMultiple * wheelData.p_loginMultiple * multipleData.p_value
                gLobalSendDataManager:getLogAds():setadTaskStatus("Full")
                gLobalSendDataManager:getLogAds():setdialyTimes(totalCoins)
                gLobalSendDataManager:getLogAds():sendAdsLog()

                gLobalSendDataManager:getLogAdvertisement():setadType("Close")
                gLobalSendDataManager:getLogAdvertisement():setadStatus("FullClose")
                gLobalSendDataManager:getLogAdvertisement():setStatus("Success")
                gLobalSendDataManager:getLogAdvertisement():setdialyTimes(totalCoins)
                gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
            else
                gLobalSendDataManager:getLogAds():setadTaskStatus("Return")
                gLobalSendDataManager:getLogAds():sendAdsLog()

                gLobalSendDataManager:getLogAdvertisement():setadType("Close")
                gLobalSendDataManager:getLogAdvertisement():setadStatus("MidwayClose")
                gLobalSendDataManager:getLogAdvertisement():setStatus("Fail")
                gLobalSendDataManager:getLogAdvertisement():sendAdsLog()

                self:initPayWheel()
            end
        end,
        ViewEventType.NOTIFY_CASHBONUS_VIDEO_REWARD
    )

    globalData.adsRunData.p_haveCashBonusWheel = true

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local data = params.data
            local success = params.success
            if success then
                gLobalDataManager:setNumberByField("lastRewardWheelTime", os.time())
                self:collectSuccessCallFun()
            else
                gLobalViewManager:removeLoadingAnima()
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.CASHBONUS_COLLECT_ACTION_CALLBACK
    )
end

function CashBonusWheelView:closeUI()
    if self.m_isClose then
        return
    end
    -- if self.m_buyTipView then
    --     self.m_buyTipView:removeFromParent()
    -- end

    local netFeature = gLobalSendDataManager:getNetWorkFeature()
    if netFeature and netFeature.sendActionLCTaskInfo then
        netFeature:sendActionLCTaskInfo()
    end
    if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.FirstLogin) then
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.FirstLogin)
        gLobalAdsControl:playAutoAds(PushViewPosType.FirstLogin)
    end

    self.m_isClose = true
    globalData.adsRunData.p_haveCashBonusWheel = false

    gLobalSoundManager:removeSubmodBgm(self.__cname)

    gLobalNoticManager:removeAllObservers(self)
    gLobalSendDataManager:getLogIap():closeIapLogInfo()
    self:removeFromParent()
end

function CashBonusWheelView:initSettlementView()
    self:setTouchEnabled(self.m_btn_collect, false)

    self.m_csbOwner["m_lb_base_reward"]:setString("?")
    self.m_csbOwner["m_lb_mutil_reward"]:setString("?")
    self.m_csbOwner["m_lb_total_reward"]:setString("?")
    self.m_csbOwner["m_lb_vip_reward"]:setString("?")
end

--[[
    @desc: 更新jackpot 信息
    time:2019-04-18 14:51:23
    --@jackpotType:
    @return:
]]
function CashBonusWheelView:updateJackpot(jackpotType)
    self.p_baseJackpotLb:stopAllActions()
    self.p_payJackpotLb:stopAllActions()

    local jackpotLb = nil
    local wheelData = nil
    if jackpotType == WHEELTYPE.WHEELTYPE_BASE then
        jackpotLb = self.p_baseJackpotLb
        wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    elseif jackpotType == WHEELTYPE.WHEELTYPE_PAY then
        jackpotLb = self.p_payJackpotLb
        wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    end
    local baseCoin = wheelData.p_coinsShowBase
    local maxCoin = wheelData.p_coinsShowMax
    local perAdd = wheelData.p_coinsShowPerSecond
    self.m_jackpotCurCoin = wheelData.p_coinsShowBase + util_random(1, (maxCoin - baseCoin) * 0.5)
    jackpotLb:setString(util_formatMoneyStr(tostring(self.m_jackpotCurCoin)))
    self.m_wheelJackpotTimer =
        schedule(
        jackpotLb,
        function()
            local isStop = false
            if jackpotType == WHEELTYPE.WHEELTYPE_BASE then
                if self.m_stopFreeWheelJackpotTimer == true then
                    isStop = true
                end
            elseif jackpotType == WHEELTYPE.WHEELTYPE_PAY then
                if self.m_stopPayWheelJackpotTimer == true then
                    isStop = true
                end
            end
            if isStop == true or self.m_isClose == true then
                self:stopAction(self.m_wheelJackpotTimer)
                self.m_wheelJackpotTimer = nil
                return
            end
            self.m_jackpotCurCoin = perAdd * 0.08 + self.m_jackpotCurCoin
            if self.m_jackpotCurCoin >= maxCoin then
                self.m_jackpotCurCoin = baseCoin
            end
            jackpotLb:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))
        end,
        0.08
    )
end

function CashBonusWheelView:getJackpotAddValue()
    local addV = self.m_jackpotCurCoin - G_GetMgr(G_REF.CashBonus):getPayWheelData().p_coinsShowBase
    return addV
end

function CashBonusWheelView:stopFreeWheelJackpot()
    self.m_stopFreeWheelJackpotTimer = true
end

function CashBonusWheelView:stopPayWheelJackpot()
    self.m_stopPayWheelJackpotTimer = true
    local jp_data = self:getJackpotAddValue()
    G_GetMgr(G_REF.CashBonus):setJackpotData(jp_data)
end

--[[
    @desc: 初始化滚动轮盘上的 金币信息
    time:2019-04-18 11:58:37
    @return:
]]
function CashBonusWheelView:initWheelCoinList()
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()

    for i = 2, 15 do
        -- 免费轮盘
        local shuziLb = util_findChildByNameTraverse(self, {"Layer", "Node_2", "lunpan", "Wheel", "shuzi", "shuzi_" .. i}, 1)
        local showCoin = wheelData.p_values[i] * multipleData.p_value
        local curShowCoin = wheelData.p_values[i] -- 第一个位置是 jackpot 的数值信息
        shuziLb:setString(util_getFromatMoneyStr(curShowCoin))
        util_scaleCoinLabGameLayerFromBgWidth(shuziLb, 227)

        -- 支付轮盘
        local payJackpotLb = util_findChildByNameTraverse(self, {"Layer", "Node_2", "Node_53", "Node_1", "lunpan", "shuzi", "jackpot_" .. i}, 1)
        local jackpotNode = util_createView("views.cashBonus.CashBonusWheelJackpotText", i)
        payJackpotLb:addChild(jackpotNode)
        jackpotNode:setName("JackpotText")
        jackpotNode:initCoin(curShowCoin)
        jackpotNode:updateJackpot()

        self.p_baseCoinLabels[#self.p_baseCoinLabels + 1] = shuziLb
        self.p_payJackpots[#self.p_payJackpots + 1] = jackpotNode
    end
end

function CashBonusWheelView:updateWheelCoinList()
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    for i = 2, 15 do
        -- 免费轮盘
        local shuziLb = self.p_baseCoinLabels[i - 1]
        local showCoin = wheelData.p_values[i] * multipleData.p_value
        local curShowCoin = wheelData.p_values[i] -- 第一个位置是 jackpot 的数值信息
        shuziLb:setString(util_getFromatMoneyStr(curShowCoin))
        util_scaleCoinLabGameLayerFromBgWidth(shuziLb, 227)
        -- 支付轮盘
        local jackpotNode = self.p_payJackpots[i - 1]
        jackpotNode:setName("JackpotText")
        jackpotNode:initCoin(curShowCoin)
        jackpotNode:updateJackpot()
    end
end

--[[
    @desc: 播放轮盘进场开始的动画流程
    time:2019-04-19 14:18:55
    @return:
]]
function CashBonusWheelView:playProcessBarAni()
    self.m_multipilerBar:playAnimShow()
    performWithDelay(
        self,
        function()
            self.m_multipilerBar:addPercent(
                function()
                    --播放闪光
                    self.m_multipilerBar:playAnimFlicker(
                        function()
                            -- 播放粒子 同时播放进度清零
                            performWithDelay(
                                self,
                                function()
                                    self.m_multipilerBar:playAnimParticle()
                                    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPIN_ACCUMULATION_PARTICLE)
                                    self.m_multipilerBar:reducePercent(
                                        function()
                                            --go on
                                            self:playUpgradeAni()
                                        end
                                    )
                                end,
                                0.5
                            )
                        end
                    )
                end
            )
        end,
        0.4
    )
end

--[[
    @desc: 轮盘播放闪光， 开始乘以增倍器的倍数， 重置数字
    time:2019-04-19 11:42:54
    @return:
]]
function CashBonusWheelView:playUpgradeAni()
    self:runCsbAction("upgrade", false)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_LEVEL_UP_ONE)
            local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
            for i = 2, 15 do
                local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
                local coinValue = wheelData.p_values[i] * multipleData.p_value -- 第一个位置是 jackpot 的数值信息
                local shuzi = util_findChildByNameTraverse(self, {"Layer", "Node_2", "lunpan", "Wheel", "shuzi", "shuzi_" .. i}, 1)
                shuzi:setString(util_getFromatMoneyStr(coinValue))
                util_scaleCoinLabGameLayerFromBgWidth(shuzi, 227)
            end
            performWithDelay(
                self,
                function()
                    self:runCsbAction(
                        "change",
                        false,
                        function()
                            -- performWithDelay(self, function()
                            self:playAddTouchLayer()
                            -- end , 1)
                        end
                    )
                end,
                0.5
            )
        end,
        0.2
    )
end
--[[
    @desc: 增加轮盘点击响应区域， 并且播放提示动画
    time:2019-04-19 11:43:35
    @return:
]]
function CashBonusWheelView:playAddTouchLayer()
    local layer = cc.Layer:create()
    if nil ~= layer then
        layer:onTouch(
            function()
                if self.isToSpin then
                    return
                end
                if globalPlatformManager.sendFireBaseLogDirect then
                    globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.RouletteSpin)
                end
                self.isToSpin = true
                self:spinCallFun()
            end,
            false,
            false
        )
        --layer:setBackGroundColorOpacity(0)
        self:addChild(layer, 1)
    end
    self.m_touchLayer = layer
    self:runCsbAction("touch", true)
end

function CashBonusWheelView:setUsingPointerSp(pointerSp)
    self.m_usingPointerSp = pointerSp
end
function CashBonusWheelView:resetUsingPointerSp()
    self.m_usingPointerSp:setRotation(0)
    self.m_usingPointerSp:stopAllActions()
end
--[[
    @desc: 点击spin 后开始执行滚动逻辑
    time:2019-04-19 11:58:43
    @return:
]]
function CashBonusWheelView:spinCallFun()
    self:stopFreeWheelJackpot()
    self.m_randomIndex = G_GetMgr(G_REF.CashBonus):getWheelData():getResultCoinIndex()

    self:runCsbAction("xuanzhuan", true)

    self.m_wheelSpinBtn:setVisible(false)

    self:setUsingPointerSp(self.m_wheelPointerSp)
    self:startRoolWheel()

    self.m_wheelControl =
        require("base.BaseWheel"):create(
        self.m_wheelBaseNode,
        15,
        function()
            self:showWheelFashEffect()
            self:resetUsingPointerSp()
            self:playJieSuanEffect()
        end,
        function(distance, targetStep, isBack)
            self:setRotionWheel(distance, targetStep)
            self:setRotionOne(distance, targetStep, isBack)
        end
    )
    self:addChild(self.m_wheelControl)
    self.m_wheelControl:beginWheel()
    self.m_wheelControl:recvData(self.m_randomIndex)
end

function CashBonusWheelView:changeAng(ang)
    local k = 0
    local b = 0
    if ang >= 18 then
        k = 0
        b = -40
    elseif ang >= 16 then
        k = -2
        b = -4
    elseif ang >= 13 then
        k = -4
        b = 28
    elseif ang >= 12 then
        k = -7
        b = 67
    elseif ang >= 11 then
        k = -5
        b = 43
    elseif ang >= 9 then
        k = -6
        b = 54
    end
    local pointerRot = k * ang + b
    return pointerRot
end
--[[
    @desc: 设置滚动信息
    time:2019-04-19 12:24:37
    --@distance:
	--@targetStep:
	--@isBack:
    @return:
]]
function CashBonusWheelView:setRotionOne(distance, targetStep, isBack)
    local ang = distance % targetStep

    self.m_angDistance = distance
    local pointerSpeed = self.m_pointerSpeed
    if ang >= 9 and ang < 20 then
        local pointerRot = self:changeAng(ang)
        if pointerRot >= -40 and pointerRot <= self.m_usingPointerSp:getRotation() or isBack then
            self.m_isRotPointer = false
            self.m_usingPointerSp:setRotation(pointerRot)
        end
    else
        self.m_isRotPointer = true
    end
end
--[[
    @desc: 计算旋转角度信息， 播放声音
    time:2019-04-19 12:27:04
    --@distance:
	--@targetStep:
    @return:
]]
function CashBonusWheelView:setRotionWheel(distance, targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_TURN)
    end
end
--[[
    @desc: 播放轮盘 falsh 效果, 选择区域闪烁
    time:2019-04-19 12:12:56
    @return:
]]
function CashBonusWheelView:showWheelFashEffect()
    if nil ~= self.m_Particle_1 then
        self.m_Particle_1:resetSystem()
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_STOPPED)
    --self.flashNode_first:setVisible(false)
    local nodeFlash = util_createView("views.cashBonus.CashBonusWheelFalsh")
    self.m_wheelFlashNode:addChild(nodeFlash)
    nodeFlash:playAnim()
    self.m_wheelFash = nodeFlash
end
--[[
    @desc: 播放结算效果
    time:2019-04-19 12:13:42
    @return:
]]
function CashBonusWheelView:playJieSuanEffect()
    self:initSettlementView()

    self:runCsbAction(
        "jiesuan",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self:showSettlementAni()
                end,
                0.6
            )
        end
    )
end
--[[
    @desc: 显示轮盘结果界面， 播放动画
    time:2019-04-19 12:28:40
    @return:
]]
function CashBonusWheelView:showSettlementAni()
    -- 显示基础奖励
    local function showBaseRewardFun()
        local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        local baseCoins = tostring(wheelData.p_value * multipleData.p_value)
        self.m_csbOwner["m_lb_base_reward"]:setString(util_formatMoneyStr(baseCoins))
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)

        local wheelBonusBao = util_createView("views.cashBonus.CashBonusWheelBao")
        self.m_csbOwner["m_lb_base_reward"]:addChild(wheelBonusBao)
        wheelBonusBao:setPositionNormalized(cc.p(0.5, 0.5))
        wheelBonusBao:playAnim()
    end
    -- 显示vip 加成奖励
    local function showVipRewardFun()
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()

        self.m_csbOwner["m_lb_vip_reward"]:setString(tostring(wheelData.p_vipMultiple * 100) .. "%")
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)

        local wheelBonusBao = util_createView("views.cashBonus.CashBonusWheelBao")
        self.m_csbOwner["m_lb_vip_reward"]:addChild(wheelBonusBao)
        wheelBonusBao:setPositionNormalized(cc.p(0.5, 0.5))
        wheelBonusBao:playAnim()

        self.m_vipBonus = util_createView("views.cashBonus.CashBonusWheelVip")
        self.m_csbOwner["vipBonus"]:addChild(self.m_vipBonus)
    end
    -- 显示登录奖励
    local function showLoginRewardFun()
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()

        self.m_csbOwner["m_lb_mutil_reward"]:setString(tostring(wheelData.p_loginMultiple * 100) .. "%")
        local wheelBonusBao = util_createView("views.cashBonus.CashBonusWheelBao")
        self.m_csbOwner["m_lb_mutil_reward"]:addChild(wheelBonusBao)
        wheelBonusBao:setPositionNormalized(cc.p(0.5, 0.5))
        wheelBonusBao:playAnim()

        self.m_mutilTip = util_createView("views.cashBonus.CashBonusWheelSevenDaily")
        self.m_csbOwner["multipller"]:addChild(self.m_mutilTip)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    end
    -- 显示总钱数
    local function showTotalRewardFun()
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
        local multiple = globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD
        if globalData.deluexeClubData:getDeluexeClubStatus() ~= true then
            multiple = 1
        else
            multiple = (multiple + 100) / 100
        end
        local totalCoins = wheelData.p_value * wheelData.p_vipMultiple * wheelData.p_loginMultiple * multiple * multipleData.p_value
        local wheelBonusBao = util_createView("views.cashBonus.CashBonusWheelBao")
        self.m_csbOwner["m_lb_total_reward"]:addChild(wheelBonusBao)
        wheelBonusBao:setPositionNormalized(cc.p(0.5, 0.5))
        wheelBonusBao:playAnim()
        self.m_csbOwner["m_lb_total_reward"]:setString(util_formatCoins(totalCoins, 9))

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)

        local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
        local vipMul = tonumber(wheelData.p_vipMultiple) or 1
        local loginMul = tonumber(wheelData.p_loginMultiple) or 1
        local expMul = tonumber(self.m_logMul) or 1
        local coinsData = {}
        coinsData.rewardCoins = totalCoins
        coinsData.addCoinsVip = wheelData.p_value * (vipMul - 1)
        coinsData.addCoinsDaily = wheelData.p_value * (loginMul - 1)
        coinsData.addCoinsMultiple = wheelData.p_value * (expMul - 1)
        coinsData.days = G_GetMgr(G_REF.CashBonus):getLoginDays()
        coinsData.multipleVip = vipMul
        coinsData.multipleDaily = loginMul
        gLobalSendDataManager:getLogFeature():sendCashBonusWheelLog(LOG_ENUM_TYPE.Wheel_Collect, coinsData, self.m_logMul, self.m_logExp)
    end

    function showDeluexeExtra()
        --抛物线飞倍数
        local startPos = cc.p(self.m_sp_deluxe:getPosition())
        local endPos = cc.p(self.m_csbOwner["m_lb_base_reward"]:getPosition())
        local radian = 75 * math.pi / 180
        local height = 250
        local q1x = startPos.x + (endPos.x - startPos.x) / 4
        local q1 = cc.p(q1x, height + startPos.y + math.cos(radian) * q1x)
        local q2x = startPos.x + (endPos.x - startPos.x) / 2
        local q2 = cc.p(q2x, height + startPos.y + math.cos(radian) * q2x)
        local bez = cc.BezierTo:create(0.6, {q1, q2, endPos})
        local seq = cc.Sequence:create(cc.ScaleTo:create(0.2, 3), cc.ScaleTo:create(0.4, 1.5))
        local spw = cc.Spawn:create(bez, seq)
        self.m_sp_deluxe:runAction(spw)
    end

    function growBaseCoin()
        --倍数飞到位置滚动基础钱
        self.m_sp_deluxe:setVisible(false)
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        local baseCoins = wheelData.p_value
        local multiple = globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD
        local time = 0.02
        local extraNum = baseCoins * multiple / 100
        local addValue = extraNum / 15
        util_jumpNum(self.m_csbOwner["m_lb_base_reward"], baseCoins, extraNum + baseCoins, addValue, 0.02, {30})
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    end
    -- 播放结果回调函数
    local function showResultCallFun(updateIndex)
        if updateIndex == 1 then
            showBaseRewardFun()
        elseif updateIndex == 2 then
            showDeluexeExtra()
        elseif updateIndex == 4 then
            growBaseCoin()
        elseif updateIndex == 6 then
            showVipRewardFun()
        elseif updateIndex == 7 then
            showLoginRewardFun()
        elseif updateIndex == 12 then
            showTotalRewardFun()
        elseif updateIndex == 13 then
            self:setTouchEnabled(self.m_btn_collect, true)
            self.m_btn_collect:setVisible(true)
            self:stopAction(self.m_showResultAction)
        end
    end -- end function

    performWithDelay(
        self,
        function()
            local index = 0
            self.m_showResultAction =
                schedule(
                self,
                function()
                    index = index + 1
                    showResultCallFun(index)
                    if globalData.deluexeClubData:getDeluexeClubStatus() ~= true and index == 1 then
                        index = 5
                    end
                end,
                0.3
            )
        end,
        0.1
    )
end
--[[
    @desc: 点击关闭逻辑处理
    time:2019-04-19 16:17:43
    @return:
]]
function CashBonusWheelView:clickBuyTipCloseCallFun()
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()

    self.m_btnClose:setVisible(false)
    self.m_buyTipView =
        util_createView(
        "views.cashBonus.CashBonusBuyTip",
        function()
            if self.m_isClose then
                return
            end
            if self.m_isToSpinTwo then
                return
            end
            self.m_isToSpinTwo = true
            self.m_isCloseClicked = true --再次锁定返回功能
            self.m_isInAniTwoIdle = false
            self:setTouchEnabled(self.m_btnClose, false)
            self.m_btnClose:setVisible(false)
            self:buyWheelPay(true)
        end,
        function()
            if true == self.m_isCloseClicked then
                return
            end
            self.m_isCloseClicked = true
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            self:closeUI()
        end,
        wheelPayData.p_coinsShowMax,
        wheelPayData.p_multiple,
        wheelPayData.p_price
    )

    local close = self:findChild("m_close")
    if close then
        close:addChild(self.m_buyTipView)
    end
end

--[[
    @desc: 处理点击事件
    time:2019-04-19 14:08:15
    --@sender:
    @return:
]]
function CashBonusWheelView:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_collect" then -- 点击收集按钮
        if globalPlatformManager.sendFireBaseLogDirect then
            globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.RouletteFreeCollect)
        end
        self:collectClickCallFun()
    elseif name == "btn_close" then
        if globalPlatformManager.sendFireBaseLogDirect then
            globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.RoulettePaymentClose1)
        end
        self:clickBuyTipCloseCallFun()
    end
end

function CashBonusWheelView:collectSuccessCallFun()
    local payWheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    self.m_payMulLb:setString("x" .. payWheelData.p_multiple)
    globalLocalPushManager:pushNotifyCashbonus()
    gLobalViewManager:removeLoadingAnima()

    -- 获取飞行目标位置
    local endPos = globalData.flyCoinsEndPos
    local m_lb_total_reward = self.m_csbOwner["m_lb_total_reward"]
    local startPos = m_lb_total_reward:getParent():convertToWorldSpace(cc.p(m_lb_total_reward:getPosition()))
    gLobalViewManager:flyCoins(startPos, endPos)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    performWithDelay(
        self,
        function()
            -- 通知金币发生变化
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            performWithDelay(
                self,
                function()
                    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PAYROULETTE then -- 这里是一个逻辑上的需求 ???
                        self:closeUI()
                    else
                        self:collectOverCallFun()
                    end
                end,
                0.5
            )
        end,
        0.5
    )
    self.m_mutilTip:runCsbAction("over")
    self.m_vipBonus:runCsbAction("over")
end

--[[
    @desc: 点击收集按钮事件响应
    time:2019-04-19 14:09:59
    @return:
]]
function CashBonusWheelView:collectClickCallFun()
    if true == self.m_isCollectBtnClicked then
        return
    end
    self.m_isCollectBtnClicked = true
    self:setTouchEnabled(self.m_btn_collect, false)

    gLobalViewManager:addLoadingAnima()

    if self.m_videoReward == true then
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
        local totalCoins = wheelData.p_value * wheelData.p_vipMultiple * wheelData.p_loginMultiple * multipleData.p_value

        local adsInfo = globalData.adsRunData:getAdsInfoForPos(PushViewPosType.DialyBonus)
        local messageData = {id = adsInfo.p_id, position = adsInfo.p_position, type = adsInfo.p_type}
        gLobalSendDataManager:getNetWorkFeature():sendWatchViodeMessage(
            messageData,
            function(target, resultData)
                local result = resultData.result
                if DEBUG == 2 then
                    release_print(result)
                    print(result)
                end

                if resultData:HasField("simpleUser") == true then
                    globalData.syncSimpleUserInfo(resultData.simpleUser)
                end
                self:collectSuccessCallFun()
            end,
            function()
                gLobalViewManager:showReConnect()
            end
        )
    else
        G_GetMgr(G_REF.CashBonus):sendActionCashBonus(CASHBONUS_TYPE.BONUS_WHEEL)
    end
end
--[[
    @desc: 新用户关闭窗口的逻辑处理
    time:2019-04-19 14:15:31
    @return:
]]
function CashBonusWheelView:closeUIWithNewPlayer()
    self.m_wheelFash:Hide()

    if true then
        self:closeUI() -- 不在播放动画了， 直接关闭掉 2019-04-26 22:58:24
    end

    local actionList = {}
    actionList[#actionList + 1] = cc.FadeOut:create(1)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            self:closeUI()
        end
    )
    local seq = cc.Sequence:create(actionList)
    self:runAction(seq)
end

--[[
    @desc: 将轮盘从普通状态切换到 付费轮盘
    author:{author}
    time:2019-04-19 14:25:55
    @return:
]]
function CashBonusWheelView:changeWheelBaseToPay()
    self:runCsbAction(
        "over",
        false,
        function()
            self:runCsbAction(
                "two_fangda",
                false,
                function()
                    self:runCsbAction("two_idle", true)
                    self.m_isInAniTwoIdle = true
                    self.m_isCloseClicked = false --放开返回功能

                    self:setTouchEnabled(self.m_btnClose, true)
                    self.m_btnClose:setVisible(true)

                    -- 创建点击相应区域
                    local layer = cc.Layer:create()
                    if nil ~= layer then
                        layer:onTouch(
                            function()
                                if self.m_isClose then
                                    return
                                end
                                if self.m_isToSpinTwo then
                                    return
                                end
                                self.m_isToSpinTwo = true
                                self.m_isCloseClicked = true --再次锁定返回功能
                                self.m_isInAniTwoIdle = false
                                self:setTouchEnabled(self.m_btnClose, false)
                                self.m_btnClose:setVisible(false)
                                self:buyWheelPay(false)
                                if globalPlatformManager.sendFireBaseLogDirect then
                                    globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.RoulettePaymentOrder1)
                                end
                            end,
                            false,
                            false
                        )
                        self.m_touchPayNode:addChild(layer, 1)
                    end
                end
            )
        end
    )
end

--[[
    @desc: 播放付费轮盘 金币变化
    time:2019-04-19 14:27:30
    @return:
]]
function CashBonusWheelView:showWheelPayCoinChange()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_LEVEL_UP)
            local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
            local spMul = wheelPayData.p_multiple
            local iMul = 1
            self.m_changePayCoinAction =
                schedule(
                self.m_touchPayNode,
                function()
                    if iMul > spMul then
                        self.m_touchPayNode:stopAction(self.m_changePayCoinAction)
                        self.m_changePayCoinAction = nil
                        for i = 1, 14 do -- 轮子上总共有15个， 第一个是 jackpot
                            local jackpotNode = self.p_payJackpots[i]
                            local coin = wheelPayData.p_values[i + 1]
                            jackpotNode:initCoin(coin)
                        end
                        return
                    end
                    for i = 1, 14 do -- 轮子上总共有15个， 第一个是 jackpot
                        local jackpotNode = self.p_payJackpots[i]
                        local coin = wheelPayData.p_values[i + 1] / spMul * iMul
                        jackpotNode:initCoin(coin)
                    end
                    iMul = iMul + 1
                end,
                0.04
            )
        end,
        0.9
    )
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "loginLobbyPush")
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "CashBonusWheelView"
    goodsInfo.goodsId = wheelPayData.p_key
    goodsInfo.goodsPrice = wheelPayData.p_price
    goodsInfo.discount = wheelPayData.p_multiple * 100
    goodsInfo.totalCoins = nil
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "dayRoulette"
    purchaseInfo.purchaseName = "dayRoulette" .. wheelPayData:getPayIdx()
    purchaseInfo.purchaseStatus = "dayRoulette"

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end
--[[
    @desc: 设置付费轮盘信息
    time:2019-04-19 16:00:16
    @return:
]]
function CashBonusWheelView:setWheelPayInfo()
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()

    local touch = self:findChild("beishu")
    if touch then
        touch:setString("$" .. wheelPayData.p_price)
    end

    --TODO 设置变化倍数
end

function CashBonusWheelView:initVideoWheel()
    self.m_wheelControl:setRotation(0)
    self.isToSpin = false
    self.m_isCollectBtnClicked = false
    self.m_videoReward = true
    self.m_btn_collect:setVisible(false)
    self:updateWheelCoinList()
    self:playAddTouchLayer()

    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "vedioRewardPush")
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "CashBonusWheelView"
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "dayRoulette"
    purchaseInfo.purchaseName = "dayRoulette"
    purchaseInfo.purchaseStatus = "normal"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function CashBonusWheelView:initPayWheel()
    self:changeWheelBaseToPay()

    performWithDelay(
        self,
        function()
            self.m_wheelPayJackpotEffect:playAnim()
            -- self.m_wheelPayDiamondEffect:playAnim()
        end,
        2.5
    )
    performWithDelay(
        self,
        function()
            self.m_ParticleToPlayInOver:setVisible(true)
            self.m_ParticleToPlayInOver:resetSystem()
        end,
        0.5
    )

    self:showWheelPayCoinChange()
end

--[[
    @desc: 每日轮盘结算完毕后的回调
    time:2019-04-19 14:14:37
    @return:
]]
function CashBonusWheelView:collectOverCallFun()
    if true == self.isNewPlayer then
        self:closeUIWithNewPlayer()
        return
    end
    self:setWheelPayInfo()
    self:updateJackpot(WHEELTYPE.WHEELTYPE_PAY)

    self.m_wheelFash:Hide()

    if self.m_videoReward == false and globalData.adsRunData:isPlayRewardForPos(PushViewPosType.DialyBonus) then
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.DialyBonus)
        gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
        local view =
            util_createView(
            "views.dialogs.AdsRewardLayer",
            AdsRewardDialogType.DailyBonus,
            PushViewPosType.DialyBonus,
            function()
                gLobalViewManager:addLoadingAnima()
                gLobalAdsControl:playRewardVideo(PushViewPosType.DialyBonus)
            end,
            function()
                -- performWithDelay(self, function()
                self:initPayWheel()
                -- end, 1)
            end
        )
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        gLobalSendDataManager:getLogAds():createPaySessionId()
        gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.DialyBonus)
        gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
        globalPlatformManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.DialyBonus})
    else
        self:initPayWheel()
    end
end
--[[
    @desc: 购买支付轮盘
    time:2019-04-19 16:32:47
    @return:
]]
function CashBonusWheelView:buyWheelPay(isSecond)
    local function closeBuyTip()
        if self.m_buyTipView ~= nil then
            self.m_buyTipView:removeFromParent()
        end
    end

    self:stopPayWheelJackpot()

    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local buyRase = 0 ---翻倍
    local iapId = wheelPayData.p_key
    local price = wheelPayData.p_price
    local totalCoins = wheelPayData.p_value

    self.m_randomIndex = wheelPayData:getResultCoinIndex()

    -- 购买成功
    local function buySuccessCallFun()
        -- 隐藏benefits
        if self.m_luckyStampTipView ~= nil then
            self.m_luckyStampTipView:setVisible(false)
        end
        if self.m_infoPBnode ~= nil then
            self.m_infoPBnode:setVisible(false)
        end
        self.m_payWheelBuySuccess = true
        -- 付费轮盘，在付费后，将spin按钮上的价格去掉，spin剧中显示
        self.m_paySpinCoin:setVisible(false)
        local posx, posy = cc.p(self.m_paySpinText:getPosition())
        local move = cc.MoveTo:create(0.2, cc.p(posx, 0))
        self.m_paySpinText:runAction(move)
        -- 转盘特效
        self:runCsbAction("two_xuanzhuan", true)

        self:setUsingPointerSp(self.m_payWheelPointerSp)
        self:startRoolWheel()
        self.m_wheelPayControl =
            require("base.BaseWheel"):create(
            self.m_wheelPayNode,
            15,
            function()
                self:resetUsingPointerSp()
                self:wheelPayOverCallFun(totalCoins)
            end,
            function(distance, targetStep)
                self:setRotionWheel(distance, targetStep)
                self:setRotionOne(distance, targetStep, isBack)
            end
        )
        self:addChild(self.m_wheelPayControl)
        self.m_wheelPayControl:beginWheel()
        self.m_wheelPayControl:recvData(self.m_randomIndex)

        closeBuyTip()
        gLobalSendDataManager:getLogIap():setAddCoins(totalCoins)
        local goodsInfo = {}
        goodsInfo.totalCoins = totalCoins
        gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    end
    -- 购买失败
    local function buyFaildCallFun()
        if isSecond then
            if globalPlatformManager.sendFireBaseLogDirect then
                globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.Roulette_purchase_failed2)
            end
        else
            if globalPlatformManager.sendFireBaseLogDirect then
                globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.Roulette_purchase_failed1)
            end
        end
        self.m_isToSpinTwo = false
        self.m_isCloseClicked = false
        if self.setTouchEnabled ~= nil then
            self:setTouchEnabled(self.m_btnClose, true)
            self.m_btnClose:setVisible(true)
        end
    end

    -- if true == CC_IS_TEST_BUY then
    --     buySuccessCallFun()
    --     return
    -- end
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(wheelPayData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.CASHBONUS_TYPE_NEW, iapId, price, totalCoins, buyRase, buySuccessCallFun, buyFaildCallFun)
end
--[[
    @desc: 付费轮盘旋转结束 回调
    time:2019-04-19 17:02:39
    --@totalCoins:
    @return:
]]
function CashBonusWheelView:wheelPayOverCallFun(totalCoins)
    -- 通知金币变化
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

    self.m_wheelPayJackpotEffect:Hide()
    -- self.m_wheelPayDiamondEffect:Hide()

    self.m_lunpan:setVisible(false)

    if self:isJackpotChange() == true then
        totalCoins = totalCoins + (math.ceil(G_GetMgr(G_REF.CashBonus):getJackpotData()) or 0)
    end
    G_GetMgr(G_REF.CashBonus):setJackpotData(0)
    --设置奖励信息
    self.m_buyResultLb:setString(util_formatCoins(totalCoins, 20))
    local size = self.m_buyResultLb:getSize()
    self.m_buyCoinSp:setPositionX((-1 * size.width / 2) - 3)

    -- 添加金币spine 动画
    self.m_spNode = util_spineCreate("Logon/Other/JINBI", true, false, 1)
    self.m_spNode:setName("JINBI")
    self.m_spNode:setScale(0.7)
    self.m_spNode:setPosition(100, 150)
    util_spinePlay(self.m_spNode, "animation", false)
    self.m_coinSpineNode:addChild(self.m_spNode)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_TWICE_COINS_DROP_DOWN)
        end,
        0.4
    )

    self:runCsbAction(
        "two_jiesuan",
        false,
        function()
            local endPos = globalData.flyCoinsEndPos
            local startPos = self.m_buyResultLb:getParent():convertToWorldSpace(cc.p(self.m_buyResultLb:getPosition()))
            gLobalViewManager:flyCoins(startPos, endPos)
            performWithDelay(
                self,
                function()
                    -- 付费轮盘的结算界面关闭
                    self:closePayWheelReward()
                end,
                2
            )
        end
    )
end

-- PayWheel Add Jackpot start<<<----------------------------------------------------------------------------------
function CashBonusWheelView:isJackpotChange()
    return G_GetMgr(G_REF.CashBonus):getPayWheelData():isJackpotChange(self.m_randomIndex)
    -- return true
end

-- 隐藏spine动画
function CashBonusWheelView:hideSpineAnima(overFunc)
    local fadeOut = cc.FadeOut:create(0.5)
    local callFunc = cc.CallFunc:create(overFunc)
    local seq = cc.Sequence:create(fadeOut, callFunc)
    self.m_spNode:runAction(seq)
end
-- 付费轮盘的结算界面关闭
-- 如果当前次不是jackpot，那么将当前次的轮盘指向的扇形改为jackpot显示
function CashBonusWheelView:closePayWheelReward()
    if self:isJackpotChange() == false then
        self.m_twojiesuan:runAction(cc.FadeOut:create(0.5))
        -- 隐藏金币
        self:hideSpineAnima(
            function()
                -- 显示jackpot数量变化
                self:changeJackpot(
                    function()
                        -- 轮盘再停留2秒后自动移除，关闭轮盘，回到游戏大厅
                        performWithDelay(
                            self,
                            function()
                                self:closeUI()
                            end,
                            2
                        )
                    end
                )
            end
        )
    else
        self:closeUI()
    end
end

-- 购买后添加新逻辑：jackpot数量增加
-- 展示jackpot变化
function CashBonusWheelView:changeJackpot(overFunc)
    local showText = function()
        -- 在摇中的格子变为jackpot时，同时spin按钮中，从小放大显示新的文案【JACKPOT WEDGE ADDED】
        self:showSpinText(overFunc)
    end

    local exchangeJackpot = function()
        -- 然后再播放一个jackpot替换特效，将这个格子替换为jackpot
        self:exchange2Jackpot(showText)
    end

    local selectEffect = function()
        -- 先播放免费轮盘的那个中奖特效
        self:playFreeWheelSelectEffect(exchangeJackpot)
    end

    -- local flyEffect = function()
    --     self:jackpotsFlyEffect()
    -- end

    local autoTurn = function()
        -- 自动转动轮盘【转动2-3周】
        -- 轮盘停留在将要替换为jackpot的那个格子
        self:payWheelAutoTurn(selectEffect)
    end

    -- 去除spin按钮位置的文案，空着
    -- 自动转动轮盘【转动2-3周】
    -- 轮盘停留在将要替换为jackpot的那个格子
    -- 变jackpot的摇奖时，在摇中变jackpot的格子前，增加一个飞往spin按钮的特效
    -- 再播放免费轮盘的那个中奖特效
    -- 再播放一个jackpot替换特效，将这个格子替换为jackpot
    -- 再播放spin按钮中从小放大显示新的文案【JACKPOT WEDGE ADDED】
    self:hideSpinText(autoTurn)
end

function CashBonusWheelView:showSpinText(overFunc)
    self.m_spin_added:setScale(0.1)
    local scale1 = cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.3, 1.5))
    local scale2 = cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 0.9))
    local scale3 = cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.1, 1))
    local seq2 = cc.Sequence:create(scale1, scale2, scale3)
    -- local scale = cc.EaseBackOut:create(cc.ScaleTo:create(0.4, 1));
    local fade = cc.FadeIn:create(0.5)
    local spaw = cc.Spawn:create(fade, seq2)
    local call =
        cc.CallFunc:create(
        function()
            if overFunc then
                overFunc()
            end
        end
    )
    self.m_spin_added:setVisible(true)
    local seq = cc.Sequence:create(spaw, call)
    self.m_spin_added:runAction(seq)
end

function CashBonusWheelView:hideSpinText(overFunc)
    local fade = cc.FadeOut:create(0.5)
    local call =
        cc.CallFunc:create(
        function()
            if overFunc then
                overFunc()
            end
        end
    )
    local seq = cc.Sequence:create(fade, call)
    self.m_spin_wenzi:runAction(seq)
end

function CashBonusWheelView:payWheelAutoTurn(overFunc)
    self:runCsbAction("two_xuanzhuan", true)
    self.m_jackpotIndex = G_GetMgr(G_REF.CashBonus):getPayWheelData():getNewJackpotIndex()
    if self.m_jackpotIndex == nil then
        if overFunc then
            overFunc()
        end
        return
    end

    -- 轮盘开始2秒后播放特效， 为了更好连接上中奖特效
    performWithDelay(
        self,
        function()
            self:jackpotsFlyEffect()
        end,
        1.2
    )

    self.m_wheelPayJackpotControl =
        require("views.cashBonus.CashBonusPayWheelJackpot"):create(
        self.m_wheelPayNode,
        15,
        function()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_WHEEL_BONUS_STOPPED)
            if overFunc then
                overFunc()
            end
        end,
        function(distance, targetStep)
            self:setRotionWheel(distance, targetStep)
        end
    )

    self:addChild(self.m_wheelPayJackpotControl)

    self.m_wheelPayJackpotControl:beginWheel()
    self.m_wheelPayJackpotControl:recvData(self.m_jackpotIndex)
end

function CashBonusWheelView:playFreeWheelSelectEffect(overFunc)
    self:runCsbAction("zhongjiang")

    self.m_payWheelSelectAnim = util_createAnimation("Hourbonus_new/DailyBonusLayer_zj.csb")
    local Node_selectAnim = self:findChild("Node_selectAnim")
    Node_selectAnim:addChild(self.m_payWheelSelectAnim)
    self.m_payWheelSelectAnim:playAction(
        "idle",
        false,
        function()
            if overFunc then
                overFunc()
            end
        end
    )
end

-- 中jackpot特效
function CashBonusWheelView:jackpotsFlyEffect(overFunc)
    self.m_jackpotWheelRewardAnim = util_createAnimation("Hourbonus_new/DailyBonusLayer_turnlight.csb")
    local Node_jackpotEffect = self:findChild("Node_jackpotEffect")
    Node_jackpotEffect:addChild(self.m_jackpotWheelRewardAnim)
    self.m_jackpotWheelRewardAnim:playAction(
        "idle",
        false,
        function()
            if overFunc then
                overFunc()
            end
        end
    )
end

-- 将格子替换为jackpot
function CashBonusWheelView:exchange2Jackpot(overFunc)
    -- self.m_jackpotIndex
    local jackpotNode = self.p_payJackpots[self.m_jackpotIndex - 1]
    if jackpotNode then
        jackpotNode:playExchange2Jackpot(
            function()
                if overFunc then
                    overFunc()
                end
            end
        )
    else
        -- 理论上不应该走这里
        if overFunc then
            overFunc()
        end
    end
end
-- PayWheel Add Jackpot end<<<----------------------------------------------------------------------------------

function CashBonusWheelView:setTouchEnabled(btn, flag)
    btn:setBright(flag)
    btn:setTouchEnabled(flag)
end

function CashBonusWheelView:onKeyBack()
    -- 不在允许按 esc 取消掉了
    -- if true ~= self.m_isInAniTwoIdle then
    --     return
    -- end
    -- if true == self.m_isToSpinTwo then
    --     return
    -- end
    -- if true == self.m_isCloseClicked then
    --     return
    -- end
    -- self:setTouchEnabled(self.m_btn_collect,false)
    -- self:setTouchEnabled(self.m_btnClose,false)
    -- local actionList={}
    -- actionList[#actionList+1] = cc.FadeOut:create(1)
    -- actionList[#actionList+1] = cc.CallFunc:create(function()
    --     self:closeUI()
    -- end)
    -- local seq = cc.Sequence:create(actionList)
    -- self:runAction(seq)
end

return CashBonusWheelView
