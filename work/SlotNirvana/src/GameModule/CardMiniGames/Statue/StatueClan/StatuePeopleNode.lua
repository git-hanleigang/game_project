--[[
    雕像
]]

local StatuePeopleNode = class("StatuePeopleNode", BaseView)

function StatuePeopleNode:initUI(_statueType)
    self.m_statueType = _statueType
    StatuePeopleNode.super.initUI(self)
    self:initView()
end

function StatuePeopleNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_people.csb"
end

function StatuePeopleNode:initCsbNodes()
    self.m_spIcon = self:findChild("sp_statue")
    self.m_spIconLv = self:findChild("sp_statue_0")
    
    self.m_nodeBehind = self:findChild("Node_behind")
    self.m_nodeBefore = self:findChild("Node_before")
    self.m_nodeSelf = self:findChild("Node_self")
end

function StatuePeopleNode:initView()
    local statueLevel, _ = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
    if not statueLevel then
        return 
    end
    -- 初始化icon
    util_changeTexture(self.m_spIcon, string.format(self:getIconRes(), statueLevel))

    -- 左右雕塑的特效位置不太一样
    if self.m_statueType == 1 then
        self.m_nodeBefore:setPositionX(-50)
        self.m_nodeBehind:setPositionX(-50)
    elseif self.m_statueType == 2 then
        self.m_nodeBefore:setPositionX(0)
        self.m_nodeBehind:setPositionX(0)
    end

    -- 如果等级是2级和3级要显示特效
    local peopleAnima = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatuePeopleIdleAnimaNode", self.m_statueType)
    peopleAnima:playIdle(statueLevel)
    self.m_nodeSelf:addChild(peopleAnima)
end

function StatuePeopleNode:getIconRes()
    if self.m_statueType == 1 then
        return "CardRes/season202102/Statue/img/StatueLayer/jianzhu_nv%d.png"
    elseif self.m_statueType == 2 then
        return "CardRes/season202102/Statue/img/StatueLayer/jianzhu_zhanshi%d.png"
    end
end

function StatuePeopleNode:showLevelUpAnima(parentNode, _animType)
    local anim = util_createView("GameModule.CardMiniGames.Statue.StatueClan.StatuePeoplesLevelUpAnimaNode", _animType)
    anim:playLevelUpAnima()
    parentNode:addChild(anim)
end

function StatuePeopleNode:playLevelupAction()
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePeopleLight)
    self:showLevelUpAnima(self.m_nodeBefore, "before")
    self:showLevelUpAnima(self.m_nodeBehind, "behind")
    performWithDelay(self, function()
        local function changeTexture(spIcon)
            local statueLevel, _ = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
            if not statueLevel then
                return 
            end
            -- 初始化icon
            util_changeTexture(spIcon, string.format(self:getIconRes(), statueLevel))
        end
        
        
        changeTexture(self.m_spIconLv)
        self:runCsbAction("shengji", false, function()
            self.m_spIcon:setOpacity(255)
            self.m_spIconLv:setVisible(false)
            self:initView()
        end, 60)
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_LIZI_FLY2LOCK, {statueType = self.m_statueType})
        end, 40/60)
    end, 0.5)
end

function StatuePeopleNode:onEnter()
    StatuePeopleNode.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(target, params)
        if self.m_statueType == params.statueType then
            self:playLevelupAction()
        end
    end, CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_ANIMA_PEOPLE)
end

function StatuePeopleNode:onExit()
    StatuePeopleNode.super.onExit(self)
end

return StatuePeopleNode