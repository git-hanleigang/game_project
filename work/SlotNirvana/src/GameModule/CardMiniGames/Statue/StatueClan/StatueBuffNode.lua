--[[

]]
local StatueBuffNode = class("StatueBuffNode", BaseView)

function StatueBuffNode:initUI(_statueType, _peopleWorldPos)
    self.m_statueType = _statueType
    self.m_peopleWorldPos = _peopleWorldPos
    StatueBuffNode.super.initUI(self)

    self:initData()
    self:initView()
end

function StatueBuffNode:getCsbName()
    local csbName = nil
    if self.m_statueType == 1 then
        csbName = "CardRes/season202102/Statue/Statue_buff_left.csb"
    elseif self.m_statueType == 2 then
        csbName = "CardRes/season202102/Statue/Statue_buff_right.csb"
    end
    assert(csbName ~= nil, "StatueBuffNode csbName is nil")
    return csbName
end

function StatueBuffNode:initCsbNodes()
    self.m_fntBuffs = {}
    for i = 1, 3 do
        local lbBuff = self:findChild("font_benefits" .. i)
        table.insert(self.m_fntBuffs, lbBuff)
    end
    self.m_nodeLocks = {}
    for i = 1, 3 do
        local nodeLock = self:findChild("sp_lock" .. i)
        table.insert(self.m_nodeLocks, nodeLock)
    end
    self.m_nodeEffects = {}
    for i = 1, 3 do
        local nodeEff = self:findChild("ef_sg" .. i)
        table.insert(self.m_nodeEffects, nodeEff)
    end
end

function StatueBuffNode:initData()
    self.m_clanData = CardSysManager:getStatueMgr():getRunData():getStatueClanListData(self.m_statueType)
    self.m_statueLevel = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
end

function StatueBuffNode:initView()
    if not self.m_clanData or not self.m_statueLevel then
        return
    end
    self:initText()
    self:initLock()
end
function StatueBuffNode:initText()
    for i = 1, 3 do
        local txt = "null"
        if self.m_clanData[i] then
            local buffInfos = CardSysManager:getStatueMgr():getRunData():getBuffInfo(self.m_clanData[i].rewards)
            if buffInfos and buffInfos[1].p_buffInfo then
                txt = buffInfos[1].p_buffInfo.buffDescription
            end
        else
            release_print(string.format("------ #self.m_clanData = %d, i = %d------", #self.m_clanData, i))
        end
        self.m_fntBuffs[i]:setString(txt)
        if i <= self.m_statueLevel then
            self.m_fntBuffs[i]:setColor(cc.c3b(255, 255, 255))
        else
            self.m_fntBuffs[i]:setColor(cc.c3b(127, 115, 150))
        end
    end
end

function StatueBuffNode:initLock()
    self.m_lockUIs = {}
    for i = 1, 3 do
        local lockUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueBuffLockNode", self.m_statueType, i)
        self.m_nodeLocks[i]:addChild(lockUI)
        self.m_lockUIs[i] = lockUI
        if i > self.m_statueLevel then
            lockUI:showLock()
        else
            lockUI:hideLock()
        end
    end
end

--[[
    @desc: 升级相关函数
    author:{author}
    time:2021-04-17 19:51:25
    @return:
]]
function StatueBuffNode:createFlyParticle()
    if not self.m_flyLizi then
        self.m_flyLizi = cc.ParticleSystemQuad:create("CardRes/season202102/Statue/particle/Statue_yaoshi_lizi.plist")
        gLobalViewManager:getViewLayer():addChild(self.m_flyLizi, ViewZorder.ZORDER_SPECIAL)
    end
    self.m_flyLizi:setVisible(true)
    self.m_flyLizi:setPosition(self.m_peopleWorldPos)
    return self.m_flyLizi
end

function StatueBuffNode:startFlyParticle(_index)
    if self.m_nodeLocks and self.m_nodeLocks[_index] then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueFly2Lock)
        local uiPos = cc.p(self.m_nodeLocks[_index]:getPosition())
        local endWorldPos = self.m_nodeLocks[_index]:getParent():convertToWorldSpace(cc.p(uiPos.x, uiPos.y))
        local lizi = self:createFlyParticle()
        local moveTo = cc.MoveTo:create(36 / 60, endWorldPos)
        local moveEndCall =
            cc.CallFunc:create(
            function()
                lizi:setVisible(false)
                self:doLevelUpAction(_index)
            end
        )
        lizi:runAction(cc.Sequence:create(moveTo, moveEndCall))
    end
end

function StatueBuffNode:doLevelUpAction(_index)
    if self.m_lockUIs[_index] then
        self.m_lockUIs[_index]:playLevelUp()
    end
    self:playLevelUpEffect(_index)
end

function StatueBuffNode:playLevelUpEffect(index)
    local effectUI = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatueBuffLevelUpEffectNode")
    self.m_nodeEffects[index]:addChild(effectUI)
    effectUI:playLevelUp(
        function()
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_ANIMA_OVER, {statueType = self.m_statueType})
        end
    )
    self.m_fntBuffs[index]:setColor(cc.c3b(255, 255, 255))
end

function StatueBuffNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.statueType == self.m_statueType then
                local statueLevel = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
                if not statueLevel then
                    return
                end
                statueLevel = math.max(1, statueLevel)
                for i = 1, #self.m_nodeEffects do
                    if (i > self.m_statueLevel and i < statueLevel) or i == statueLevel then
                        self:startFlyParticle(i)
                    end
                end
                self.m_statueLevel = statueLevel
            end
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_LIZI_FLY2LOCK
    )
end

function StatueBuffNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return StatueBuffNode
