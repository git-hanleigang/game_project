local CashBonusPickGameView = class("CashBonusPickGameView", util_require("base.BaseView"))
function CashBonusPickGameView:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    -- setDefaultTextureType("RGBA8888", nil)

    local maskUI = util_newMaskLayer()
    self:addChild(maskUI, -1)
    maskUI:setOpacity(192)

    self:createCsbNode("NewCashBonus/CashBonusNew/CashPickGameLayer.csb", isAutoScale)

    self.m_resultNode = self:findChild("node_result")
    self:showBg()

    self:initBox()

    self:showVipAdd()

    self:showMultAdd()

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASHBONUS_FLYGOLD)

    self:refreshTitle()
    self:runCsbAction("show")
    -- setDefaultTextureType("RGBA4444", nil)
end

function CashBonusPickGameView:initDatas(_type)
    self.m_type = _type
end

function CashBonusPickGameView:refreshTitle()
    local Image_vault_sliver = self:findChild("Image_vault_sliver")
    local Image_vault_gold = self:findChild("Image_vault_gold")
    local Image_sliver = self:findChild("Image_sliver")
    local Image_gold = self:findChild("Image_gold")

    if Image_vault_sliver then
        Image_vault_sliver:setVisible(self.m_type == "SILVER")
    end
    if Image_vault_gold then
        Image_vault_gold:setVisible(self.m_type == "GOLD")
    end
    if Image_sliver then
        Image_sliver:setVisible(self.m_type == "SILVER")
    end
    if Image_gold then
        Image_gold:setVisible(self.m_type == "GOLD")
    end
end

--倍增器加成
function CashBonusPickGameView:showMultAdd()
    self.m_multy = util_createView("views.cashBonus.DailyBonus.DailybonusRewardX")
    self:findChild("Node_mult"):addChild(self.m_multy)
    self.m_multy:playIdleAction()
end

--三个格子
function CashBonusPickGameView:initBox()
    local cBGameData = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultGame()

    self.m_boxList = {}
    self.m_boxTextList = {}

    for i = 1, 1 do
        local view = util_createView("views.cashBonus.cashBonusPickGame.CashBonusPickGameBox")
        view:initData(
            {type = cBGameData.type, index = i},
            function(index)
                self:selectBox(index)
            end
        )
        self:findChild("Node_box" .. i):addChild(view)
        self.m_boxList[#self.m_boxList + 1] = view

        local textView = util_createView("views.cashBonus.cashBonusPickGame.CashBonusPickGameBoxText", {type = cBGameData.type, index = i})
        self:findChild("Node_boxText" .. i):addChild(textView)
        self.m_boxTextList[#self.m_boxTextList + 1] = textView
    end
end

function CashBonusPickGameView:selectBox(index)
    G_GetMgr(G_REF.CashBonus):getRunningData():sortCashVaultGameBoxOrder(index)
    local cBGameData = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultGame()
    if self.m_vipAddview then
        self.m_vipAddview:closeUI()
    end
    if self.m_multy then
        self.m_multy:playOverAction()
    end
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "over",
                false,
                function()
                    self:runCsbAction("idel1")
                    self:refreshTitle()
                end,
                30
            )
        end,
        5 / 6
    )
    self.m_flyDataList = {}
    local selectInnerFun = function(delayTime, boxItem, textItem, boxData, callFunc2)
        boxItem:setSelect(
            delayTime,
            boxData,
            function()
                textItem:playShowAnim()
            end,
            callFunc2
        )
        textItem:initData(boxData, self.m_flyDataList)
    end
    local needShowResult = true
    for i = 1, #self.m_boxList do
        if i == index then -- 直接弹出
            selectInnerFun(
                0.1,
                self.m_boxList[i],
                self.m_boxTextList[i],
                cBGameData.boxes[i],
                function()
                    self:showCoinsMerge()
                end
            )
        end
    end
end
function CashBonusPickGameView:showCoinsMerge()
    self.m_showCoins = self.m_flyDataList[1].data.coins
    self.m_flyItem = self:createFlyText(self.m_flyDataList[1])
    self:showResult()
end

--显示结果
function CashBonusPickGameView:showResult()
    self.m_resultView = util_createView("views.cashBonus.cashBonusPickGame.CashBonusResultView")
    self.m_resultNode:addChild(self.m_resultView)
    self.m_resultView:setLocalZOrder(-10)
    -- local worldPos = cc.p(0, 0)
    -- local pos = self.m_resultView:getParent():convertToNodeSpace(cc.p(worldPos.x, -10))
    --self.m_resultView:setPositionY(pos.y)

    self.m_resultView:initData(
        function()
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end
    )

    performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                local endPos = self.m_resultView:getCoinsFlyEndPos()
                local pos = self.m_resultNode:convertToNodeSpace(cc.p(endPos))
                self:flyCoinsIcon(self.m_flyItem, pos)
            end
        end,
        21 / 30
    )
end

function CashBonusPickGameView:flyCoinsIcon(item, endPos)
    item:playAction("animation0")
    util_playMoveToAction(
        item,
        13 / 30,
        endPos,
        function()
            item:setVisible(false)
        end
    )
    performWithDelay(
        self,
        function()
            self.m_resultView:playEffectDropCoins(
                self.m_showCoins,
                function()
                    local cBGameData = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultGame()
                    self.m_resultView:playEffectDelux(
                        {
                            vipMultiply = cBGameData.vipMultiply,
                            totalCoins = cBGameData.totalCoins,
                            needPlayLight = true
                        }
                    )
                end
            )
        end,
        13 / 30
    )
end

--创建fly动画
function CashBonusPickGameView:createFlyText(tempData)
    local flyIcon = util_createAnimation("NewCashBonus/CashBonusNew/CashPickGameFlyText.csb")
    self.m_resultNode:addChild(flyIcon)
    flyIcon:setVisible(true)

    local startPos = tempData.startPos
    local pos = self.m_resultNode:convertToNodeSpace(cc.p(startPos))
    flyIcon:setPosition(pos)

    self:setTestStr(flyIcon, self.m_showCoins)
    return flyIcon
end

--vip加成
function CashBonusPickGameView:showVipAdd()
    self.m_vipAddview = util_createView("views.cashBonus.cashBonusPickGame.CashBonusVipAddView")
    self:findChild("node_vipAdd"):addChild(self.m_vipAddview)

    -- local worldPos = cc.p(0, 0)
    -- local pos = self.m_vipAddview:getParent():convertToNodeSpace(cc.p(worldPos.x, 8))
    -- self.m_vipAddview:setPositionY(pos.y)

    self.m_vipAddview:initData()
    self.m_vipAddview:runShowAction()
end

--背景
function CashBonusPickGameView:showBg()
    local bg = util_createView("views.cashBonus.cashBonusPickGame.CashBonusPickGameBgView", self.m_type)
    self:findChild("bgNode"):addChild(bg)
    bg:playNodeAction()
    -- bg:playAction(
    --     "show",
    --     false,
    --     function()
    --         bg:playAction("idle", true)
    --     end
    -- )
end

function CashBonusPickGameView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:findChild("bg"):setCascadeOpacityEnabled(true)
    self:setCascadeOpacityEnabled(true)
    local closeName = "close"
    if self.m_flyDataList and #self.m_flyDataList == 3 then
        closeName = "close2"
    end
    self:runCsbAction(
        closeName,
        false,
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )
end

function CashBonusPickGameView:setTestStr(item, coins)
    local uiList = {}
    local icon = item:findChild("coins_1")
    table.insert(uiList, {node = icon})
    local lbsCoins = item:findChild("BitmapFontLabel_1")
    lbsCoins:setString(string.lower(util_formatCoins(tonumber(coins), 30)))
    table.insert(uiList, {node = lbsCoins, alignX = 5, alignY = 7})
    util_alignCenter(uiList)
    -- local cont = lbsCoins:getContentSize()
    -- icon:setPositionX(lbsCoins:getPositionX()-cont.width/2-40)
end

return CashBonusPickGameView
