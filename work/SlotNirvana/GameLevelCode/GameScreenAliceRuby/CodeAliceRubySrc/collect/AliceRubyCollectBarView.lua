---
--xcyy
--2018年5月23日
--AliceRubyCollectBarView.lua

local AliceRubyCollectBarView = class("AliceRubyCollectBarView",util_require("base.BaseView"))

function AliceRubyCollectBarView:initUI()

    self:createCsbNode("AliceRuby_top.csb")
    
    self.tuZiNode = self:findChild("Alice_jindu_tuzi")
    self.tuZiHead = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectActView","AliceRuby_jindu_tuzi")
    self.tuZiNode:addChild(self.tuZiHead)
    self.tuZiHead:runCsbAction("idleframe")
    

    self:initLoadingbar(0)
    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self:addClick(self.m_csbOwner["map"])
end

function AliceRubyCollectBarView:onEnter()
 

end
-- 兔子渐显
function AliceRubyCollectBarView:setTuziShow( )
    self.tuZiHead:runCsbAction("idleframe")
end

--兔子渐隐
function AliceRubyCollectBarView:setTuziHide( func)
    self.tuZiHead:runCsbAction("over",false,function (  )
        if func then
            func()
        end
    end)

end

function AliceRubyCollectBarView:initLoadingbar(percent)
    self:findChild("Alice_jindutiao"):setPercent(percent)
    local width = self:findChild("Alice_jindutiao"):getContentSize().width
    local posX = width*percent/100
    self.tuZiNode:setPosition(posX-410,11)
end

function AliceRubyCollectBarView:updateLoadingbar(collectCount,needCount,update)
    local percent = self:getPercent(collectCount,needCount)
    if update then
        self:initLoadingbar(percent)
    else
        self:updateLoadingAct(self:findChild("Alice_jindutiao"),percent)
    end
end

function AliceRubyCollectBarView:updateLoadingAct(loadBar, percent)
    
    local oldPercent = loadBar:getPercent()

    local panel = loadBar

    self.actNode:stopAllActions() 
    local startIndex = 0
    schedule(self.actNode,function( )
        oldPercent = oldPercent + 1
        startIndex = startIndex + 1
        if startIndex == 1 or startIndex % 6 == 0 then      --为了保证播完整的跳跃动画
            self.tuZiHead:runCsbAction("actionframe")   --兔子跳跃   
        end
        
        if oldPercent >= percent then
            oldPercent = percent
            loadBar:setPercent(oldPercent)
            self:changeTuziPos( panel,oldPercent)
            self.actNode:stopAllActions() 
        else
            loadBar:setPercent(oldPercent)
            self:changeTuziPos( panel,oldPercent)
        end
    end,0.05)
end


function AliceRubyCollectBarView:getPercent(collectCount,needCount)
    local percent = 0
    if collectCount and needCount  then
        if collectCount >= needCount and needCount ~= 0 then
            percent = 100
        elseif collectCount == 0 and needCount == 0 then
            percent = 0
        else
            percent = (collectCount / needCount) * 100
        end
    end
    return percent
end

function AliceRubyCollectBarView:changeTuziPos(node,percent)
    local width = node:getContentSize().width
    local posX = width*percent/100
    self.tuZiNode:setPosition(posX-410,11)
end

--锁定进度条
function AliceRubyCollectBarView:lock(betLevel)
    self.m_iBetLevel = betLevel
    self.tuZiHead:setVisible(false)
    self:stopAllActions()
    self:runCsbAction("lock",false,function (  )
        self:idle()
    end)
end
--解锁进度条
function AliceRubyCollectBarView:unLock(betLevel)
    self.m_iBetLevel = betLevel
    self:findChild("Particle_1"):setVisible(true)
    self:findChild("Particle_1"):setDuration(0.5)
    self:findChild("Particle_1"):resetSystem()
    self.tuZiHead:setVisible(true)
    self.tuZiHead:runCsbAction("show")
    self:stopAllActions()
    self:runCsbAction("unlock", false, function()
        
        self:idle()
        self:findChild("Particle_1"):stopSystem()
        self:findChild("Particle_1"):setVisible(false)
    end)
end

function AliceRubyCollectBarView:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self:runCsbAction("lock", true)
    else
        self:runCsbAction("idle", true)
    end
end

function AliceRubyCollectBarView:onExit()
 
end

--默认按钮监听回调
function AliceRubyCollectBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Alice_jindu_tishi" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")
    elseif name == "map" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end


return AliceRubyCollectBarView