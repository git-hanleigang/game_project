---普通结算弹窗

local DaliyBonusReslutLayer = class("DaliyBonusReslutLayer", BaseLayer)
DaliyBonusReslutLayer.m_coinNum = nil
DaliyBonusReslutLayer.m_bHasDeluexe = nil

function DaliyBonusReslutLayer:initDatas(endCallFunc, bHasDeluexe)
    self:setLandscapeCsbName("Hourbonus_new3/DailyBonusResultLayer.csb")
    self.endCallFunc = endCallFunc
    self.m_bHasDeluexe = bHasDeluexe
    self.m_coinNum = 0
    self.m_isCollected = false
end

function DaliyBonusReslutLayer:initUI()
    DaliyBonusReslutLayer.super.initUI(self)

    self.m_nodeDivi = self:findChild("node_division")
    self.sp_coin = self:findChild("sp_coin")
    self.lb_coin = self:findChild("lb_coin")
    self.m_btn = self:findChild("spinnow")
    self.m_btn:setTouchEnabled(false)
end

function DaliyBonusReslutLayer:setWheelType(nType)
    self.m_wheelType = nType
end

function DaliyBonusReslutLayer:setWinCoinNum(num)
    self.lb_coin:setString(util_formatCoins(tonumber(num), 11))
    util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})
    self.m_coinNum = tonumber(num)
end

function DaliyBonusReslutLayer:getWinCoinNum()
    return self.m_coinNum
end

function DaliyBonusReslutLayer:playHideAction()
    DaliyBonusReslutLayer.super.playHideAction(self, "stop")
end

function DaliyBonusReslutLayer:closeUI(closeEndFunc)
    local _callback = function()
        util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})
        if closeEndFunc then
            closeEndFunc()
        end
        gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusViewClose.mp3")
    end
    DaliyBonusReslutLayer.super.closeUI(self, _callback)
end

function DaliyBonusReslutLayer:getCoinLabelWorldPos()
    local posWorld = self:findChild("spinnow"):getParent():convertToWorldSpace(cc.p(self:findChild("spinnow"):getPosition()))
    return posWorld
end

function DaliyBonusReslutLayer:playShowAction()
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusResultShow.mp3")
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusResultShowLayerDown.mp3")
        end,
        0.9
    )

    if self.m_bHasDeluexe then
        local bonusCfg = G_GetMgr(G_REF.CashBonus):getBonusConfig()
        if bonusCfg and bonusCfg.commonCsb then
            -- self.m_delux = util_createAnimation("Hourbonus_new3/CashPickDeluxeAdd.csb")
            self.m_delux = util_createAnimation(bonusCfg.commonCsb.CashPickDeluxeAdd)
            self.m_delux:findChild("labExra"):setString(globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD .. "%")
            local nodeDelux = self:findChild("nodeClub")
            self.m_delux:setPosition(cc.p(619, -87))
            nodeDelux:addChild(self.m_delux)
            util_setCascadeOpacityEnabledRescursion(nodeDelux, true)
        end
    end

    DaliyBonusReslutLayer.super.playShowAction(self, "pull", false)
end

function DaliyBonusReslutLayer:onShowedCallFunc()
    local leagueBonusDis = 0
    local leagueDivi = 0
    local wheelData = nil
    if self.m_wheelType == WHEELTYPE.WHEELTYPE_NORMAL then
        wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    end
    if wheelData then
        leagueBonusDis = wheelData:getArenaMultiple()
        leagueDivi = wheelData.m_arneaDivision
    end

    local endActionCall = function()
        self.m_btn:setTouchEnabled(true)
        DaliyBonusReslutLayer.super.onShowedCallFunc(self)
    end
    util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})

    -- 添加金币动画
    local addCoinsAction = function(actType, callback)
        local addCoins = 0
        local addDis = 1
        if actType == "Deluexe" then
            addDis = addDis * (1 + globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD / 100)
        elseif actType == "League" then
            addDis = addDis * (1 + leagueBonusDis / 100)
        end
        addCoins = self.m_coinNum * (addDis - 1)

        local addValue = addCoins / 12
        local lbs_jump = self.lb_coin
        local _callFunc = function()
            if not tolua.isnull(self.sp_coin) and not tolua.isnull(self.lb_coin) then
                util_alignCenter({{node = self.sp_coin}, {node = self.lb_coin}})
            end
            if callback then
                callback()
            else
                endActionCall()
            end
        end
        util_jumpNum(lbs_jump, self.m_coinNum, self.m_coinNum + addCoins, addValue, 1 / 30, {11}, nil, nil, _callFunc)

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
        self.m_coinNum = self.m_coinNum + addCoins
    end

    -- 关卡比赛段位加成
    local leagueDivAction = function()
        local diviNode, diviAni = util_csbCreate("Hourbonus_new3/DailyBonusResultLayer_division.csb")
        local spIcon = diviNode:getChildByName("Sprite_1")
        if spIcon then
            spIcon:setTexture("Hourbonus_new3/UI/leagues_rank" .. leagueDivi .. ".png")
        end
        local _lbDis = spIcon:getChildByName("lb1")
        if _lbDis then
            _lbDis:setString(leagueBonusDis .. "%")
        end

        self.m_nodeDivi:addChild(diviNode)
        util_csbPlayForKey(
            diviAni,
            "actionframe",
            false,
            function()
                addCoinsAction("League")
            end,
            60
        )
    end

    self:runCsbAction("idle", true)

    if self.m_bHasDeluexe then
        performWithDelay(
            self,
            function()
                if self.m_delux then
                    self.m_delux:playAction(
                        "drop",
                        false,
                        function()
                            addCoinsAction(
                                "Deluexe",
                                function()
                                    if leagueBonusDis > 0 then
                                        leagueDivAction()
                                    else
                                        endActionCall()
                                    end
                                end
                            )
                        end
                    )
                    self.m_delux:runAction(cc.MoveBy:create(0.2, cc.p(100, 0)))
                else
                    if leagueBonusDis > 0 then
                        leagueDivAction()
                    else
                        endActionCall()
                    end
                end
            end,
            0.7
        )
    else
        if leagueBonusDis > 0 then
            leagueDivAction()
        else
            endActionCall()
        end
    end
end

function DaliyBonusReslutLayer:onClickMask()
    self:onClickSpinNow()
end

function DaliyBonusReslutLayer:onClickSpinNow()
    self.m_btn:setTouchEnabled(false)
    if self.m_isCollected then
        return
    end
    -- self:closeUI()
    self.endCallFunc()

    self.m_isCollected = true
end

function DaliyBonusReslutLayer:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "spinnow" then
        self:onClickSpinNow()
    end
end

----------DialyBonus--------end
return DaliyBonusReslutLayer
