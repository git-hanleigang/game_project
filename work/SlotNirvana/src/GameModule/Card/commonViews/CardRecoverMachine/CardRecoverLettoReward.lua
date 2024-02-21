--[[--
    回收机 - 乐透
]]
local BaseView = util_require("base.BaseView")
local CardRecoverLettoReward = class("CardRecoverLettoReward", BaseView)
local CSB_FRAME = 30
function CardRecoverLettoReward:initUI(baseCoins, curMul, bonusMul, rewardCoins, dropReward, func)
    self.m_clickFunc = func
    self.m_dropReward = dropReward
    self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverLettoBottomRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))

    local m_lb_v1 = self:findChild("m_lb_v1")
    m_lb_v1:setString(util_getFromatMoneyStr(baseCoins))
    local m_lb_v2 = self:findChild("m_lb_v2")
    m_lb_v2:setString(curMul)

    local m_lb_v3 = self:findChild("m_lb_v3")
    local totalMul = (1 + (bonusMul or 0)) * 100
    local statueBuffMul = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_LOTTO_COIN_BONUS)
    if statueBuffMul and statueBuffMul > 0 then
        totalMul = statueBuffMul * totalMul
    end
    m_lb_v3:setString(totalMul .. "%")
    local m_lb_coins = self:findChild("m_lb_coins")
    m_lb_coins:setString(util_getFromatMoneyStr(rewardCoins))

    local sp_coins = self:findChild("sp_coins")
    local sp_item = self:findChild("sp_item")
    local sp_and = self:findChild("sp_and")

    self.m_btnInfo = self:findChild("Button_i")

    if dropReward then
        if
            dropReward.type == CardSysConfigs.CardDropType.wild or dropReward.type == CardSysConfigs.CardDropType.wild_normal or dropReward.type == CardSysConfigs.CardDropType.wild_link or
                dropReward.type == CardSysConfigs.CardDropType.wild_golden
         then
            --如果是wild卡替换资源
            util_changeTexture(sp_item, string.format(CardResConfig.commonRes.CardRecoverLettoItemWildRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
            sp_item:setScale(0.3)
        end
        if dropReward.cards and #dropReward.cards > 0 then
            util_alignCenter(
                {
                    {node = sp_coins, alignY = -3},
                    {node = m_lb_coins, alignX = 20},
                    {node = sp_and, alignX = 20, alignY = -6},
                    {node = sp_item, alignX = 10, alignY = -2}
                }
            )
        end
    else
        util_alignCenter(
            {
                {node = sp_coins, alignY = -3},
                {node = m_lb_coins, alignX = 20}
            }
        )
        sp_item:setVisible(false)
        sp_and:setVisible(false)
    end
end
function CardRecoverLettoReward:showIdle()
    self:setVisible(true)
    self:runCsbAction(
        "show2",
        false,
        function()
            self:showEff()
            self:runCsbAction(
                "animation0",
                false,
                function()
                end,
                CSB_FRAME
            )
        end,
        CSB_FRAME
    )
end
--爆炸效果
function CardRecoverLettoReward:showEff()
    local node_eff1 = self:findChild("node_eff1")
    if node_eff1 then
        local spEff = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoBottomGuangRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        node_eff1:addChild(spEff)
        spEff:runCsbAction("show")
    end
    performWithDelay(
        self,
        function()
            local node_eff2 = self:findChild("node_eff2")
            if node_eff2 then
                local spEff = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoBottomGuangRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
                node_eff2:addChild(spEff)
                spEff:runCsbAction("show")
            end
        end,
        0.5
    )
    performWithDelay(
        self,
        function()
            local node_eff3 = self:findChild("node_eff3")
            if node_eff3 then
                local spEff = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoBottomGuangRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
                node_eff3:addChild(spEff)
                spEff:runCsbAction("show")
            end
        end,
        1
    )
end

function CardRecoverLettoReward:showOver()
    self:runCsbAction(
        "over",
        false,
        function()
        end,
        CSB_FRAME
    )
end

-- 加成系数数据
function CardRecoverLettoReward:showStatueBuffBubble()
    local bubbleNode = self:findChild("qipao")
    local bubbleUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverLettoRewardBubble")
    bubbleNode:addChild(bubbleUI)
end

function CardRecoverLettoReward:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_collect" then
        -- sender:setBright(false)
        -- sender:setTouchEnabled(false)
        self:setButtonLabelDisEnabled("btn_collect", false) 
        if self.m_clickFunc then
            self.m_clickFunc()
        end
    elseif name == "Button_i" then
        self:showStatueBuffBubble()
    end
end
return CardRecoverLettoReward
