---
--smy
--2018年4月17日
--JackPotTitleLayer.lua
local QuickHitJackPotLayer = class("FreeSpinBar", util_require("base.BaseView"))
QuickHitJackPotLayer.m_jackPotMaxNum = 5
QuickHitJackPotLayer.m_WinLightArray = {}

function QuickHitJackPotLayer:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Socre_QuickHit_Jackpot.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")

    self:hideWinnerImg()
    self.m_WinLightArray = {}

end

function QuickHitJackPotLayer:createWinLightCsbNode( index )
    
    for i = 1,self.m_jackPotMaxNum do
        local pos = 10 - i
        if index == pos then
            local light = util_createView("CodeQuickHitSrc.QuickHitJackPotWinLight")  
            self:findChild("Node_flash_"..pos):addChild(light)
            table.insert( self.m_WinLightArray, light ) 
        end
        
    end
end

function QuickHitJackPotLayer:showJackPotAni(index)
    self:hideOneLab( index )
    self:showOneWinnerImg( index )
end

function QuickHitJackPotLayer:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("ab_jp_range_9"),1,true)
    self:changeNode(self:findChild("ab_jp_range_8"),2,true)
    self:changeNode(self:findChild("ab_jp_range_7"),3,true)
    self:changeNode(self:findChild("ab_jp_range_6"),4,true)
    self:changeNode(self:findChild("ab_jp_range_5"),5,true)
    -- self:updateSize()

    self:updateLabelSize({label=self:findChild("ab_jp_range_9"),sx=1,sy=1},388)
    self:updateLabelSize({label=self:findChild("ab_jp_range_8"),sx=1,sy=1},355)
    self:updateLabelSize({label=self:findChild("ab_jp_range_7"),sx=1,sy=1},310)
    self:updateLabelSize({label=self:findChild("ab_jp_range_6"),sx=1,sy=1},277)
    self:updateLabelSize({label=self:findChild("ab_jp_range_5"),sx=1,sy=1},243)

end

--jackpot算法
function QuickHitJackPotLayer:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function QuickHitJackPotLayer:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function QuickHitJackPotLayer:onExit()

    self:removeDelayFunc()
end


function QuickHitJackPotLayer:hideWinnerImg( )
    for i=1,self.m_jackPotMaxNum do
        local pos = i + 4
        self:findChild("winner_"..pos):setVisible(false)
        self:findChild("Node_light_"..pos):setVisible(false)
        self:findChild("Node_flash_"..pos):setVisible(false)   
    end
    for k,v in pairs(self.m_WinLightArray) do
        v:removeFromParent()
    end
    self.m_WinLightArray = {}
end

function QuickHitJackPotLayer:showOneWinnerImg( pos )

        self:findChild("winner_"..pos):setVisible(true)
        self:findChild("winner_"..pos):setLocalZOrder(10)
        self:findChild("Node_light_"..pos):setVisible(true)
        self:findChild("Node_flash_"..pos):setVisible(true)
        

        self:createWinLightCsbNode(pos)

        self:createDelayFunc()
end
function QuickHitJackPotLayer:showJumpLab( )
    for i=1,self.m_jackPotMaxNum do
        local pos = i + 4
        self:findChild("ab_jp_range_"..pos):setVisible(true)
        -- self:findChild("QuickHit_fuhao"..pos):setVisible(true)
    end
end
function QuickHitJackPotLayer:hideOneLab( pos )
    
    self:findChild("ab_jp_range_"..pos):setVisible(false)
    -- self:findChild("QuickHit_fuhao"..pos):setVisible(false)
end

function QuickHitJackPotLayer:createDelayFunc( )
   self.m_DelayFunc =  scheduler.performWithDelayGlobal(function(  )
                        self.m_DelayFunc = nil
                        self:showJumpLab()
                        self:hideWinnerImg()
                        end,6,"QuickHitJackPotLayer")
end

function QuickHitJackPotLayer:removeDelayFunc( )
    if self.m_DelayFunc then
        self:showJumpLab()
        self:hideWinnerImg()
        scheduler.unscheduleGlobal(self.m_DelayFunc)
    end
end

return QuickHitJackPotLayer