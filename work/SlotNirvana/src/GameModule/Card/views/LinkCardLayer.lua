--[[
    link展示，link小游戏的入口
    
    link大卡界面：有link卡时的显示规则
    左右切换
        不弹
    进入集卡时首次显示
        大厅入口进入
            大于等于5：不弹
            小于5：弹
        link掉落跳转进入
            弹
    返回章节再进入含link章节（跟怎么进入集卡的无关）
        大于等于5
            点击link大卡界面关闭：不弹
            未点击link大卡界面关闭：不弹
        小于5
            点击link大卡界面关闭：不弹
            未点击link大卡界面关闭：弹    
]]
local BaseView = util_require("base.BaseView")
local LinkCardLayer = class("LinkCardLayer", BaseView)
local LinkLayerBigDelay = 0.2
function LinkCardLayer:initUI(cardData)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:createCsbNode(CardResConfig.GoToLinkGameCard, isAutoScale)

    self.m_isClickTouch = false
    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)

    self.m_cardNode = self:findChild("Node_card")
    self.m_cardData = cardData

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbLoopAction("idle", 3, 60)
        end,
        60
    )
    local view = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "idle", true, true)
    view:setName("Mini")
    self.m_cardNode:addChild(view)

    self:initLayer()
    self:updateBtnState()
end

function LinkCardLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.isClose then
        return
    end
    if name ~= "touch" then
        -- 清除后续打点
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():cleanParams(8)
            end
        end
    end
    if name == "Button_left" or name == "layer_left" then
        local view = CardSysManager:getCardClanView()
        if view.m_bScrolling == true then
            return
        end
        if view.m_curPageIndex <= 1 then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:updateBtnState()
        local view = CardSysManager:getCardClanView()
        if view then
            view:movePageDir(1)
        end
    elseif name == "Button_right" or name == "layer_right" then
        local view = CardSysManager:getCardClanView()
        if view.m_bScrolling == true then
            return
        end
        if view.m_curPageIndex >= view.m_pageNum then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:updateBtnState()
        local view = CardSysManager:getCardClanView()
        if view then
            view:movePageDir(-1)
        end
    elseif name == "Button_x" then
        -- -- 直接关闭卡册界面 ，也就是说 此关卡有可玩的link卡，如果不玩，就不允许看其他卡牌 --
        -- CardSysManager:closeCardClanView(function()
        --     CardSysManager:exitCard()
        -- end)
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        -- 关闭了link游戏点击进入界面 --
        CardSysManager:setLinkCardClickX(true)
        CardSysManager:closeLinkCardView(1)
    elseif name == "touch" then
    -- 以前赛季无法进入link小游戏了

    -- 打开link 小游戏
    -- if self.m_isClickTouch == true then
    --     return
    -- end
    -- self.m_isClickTouch = true
    -- CardSysManager:closeLinkCardView(2, function()
    --     -- 引导打点：Card引导-5.进入link游戏
    --     if CardSysManager:isInGuide() then
    --         if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
    --             gLobalSendDataManager:getLogGuide():sendGuideLog(8, 5)
    --         end
    --     end
    --     CardSysManager:showNadoMachine( self.m_cardData.cardId, self.m_cardData.linkCount , self.m_cardData.clanId, function()
    --         -- CardSysManager:closeCardClanView()
    --     end)
    -- end)
    end
end

function LinkCardLayer:closeUI(closeType, callFunc)
    if self.isClose then
        return
    end
    self.isClose = true

    if closeType == 1 then
        if callFunc then
            callFunc()
        end
        self:removeFromParent()
    elseif closeType == 2 then
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.LinkLayerBig)
            end,
            LinkLayerBigDelay
        )
        local card = self.m_cardNode:getChildByName("Mini")
        card:runAction(cc.FadeOut:create(0.5))
        self:runCsbAction(
            "over_2",
            false,
            function()
                if callFunc then
                    callFunc()
                end
                self:removeFromParent()
            end,
            60
        )
    end
end

function LinkCardLayer:updateBtnState()
    local Button_left = self:findChild("Button_left")
    local Button_right = self:findChild("Button_right")

    local view = CardSysManager:getCardClanView()
    if view then
        Button_left:setVisible(view.m_curPageIndex > 1)
        Button_right:setVisible(view.m_curPageIndex < view.m_pageNum)
    end
end

function LinkCardLayer:initLayer()
    local layer_right = self:findChild("layer_right")
    self:addClick(layer_right)
    local layer_left = self:findChild("layer_left")
    self:addClick(layer_left)
end

return LinkCardLayer
