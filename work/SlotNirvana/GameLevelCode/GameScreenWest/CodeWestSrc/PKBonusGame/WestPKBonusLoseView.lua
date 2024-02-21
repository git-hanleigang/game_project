---
--xcyy
--2018年5月23日
--WestPKBonusLoseView.lua

local WestPKBonusLoseView = class("WestPKBonusLoseView",util_require("base.BaseView"))

WestPKBonusLoseView.m_machine = nil

function WestPKBonusLoseView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("West/BonusGamelose.csb")

    self:addClick( self:findChild("click_1") )
    self:addClick( self:findChild("click_2") )
    self:addClick( self:findChild("click_3") )

    self.m_Ma1 = util_createAnimation("BonusGamelose_ma1.csb")
    self:findChild("ma"):addChild(self.m_Ma1)
    self.m_Ma2 = util_createAnimation("BonusGamelose_ma2.csb")
    self:findChild("ma"):addChild(self.m_Ma2)
    self.m_Ma3 = util_createAnimation("BonusGamelose_ma3.csb")
    self:findChild("ma"):addChild(self.m_Ma3)

    self:initRewordLab( )

    
    
    


    self.m_Hero = util_createAnimation("West/BonusGamelose_ren.csb")
    self:findChild("ren"):addChild(self.m_Hero)
    self.m_Hero:runCsbAction("ildeframe_1",true)

    self:runCsbAction("ildeframe_1",true)
    self.m_Ma1:runCsbAction("ildeframe_1")
    self.m_Ma2:runCsbAction("ildeframe_1")
    self.m_Ma3:runCsbAction("ildeframe_1")

end




function WestPKBonusLoseView:onEnter()
 

end

function WestPKBonusLoseView:showBeginAct( func)
    
    if func then
        func()
    end

end
function WestPKBonusLoseView:onExit()
 
end

--默认按钮监听回调
function WestPKBonusLoseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_1" then
        
        if self.m_machine:isCanTouch( ) then
            gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_ClickHorse.mp3")
            self.m_machine:setClickData( 0 )
            print(" WestPKBonusLoseView 第几个 @@@@ ".. 0)
            self:findChild("click_1"):setVisible(false)
            self:findChild("click_2"):setVisible(false)
            self:findChild("click_3"):setVisible(false)
        end

    elseif name == "click_2" then

        if self.m_machine:isCanTouch( ) then
            gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_ClickHorse.mp3")
            self.m_machine:setClickData( 1 )
            print(" WestPKBonusLoseView 第几个 @@@@ ".. 1)
            self:findChild("click_1"):setVisible(false)
            self:findChild("click_2"):setVisible(false)
            self:findChild("click_3"):setVisible(false)
        end
    elseif name == "click_3" then

        if self.m_machine:isCanTouch( ) then
            gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_ClickHorse.mp3")
            self.m_machine:setClickData( 2 )
            print(" WestPKBonusLoseView 第几个 @@@@ ".. 2)
            self:findChild("click_1"):setVisible(false)
            self:findChild("click_2"):setVisible(false)
            self:findChild("click_3"):setVisible(false)
        end
    end

    

end

function WestPKBonusLoseView:initRewordLab( )
    for i=1,3 do

        local zi = self["m_Ma"..i]:findChild("ma" .. i ..  "_ma_zi")
        local rewordlab = util_createAnimation("West_bonusgame_lose_ma_zi.csb")
        zi:addChild(rewordlab)
        self["rewordlab".. i] = rewordlab
        rewordlab:setVisible(false)
        
    end
end

function WestPKBonusLoseView:restAllClickBtn( )
    self:runCsbAction("ildeframe_1",true)

    self.m_Ma1:runCsbAction("ildeframe_1")
    self.m_Ma2:runCsbAction("ildeframe_1")
    self.m_Ma3:runCsbAction("ildeframe_1")


    for i=1,3 do

        local mask = self["m_Ma"..i]:findChild("ma".. i .."_ma_hei")
        mask:setVisible(true)
        local zi = self["rewordlab".. i]
        zi:setVisible(false)

        local guang1 = self["m_Ma"..i]:findChild("Socre_West_ma_".. i .."_Guang_1")
        guang1:setVisible(true)

        local guang2 = self["m_Ma"..i]:findChild("Socre_West_ma_".. i .."_Guang_2")
        guang2:setVisible(true)

        

        self:findChild("click_".. i):setVisible(true)

    end
end

return WestPKBonusLoseView