---
--xcyy
--2018年5月23日
--GeminiJourneyCollectView.lua
local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyCollectView = class("GeminiJourneyCollectView",util_require("Levels.BaseLevelDialog"))

function GeminiJourneyCollectView:initUI(_machine)

    self.m_machine = _machine
    self:createCsbNode("GeminiJourney_RespinCounter.csb")
    self:runCsbAction("idle1", true)

    self.m_btnView = util_createView("GeminiJourneySrc.GeminiJourneyCollectBtn", self, self.m_machine)
    self:findChild("button"):addChild(self.m_btnView)

    -- 收集tips
    self.m_tipsView = util_createView("GeminiJourneySrc.GeminiJourneyCollectTips", self, self.m_machine)
    self:findChild("Node_tips"):addChild(self.m_tipsView)

    -- 右侧收集文本光效
    self.m_collectTextSpine = util_spineCreate("GeminiJourney_RespinCounter_wenzi",true,true)
    self:findChild("Node_zi"):addChild(self.m_collectTextSpine)

    self.m_curBonusCount = 0
    self.m_sixLastEffectNodeList = {}
    -- 6个bonusNode
    self.m_sixBonusNodeList = {}
    for i=1, 6 do
        self.m_sixBonusNodeList[i] = util_createView("GeminiJourneySrc.GeminiJourneyCollectBonusNode")
        self:findChild("6_spot"..i):addChild(self.m_sixBonusNodeList[i], 10)
        self.m_sixBonusNodeList[i]:setVisible(false)
        if i >= 5 then
            self.m_sixLastEffectNodeList[i] = util_createAnimation("GeminiJourney_RespinCounter_zg.csb")
            self:findChild("6_spot"..i):addChild(self.m_sixLastEffectNodeList[i])
            self.m_sixLastEffectNodeList[i]:setVisible(false)
        end
    end

    self.m_clickPanel = self:findChild("Panel_click")
    self:addClick(self.m_clickPanel)
    self:recoverBonusPlay()

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

--默认按钮监听回调
function GeminiJourneyCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" and self.m_machine:tipsBtnIsCanClick() then
        self:showTips()
    end
end

-- 设置弹板上最小bet的钱
function GeminiJourneyCollectView:setHighBetLevelCoins(_highBetLevelCoins)
    self.m_tipsView:setHighBetLevelCoins(_highBetLevelCoins)
end

-- 触发respin-(bonus玩法)
function GeminiJourneyCollectView:triggerBonusPlay()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBonus_Full)
    util_spinePlay(self.m_collectTextSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_collectTextSpine, "actionframe", function()
        util_spinePlay(self.m_collectTextSpine, "idle1", true)
    end) 
end

-- 文本动画恢复常态
function GeminiJourneyCollectView:recoverBonusPlay()
    util_spinePlay(self.m_collectTextSpine, "idle", true)
end

function GeminiJourneyCollectView:showCollectBonus(_betLevel, _onEnter, _freeMode)
    if not self.m_lastBetLevel then
        if _betLevel == 0 then
            self:showBtnAndPanel(true, _freeMode)
            self:runCsbAction("idle1", true)
        else
            self:closeBtnAndPanel(true)
            self:runCsbAction("idle2", true)
        end
    elseif self.m_lastBetLevel ~= _betLevel then
        util_resetCsbAction(self.m_csbAct)
        if _betLevel == 0 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Bet_Low)
            self:showBtnAndPanel()
            self:runCsbAction("switch2", false, function()
                self:runCsbAction("idle1", true)
            end)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Bet_Hight)
            self:closeBtnAndPanel()
            self:runCsbAction("switch1", false, function()
                self:runCsbAction("idle2", true)
            end)
        end
    end
    self.m_lastBetLevel = _betLevel
end

-- 显示按钮和弹板
function GeminiJourneyCollectView:showBtnAndPanel(_onEnter, _freeMode)
    if not _freeMode then
        self:showTips()
    end
    self.m_btnView:showBtn(_onEnter)
    self.m_clickPanel:setVisible(true)
end

-- 关闭按钮和弹板
function GeminiJourneyCollectView:closeBtnAndPanel(_onEnter)
    self:spinCloseTips()
    self.m_btnView:closeBtn(_onEnter)
    self.m_clickPanel:setVisible(false)
end

function GeminiJourneyCollectView:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function GeminiJourneyCollectView:showTips()
    self.m_tipsView:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_tipsView:closeTips()
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_tipsView:showTips()
    else
        closeTips()
    end
    performWithDelay(self.m_tipsView, function ()
	    closeTips()
    end, 8.0)
end

-- 根据bet等级显示槽上的bonus
function GeminiJourneyCollectView:collectBonusNode(_isBuling, _bonusCount, _onEnter, _slotNode)
    -- 播落地累加
    if _isBuling then
        self.m_curBonusCount = self.m_curBonusCount + 1
        if self.m_curBonusCount <= 6 then
                self.m_sixBonusNodeList[self.m_curBonusCount]:showStart()
            end
        self:showLastCollectEffectNode(_slotNode)
    else
        self.m_curBonusCount = _bonusCount
        -- 6个槽
        for i=1, 6 do
            if _bonusCount >= i then
                self.m_sixBonusNodeList[i]:showStart(_onEnter)
            else
                self.m_sixBonusNodeList[i]:closeOver(_onEnter)
            end
        end
    end
end

-- 槽上待集满时的特效（5个槽最后一个；6个槽最后两个）
function GeminiJourneyCollectView:showLastCollectEffectNode(_slotNode)
    local curBonusCount = self.m_curBonusCount
    local slotNode = _slotNode
    local curCol = slotNode.p_cloumnIndex
    if self.m_lastBetLevel == 1 then
        util_resetCsbAction(self.m_sixLastEffectNodeList[5].m_csbAct)
        -- 需要播放光效
        if curBonusCount == 4 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBonus_Expect)
            self.m_sixLastEffectNodeList[5]:setVisible(true)
            self.m_sixLastEffectNodeList[5]:runCsbAction("idle", true)
        elseif curBonusCount == 5 then
            -- 需要炸开
            self.m_sixLastEffectNodeList[5]:runCsbAction("show", false, function()
                self.m_sixLastEffectNodeList[5]:setVisible(false)
            end)
            performWithDelay(self.m_scWaitNode, function()
                self:triggerBonusPlay()
            end, 0.2)
        end
    else
        -- 需要播放光效
        if curBonusCount == 4 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBonus_Expect)
            for i=5, 6 do
                self.m_sixLastEffectNodeList[i]:setVisible(true)
                util_resetCsbAction(self.m_sixLastEffectNodeList[i].m_csbAct)
                self.m_sixLastEffectNodeList[i]:runCsbAction("idle", true)
            end
        elseif curBonusCount == 5 then
            if curCol ~= 5 or self.m_machine:getCurFeatureIsRespin() then
                self.m_sixLastEffectNodeList[curBonusCount]:runCsbAction("show", false, function()
                    self.m_sixLastEffectNodeList[curBonusCount]:setVisible(false)
                end)
            end
        elseif curBonusCount == 6 then
            -- 需要炸开
            self.m_sixLastEffectNodeList[curBonusCount]:runCsbAction("show", false, function()
                self.m_sixLastEffectNodeList[curBonusCount]:setVisible(false)
            end)
            performWithDelay(self.m_scWaitNode, function()
                self:triggerBonusPlay()
            end, 0.2)
        end
    end
end

-- 停轮集满时的特效消失
function GeminiJourneyCollectView:closeLastCollectEffectNode()
    for k, sixEffectNode in pairs(self.m_sixLastEffectNodeList) do
        if sixEffectNode:isVisible() then
            sixEffectNode:runCsbAction("over", false, function()
                sixEffectNode:setVisible(false)
            end)
        end
    end
end

return GeminiJourneyCollectView
