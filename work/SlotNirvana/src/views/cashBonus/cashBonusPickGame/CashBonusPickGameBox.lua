local CashBonusPickGameBox = class("CashBonusPickGameBox", util_require("base.BaseView"))

function CashBonusPickGameBox:initUI()
    -- setDefaultTextureType("RGBA8888", nil)
    self:createCsbNode("NewCashBonus/CashBonusNew/CashPickGameBox.csb")
    self:runCsbAction("show", false)
    self:addClick(self:findChild("btn_open"))

    self.m_node_gold = self:findChild("node_gold")
    self.m_node_silver = self:findChild("node_silver")

    self.m_node_goldWinAll = self:findChild("node_goldWinAll")
    self.m_node_silverWinAll = self:findChild("node_silverWinAll")
    -- setDefaultTextureType("RGBA4444", nil)
end
--
--{type=1,coins=99999}
function CashBonusPickGameBox:initData(data, callback)
    self.m_data = data
    self.m_callback = callback
    self.m_node_gold:setVisible(data.type == CASHBONUS_TYPE.BONUS_GOLD)
    self.m_node_silver:setVisible(data.type == CASHBONUS_TYPE.BONUS_SILVER)
    self:findChild("goldDark"):setVisible(data.type == CASHBONUS_TYPE.BONUS_GOLD)
    self:findChild("silverDark"):setVisible(data.type == CASHBONUS_TYPE.BONUS_SILVER)

    self.m_node_goldWinAll:setVisible(data.type == CASHBONUS_TYPE.BONUS_GOLD)
    self.m_node_silverWinAll:setVisible(data.type == CASHBONUS_TYPE.BONUS_SILVER)

    self:runCsbAction(
        "show",
        false,
        function()
            self.m_canClick = true
            self:runCsbAction("idle", true)
        end,
        30
    )
end

function CashBonusPickGameBox:setSelect(delayTime, data, showTextCall, endCallback)
    self.m_click = true

    local animName = "open"
    local type = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultBoxType(self.m_data.index)
    if type ~= CASHBACK_BOX_TYPE.ALL_WIN_SELECTED and type ~= CASHBACK_BOX_TYPE.COIN_SELECTED then
        animName = "openDark"
    end

    performWithDelay(
        self,
        function()
            local delay2 = 1
            if animName == "openDark" then
                delay2 = 0.01
            end
            local isWinAll = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultBoxIsWinAll()
            if type == CASHBACK_BOX_TYPE.COIN_SELECTED and isWinAll then
                animName = "open2"
                delay2 = 0.02
            end

            self:runCsbAction(
                animName,
                false,
                function()
                    if endCallback then
                        endCallback()
                    end
                end,
                30
            )

            performWithDelay(
                self,
                function()
                    if type == CASHBACK_BOX_TYPE.ALL_WIN_SELECTED or type == CASHBACK_BOX_TYPE.COIN_SELECTED then
                        gLobalSoundManager:playSound("Sounds/Music_vault_open_box.mp3")
                    end

                    if showTextCall then
                        showTextCall()
                    end
                end,
                delay2
            )
        end,
        delayTime
    )
end

function CashBonusPickGameBox:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_canClick then
        return
    end
    if self.m_click then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self.m_click = true
    if name == "btn_open" then
        if self.m_callback then
            self.m_callback(self.m_data.index)
        end
    end
end

return CashBonusPickGameBox
