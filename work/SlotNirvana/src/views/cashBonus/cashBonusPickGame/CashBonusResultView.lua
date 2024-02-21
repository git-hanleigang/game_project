local CashBonusResultView = class("CashBonusResultView", util_require("base.BaseView"))
CashBonusResultView.stepDelayTime = 0.35
function CashBonusResultView:initUI(data)
    -- setDefaultTextureType("RGBA8888", nil)

    self.m_vaultData = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultGame()
    if self.m_vaultData and tonumber(self.m_vaultData.arenaMultiple or 0) > 0 then
        self:createCsbNode("NewCashBonus/CashBonusNew/CashGameResult_0.csb")
    else
        self:createCsbNode("NewCashBonus/CashBonusNew/CashGameResult.csb")
    end
    self.m_Button_1 = self:findChild("Button_1")
    self.m_Button_1:setVisible(false)
    -- setDefaultTextureType("RGBA4444", nil)
end
function CashBonusResultView:initData(callback)
    self.m_callback = callback

    local sp_vipBoostTip = self:findChild("sp_vipBoostTip")
    if sp_vipBoostTip then
        sp_vipBoostTip:setVisible(false)
        local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if vipBoost and vipBoost:isOpenBoost() then
            sp_vipBoostTip:setVisible(true)
        end
    end

    if G_GetMgr(G_REF.CashBonus):isOpenDeluex() then
        self.m_delux = util_createAnimation("NewCashBonus/CashBonusNew/CashPickDeluxeAdd.csb")
        self.m_delux:findChild("labExra"):setString(globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD .. "%")
        self:updateLabelSize({label = self.m_delux}, 70)
        local nodeDelux = self:findChild("node_delux")
        nodeDelux:addChild(self.m_delux)
    end

    self:runCsbAction("show", false)
end

function CashBonusResultView:initCsbNodes()
    self.m_spCoin = self:findChild("lb_coin")
    self.m_sumCoinsLb = self:findChild("lb_sumCoin")
    self.m_nodeCoin = self:findChild("node_coins")
    self.m_nodeCoin:setVisible(false)
end

function CashBonusResultView:getCoinsFlyEndPos()
    local nodeEff1 = self:findChild("nodeEff1")
    local endPos = nodeEff1:getParent():convertToWorldSpace(cc.p(nodeEff1:getPosition()))
    return endPos
end

--@data: 1  pick 小游戏 展示的入口
function CashBonusResultView:playEffectDropCoins(coins, callback)
    if not self.m_baseCoins then
        self.m_baseCoins = 0
    end
    local addValue = coins / 12
    local time = 13 / 30
    local lbs_jump = self:findChild("lb_baseCoins")
    local newCoins = self.m_baseCoins + coins
    -- util_jumpNum(lbs_jump, self.m_baseCoins, self.m_baseCoins+coins, addValue, 1/30, {30})
    lbs_jump:setString(util_formatCoins(tonumber(newCoins), 4))
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)

    self.m_baseCoins = newCoins
    performWithDelay(
        self,
        function()
            if callback then
                callback()
            end
        end,
        time / 2
    )
end

--@data: 2 展示的入口 {vipMultiply=1  totalCoins=2}
function CashBonusResultView:playEffectDelux(data)
    self.m_data = data
    if G_GetMgr(G_REF.CashBonus):isOpenDeluex() == false then
        self:playEffectVipBonus()
    else
        self.m_delux:playAction(
            "drop",
            false,
            function()
                local addCoins = self.m_baseCoins * globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD / 100
                local addValue = addCoins / 12
                local lbs_jump = self:findChild("lb_baseCoins")
                local newCoins = self.m_baseCoins + addCoins
                -- util_jumpNum(lbs_jump, self.m_baseCoins, self.m_baseCoins+addCoins, addValue, 1/30, {30})
                lbs_jump:setString(util_formatCoins(tonumber(newCoins), 4))
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
                self.m_baseCoins = newCoins
                performWithDelay(
                    self,
                    function()
                        self:playEffectVipBonus()
                    end,
                    15 / 30
                )
            end
        )
    end
end

function CashBonusResultView:playEffectVipBonus(needShowLight)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    local eff = util_createAnimation("NewCashBonus/CashBonusNew/CashPickResultlbEff.csb")
    local nodeEff2 = self:findChild("nodeEff2")
    nodeEff2:addChild(eff)
    eff:playAction("change")

    performWithDelay(
        self,
        function()
            self:findChild("lb_vipBonus"):setString((self.m_data.vipMultiply * 100) .. "%")
        end,
        1 / 5
    )
    performWithDelay(
        self,
        function()
            self:playEffectMult()
        end,
        self.stepDelayTime
    )
end

function CashBonusResultView:playEffectMult()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    local eff = util_createAnimation("NewCashBonus/CashBonusNew/CashPickResultlbEff.csb")
    local nodeEff2 = self:findChild("nodeEff3")
    nodeEff2:addChild(eff)
    eff:playAction("change")

    performWithDelay(
        self,
        function()
            self:findChild("lb_multip"):setString((G_GetMgr(G_REF.CashBonus):getMultipleData().p_value * 100) .. "%")
        end,
        1 / 5
    )

    -- 判断是否有关卡挑战段位加成
    if self.m_vaultData and tonumber(self.m_vaultData.arenaMultiple or 0) > 0 then
        performWithDelay(
            self,
            function()
                self:playEffectDivi(tonumber(self.m_vaultData.arenaMultiple))
            end,
            self.stepDelayTime
        )
    else
        performWithDelay(
            self,
            function()
                self:playEffectSum()
            end,
            self.stepDelayTime
        )
    end
end

function CashBonusResultView:playEffectSum()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)

    local eff = util_createAnimation("NewCashBonus/CashBonusNew/CashPickResultlbEff.csb")
    local nodeEff4 = self:findChild("nodeEff4")
    nodeEff4:addChild(eff)
    eff:playAction(
        "change",
        false,
        function()
        end
    )
    performWithDelay(
        self,
        function()
            -- 327
            self.m_nodeCoin:setVisible(true)
            self.m_sumCoinsLb:setString(util_formatCoins(self.m_data.totalCoins, 9))
            util_alignCenter(
                {
                    {node = self.m_spCoin, alignX = 0},
                    {node = self.m_sumCoinsLb, alignX = 0}
                }
            )
            -- self:updateLabelSize({label = sumCoinsLb, sx = 1, sy = 1}, 327)
        end,
        1 / 5
    )
    self:showCollectBtn()
end

-- 播放段位动画
function CashBonusResultView:playEffectDivi(divi)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    local eff = util_createAnimation("NewCashBonus/CashBonusNew/CashPickResultlbEff.csb")
    local nodeEff2 = self:findChild("nodeEff5")
    nodeEff2:addChild(eff)
    eff:playAction("change")

    performWithDelay(
        self,
        function()
            self:findChild("lb_division"):setString((100 + divi) .. "%")
        end,
        1 / 5
    )

    performWithDelay(
        self,
        function()
            self:playEffectSum()
        end,
        self.stepDelayTime
    )
end

function CashBonusResultView:showCollectBtn()
    self.m_Button_1:setVisible(true)
    -- self.m_Button_1:setScale(0.01)
    -- util_playScaleToAction(self.m_Button_1,2/3,1)
end

function CashBonusResultView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_click then
        return
    end
    self.m_click = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "Button_1" then
        -- self:findChild("Button_1"):setEnabled(false)
        --self:setButtonLabelDisEnabled("Button_1", false)
        self.m_Button_1:setTouchEnabled(false)
        self:showFlyCoins(
            function()
                if self.m_callback then
                    self.m_callback()
                end
            end
        )
    end
end

function CashBonusResultView:showFlyCoins(callback)
    --发送成功
    local flyIcon = self:findChild("Button_1")
    local contet = flyIcon:getContentSize()
    local startPos = flyIcon:convertToWorldSpace(cc.p(contet.width / 2, contet.height / 2))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        self.m_data.totalCoins,
        function()
            if callback then
                callback()
            end
        end
    )
end
function CashBonusResultView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:playEffectMult()
        end,
        ViewEventType.NOTIFY_CASHBONUS_RESULT_LIGHTEND
    )
end
function CashBonusResultView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return CashBonusResultView
