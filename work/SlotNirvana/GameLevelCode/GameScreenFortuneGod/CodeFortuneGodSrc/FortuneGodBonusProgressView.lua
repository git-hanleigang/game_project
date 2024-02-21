---
--xcyy
--2018年5月23日
--FortuneGodBonusProgressView.lua

local FortuneGodBonusProgressView = class("FortuneGodBonusProgressView",util_require("Levels.BaseLevelDialog"))

local PROGRESS_WIDTH = 840

function FortuneGodBonusProgressView:initUI()

    self:createCsbNode("FortuneGod_jindutiao.csb")

    self.m_progress = self.m_csbOwner["Node_jindutiao"]
    self:initLoadingbar(0)
    

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self:addClick(self:findChild("Panel_dianji"))
    self:addClick(self:findChild("Panel_dianji_0"))
    

    self.oneGold = util_spineCreate("FortuneGod_Jindutiaojinbi",true,true)
    self:findChild("Node_danjinbi"):addChild(self.oneGold)
    util_spinePlay(self.oneGold,"idleframe")

    --lizi 
    self.lizi = util_createAnimation("FortuneGod_jindutiao_lizi.csb")
    self:findChild("Node_lizi"):addChild(self.lizi)
    self.lizi:findChild("Particle_1"):stopSystem()
end

function FortuneGodBonusProgressView:onEnter()

    FortuneGodBonusProgressView.super.onEnter(self)

end

function FortuneGodBonusProgressView:onExit()
    
    FortuneGodBonusProgressView.super.onExit(self)

end

function FortuneGodBonusProgressView:updateLoadingbar(per,update)
    local percent = self:getPercent(per)
    if update then
        self:updateLoadingAct(percent)
        
    else
        self:initLoadingbar(percent)
    end
end

function FortuneGodBonusProgressView:getPercent(percent)
    
    if percent then
        local percent1 = 0
        if percent > 100 then
            percent1 = 100
        elseif percent < 0 then
            percent1 = 0
        else
            percent1 = percent
        end
        return percent1
    end

    return percent
end

function FortuneGodBonusProgressView:initLoadingbar(percent)
    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
end

function FortuneGodBonusProgressView:updateLoadingAct(percent)
    self.actNode:stopAllActions() 
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    util_schedule(self.actNode,function( )
        oldPercent = oldPercent + 1

        if oldPercent >= percent then
            oldPercent = percent
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            util_spinePlay(self.oneGold,"actionframe",false)
            self.actNode:stopAllActions() 
        else
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
        end
    end,0.05)
end

--默认按钮监听回调
function FortuneGodBonusProgressView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")

    elseif  name == "Panel_dianji" or name == "Panel_dianji_0" then 
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")

    end
end

function FortuneGodBonusProgressView:showJiMan(func)
    self.lizi:findChild("Particle_1"):resetSystem()
    performWithDelay(self,function (  )
        self.lizi:findChild("Particle_1"):stopSystem()
        if func then
            func()
        end
    end,2)
end

return FortuneGodBonusProgressView