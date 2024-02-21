--[[
    
    author:徐袁
    time:2021-03-20 16:47:38
]]
local BaseRotateLayer = require("base.BaseRotateLayer")
local StatueMainLayer = class("StatueMainLayer", BaseRotateLayer)

StatueMainLayer.ActionType = "Common"

function StatueMainLayer:ctor()
    StatueMainLayer.super.ctor(self)
    self:setName("StatueMainLayer")
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("CardRes/season202102/Statue/StatueMainLayer.csb")
end

function StatueMainLayer:initUI(openSource)
    self.m_openSource = openSource
    StatueMainLayer.super.initUI(self)
    self:setExtendData("StatueMainLayer")
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-20 16:47:38
    @return:
]]
function StatueMainLayer:initCsbNodes()
    self.m_nodeBox = self:findChild("Node_box")
    self.m_nodeStatueLeft = self:findChild("Node_statueleft")
    self.m_nodeStatueRight = self:findChild("Node_statueright")
    self.m_nodeBuffLeft = self:findChild("Node_buff_left")
    self.m_nodeBuffRight = self:findChild("Node_buff_right")
    self.m_nodeRewardLeft = self:findChild("Node_reward_left")
    self.m_nodeRewardRight = self:findChild("Node_reward_right")
    self.m_nodeChipLeft = self:findChild("Node_chip_left")
    self.m_nodeChipRight = self:findChild("Node_chip_right")
    self.m_nodeLvUpLizi = self:findChild("Node_levelUpLizi")

    self.m_worldPosLeft = self.m_nodeStatueLeft:getParent():convertToWorldSpace(cc.p(self.m_nodeStatueLeft:getPositionX(), self.m_nodeStatueLeft:getPositionY()))
    self.m_worldPosRight = self.m_nodeStatueRight:getParent():convertToWorldSpace(cc.p(self.m_nodeStatueRight:getPositionX(), self.m_nodeStatueRight:getPositionY()))
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-20 16:47:38
    @return:
]]
function StatueMainLayer:initView()
    -- self:initCsbNodes()
    self:initPlayBox()
    self:initLeftStatue()
    self:initRightStatue()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 注册消息事件
function StatueMainLayer:registerListener()
    StatueMainLayer.super.registerListener(self)
end

function StatueMainLayer:onEnter()
    StatueMainLayer.super.onEnter(self)

    if not CardSysManager:getStatueMgr():isFirstEnterStatueClan() then
        CardSysManager:getStatueMgr():saveFirstEnterStatueClan()
        local view = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueInfo")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local frameName = nil
            if params then
                if params.statueType == 1 then
                    frameName = "nv"
                elseif params.statueType == 2 then
                    frameName = "nan"
                end
            end
            if frameName then
                local spineEff = util_spineCreate("CardRes/season202102/Statue/particle/Statue_shenji", false, true, 1)
                self.m_nodeLvUpLizi:addChild(spineEff)
                util_spinePlay(spineEff, frameName)
                util_spineEndCallFunc(
                    spineEff,
                    frameName,
                    function()
                        util_nextFrameFunc(
                            function()
                                if spineEff then
                                    spineEff:removeFromParent()
                                    spineEff = nil
                                end
                            end
                        )
                    end
                )
            end
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_LIZI_FLY2PEOPLE
    )
end

function StatueMainLayer:onExit()
    StatueMainLayer.super.onExit(self)
end

function StatueMainLayer:playShowAction()
    local _action = function(callback)
        self:runCsbAction(
            "ruchang",
            false,
            function()
                self:runCsbAction("idle", true, nil, 60)
                if callback then
                    callback()
                end
            end,
            60
        )
    end
    StatueMainLayer.super.playShowAction(self, _action)
end

-- layer显示完成的回调
function StatueMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function StatueMainLayer:clickFunc(sender)
    local senderName = sender:getName()
    local isLevelUp = CardSysManager:getStatueMgr():getLevelUping()
    if isLevelUp then
        return
    end
    if senderName == "btn_play" then
        StatuePickControl:requestEnterGame()
    elseif senderName == "btn_close" then
        if self.m_openSource == "CardAlbumView" then
            CardSysManager:showCardAlbumView()
        end
        self:closeUI(
            function()
                CardSysManager:getStatueMgr():exitStatueClanUI()
            end
        )
    elseif senderName == "btn_shuoming" then
        self:showInfo()
    end
end

-- 小游戏入口
function StatueMainLayer:initPlayBox()
    local boxUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueBoxNode")
    self.m_nodeBox:addChild(boxUI)
end

-- 左侧神像
function StatueMainLayer:initLeftStatue()
    local statueType = 1
    self:initStatue(statueType)
    self:initBuff(statueType)
    self:initReward(statueType)
    self:initCards(statueType)
end

-- 右侧神像
function StatueMainLayer:initRightStatue()
    local statueType = 2
    self:initStatue(statueType)
    self:initBuff(statueType)
    self:initReward(statueType)
    self:initCards(statueType)
end

-- 神像的icon
function StatueMainLayer:initStatue(_statueType)
    local peopleUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatuePeopleNode", _statueType)
    if _statueType == 1 then
        self.m_nodeStatueLeft:addChild(peopleUI)
    elseif _statueType == 2 then
        self.m_nodeStatueRight:addChild(peopleUI)
    end
end

-- 每升一级获得buff
function StatueMainLayer:initBuff(_statueType)
    if _statueType == 1 then
        local buffUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueBuffNode", _statueType, self.m_worldPosLeft)
        self.m_nodeBuffLeft:addChild(buffUI)
    elseif _statueType == 2 then
        local buffUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueBuffNode", _statueType, self.m_worldPosRight)
        self.m_nodeBuffRight:addChild(buffUI)
    end
end

-- 所有集齐奖励
function StatueMainLayer:initReward(_statueType)
    if _statueType == 1 then
        local rewardUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueRewardNode", _statueType)
        self.m_nodeRewardLeft:addChild(rewardUI)
    elseif _statueType == 2 then
        local rewardUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueRewardNode", _statueType)
        self.m_nodeRewardRight:addChild(rewardUI)
    end
end

-- 卡片
function StatueMainLayer:initCards(_statueType)
    if _statueType == 1 then
        local chipUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueCardNode", _statueType)
        chipUI:setName("StatueCardNode")
        self.m_nodeChipLeft:addChild(chipUI)
    elseif _statueType == 2 then
        local chipUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueCardNode", _statueType)
        chipUI:setName("StatueCardNode")
        self.m_nodeChipRight:addChild(chipUI)
    end
end

-- 更新卡牌
function StatueMainLayer:addCard(cardInfo, callback)
    if not cardInfo then
        if callback then
            callback()
        end
        return
    end

    local callFunc = function()
        if callback then
            callback()
        end
    end

    local _clanData = CardSysRuntimeMgr:getClanDataByClanId(cardInfo.clanId)
    if not _clanData then
        if callback then
            callback()
        end
        return
    end
    
    if _clanData.type == CardSysConfigs.CardClanType.statue_left then
        local chipUILeft = self.m_nodeChipLeft:getChildByName("StatueCardNode")
        if chipUILeft then
            local callFunc2 = function()
                if chipUILeft:checkLevelUpAction() then
                    chipUILeft:statueLevelUpStart(callFunc)
                else
                    callFunc()
                end
            end
            chipUILeft:addCard(cardInfo, callFunc2)
        end
    elseif _clanData.type == CardSysConfigs.CardClanType.statue_right then
        local chipUIRight = self.m_nodeChipRight:getChildByName("StatueCardNode")
        if chipUIRight then
            local callFunc2 = function()
                if chipUIRight:checkLevelUpAction() then
                    chipUIRight:statueLevelUpStart(callFunc)
                else
                    callFunc()
                end
            end
            chipUIRight:addCard(cardInfo, callFunc2)
        end
    end
end

function StatueMainLayer:showInfo()
    local view = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueInfo")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return StatueMainLayer
