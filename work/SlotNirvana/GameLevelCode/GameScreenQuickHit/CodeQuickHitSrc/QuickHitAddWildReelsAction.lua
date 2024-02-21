---
--xhkj
--2018年6月11日
--QuickHitAddWildReelsAction.lua

local QuickHitAddWildReelsAction = class("QuickHitAddWildReelsAction", util_require("base.BaseView"))
QuickHitAddWildReelsAction.wildNum = nil
QuickHitAddWildReelsAction.jackPotNodeArray = nil

QuickHitAddWildReelsAction.SizeY = 306
QuickHitAddWildReelsAction.SizeX = 132
QuickHitAddWildReelsAction.NeedTime = 0

QuickHitAddWildReelsAction.SizeYArray ={57.5,153,248.5}

QuickHitAddWildReelsAction.downTime = 0.4
QuickHitAddWildReelsAction.downintervalTime = 0.1

QuickHitAddWildReelsAction.jumpTime = 0.3
QuickHitAddWildReelsAction.jumpintervalTime = 0.05

QuickHitAddWildReelsAction.m_AddPos = 55

QuickHitAddWildReelsAction.NeedTime = 0

function QuickHitAddWildReelsAction:initUI(num)

    local resourceFilename="Socre_QuickHit_reel_win_wild.csb"
    self:createCsbNode(resourceFilename)
    self.wildNum = num 
    self.jackPotNodeArray = {}

    self:createJackPotSymbol()

    util_setCascadeOpacityEnabledRescursion(self,true)


     

    local timeJump = self:symbolJumpRun()
    
    performWithDelay(self,function() 

        self:symbolDownRun()
        
    end,timeJump + 0.2)

   local  TimeDown = self.downTime  + (self.downintervalTime * math.floor( self.wildNum/5) )

    self.NeedTime =  timeJump + TimeDown + 0.2 
    

    


end

function QuickHitAddWildReelsAction:getWaitTime( )
    return self.NeedTime
end

function QuickHitAddWildReelsAction:createJackPotSymbol()

    local index = 0
    local zorder = 0
    for i=1,self.wildNum do
        if index == 5 then
            index = 0
            zorder = zorder + 1
        end
        local fathername = "sp_reel_wild_"..index

        local quickHitsymbol = util_spineCreate("Socre_QuickHit_Wild", true,true)  -- util_createView("CodeQuickHitSrc.QuickHitAddWildSymbol","Socre_QuickHit_Wheel1.csb")
        self:findChild(fathername):addChild(quickHitsymbol)
        quickHitsymbol.index = index 
        local startPOS = cc.p(self:findChild("startPos"):getPosition())
        local unitPos = self:findChild("startPos"):getParent():convertToWorldSpace(startPOS)

        local pos = self:findChild(fathername):convertToNodeSpace(unitPos)
        quickHitsymbol:setPosition(pos)
        quickHitsymbol:setScale(0.1)
        quickHitsymbol:setLocalZOrder(100 - zorder*10)

        table.insert( self.jackPotNodeArray,quickHitsymbol )

        index = index + 1
    end
   
end

function QuickHitAddWildReelsAction:symbolJumpRun( )
    local JumpRunWaitTime = 0
    local waitTimeIndex = 0


    for k,v in pairs(self.jackPotNodeArray) do

        local node = v
        local nodepos = cc.p(node:getPosition())
        local PosY = 306 + self.SizeYArray[1] + self.m_AddPos  * waitTimeIndex
        local PosX = self.SizeX /2
        local endPos =cc.p(PosX,PosY ) 
        local time = self.jumpTime
        local func = nil
        performWithDelay(self,function() 
            if node.index == 4 then
                gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wild_jump.mp3")
            end
            self:nodeJumpAction( node,endPos,time,func )

        end,self.jumpintervalTime * waitTimeIndex)

        if v.index == 4 then
            waitTimeIndex = waitTimeIndex + 1
        end
        
    end
    JumpRunWaitTime = self.jumpTime + (self.jumpintervalTime * waitTimeIndex)

    return JumpRunWaitTime
end

function QuickHitAddWildReelsAction:symbolDownRun( )

    local waitTimeIndex = 0
    local Boompos = nil


    for k,v in pairs(self.jackPotNodeArray) do
        

        local node = v
        local nodepos = cc.p(node:getPosition())
        local endPos =cc.p(nodepos.x,nodepos.y - 430 - self.m_AddPos * waitTimeIndex) 
        if not Boompos then
            Boompos =  cc.p(nodepos.x,nodepos.y - 430- self.m_AddPos * waitTimeIndex)
        end
        local time = self.downTime
        local func = function(  )
            node:setVisible(false)
        end
        performWithDelay(self,function() 

            self:nodeAction( node,endPos,time,func )
        end,self.downintervalTime * waitTimeIndex)
        
        if v.index == 4 then
            waitTimeIndex = waitTimeIndex + 1
        end
        
    end

    -- performWithDelay(self,function() 
    --     for i=1,5 do
    --         local index = i - 1 
    --         local fathername = "sp_reel_wild_"..index
    --         local FlashAction = util_createView("CodeQuickHitSrc.QuickHitAddWildReelsFlashAction")
    --         local PosX = self.SizeX /2
    --         local PosY = self.SizeY /2
    --         FlashAction:setPosition(cc.p(PosX,PosY))
    --         FlashAction:setLocalZOrder(100)
    --         self:findChild(fathername):addChild(FlashAction)
    --     end

        

    -- end, (self.downintervalTime * (waitTimeIndex - 1)))


    gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wild_down.mp3")

    performWithDelay(self,function() 
        for i=1,5 do
            local boomAction = util_createView("CodeQuickHitSrc.QuickHitAddWildReelsBoomAction")
            local pos = i - 1
            self:findChild("sp_reel_wild_"..pos):addChild(boomAction)
            boomAction:setLocalZOrder(1000)
            --if Boompos then
                boomAction:setPosition(cc.p(self.SizeX /2,-20))
            --end
        end
       
        
    end, 0.2)

    
    

end

function QuickHitAddWildReelsAction:nodeJumpAction( node,endPos,flyTime,func )
 
    local actionList = {}
      
      actionList[#actionList + 1] = cc.CallFunc:create(function()
            local scaleLIst = {}
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime,1)
            node:runAction(cc.Sequence:create(scaleLIst))
      end)
      
     local startPos =  cc.p(node:getPosition()) 
      

      actionList[#actionList + 1] = cc.EaseInOut:create(cc.JumpTo:create(flyTime, cc.p(endPos),200, 1),1)

      
      node:runAction(cc.Sequence:create(actionList))
end

function QuickHitAddWildReelsAction:nodeAction( node,endPos,time,func )
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(time,cc.p(endPos))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function QuickHitAddWildReelsAction:onEnter()
   

end


function QuickHitAddWildReelsAction:onExit()
    
end

function QuickHitAddWildReelsAction:removeSelf(func)
    if func then
        func()
    end

    self:removeFromParent()
end

function QuickHitAddWildReelsAction:initMachine(machine)
    self.m_machine = machine
end

return QuickHitAddWildReelsAction