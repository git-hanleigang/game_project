--[[
]]
local StatueBoxNode = class("StatueBoxNode", BaseView)
function StatueBoxNode:initUI()
    self:initData()
    StatueBoxNode.super.initUI(self)
    self:updateView()
end

function StatueBoxNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_box.csb"
end

function StatueBoxNode:initCsbNodes()
    self.m_fntTime = self:findChild("font_time")
    self.m_spTime = self:findChild("sp_time")
    self.m_btnPlay = self:findChild("btn_play")
    self.m_nodeEff = self:findChild("ef_xuanwo")
    self.m_nodeFinger = self:findChild("shouzhi")
end

function StatueBoxNode:initData()
end

function StatueBoxNode:updateView()
    self:updateInfo()
    self.m_stopTime = StatuePickGameData:getCooldownTime()
    self:updateCountdown()
end

function StatueBoxNode:updateInfo()
    self.m_state = StatuePickGameData:getGameStatus()
    if self.m_state == StatuePickStatus.FINISH then
        self.m_spTime:setVisible(true)
        self.m_btnPlay:setVisible(false)
        self.m_nodeEff:setVisible(false)
        self:runCsbAction("idle2", true, nil, 60)
    else
        self.m_spTime:setVisible(false)
        self.m_btnPlay:setVisible(true)
        self.m_nodeEff:setVisible(true)
        self:runCsbAction("idle", true, nil, 60)
    end
end

function StatueBoxNode:updateCountdown()
    local curTime = StatuePickGameData:getCooldownTime()

    self.m_fntTime:setString(util_count_down_str(curTime))
    if self.m_stopTime and self.m_stopTime <= 0 then
        if self.m_state == StatuePickStatus.FINISH then
            StatuePickGameData:setGameStatus(StatuePickStatus.PREPARE)
            self:updateInfo()
        end
    end

    self.m_stopTime = curTime
end

function StatueBoxNode:clickFunc(sender)
    local name = sender:getName()
    local isLevelUp = CardSysManager:getStatueMgr():getLevelUping()
    if isLevelUp then
        return
    end
    if name == "btn_play" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueBoxPlayClick)        
        self:delFinger()
        StatuePickControl:requestEnterGame()
    end
end

function StatueBoxNode:addFinger()
    if not CardSysManager:getStatueMgr():isEnterPickBox() then
        self.m_fingerUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueFingerNode")
        self.m_nodeFinger:addChild(self.m_fingerUI)
    end
end

function StatueBoxNode:delFinger()
    if self.m_fingerUI ~= nil then
        CardSysManager:getStatueMgr():saveEnterPickBox()
        self.m_fingerUI:removeFromParent()
        self.m_fingerUI = nil
    end    
end

function StatueBoxNode:onEnter()
    if not self.m_state then
        self.m_state = StatuePickGameData:getGameStatus()
    end
    if self.m_state ~= StatuePickStatus.FINISH then
        self:addFinger()
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateCountdown()
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_UPDATE_TIME
    )

    -- 领取奖励完成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateInfo()
        end,
        ViewEventType.STATUS_PICK_COLLECT_REWARD_COMPLETED
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateView()
        end,
        ViewEventType.STATUS_PICK_GAME_UPDATE
    )

    schedule(
        self,
        function()
            self:updateCountdown()
        end,
        1
    )
end

return StatueBoxNode
