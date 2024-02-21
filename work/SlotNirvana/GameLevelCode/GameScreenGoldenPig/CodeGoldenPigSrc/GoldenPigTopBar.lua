---
--xhkj
--2018年6月11日
--GoldenPigTopBar.lua

local GoldenPigTopBar = class("GoldenPigTopBar", util_require("base.BaseView"))

--收集进度条初始进度
local COLLECT_PROGRESS_BASE = 3

--收集进度小目标补齐量(为了涨收集进度不被奖励图标遮挡)
local COLLECT_PROGRESS_GAP = 6.5

--收集进度条小目标标准
local COLLECT_PROGRESS_AIM = {
    24.5,
    52.5,
    98
}

--收集进度条动画列表
local COLLECT_PROGRESS_ANIMATION = {
    TOLOCK = "suoding2",
    LOCK = "suoding",
    UNLOCK = "jiesuo",
    NORMAL = "idle",
    COLLECT = "shoujiFK",
    FULL_PROGRESS_1 = "jiman1",
    FULL_PROGRESS_2 = "jiman2",
    FULL_PROGRESS_3 = "jiman3"
}

function GoldenPigTopBar:initUI(data)
    self.m_machine = data.machine

    local resourceFilename = "GoldenPig_Socre_Top.csb"
    self:createCsbNode(resourceFilename)
    self:initCollectProgress()
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self.collectNode = self:findChild("jindutiao")

    self.m_clickOver = true

    self.m_ComingIn = true

    self.m_tip = util_createAnimation("GoldenPig_Tips.csb")

    self.m_machine:findChild("Tips"):addChild(self.m_tip)
    self.m_tip:findChild("miaoshuzi2"):setVisible(false)

    self.m_tip:runCsbAction(
        "start",
        false,
        function()
            self.m_ComingIn = false
            self.m_tip:runCsbAction("idleframe", true)
            self:findChild("jiesuoclick"):setVisible(false)
            self:findChild("click"):setVisible(false)

            self:setTouchLayer()
            self.m_execute =
                performWithDelay(
                self,
                function()
                    self.m_execute = nil
                    self:removeTip()
                end,
                2
            )
        end
    )
end

function GoldenPigTopBar:playIdle()
    self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
end
function GoldenPigTopBar:playLock()
    self:runCsbAction(COLLECT_PROGRESS_ANIMATION.LOCK, true)
end

function GoldenPigTopBar:setFadeOutAction()
    self.m_csbNode:runAction(cc.FadeOut:create(1))
end

function GoldenPigTopBar:initMachine(machine)
    if not self.m_machine then
        self.m_machine = machine
    end
end

function GoldenPigTopBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function GoldenPigTopBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self.m_csbOwner["m_lb_grand"], 1, true)
    self:changeNode(self.m_csbOwner["m_lb_major"], 2, true)
    self:changeNode(self.m_csbOwner["m_lb_minor"], 3)
    self:changeNode(self.m_csbOwner["m_lb_mini"], 4)
    self:updateSize()
end

function GoldenPigTopBar:updateSize()
    local label1 = self.m_csbOwner["m_lb_grand"]
    local label2 = self.m_csbOwner["m_lb_major"]
    local info1 = {label = label1}
    local info2 = {label = label2}
    self:updateLabelSize(info1, 216)

    self:updateLabelSize(info2, 200)

    local label3 = self.m_csbOwner["m_lb_minor"]
    local label4 = self.m_csbOwner["m_lb_mini"]
    local info3 = {label = label3}
    local info4 = {label = label4}
    self:updateLabelSize(info3, 190, {info4})
end

function GoldenPigTopBar:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 30))
end

function GoldenPigTopBar:toAction(actionName)
    self:runCsbAction(actionName)
end

--收集相关
--初始化进度条
function GoldenPigTopBar:initCollectProgress()
    self.m_collectProgressPer = COLLECT_PROGRESS_BASE
    self.m_isLock = false
    self.m_isShow = true

    self:findChild("jiesuoclick"):setVisible(false)

    self.m_collectProgress = self:findChild("LoadingBar")
    self.m_collectProgress:setPercent(COLLECT_PROGRESS_BASE)

    self.m_collectCoinList = {}
    for i = 1, 2 do
        local coin = {}
        coin.coinNode = self:findChild("coinNode_" .. i)
        coin.coinSp, coin.coinAct = util_csbCreate("GoldenPig_Socre_Top_0.csb")
        util_csbPlayForKey(coin.coinAct, "idle", true)
        coin.coinNode:addChild(coin.coinSp)

        table.insert(self.m_collectCoinList, coin)
    end

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("click_0"))
    self:addClick(self:findChild("click_1"))
    self:addClick(self:findChild("click_2"))
    self:addClick(self:findChild("click_3"))
    self:addClick(self:findChild("click_4"))

    self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
end

--重置进度条
function GoldenPigTopBar:resetCollectProgress()
    self.m_collectProgressPer = COLLECT_PROGRESS_BASE

    if self.m_collectProgress then
        self.m_collectProgress:setPercent(COLLECT_PROGRESS_BASE)
    end

    self:resetCollectCoinAnim()

    self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
end

function GoldenPigTopBar:setCollectCoinIsVisible(isVisible)
    for i, v in ipairs(self.m_collectCoinList) do
        local coinNode = v.coinNode
        coinNode:setVisible(isVisible)
    end
end

function GoldenPigTopBar:resetCollectCoinAnim()
    for i, v in ipairs(self.m_collectCoinList) do
        local coinAct = v.coinAct
        util_csbPlayForKey(coinAct, "idle", true)
    end
end

function GoldenPigTopBar:collectCoinRunAnim(curAnimIndex, isOwn)
    for i, v in ipairs(self.m_collectCoinList) do
        local coinAct = v.coinAct
        if i < curAnimIndex then
            util_csbPlayForKey(coinAct, "idle2", true)
        elseif i == curAnimIndex then
            if isOwn then
                util_csbPlayForKey(coinAct, "idle2", true)
            else
                util_csbPlayForKey(
                    coinAct,
                    "jiman",
                    false,
                    function()
                        util_csbPlayForKey(coinAct, "idle2", true)
                    end
                )
            end
        else
            util_csbPlayForKey(coinAct, "idle", true)
        end
    end
end

--设置进度条数据
function GoldenPigTopBar:setCollectProgressData(curCollectIndex, curLeftNum, curTotalNum, isAnim, callBackFun)
    local curPer = COLLECT_PROGRESS_BASE
    local curGapPer = 0 --小进度区间差值 需要减去小进度补齐量
    local isUp = curLeftNum == 0

    for i = 1, #COLLECT_PROGRESS_AIM do
        if i < curCollectIndex then
            curPer = COLLECT_PROGRESS_AIM[i]
        end
    end

    if curCollectIndex > 1 then
        curGapPer = COLLECT_PROGRESS_AIM[curCollectIndex] - COLLECT_PROGRESS_AIM[curCollectIndex - 1] - COLLECT_PROGRESS_GAP
        curPer = curPer + COLLECT_PROGRESS_GAP
    else
        curGapPer = COLLECT_PROGRESS_AIM[curCollectIndex] - curPer
    end

    curPer = (curTotalNum - curLeftNum) / curTotalNum * curGapPer + curPer
    curPer = math.max(curPer, COLLECT_PROGRESS_BASE)

    local isAdd = curPer > self.m_collectProgressPer
    self.m_collectProgressPer = curPer

    --这个是为了 开启新进度 要做个补齐 让进度条露出来不被奖励遮挡
    --此时curPer 必然比self.m_collectProgressPer 要大 因为加了补齐量
    --如果此时有新收集 没问题 自然涨上去
    --没有收集 就不涨了 等下次收集再涨
    if curLeftNum == curTotalNum then
        isAdd = false
    end

    if isAnim then
        if self.m_progressAct then
            self:stopAction(self.m_progressAct)
            self.m_progressAct = nil
        end

        if isAdd then
            local progressWidth = 930

            local progressFKParticle2 = self:findChild("Particle_2")
            local progressFKParticle3 = self:findChild("Particle_3")
            progressFKParticle3:setVisible(true)
            progressFKParticle3:stopSystem()
            progressFKParticle3:resetSystem()

            self:runCsbAction(
                COLLECT_PROGRESS_ANIMATION.COLLECT,
                false,
                function()
                    if not isUp then
                        self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
                    end
                end
            )

            self.m_progressAct =
                schedule(
                self,
                function()
                    local newPercent = self.m_collectProgress:getPercent() + 0.5

                    if newPercent > self.m_collectProgressPer then
                        newPercent = self.m_collectProgressPer

                        self:stopAction(self.m_progressAct)
                        self.m_progressAct = nil

                        progressFKParticle2:setPositionX(self.m_collectProgressPer / 100 * progressWidth)
                        progressFKParticle2:setVisible(true)
                        progressFKParticle2:stopSystem()
                        progressFKParticle2:resetSystem()

                        --当前小关进度完成
                        if isUp then
                            self:runCollectProgressAnimation(callBackFun)
                        else
                            if callBackFun then
                                callBackFun()
                            end
                        end
                    end

                    progressFKParticle3:setPositionX(newPercent / 100 * progressWidth)

                    self.m_collectProgress:setPercent(newPercent)
                end,
                0.02
            )
        else
            -- self.m_collectProgress:setPercent(self.m_collectProgressPer)

            if callBackFun then
                callBackFun()
            end
        end
    else
        -- self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true) --111111111111

        if callBackFun then
            callBackFun()
        end

        self.m_collectProgress:setPercent(self.m_collectProgressPer)

        local curAnimIndex = 0

        for i = 1, #COLLECT_PROGRESS_AIM do
            if self.m_collectProgressPer >= COLLECT_PROGRESS_AIM[i] then
                curAnimIndex = i
            end
        end

        self:collectCoinRunAnim(curAnimIndex, true)
    end
end

--根据当前收集进度播放动画
function GoldenPigTopBar:runCollectProgressAnimation(callBackFun)
    local animName = COLLECT_PROGRESS_ANIMATION.NORMAL
    local curAnimIndex = 0

    for i = 1, #COLLECT_PROGRESS_AIM do
        if self.m_collectProgressPer >= COLLECT_PROGRESS_AIM[i] then
            animName = COLLECT_PROGRESS_ANIMATION["FULL_PROGRESS_" .. i]
            curAnimIndex = i
        end
    end

    if animName ~= COLLECT_PROGRESS_ANIMATION.NORMAL then
        if curAnimIndex == #COLLECT_PROGRESS_AIM then
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_big_start.mp3")
        else
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_small_start.mp3")
        end

        self:collectCoinRunAnim(curAnimIndex, false)

        self:runCsbAction(
            animName,
            false,
            function()
                performWithDelay(
                    self,
                    function()
                        if callBackFun then
                            callBackFun()
                        end
                    end,
                    0.5
                )

                self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
            end
        )
    else
        if callBackFun then
            callBackFun()
        end

        self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
    end
end

--获取进度条起始点
function GoldenPigTopBar:getCollectStartPos()
    local node = self:findChild("Sprite_4")
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return worldPos
end

function GoldenPigTopBar:showIsLock(isLock)
    if self.m_tip and not self.m_ComingIn then
        self:removeTip()
    end

    self.m_isLock = isLock

    self:findChild("click"):setVisible(false)
    self:findChild("jiesuoclick"):setVisible(false)
    if isLock then
        self:showLock()
    else
        self:showUnLock()
    end
end

function GoldenPigTopBar:showLock()
    --reset
    util_resetCsbAction(self.m_csbAct)

    self:findChild("jiesuoclick"):setVisible(false)
    self:findChild("click"):setVisible(false)
    self:runCsbAction(
        COLLECT_PROGRESS_ANIMATION.TOLOCK,
        false,
        function()
            self:runCsbAction(COLLECT_PROGRESS_ANIMATION.LOCK, true)
            self:findChild("click"):setVisible(true)
            self:findChild("jiesuoclick"):setVisible(false)
        end
    )
end

function GoldenPigTopBar:showUnLock()
    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_unlock.mp3")

    --reset
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction(
        COLLECT_PROGRESS_ANIMATION.UNLOCK,
        false,
        function()
            self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
            self:findChild("jiesuoclick"):setVisible(true)
        end
    )

    local particle = self:findChild("Particle_4")
    if particle then
        particle:setVisible(true)
        particle:stopSystem()
        particle:resetSystem()
    end
end

function GoldenPigTopBar:isShowCollectProgress(isShow, isAnim)
    if self.m_isShow == isShow then
        return
    end

    self.m_isShow = isShow
    local animName = ""

    if self.m_isShow then
        if self.m_isLock then
            animName = "change_idle2"
        else
            animName = "change_idle"
        end
    else
        if self.m_isLock then
            animName = "change2"
        else
            animName = "change"
        end
    end

    if animName ~= "" then
        --得先停下 不然可能被收集的回调打断
        util_resetCsbAction(self.m_csbAct)

        if isAnim then
            self:runCsbAction(
                animName,
                false,
                function()
                    if self.m_isShow and not self.m_isLock then
                        self:runCsbAction(COLLECT_PROGRESS_ANIMATION.NORMAL, true)
                    end
                end
            )
        else
            local animInfo = util_csbGetInfo(self.m_csbAct, animName)
            util_csbPlayForIndex(self.m_csbAct, animInfo.endIndex, animInfo.endIndex, false)
        end
    end
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取
--默认按钮监听回调
function GoldenPigTopBar:clickFunc(sender)
    if self.m_machine:getCurrSpinMode() == RESPIN_MODE then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self.m_machine:updateBetToCanCollect()
        if self.m_isLock == false then
            self:showUnLock()

            self:findChild("jiesuoclick"):setVisible(true)
            self:findChild("click"):setVisible(false)
        end
    end

    if name == "click_0" or name == "click_1" or name == "click_2" or name == "click_3" or name == "click_4" then
        if self.m_clickOver == true then
            return
        end

        if not self:findChild("jiesuoclick"):isVisible() then
            return
        end
        self.m_isLock = false
        self.m_clickOver = true

        self.m_tip = util_createAnimation("GoldenPig_Tips.csb")

        if name == "click_0" then
            self.m_machine:findChild("Tips"):addChild(self.m_tip)
            self.m_tip:findChild("miaoshuzi2"):setVisible(false)
        elseif name == "click_1" then
            self.m_machine:findChild("Tips"):addChild(self.m_tip)
            self.m_tip:findChild("miaoshuzi2"):setVisible(false)
        elseif name == "click_2" then
            self.m_machine:findChild("Tips"):addChild(self.m_tip)
            self.m_tip:findChild("miaoshuzi2"):setVisible(false)
        elseif name == "click_3" then
            self.m_machine:findChild("Tips_1"):addChild(self.m_tip)
            self.m_tip:findChild("miaoshuzi1"):setVisible(false)
        elseif name == "click_4" then
            self.m_machine:findChild("Tips_2"):addChild(self.m_tip)
            self.m_tip:findChild("miaoshuzi1"):setVisible(false)
        end

        self:findChild("click"):setVisible(false)
        self:findChild("jiesuoclick"):setVisible(false)

        self.m_tip:runCsbAction(
            "start",
            false,
            function()
                self.m_tip:runCsbAction("idleframe", true)
                self:findChild("jiesuoclick"):setVisible(false)
                self:findChild("click"):setVisible(false)

                self:setTouchLayer()
                self.m_execute =
                    performWithDelay(
                    self,
                    function()
                        self.m_execute = nil
                        self:removeTip()
                    end,
                    2
                )
            end
        )
    end
end

function GoldenPigTopBar:removeTip()
    self:stopAction(self.m_execute)

    if self.m_tip ~= nil then
        local eventDispatcher = self.m_tip:getEventDispatcher()
        eventDispatcher:removeEventListenersForTarget(self.m_tip, true)
        self.m_tip:runCsbAction(
            "over",
            false,
            function()
                if self.m_tip then
                    self.m_tip:removeFromParent()
                    self.m_tip = nil
                    self:findChild("jiesuoclick"):setVisible(true)
                    self.m_clickOver = false
                end
            end
        )
    end
end

function GoldenPigTopBar:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:removeTip()
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_tip:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_tip)
end

return GoldenPigTopBar
