---
--xcyy
--2018年5月23日
--DiscoFeverJackPotBarView.lua

local DiscoFeverJackPotBarView = class("DiscoFeverJackPotBarView",util_require("base.BaseView"))
DiscoFeverJackPotBarView.m_actionName = {"UIorange","UIpurple","UIgreen","UIred"}
DiscoFeverJackPotBarView.m_NormalactionName = "UIblue"
DiscoFeverJackPotBarView.m_FsMusicalSpineName = {"DiscoFever_freespin_yellow","DiscoFever_freespin_purple","DiscoFever_freespin_green","DiscoFever_freespin_red"}
DiscoFeverJackPotBarView.m_NormalMusicalSpineName = "DiscoFever_normal_blue"
function DiscoFeverJackPotBarView:initUI()

    self:createCsbNode("DiscoFever_jackpot.csb")

    self:createMusicalSpine( )

    self:creatrJPWinActiom()

    self:hideAllJpWinImg(  )

    self.m_jpUpgradeView = util_createView("CodeDiscoFeverSrc.DiscoFeverJackPotjpUpgradeView")
    self:findChild("jpupgrade"):addChild(self.m_jpUpgradeView)
    self.m_jpUpgradeView:setVisible(false)

    self.m_jpUpgradeView2 = util_createView("CodeDiscoFeverSrc.DiscoFeverJackPotjpUpgrade_2_View")
    self:findChild("jpupgrade"):addChild(self.m_jpUpgradeView2)
    self.m_jpUpgradeView2:setVisible(false)
    
end

function DiscoFeverJackPotBarView:creatrJPWinActiom( )

    for index = 1,5 do
        local name = "jpnode_" .. index
        self[name] = util_createView("CodeDiscoFeverSrc.DiscoFeverJPWinView")
        self:findChild(name):addChild(self[name])
        self[name]:setVisible(false)
    end
    
    
end

function DiscoFeverJackPotBarView:showOneJPAction( index )
    if index == nil then
        return
    end

    
    self:hideAllJpWinImg()
    self:hideAllJPAction()

    self:showJpWinImg( 6 - index )
    
    local name = "jpnode_" .. 6 - index
    if self[name] then
        self[name]:setVisible(true)
        self[name]:runCsbAction("animation0",true)
    end 
end

function DiscoFeverJackPotBarView:hideAllJPAction( )
    for index = 1,5 do
        local name = "jpnode_" .. index
        if self[name] then
            self[name]:setVisible(false)
            self[name]:runCsbAction("animation0")
        end
    end
end

function DiscoFeverJackPotBarView:createMusicalSpine( )
    for k,v in pairs(self.m_FsMusicalSpineName) do
        local name = v
        self[name] = util_spineCreateDifferentPath(name,"yinjie_1", true, true)
        self[name]:setVisible(false)
        self:findChild("Musical"):addChild(self[name])
    end

    self[self.m_NormalMusicalSpineName] = util_spineCreateDifferentPath(self.m_NormalMusicalSpineName,"yinjie_1", true, true)
    self:findChild("Musical"):addChild(self[self.m_NormalMusicalSpineName])
    
    performWithDelay(self,function(  )
        if self.m_machine:getFreatureIsFreeSpin()  then

        elseif self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
            
        else
            util_spinePlay(self[self.m_NormalMusicalSpineName],"idleframe",true)
        end
    end,4)

end

function DiscoFeverJackPotBarView:toFreespin( )

    self[self.m_NormalMusicalSpineName]:setVisible(false)
    util_spinePlay(self[self.m_NormalMusicalSpineName],"idleframe",false)
    
    
end

function DiscoFeverJackPotBarView:toNormal( )

    self[self.m_NormalMusicalSpineName]:setVisible(true)
    util_spinePlay(self[self.m_NormalMusicalSpineName],"idleframe",true)
    self:runCsbAction(self.m_NormalactionName,true)
    self:runMusicalSpineAction(false )
    self:updateMusicalSpine( )
end

function DiscoFeverJackPotBarView:runMusicalSpineAction(state )
    for k,v in pairs(self.m_FsMusicalSpineName) do
        local name = v
        util_spinePlay(self[name],"idleframe",state)
    end
end

function DiscoFeverJackPotBarView:updateMusicalSpine(index )

    for k,v in pairs(self.m_FsMusicalSpineName) do
        local name = v
        if index == k then
            self:changeFsJPAction(index)
            self[name]:setVisible(true)
        else
            self[name]:setVisible(false)
        end
        
    end

    
end

function DiscoFeverJackPotBarView:onExit()
 
end

function DiscoFeverJackPotBarView:changeFsJPAction(index)
    if index < 0 then
        index = 1
    end

    if index > #self.m_actionName then
        index = #self.m_actionName
    end

    

    local actionName = self.m_actionName[index]
    self:runCsbAction(actionName,true)
end

function DiscoFeverJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function DiscoFeverJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end



-- 更新jackpot 数值信息
--
function DiscoFeverJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("BitmapFontLabel_1"),1,self.m_machine:checkJpBarIsJump(1))
    self:changeNode(self:findChild("BitmapFontLabel_2"),2,self.m_machine:checkJpBarIsJump(2))
    self:changeNode(self:findChild("BitmapFontLabel_3"),3,self.m_machine:checkJpBarIsJump(3))
    self:changeNode(self:findChild("BitmapFontLabel_4"),4,self.m_machine:checkJpBarIsJump(4))
    self:changeNode(self:findChild("BitmapFontLabel_5"),5,self.m_machine:checkJpBarIsJump(5))
    self:updateSize()
end

function DiscoFeverJackPotBarView:updateSize()

    local label1=self.m_csbOwner["BitmapFontLabel_1"]
    local label2=self.m_csbOwner["BitmapFontLabel_2"]
    local label3=self.m_csbOwner["BitmapFontLabel_3"]
    local label4=self.m_csbOwner["BitmapFontLabel_4"]
    local label5=self.m_csbOwner["BitmapFontLabel_5"]

    local info1={label=label1,sx = 1.7,sy = 1.7}
    local info2={label=label2,sx = 1.6,sy = 1.6}
    local info3={label=label3,sx = 1.5,sy = 1.5}
    local info4={label=label4,sx = 1.4,sy = 1.4}
    local info5={label=label5,sx = 1.3,sy = 1.3}

    self:updateLabelSize(info1,238)
    self:updateLabelSize(info2,211)
    self:updateLabelSize(info3,173)
    self:updateLabelSize(info4,146)
    self:updateLabelSize(info5,119)
end


function DiscoFeverJackPotBarView:changeNode(label,index,isJump)
    --if isJump then
        local value=self.m_machine:BaseMania_updateJackpotScore(index)

        if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
            value = self.m_machine:getNetJackpotScore(index)
        end
        label:setString(util_formatCoins(value,20))
   -- end
    
end

function DiscoFeverJackPotBarView:hideAllJpWinImg(  )

    for i=1,5 do
        local name = "DiscoFever_jackpot_zhongjaing_" .. i + 8
        local img =  self:findChild(name)
        if img then
            img:setVisible(false)
        end
    end
    
end

function DiscoFeverJackPotBarView:showJpWinImg( index )
    local name = "DiscoFever_jackpot_zhongjaing_" .. index + 8
    local img =  self:findChild(name)
    if img then
        img:setVisible(true)
    end
end


return DiscoFeverJackPotBarView