--[[--
    章节选择界面的标题
]]
local UIStatus = {
    Normal = 1,
    Complete = 2
}
local CardAlbumTitle = class("CardAlbumTitle", BaseView)

function CardAlbumTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumTitleRes, "season202302")
end

function CardAlbumTitle:getTimeLua()
    return "GameModule.Card.season202302.CardSeasonTime"
end

function CardAlbumTitle:getRoundTipLua()
    return "GameModule.Card.season202302.CardAlbumRoundTip"
end

function CardAlbumTitle:getRoundRewardListLua()
    return "GameModule.Card.season202302.CardAlbumRoundRewardList"
end

function CardAlbumTitle:initDatas(_albumClass)
    self.m_albumClass = _albumClass
end

function CardAlbumTitle:initCsbNodes()
    self.m_nodeRoot = self:findChild("root")
    self.m_lb_coins = self:findChild("coins")
    self.m_lb_pro = self:findChild("process")
    self.m_timeNode = self:findChild("Node_time")

    self.m_spCoin = self:findChild("jinbi")
    self.m_nodeRound = self:findChild("node_round_tip")
    self.m_nodeList = self:findChild("Node_list")
    self.m_nodeBanzi = self:findChild("node_banzi")

    self.m_btnOpen = self:findChild("btn_open")
    self.m_spOpen = self:findChild("sp_open")
end

function CardAlbumTitle:initUI()
    CardAlbumTitle.super.initUI(self)
    self:initView()
end

function CardAlbumTitle:initView()
    self:initTime()
    self:initRoundTip()

    -- 以往赛季隐藏轮次列表
    if tonumber(CardSysRuntimeMgr:getSelAlbumID()) == tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
        self:initRoundRewards()
        self.m_btnOpen:setVisible(true)
        self.m_spOpen:setVisible(true)
    else
        self.m_btnOpen:setVisible(false)
        self.m_spOpen:setVisible(false)
    end
    
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CardAlbumTitle:initTime()
    -- 赛季结束时间戳
    local ui = util_createView(self:getTimeLua())
    self.m_timeNode:addChild(ui)
end

function CardAlbumTitle:initRoundTip()
    local view = util_createView(self:getRoundTipLua())
    self.m_nodeRound:addChild(view)
end

--[[-- 赛季新增多轮奖励展示 ]]
function CardAlbumTitle:initRoundRewards()
    self.m_rewards = util_createView(self:getRoundRewardListLua())
    if self.m_rewards then
        self.m_nodeList:addChild(self.m_rewards)
    end
end

function CardAlbumTitle:createHideLayout()
    local tLayout = ccui.Layout:create()
    tLayout:setName("round_hide_touch")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(false)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(0)

    self:addChild(tLayout)
    self:addClick(tLayout)

    local scale = self:getUIScalePro()
    if scale < 1 then
        scale = 1 / scale
    end
    tLayout:setScale(scale)

    return tLayout
end

function CardAlbumTitle:playStart(_over)
    self:runCsbAction("show2", false, _over, 30)
end

function CardAlbumTitle:playIdle()
    self:runCsbAction("idle2", true, nil, 30)
end

function CardAlbumTitle:playOver(_over)
    self:runCsbAction("over2", false, _over, 30)
end

function CardAlbumTitle:playCompleteStart(_over)
    self:runCsbAction("show1", false, _over, 30)
end

function CardAlbumTitle:playCompleteIdle()
    self:runCsbAction("idle1", true, nil, 30)
end

function CardAlbumTitle:playCompleteOver(_over)
    self:runCsbAction("over1", false, _over, 30)
end

function CardAlbumTitle:showRoundReward()
    if self:isRoundGuiding() then
        return
    end
    if self.m_rounding then
        return
    end
    self.m_rounding = true
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

    if not self.m_touchLayer then
        self.m_touchLayer = self:createHideLayout()
        self.m_touchLayer:setGlobalZOrder(1)
        self.m_touchLayer:setVisible(false)
        local lPos = self.m_touchLayer:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
        self.m_touchLayer:setPosition(lPos)
    end

    local function showCall()
        if not tolua.isnull(self) then
            self.m_rounding = false
            self.m_touchLayer:setVisible(true)
        end
    end
    self.m_nodeBanzi:runAction(cc.FadeOut:create(0.5))
    if self.m_rewards then
        self.m_rewards:playStart(showCall)
    else
        showCall()
    end
end

function CardAlbumTitle:hideRoundReward()
    if self:isRoundGuiding() then
        return
    end
    if self.m_rounding then
        return
    end
    self.m_rounding = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local function hideCall()
        if not tolua.isnull(self) then
            self.m_rounding = false
            if self.m_touchLayer then
                self.m_touchLayer:setVisible(false)
            end
            if self.m_UIStatus == UIStatus.Complete then
                self:playCompleteIdle()
            else
                self:playIdle()
            end
        end
    end
    util_performWithDelay(
        self,
        function()
            self.m_nodeBanzi:runAction(cc.FadeIn:create(0.5))
        end,
        0.5
    )
    if self.m_rewards then
        self.m_rewards:playOver(hideCall)
    else
        hideCall()
    end
end

function CardAlbumTitle:updateUIStatus(isPlayStart)
    self.m_UIStatus = self:getUIStatus()
    if self.m_UIStatus == UIStatus.Complete then
        if isPlayStart then
            self.m_starting = true
            self:playCompleteStart(
                function()
                    self.m_starting = false
                    self:playCompleteIdle()
                end
            )
        else
            self:playCompleteIdle()
        end
    else
        if isPlayStart then
            self.m_starting = true
            self:playStart(
                function()
                    self.m_starting = false
                    self:playIdle()
                end
            )
        else
            self:playIdle()
        end
    end
end

function CardAlbumTitle:updatePro()
    local cur, max = self:getPro()
    self.m_lb_pro:setString(cur .. "/" .. max)
end

function CardAlbumTitle:updateCoin()
    local coins = tonumber(self:getAlbumCoins() or 0)
    local specialReward = 1
    if G_GetMgr(ACTIVITY_REF.CardEndSpecial):getRunningData() then
        specialReward = globalData.constantData.CARD_SPECIAL_REWAR or 1
    end
    self.m_lb_coins:setString(util_formatCoins(coins * specialReward, 33))
    local UIList = {}
    util_formatStringScale(self.m_lb_coins, 530, 0.75)
    table.insert(UIList, {node = self.m_spCoin, anchor = cc.p(0.5, 0.5)})
    table.insert(UIList, {node = self.m_lb_coins, alignX = 5, alignY = self.m_lb_coins:getPositionY(), scale = self.m_lb_coins:getScale(), anchor = cc.p(0.5, 0.5)})
    util_alignCenter(UIList)
end

function CardAlbumTitle:updateUI(isPlayStart)
    self:updateUIStatus(isPlayStart)
    self:updatePro()
    self:updateCoin()
end

-- 赛季新增多轮次弹框
function CardAlbumTitle:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_open" then
        self:showRoundReward()
    elseif name == "round_hide_touch" then
        self:hideRoundReward()
    end
end

function CardAlbumTitle:onEnter()
    CardAlbumTitle.super.onEnter(self)
end

function CardAlbumTitle:isRoundGuiding()
    if self.m_albumClass:isGuiding() then
        return true
    end
    return false
end

function CardAlbumTitle:getAlbumCoins()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return albumData.coins or 0
    end
    return 0
end

function CardAlbumTitle:getPro()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return albumData.current or 0, albumData.total or 22
    end
    return 0, 22
end

function CardAlbumTitle:getUIStatus()
    local cur, max = self:getPro()
    if cur >= max then
        return UIStatus.Complete
    end
    return UIStatus.Normal
end

return CardAlbumTitle
