---
--xcyy
--2018年5月23日
--CatandMouseCollectBar.lua

local CatandMouseCollectBar = class("CatandMouseCollectBar",util_require("Levels.BaseLevelDialog"))

local COLLECT_NUM = 36

function CatandMouseCollectBar:initUI()

    self:createCsbNode("CatandMouse_shoujitiao.csb")
    self:runCsbAction("idleframe",true)
    self.actNode = cc.Node:create()
    self:addChild(self.actNode)
    self.changeX1 = 194
    self.changeX2 = 194
    self:createSaoGuang()
    self.isSaoGuang = true
end

function CatandMouseCollectBar:onEnter( )
    CatandMouseCollectBar.super.onEnter(self)
    schedule(self,function()
        self:upDateSaoGuang()
    end,3)
end

function CatandMouseCollectBar:onExit()
    CatandMouseCollectBar.super.onExit(self)
end

function CatandMouseCollectBar:createSaoGuang( )
    self.sapGuangLeft = util_createAnimation("CatandMouse_shoujitiao_sg.csb")
    self:findChild("Node_shoujitiao_sg"):addChild(self.sapGuangLeft)
    self.sapGuangLeft:findChild("CatandMouse_jindu_sg_5"):setVisible(true)
    self.sapGuangLeft:findChild("CatandMouse_jindu_sg_5_1"):setVisible(false)
    self.sapGuangRight = util_createAnimation("CatandMouse_shoujitiao_sg.csb")
    self:findChild("Node_shoujitiao_sg_0"):addChild(self.sapGuangRight)
    self.sapGuangRight:findChild("CatandMouse_jindu_sg_5"):setVisible(false)
    self.sapGuangRight:findChild("CatandMouse_jindu_sg_5_1"):setVisible(true)
    self.sapGuangLeft:setVisible(false)
    self.sapGuangRight:setVisible(false)
end

function CatandMouseCollectBar:upDateSaoGuang( )
    if self.isSaoGuang then
        local actList = {}
        local node = cc.Node:create()
        self:addChild(node)
        self.sapGuangLeft:setVisible(true)
        self.sapGuangRight:setVisible(true)
        local moveTo1 = cc.MoveTo:create(1, cc.p(self.changeX1,0))
        local moveTo2 = cc.MoveTo:create(1, cc.p(self.changeX2,0))
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            self.sapGuangLeft:runAction(moveTo2)
            self.sapGuangRight:runAction(moveTo1)
        end)
        actList[#actList + 1] = cc.DelayTime:create(1)
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            self.sapGuangLeft:setVisible(false)
            self.sapGuangRight:setVisible(false)
            self.sapGuangLeft:setPosition(cc.p(0,0))
            self.sapGuangRight:setPosition(cc.p(0,0))
        end)
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            node:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        node:runAction(sq)
    end
    
end

function CatandMouseCollectBar:initLoadingbar(percent1,percent2)
    local newPercent = self:setPercentForDecimal(percent2)
    self:findChild("mouse_jindutiao"):setPercent(newPercent)
    self:setPanelContentSize(newPercent)
    self:showActFire(newPercent)
end

function CatandMouseCollectBar:showActFire(percent)
    if percent <= 8/COLLECT_NUM * 100 then
        self:showCollectFire(1)
        self.isSaoGuang = false
    elseif percent >= 28/COLLECT_NUM * 100 then
        self.isSaoGuang = false
        self:showCollectFire(2)
    else
        self.isSaoGuang = true
        self:showCollectFire()
    end
end

function CatandMouseCollectBar:setPercentForDecimal(percent)
    local newPercent = percent
    if percent >= 15 and percent <= 17 then
        newPercent = 15.5
    elseif percent >= 32 and percent <= 34 then
        newPercent = 32.5
    elseif percent >= 66 and percent <= 68 then
        newPercent = 67
    elseif percent >= 83 and percent <= 85 then
        newPercent = 84.5
    end
    return newPercent
end

function CatandMouseCollectBar:setCatPercent( )
    self:findChild("cat_jindutiao"):setPercent(100)
end

function CatandMouseCollectBar:updateLoadingAct(loadBar, percent)
    self:showActFire(percent)
    local oldPercent = loadBar:getPercent()

    local panel = loadBar

    self.actNode:stopAllActions() 
    if oldPercent < percent then
        schedule(self.actNode,function( )
            oldPercent = oldPercent + 1
            
            if oldPercent >= percent then
                oldPercent = percent
                local newPercent = self:setPercentForDecimal(oldPercent)
                loadBar:setPercent(newPercent)
                self:setPanelContentSize(newPercent)
                self.actNode:stopAllActions() 
            else
                local newPercent = self:setPercentForDecimal(oldPercent)
                self:setPanelContentSize(newPercent)
                loadBar:setPercent(newPercent)
            end
        end,0.05)
    else
        schedule(self.actNode,function( )
            oldPercent = oldPercent - 1
            
            if oldPercent <= percent then
                oldPercent = percent
                local newPercent = self:setPercentForDecimal(oldPercent)
                loadBar:setPercent(newPercent)
                --设置火焰的尺寸
                self:setPanelContentSize(newPercent)
                self.actNode:stopAllActions() 
            else
                local newPercent = self:setPercentForDecimal(oldPercent)
                self:setPanelContentSize(newPercent)
                loadBar:setPercent(newPercent)
            end
        end,0.05)
    end
    
end

function CatandMouseCollectBar:updataProgress(leftNum,rightNum,update)
    if leftNum > COLLECT_NUM then
        leftNum = COLLECT_NUM
    end
    if rightNum > COLLECT_NUM then
        rightNum = COLLECT_NUM
    end
    self:upDataCollectNum(leftNum,rightNum)
    local percent1 = self:getPercent(leftNum)
    local percent2 = self:getPercent(rightNum)
    if update then
        self:updateLoadingAct(self:findChild("mouse_jindutiao"),percent2)
    else
        self:initLoadingbar(percent1,percent2)
    end
end

function CatandMouseCollectBar:getPercent(collectCount)
    local percent = 0
    if collectCount then
        if collectCount >= COLLECT_NUM then
            percent = 100
        elseif collectCount == 0 then
            percent = 0
        else
            percent = (collectCount / COLLECT_NUM) * 100
        end
    end
    return percent
end

function CatandMouseCollectBar:upDataCollectNum(leftNum,rightNum)
    self:findChild("m_lb_num1"):setString(leftNum)
    self:findChild("m_lb_num2"):setString(rightNum)
end

function CatandMouseCollectBar:showCollectFire(isShow)
    if isShow == 1 then
        self:runCsbAction("actionframe",true)
    elseif isShow == 2 then
        self:runCsbAction("actionframe1",true)
    else
        self:runCsbAction("idleframe",true)
    end
end

function CatandMouseCollectBar:setPanelContentSize(newPercent)
    --向下取整
    self.changeX1 = math.floor(394 * newPercent / 100)
    self.changeX2 = 394 - self.changeX1
    local size1 = self:findChild("Panel_lan"):getContentSize()
    local size2 = self:findChild("Panel_hong"):getContentSize()
    self:findChild("Panel_lan"):setContentSize(self.changeX1, size1.height)
    self:findChild("Panel_hong"):setContentSize(self.changeX2, size2.height)
end

function CatandMouseCollectBar:showFreeJiMan( )
    self.isSaoGuang = false
    self:runCsbAction("jiman")
end

return CatandMouseCollectBar