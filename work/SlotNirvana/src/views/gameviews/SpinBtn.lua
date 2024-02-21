--
--
-- 游戏中 spin 按钮
local SpinBtn = class("SpinBtn", util_require("base.BaseView"))

SpinBtn.m_delayTimeHandler = nil -- 延迟一秒执行 auto spin的句柄
SpinBtn.m_bIsAuto = nil --  是否auto
SpinBtn.m_spinBtn = nil --
SpinBtn.m_autoBtn = nil --
SpinBtn.m_stopBtn = nil --

function SpinBtn:initUI(_clickLayer)
    local dcName = ""
    if globalData.slotRunData.isDeluexeClub then
        dcName = "_dc"
    end
    local csbName = "Game/spinBtnNode" .. dcName .. ".csb"
    if globalData.slotRunData.isPortrait == true then
        csbName = "Game/spinBtnNodePortrait" .. dcName .. ".csb"
    end
    self:createCsbNode(csbName)
    self.m_spinBtn = self:findChild("btn_spin")
    self.m_autoBtn = self:findChild("btn_autoBtn")
    self.m_stopBtn = self:findChild("btn_stop")
    self.m_btn_spin_freeGame = self:findChild("btn_spin_freeGame") -- 获得免费spin次数的展示 按钮
    self.countsBg = self:findChild("countsBg")
    if self.countsBg then
        self.countsBg:setVisible(false)
    end
    self.freeCounts = self:findChild("freeCounts")
    if self.freeCounts then
        self.freeCounts:setString("")
    end

    self.m_btn_spin_specile = self:findChild("btn_spin_specile")
    self:changeSpecialSpinbtn(false)

    self.m_autoSpinChooseNode = util_createView("views.gameviews.AutoSpinChooseNode", {25, 50, 100, 200, 500}, handler(self, self.clickAutoSpin))
    self:addChild(self.m_autoSpinChooseNode, -1)
    self.m_autoSpinChooseNode:hide()

    self.m_spinBtn:setVisible(true)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(false)
    self.m_btn_spin_freeGame:setVisible(false)
    self.m_btn_spin_freeGame:setTouchEnabled(false)

    -- 初始化 auto spin 触发的粒子效果
    self.m_autoParticleNode = cc.ParticleSystemQuad:create("Particles/autoSpin.plist") --加粒子效果
    self:addChild(self.m_autoParticleNode)
    self.m_autoParticleNode:setVisible(false)
    self.m_autoParticleNode:stopSystem()

    self.m_autoSpinNum = self:findChild("m_lb_num")
    self.m_autoSpinNumGray = self:findChild("m_lb_num_g")
    if not globalData.slotRunData.m_isNewAutoSpin then
        if self.m_autoSpinNum then
            self.m_autoSpinNum:setVisible(false)
        end
        if self.m_autoSpinNumGray then
            self.m_autoSpinNumGray:setVisible(false)
        end
        self.m_autoBtn:loadTextureNormal("Game/ui/auto_up.png")
        self.m_autoBtn:loadTexturePressed("Game/ui/auto_down.png")
        self.m_autoBtn:loadTextureDisabled("Game/ui/auto_jinyong.png")
    end

    self:addTouchLayerClick(_clickLayer)
end

function SpinBtn:addTouchLayerClick(layer)
    if layer then
        self:addClick(layer)
    end
end

--选择了autospin数量
function SpinBtn:clickAutoSpin(num)
    self:printDebug("-------------------clickAutoSpin")
    self.m_isNetWork = false
    self.m_btnStopTouch = false
    self.m_autoParticleNode:setVisible(false)
    self.m_autoSpinChooseNode:hide()
    if not num or num == 0 then
        return
    end
    globalData.slotRunData.m_autoNum = num - 1
    --    display.spriteChangeImage(self.m_sprWordsOnBtn,"auto.png")
    globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
    globalData.slotRunData.m_isAutoSpinAction = true
    self:updateBtnStatus({SpinBtn_Type.BtnType_Auto, true})
    gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
end

function SpinBtn:clearTimingHandler()
    self:printDebug("-------------------clearTimingHandler")
    self:stopAllActions()
    self.m_autoParticleNode:setVisible(false)
    self.m_autoParticleNode:stopSystem()
end

---
--
function SpinBtn:btnTouchBegan(sender, _touchLayerSpin)
    self:printDebug("-------------------btnTouchBegan")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    self.m_autoSpinChooseNode:hide()
    self.m_bIsAuto = false
    if _touchLayerSpin then
        return
    end

    local Timing = function()
        if globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE then
            --抛出auto spin start
            self.m_bIsAuto = true
            self:clearTimingHandler()

            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_STAR)
            self:printDebug("STR_TOUCH_SPIN_BTN 触发了 auto spin")
            if not globalData.slotRunData.m_isNewAutoSpin then
                gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            end

            self:printDebug("btnTouchBegan 触发了 spin touch  " .. xcyy.SlotsUtil:getMilliSeconds())
        end

        self:clearTimingHandler()
    end
    local isFristSpin = globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1)
    if not isFristSpin and globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        performWithDelay(
            self,
            function()
                -- 播放例子
                if globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE then
                    self.m_autoParticleNode:setVisible(false)
                    self.m_autoParticleNode:resetSystem()
                end
            end,
            0.2
        )
        performWithDelay(self, Timing, 1)
    end
end
---
--
function SpinBtn:btnTouchEnd()
    self:printDebug("-------------------btnTouchEnd")
    self:clearTimingHandler()
    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:printDebug("触发了 respin 按钮点击  btnTouchEnd")
        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        self:printDebug("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        self:printDebug("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    elseif globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == REWAED_FREE_SPIN_MODE then
        -- 处于等待中， 并且活动免费送free spin 那么提前结束倒计时开始执行spin

        self:printDebug("STR_TOUCH_SPIN_BTN 触发了 reward free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        self:printDebug("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            self.m_autoSpinChooseNode:hide()
            self:printDebug("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            self:printDebug("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end
end

---
--
function SpinBtn:autoSpinOver(params)
    self:printDebug("-------------------autoSpinOver")
    --    display.spriteChangeImage(self.m_sprWordsOnBtn,"spin.png")
    globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE

    if globalData.slotRunData.gameSpinStage == WAITING_DATA or globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then
        self.m_autoBtn:setVisible(false)
        self.m_stopBtn:setVisible(true)
        self.m_spinBtn:setVisible(false)
    else
        self.m_autoBtn:setVisible(false)
        self.m_stopBtn:setVisible(false)
        self.m_spinBtn:setVisible(true)

        self.m_spinBtn:setBright(true)
        self.m_spinBtn:setTouchEnabled(true)
        gLobalNoticManager:postNotification("BET_ENABLE", true)
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    -- globalData.slotRunData.m_isAutoSpinAction = false
    self.m_isNetWork = false
end

---
--
function SpinBtn:resetSpinStatus()
    self:printDebug("-------------------resetSpinStatus")
    self:autoSpinOver()
end

function SpinBtn:autoSpinStar(params)
    self:printDebug("-------------------autoSpinStar")
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_ATUO_SPIN_ACTIVE)
    if globalData.slotRunData.m_isNewAutoSpin then
        self.m_autoSpinChooseNode:show()
    else
        self.m_autoBtn:setVisible(true)
        self.m_stopBtn:setVisible(false)
        self.m_spinBtn:setVisible(false)
        globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        globalData.slotRunData.m_isAutoSpinAction = true
    end
end

function SpinBtn:touchCanceled()
    self:clearTimingHandler()
end

function SpinBtn:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params)
            -- self:autoSpinOver(params)
        end,
        ViewEventType.AUTO_SPIN_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(params)
            self:autoSpinOver(params)
        end,
        ViewEventType.AUTO_SPIN_NEWOVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(params)
            self:autoSpinStar(params)
        end,
        ViewEventType.AUTO_SPIN_STAR
    )

    -- 监听按钮的状态变化
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateBtnStatus(params)
        end,
        ViewEventType.NOTIFY_SPIN_BTN_STATUS
    )

    -- 普通点击触发快停监听
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:normalQuickStop()
        end,
        ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP
    )

    --展示特殊spin按钮 监听
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeSpecialSpinbtn(true)
        end,
        ViewEventType.NOTIFY_LEVEL_SHOW_SPECIAL_SPIN
    )
    --隐藏特殊spin按钮 监听
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeSpecialSpinbtn(false)
        end,
        ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:normalSpinStart()
        end,
        ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:normalSpinRecv()
        end,
        ViewEventType.CHECK_QUEST_WITH_SPINRESULT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            if self.showFirstGuide then
                self:showFirstGuide()
            end
        end,
        ViewEventType.NOTIFY_CHANGE_NEWTASK_ZORDER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:rewardSpinStart()
            if data.func and type(data.func) == "function" then
                data.func()
            end
        end,
        ViewEventType.REWARD_FREE_SPIN_START
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:rewardSpinRecv(data)
        end,
        ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, data)
            self:rewardSpinOver()
            if data.func and type(data.func) == "function" then
                data.func()
            end
        end,
        ViewEventType.REWARD_FREE_SPIN_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params ~= nil and params.isShow ~= nil then
                if params.isShow == false then
                    self:clearTimingHandler()
                end
            end
        end,
        ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE
    )
end

-- 更改特殊Spin按钮状态
function SpinBtn:changeSpecialSpinbtn(isShow)
    if globalData.slotRunData.currSpinMode == REWAED_FREE_SPIN_MODE then
        isShow = false
    end
    if self.m_btn_spin_specile then
        self.m_btn_spin_specile:setVisible(isShow)
    end
    self:printDebug("-------------------changeSpecialSpinbtn")
end
function SpinBtn:normalSpinStart()
    self:printDebug("-------------------normalSpinStart")
    self.m_isNetWork = false
    self.m_btnStopTouch = false
end
function SpinBtn:normalSpinRecv()
    self.m_isNetWork = true
    self:printDebug("-------------------normalSpinRecv")
end

function SpinBtn:rewardSpinStart(data)
    self:printDebug("-------------------rewardSpinStart")
    -- 这里只是做了freegame按钮和spin按钮的替换 这里没有auto逻辑 暂时忽略auto按钮
    self.m_btn_spin_freeGame:setVisible(true)

    self.m_spinBtn:setVisible(false)
    self.m_spinBtn:setTouchEnabled(false)

    self.m_btn_spin_specile:setVisible(false)
    self.m_btn_spin_specile:setTouchEnabled(false)

    self.m_isNetWork = false
    self.m_btnStopTouch = false
end

function SpinBtn:rewardSpinRecv(data)
    self.m_isNetWork = true
    self:printDebug("-------------------normalSpinRecv")

    if data and data.rewaedFSData and data.rewaedFSData.leftTimes then
        if self.countsBg then
            self.countsBg:setVisible(true)
        end
        if self.freeCounts then
            self.freeCounts:setString(data.rewaedFSData.leftTimes)
        end
    end
end

function SpinBtn:rewardSpinOver()
    self:printDebug("-------------------rewardSpinOver")
    globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
    -- 这里只是做了freegame按钮和spin按钮的替换 这里没有auto逻辑 暂时忽略auto按钮
    self.m_btn_spin_freeGame:setVisible(false)

    self.m_spinBtn:setVisible(true)
    self.m_spinBtn:setTouchEnabled(true)

    self.m_isNetWork = false
end

---
-- 更改btn 按钮的状态
--
function SpinBtn:updateBtnStatus(param)
    if param == nil or #param == 0 then
        return
    end

    local btnType = param[1]
    local btnEnable = param[2]
    local isNetWork = param[3]
    if btnEnable then
        self:printDebug("通知改变了 按钮状态 " .. btnType .. "  " .. 1)
    else
        self:printDebug("通知改变了 按钮状态 " .. btnType .. "  " .. 2)
    end

    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(false)
    self.m_spinBtn:setVisible(false)
    gLobalNoticManager:postNotification("BET_ENABLE", false)

    if self.m_btn_spin_freeGame and self.m_btn_spin_freeGame:isVisible() then
        return
    end

    local btnNode = nil
    if btnType == SpinBtn_Type.BtnType_Auto then
        btnNode = self.m_autoBtn
        btnNode:setBright(btnEnable)
        btnNode:setTouchEnabled(btnEnable)
        gLobalNoticManager:postNotification("BET_ENABLE", btnEnable)
    elseif btnType == SpinBtn_Type.BtnType_Stop then
        btnNode = self.m_stopBtn
        btnNode:setBright(btnEnable)
        btnNode:setTouchEnabled(btnEnable)
        if globalData.slotRunData.m_isNewAutoSpin and not btnEnable and self.m_isNetWork then
            --灰色stop变灰色spin
            btnNode = self.m_spinBtn
            gLobalNoticManager:postNotification("BET_ENABLE", btnEnable)
        end
    else
        btnNode = self.m_spinBtn
        btnNode:setBright(btnEnable)
        btnNode:setTouchEnabled(btnEnable)

        gLobalNoticManager:postNotification("BET_ENABLE", btnEnable)
        if btnEnable and globalData.slotRunData.gameSpinStage == IDLE then
            --有些关卡特殊玩法结束时候强制设置了成了spin状态没有自动auto
            if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
                --恢复spin状态
                globalData.slotRunData.m_autoNum = 0
                globalData.slotRunData.m_isAutoSpinAction = false
            --改变成auto状态
            -- if globalData.slotRunData.m_isAutoSpinAction and globalData.slotRunData.m_autoNum >0 then
            --     globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            -- end
            end
        end
    end

    if globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_isAutoSpinAction then
        btnNode = self.m_autoBtn
        --请求数据的时候不置灰
        -- if isNetWork then
        btnEnable = true
    -- end
    end

    btnNode:setVisible(true)
    btnNode:setBright(btnEnable)
    btnNode:setTouchEnabled(btnEnable)

    if globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_autoNum then
        if btnEnable then
            self.m_autoSpinNum:setVisible(true)
            self.m_autoSpinNumGray:setVisible(false)
        else
            self.m_autoSpinNum:setVisible(false)
            self.m_autoSpinNumGray:setVisible(true)
        end
        self.m_autoSpinNum:setString(globalData.slotRunData.m_autoNum + 1)
        self.m_autoSpinNumGray:setString(globalData.slotRunData.m_autoNum + 1)
    end
end

function SpinBtn:btnStopTouchBegan()
    self:printDebug("-------------------btnStopTouchBegan")
    globalData.slotRunData.m_autoNum = 0
    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
    end
    globalData.slotRunData.m_isAutoSpinAction = false
end

function SpinBtn:btnStopTouchEnd()
    self:printDebug("-------------------btnStopTouchEnd")
    if self.m_btnStopTouch then
        return
    end

    self.m_btnStopTouch = true

    if globalData.slotRunData.gameSpinStage ~= GAME_MODE_ONE_RUN then
        return
    end

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then -- 自动 模式
        self:autoSpinOver()
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:printDebug("触发了 respin 按钮点击  btnStopTouchEnd")

        gLobalNoticManager:postNotification(ViewEventType.RESPIN_TOUCH_SPIN_BTN)
        return
    end

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then -- 表明滚动了起来。。
        self:normalQuickStop()
    end
end

function SpinBtn:normalQuickStop()
    self:printDebug("-------------------normalQuickStop")
    -- 将stop 按钮置灰
    self.m_stopBtn:setVisible(false)
    self.m_stopBtn:setBright(false)
    self.m_stopBtn:setTouchEnabled(false)
    self.m_spinBtn:setVisible(true)
    self.m_spinBtn:setBright(false)
    self.m_spinBtn:setTouchEnabled(false)
    if globalData.slotRunData.isClickQucikStop or not self.m_isNetWork or globalData.slotRunData.gameSpinStage == QUICK_RUN then
        return
    end
    -- 快速 点击
    gLobalNoticManager:postNotification(ViewEventType.QUICKLY_SPIN_EFFECT) -- 快速spin
    globalData.slotRunData.isClickQucikStop = true
end

function SpinBtn:onExit()
    self:clearTimingHandler()

    gLobalNoticManager:removeAllObservers(self)
end
--[[
    @desc:  处理所有按钮的点击区域
    time:2018-07-09 12:15:54
    --@sender:
	--@eventType:
    @return:
]]
function SpinBtn:baseTouchEvent(sender, eventType)
    local name = sender:getName()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 4})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 5})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 7})
    if name == "btn_spin_specile" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICKED_SPECIAL_SPIN)
        return
    end

    self:resetLocalZorder()

    if name == "touchSpin" then
        if self.m_spinBtn:isVisible() == true and self.m_spinBtn:isTouchEnabled() then
            if eventType == ccui.TouchEventType.began then
                if DEBUG == 2 then
                    local size = sender:getContentSize()
                    local beginPos = sender:getTouchBeganPosition()
                    local vbeginPos = sender:convertToNodeSpace(cc.p(beginPos))
                    if vbeginPos.x >= size.width / 2 then
                        sender:setBackGroundColorOpacity(200)
                    elseif vbeginPos.x < size.width / 2 then
                        sender:setBackGroundColorOpacity(0)
                    end
                end

                self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
                self:btnTouchBegan(sender, true)
                self:playSpinBtnClick()
            elseif eventType == ccui.TouchEventType.ended then
                self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
                self:btnTouchEnd(sender)
            elseif eventType == ccui.TouchEventType.moved then
            end
        elseif self.m_autoBtn:isVisible() == true and self.m_autoBtn:isTouchEnabled() then
        elseif self.m_stopBtn:isVisible() == true and self.m_stopBtn:isTouchEnabled() then
            if eventType == ccui.TouchEventType.began then
                self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
                self:btnStopTouchBegan(sender)
            elseif eventType == ccui.TouchEventType.ended then
                self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
                self:btnStopTouchEnd(sender)
            end
        end
    elseif name == "btn_spin" then
        if eventType == ccui.TouchEventType.began then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            self:btnTouchBegan(sender)
            self:playSpinBtnClick()
        elseif eventType == ccui.TouchEventType.ended then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            self:btnTouchEnd(sender)
        end
    elseif name == "btn_autoBtn" then
        if eventType == ccui.TouchEventType.began then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            self:btnStopTouchBegan(sender)
            if self.m_isNetWork then
                self:updateBtnStatus({SpinBtn_Type.BtnType_Spin, false})
            else
                self:updateBtnStatus({SpinBtn_Type.BtnType_Stop, false})
            end
        elseif eventType == ccui.TouchEventType.ended then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            if self.m_isNetWork and self.m_stopBtn:isTouchEnabled() then
                self:btnStopTouchEnd(sender)
            end
        end
    elseif name == "btn_stop" then
        if eventType == ccui.TouchEventType.began then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            self:btnStopTouchBegan(sender)
        elseif eventType == ccui.TouchEventType.ended then
            self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
            self:btnStopTouchEnd(sender)
        end
    end

    if eventType == ccui.TouchEventType.canceled then
        self:printDebug("-------------------baseTouchEvent name =" .. name .. " eventType =" .. eventType)
        self:touchCanceled(sender)
    end
end

function SpinBtn:playSpinBtnClick()
    gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
end

--打印开关
function SpinBtn:printDebug(strMsg)
    --测试打印
    -- release_print(strMsg)
end

--TODO-NEWGUIDE
function SpinBtn:setGuideScale(scale)
    self.m_guideScale = scale
end
--TODO-NEWGUIDE
function SpinBtn:showFirstGuide()
    if self.m_isShowFirstGuide then
        return
    end
    self.m_isShowFirstGuide = true
    performWithDelay(
        self,
        function()
            if not self.m_lastPos then
                self.m_lastPos = cc.p(self:getPosition())
                self.m_lastNode = self:getParent()
                self.m_lastZorder = self:getLocalZOrder()
                self.m_lastScale = self:getScale()
                local wordPos = self.m_lastNode:convertToWorldSpace(self.m_lastPos)
                util_changeNodeParent(gLobalViewManager:getViewLayer(), self, ViewZorder.ZORDER_GUIDE + 1)
                self:setPosition(wordPos)
                if self.m_guideScale then
                    self:setScale(self.m_guideScale)
                end
                -- 银行关卡 引导 按钮pad下太大了
                if not globalData.slotRunData.isPortrait and CC_RESOLUTION_RATIO == 2 then
                    self:setScale(1024 / 1378)
                end
                if not self.m_guideArrow then
                    local arrow = util_createView("views.newbieTask.GuideArrowNode")
                    gLobalViewManager:getViewLayer():addChild(arrow, ViewZorder.ZORDER_GUIDE + 1)
                    arrow:showIdle(2)
                    -- csc 2021-11-18 16:40:29 修改动画展示
                    arrow:setPosition(wordPos.x + 40, wordPos.y + 70) -- csc 2021-11-04 16:37:22 修改坐标
                    self.m_guideArrow = arrow
                end
            end
        end,
        2.5
    )
end
--TODO-NEWGUIDE
function SpinBtn:resetLocalZorder()
    if self.m_lastPos then
        util_changeNodeParent(self.m_lastNode, self, self.m_lastZorder)
        self:setPosition(self.m_lastPos)
        self:setScale(self.m_lastScale)
        self.m_lastPos = nil
        globalNoviceGuideManager:removeMaskUI()
    end
    if self.m_guideArrow then
        self.m_guideArrow:removeFromParent()
        self.m_guideArrow = nil
    end
end

return SpinBtn
