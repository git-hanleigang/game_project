---
--xcyy
--2018年5月23日
--BlazingMotorsTopView.lua

local BlazingMotorsTopView = class("BlazingMotorsTopView",util_require("base.BaseView"))


function BlazingMotorsTopView:initUI()

    self:createCsbNode("BlazingMotors_Jackpot.csb")

    self:updateTimes( "","" )
    self:findChild("m_lb_num_0"):setString( "") 

    self:findChild("BlazingMotors_wenzi_19"):setVisible(false)
    self:findChild("BlazingMotors_wenzi2_19"):setVisible(false)

    -- 汽车排气管 
    self.m_exhaust = util_spineCreate("BlazingMotors_di4", true, true)
    self:findChild("exhaus_fire"):addChild(self.m_exhaust)
    -- util_spinePlay(self.m_exhaust,"idleframe",true)


    self.m_JackPotBar = util_createView("CodeBlazingMotorsSrc.BlazingMotorsJackPopBarView")
    self.m_clippingNode =  util_Animateflash(self:findChild("JackpotClip"),"ui/caiqie.png",self.m_JackPotBar)
    self.m_JackPotBar:setPositionY(-130)

    self.m_TopViewRisingIdel = util_createView("CodeBlazingMotorsSrc.BlazingMotorsRisingIdelView")
    self:findChild("risingNode"):addChild(self.m_TopViewRisingIdel)
    self.m_TopViewRisingIdel:setVisible(false)

    self:findChild("logo"):setVisible(false)
    self:findChild("logo_0"):setVisible(false)
    if (display.height / display.width) >= 1.99 then
        self:findChild("logo"):setVisible(true)
    end
    if (display.height / display.width) >= 1.82 then
        self:findChild("logo_0"):setVisible(true)
    end
    

    
    
    
end

---
-- 更新freespin 剩余次数
--
function BlazingMotorsTopView:changeCharmsFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end


-- 更新并显示FreeSpin剩余次数
function BlazingMotorsTopView:updateFreespinCount( curtimes ,totalFsCount)
    if curtimes <= 1 then
        self:findChild("BlazingMotors_wenzi_19"):setVisible(true)
        self:findChild("BlazingMotors_wenzi2_19"):setVisible(true)
        
        self:findChild("BlazingMotors_wenzi_18"):setVisible(false)
        self:findChild("BlazingMotors_wenzi2_18"):setVisible(false)
    else
        self:findChild("BlazingMotors_wenzi_19"):setVisible(false)
        self:findChild("BlazingMotors_wenzi2_19"):setVisible(false)

        self:findChild("BlazingMotors_wenzi_18"):setVisible(true)
        self:findChild("BlazingMotors_wenzi2_18"):setVisible(true)
    end

    self:updateTimes( curtimes,totalFsCount )
    
end

function BlazingMotorsTopView:updateTimes( curtimes,totalFsCount )
     
    self:findChild("m_lb_num1"):setString( curtimes) 
    self:findChild("m_lb_num_1"):setString( curtimes) 
    
    -- self:findChild("m_lb_num_2"):setString(totalFsCount)

end

function BlazingMotorsTopView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function BlazingMotorsTopView:initMachine(machine)
    self.m_machine = machine
end

function BlazingMotorsTopView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count

        self:changeCharmsFreeSpinByCount(params)

        
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

-- 更新jackpot 数值信息
--
function BlazingMotorsTopView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_JackPotBar:findChild("BitmapFontLabel_1"),1,true)
    self:changeNode(self.m_JackPotBar:findChild("BitmapFontLabel_2"),2,true)
    self:changeNode(self.m_JackPotBar:findChild("BitmapFontLabel_3"),3)
    self:changeNode(self.m_JackPotBar:findChild("BitmapFontLabel_4"),4)
    self:changeNode(self.m_JackPotBar:findChild("BitmapFontLabel_5"),5)

    self:updateSize()
end

function BlazingMotorsTopView:updateSize()

    local label1=self.m_JackPotBar.m_csbOwner["BitmapFontLabel_1"]
    local label2=self.m_JackPotBar.m_csbOwner["BitmapFontLabel_2"]
    local info1={label=label1,sx=1.2,sy=1.2}
    local info2={label=label2,sx=1.1,sy=1.1}

    local label3=self.m_JackPotBar.m_csbOwner["BitmapFontLabel_3"]
    local label4=self.m_JackPotBar.m_csbOwner["BitmapFontLabel_4"]
    local info3={label=label3,sx=1.1,sy=1.1}
    local info4={label=label4,sx=1.1,sy=1.1}

    local label5=self.m_JackPotBar.m_csbOwner["BitmapFontLabel_5"]
    local info5={label=label5,sx=1.1,sy=1.1}


    self:updateLabelSize(info1,242)
    self:updateLabelSize(info2,224)
    self:updateLabelSize(info3,176)
    self:updateLabelSize(info4,155)
    self:updateLabelSize(info5,124)
end

function BlazingMotorsTopView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function BlazingMotorsTopView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BlazingMotorsTopView