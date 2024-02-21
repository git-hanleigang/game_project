---
--xcyy
--2018年5月23日
--CharmsProgress.lua

local CharmsProgress = class("CharmsProgress",util_require("base.BaseView"))

CharmsProgress.PROGRESS_WIDTH = 544
function CharmsProgress:initUI()

    self:createCsbNode("Charms_bonus_jindutiao.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self.m_particle = self:findChild("Particle_1")
    self.m_particle:setVisible(false)
    self.m_progress = self:findChild("progress")
    self:addClick(self:findChild("unlock_btn")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("bonus_btn"))
    self.m_iBetLevel = nil
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

end


function CharmsProgress:onEnter()

end

function CharmsProgress:lock(betLevel)
    self.m_actNode:stopAllActions()
    self.m_iBetLevel = betLevel
    self:runCsbAction("lock", false, function()
        
    end)
    
    performWithDelay(self.m_actNode,function(  )
        self:idle()
    end,15/30)

    
   
end

function CharmsProgress:unlock(betLevel)
    self.m_iBetLevel = betLevel
    
    self.m_actNode:stopAllActions()

    local Particle_2 = self:findChild("Particle_2")
    if Particle_2 then
        Particle_2:resetSystem()
    end

    self:runCsbAction("unlock", false, function()
    end)

    performWithDelay(self.m_actNode,function(  )
        self:idle()
    end,20/30)
end

function CharmsProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 1 then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("lock", true)
    end
    
end

function CharmsProgress:setPercent(percent)
    self.m_progress:setPositionX(self.PROGRESS_WIDTH * percent * 0.01)
end

function CharmsProgress:updatePercent(percent)
    
    self.m_actNode:stopAllActions()

    self.m_progress:runAction(cc.MoveTo:create(0.5, cc.p(self.PROGRESS_WIDTH * percent * 0.01, 0)))
    if self.m_particle:isVisible() == false then
        self.m_particle:setVisible(true)
    end
    self.m_particle:resetSystem()
    local percentNum = percent
    self:runCsbAction("kuangche", false, function()
        if percentNum >= 100 then
            gLobalSoundManager:playSound("CharmsSounds/sound_Charms_collect_completed.mp3")
            performWithDelay(self, function()
                self:completed()
            end, 2)
            
        else
            self:idle()
            -- self:runCsbAction("idle", true)
        end
    end)
end

function CharmsProgress:completed()

    self.m_actNode:stopAllActions()
    -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_collect_completed.mp3")
    self:runCsbAction("shouji", false, function()
        
    end)

    performWithDelay(self.m_actNode,function(  )
        self:runCsbAction("idle", true)
    end,65/30)
    self.m_progress:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.MoveTo:create(1.5, cc.p(self.PROGRESS_WIDTH * 205 * 0.01, 0))))
end

function CharmsProgress:onExit()

end

--默认按钮监听回调
function CharmsProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "unlock_btn" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
    elseif name == "bonus_btn" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

function CharmsProgress:getCollectPos()
    local gold = self:findChild("gold")
    local pos = gold:getParent():convertToWorldSpace(cc.p(gold:getPosition()))
    return pos
end

return CharmsProgress