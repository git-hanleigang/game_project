--
-- bet选择界面
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptLeaveGameTip = class("MiracleEgyptLeaveGameTip", util_require("base.BaseView"))

MiracleEgyptLeaveGameTip.m_CallFunc  = nil



function MiracleEgyptLeaveGameTip:initUI(  )

    self:createCsbNode("MiracleEgypt/leaveGameTip.csb")

    self.m_CallFunc = nil
    self.m_Clicked = false
end



function MiracleEgyptLeaveGameTip:setCallFunc( func)

    self.m_CallFunc = func

end

function MiracleEgyptLeaveGameTip:showAction( func )

    local runName = "start"

    self:runCsbAction(runName,false,func)
end

function MiracleEgyptLeaveGameTip:removeSelf( func )

    self:runCsbAction("over",false,function(  )
        self.m_Clicked = false
        self:setVisible(false)

        if func then
            func()
        end
    end) 

end

--结束监听
function MiracleEgyptLeaveGameTip:clickEndFunc(sender)

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
            self:removeSelf(function(  )
                
            end)
            if self.m_CallFunc then
                self.m_CallFunc()
            end

        end
    end
end

return  MiracleEgyptLeaveGameTip