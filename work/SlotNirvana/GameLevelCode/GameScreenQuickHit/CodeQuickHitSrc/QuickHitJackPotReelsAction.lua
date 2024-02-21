---
--xhkj
--2018年6月11日
--QuickHitJackPotReelsAction.lua

local QuickHitJackPotReelsAction = class("QuickHitJackPotReelsAction", util_require("base.BaseView"))
QuickHitJackPotReelsAction.jackPotNum = nil
QuickHitJackPotReelsAction.jackPotNodeArray = nil

QuickHitJackPotReelsAction.SizeY = 306
QuickHitJackPotReelsAction.SizeX = 132

QuickHitJackPotReelsAction.SizeYArray ={53, 153, 253}

QuickHitJackPotReelsAction.waitTime = 0
QuickHitJackPotReelsAction.Reboundtime = 0.2
QuickHitJackPotReelsAction.ReboundDistance = 60


function QuickHitJackPotReelsAction:initUI(num)

    local resourceFilename="Socre_QuickHit_reel.csb"
    self:createCsbNode(resourceFilename)
    self.jackPotNum = num 
    self.jackPotNodeArray = {}

    self:createJackPotSymbol()

    util_setCascadeOpacityEnabledRescursion(self,true)

    self:runCsbAction("show")
    performWithDelay(self,function() 

        self:symbolRun()
    end,0.16)

    self.waitTime = 0.16 + 1.4 + 3 + self.Reboundtime

end

function QuickHitJackPotReelsAction:createJackPotSymbol()
    local indexArray = {1,2,3,1,1,2,2,3,3}
    for i=1,self.jackPotNum do
        local fathername = "sp_reel_2"
        local index = indexArray[i]
        local col = 2
        if i > 3 then
            if i%2 == 0 then
                col = 1
                fathername = "sp_reel_1"
            else
                col = 3
                fathername = "sp_reel_3"
            end
        end
        local quickHitsymbol = util_spineCreate("Socre_QuickHit", true,true)  -- util_createView("CodeQuickHitSrc.QuickHitReelsSymbol")
        self:findChild(fathername):addChild(quickHitsymbol)
        local PosY = 306 + self.SizeYArray[index]
        local PosX = self.SizeX /2
        quickHitsymbol:setPosition(PosX,PosY)
        quickHitsymbol.col  = col

        table.insert( self.jackPotNodeArray,quickHitsymbol )
    end
end

function QuickHitJackPotReelsAction:symbolRun( )

    local time = 0.3

    gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_small_change_collor.mp3")

    for k,v in pairs(self.jackPotNodeArray) do
        local waitTime = v.col - 1

        local node = v
        local nodepos = cc.p(node:getPosition())
        local endPos =cc.p(nodepos.x,nodepos.y - 306 - self.ReboundDistance) 
        local ReboundPos = cc.p(nodepos.x,nodepos.y - 306 ) 
        

        util_spinePlay(node, "idleframe", true)
        local func = function(  )
            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_jackPot_Down.mp3")  

            
        end
        performWithDelay(self,function() 
            self:nodeAction( node,endPos,time,func,ReboundPos )
        end,0.2 * waitTime)
        
    end

    performWithDelay(self,function() 

        performWithDelay(self,function() 
            for k,v in pairs(self.jackPotNodeArray) do
                util_spinePlay(v, "actionframe", true)
            end
        end,3)

        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_jackPot_Tip.mp3")
        
    end,time+1)

end

function QuickHitJackPotReelsAction:nodeAction( node,endPos,time,func, ReboundPos)
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(time,cc.p(endPos))
    actionList[#actionList + 1] = cc.MoveTo:create(self.Reboundtime,cc.p(ReboundPos))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function QuickHitJackPotReelsAction:onEnter()
   

end


function QuickHitJackPotReelsAction:onExit()
    
end

function QuickHitJackPotReelsAction:removeSelf()
    self:runCsbAction("over",false,function(  )
        self:removeFromParent()
    end)
end

function QuickHitJackPotReelsAction:initMachine(machine)
    self.m_machine = machine
end

function QuickHitJackPotReelsAction:getWaitTime( )
    return self.waitTime
end

return QuickHitJackPotReelsAction