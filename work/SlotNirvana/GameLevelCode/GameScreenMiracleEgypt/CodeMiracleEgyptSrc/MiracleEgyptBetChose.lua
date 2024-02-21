--
-- bet选择界面
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptBetChose = class("MiracleEgyptBetChose", util_require("base.BaseView"))

MiracleEgyptBetChose.m_ActionName1 = {"Bet1start","Bet1idle","Bet1over"}
MiracleEgyptBetChose.m_ActionName2 = {"Bet2start","Bet2idle","Bet2over"}

MiracleEgyptBetChose.m_ActionType = nil
MiracleEgyptBetChose.m_CallFunc = nil
MiracleEgyptBetChose.m_FirstIn = true
MiracleEgyptBetChose.m_Clicked = false



function MiracleEgyptBetChose:initUI(  )

    self:createCsbNode("MiracleEgypt/Betchose.csb")

    self.m_Clicked = false
end

function MiracleEgyptBetChose:setMinBetStr( num)

    self:findChild("BitmapFontLabel_6"):setString( num)

    local node = self:findChild("BitmapFontLabel_6")
    self:updateLabelSize({label = node,sx = 1,sy=1}, 663)
end

function MiracleEgyptBetChose:setBetChoseInfo( actType,func,machine )
    -- actType --1 catView
    -- actType --2 betview
    self.m_ActionType = actType
    self.m_CallFunc = func
    self.m_machine = machine
end

function MiracleEgyptBetChose:showAction( index,loop,func )

    if index == 1 and self.m_FirstIn == false then
        gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_View_Start.mp3")
    end

    self.m_FirstIn = false

    local runName = self["m_ActionName"..self.m_ActionType][index]

    self:runCsbAction(runName,loop,func)
end

function MiracleEgyptBetChose:removeSelf( )

    self:showAction(3,false,function(  )
        self.m_Clicked = false
        self:setVisible(false)
    end) 

end

--结束监听
function MiracleEgyptBetChose:clickEndFunc(sender)

    
    
    if self.m_Clicked == true then
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    self.m_Clicked = true

    if sender then
        local name = sender:getName()
        if name == "Button_Reject" then

            self:removeSelf()
        elseif name == "Button_Activeae" then
            
            self.m_machine:changeBetToCatOpen()
            
            self:removeSelf()
        elseif name == "Button_Reject_2" then

            globalData.slotRunData.iLastBetIdx  =  self.m_machine.m_oldBetID 

            self:removeSelf()
        elseif name == "Button_Activeae_2" then
            
            self.m_machine:changeFirstBet()
            
            self:removeSelf()
        end
    end
end

return  MiracleEgyptBetChose