local StatueBuffLockNode = class("StatueBuffLockNode", BaseView)
function StatueBuffLockNode:initUI(_statueType, _index)
    self.m_statueType = _statueType
    self.m_index = _index
    StatueBuffLockNode.super.initUI(self)
end

function StatueBuffLockNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_Lock.csb"
end

function StatueBuffLockNode:initCsbNodes()
    self.m_spEff = self:findChild("ef_baodian") 
end

function StatueBuffLockNode:showLock()
    self:runCsbAction("idle", true, nil, 60)
end

function StatueBuffLockNode:hideLock()
    self:runCsbAction("idle2", true, nil, 60)
end

function StatueBuffLockNode:playLevelUp(levelUpOver)
    performWithDelay(self, function()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueBuffUnlock)
        self.m_spEff:stopSystem()
        self.m_spEff:resetSystem()
    end, 52/60)
    self:runCsbAction("jiesuo", false, function()
        self:hideLock()
        if levelUpOver then
            levelUpOver()
        end
    end, 60)
end

-- function StatueBuffLockNode:onEnter()
 
-- end

-- function StatueBuffLockNode:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end


return StatueBuffLockNode