---
--xcyy
--2018年5月23日
--OZChooseView.lua

local OZChooseView = class("OZChooseView",util_require("base.BaseView"))
OZChooseView.m_click = false
OZChooseView.m_machine = nil


function OZChooseView:initUI(machine)

    self:createCsbNode("OZ/GameScreenOZ_select.csb")

    self.m_click = false
    self.m_machine = machine

    gLobalSoundManager:playSound("OZSounds/music_OZ_ChooseView_show.mp3")

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self:addClick(self:findChild("click_1"))
        self:addClick(self:findChild("click_2"))
        self:addClick(self:findChild("click_3"))
        self:addClick(self:findChild("click_4"))
    end)


end


function OZChooseView:onEnter()
 

end

function OZChooseView:setEndCall( func )
    self.m_endCall = function(  )
        if func then
            func()
        end
    end
end

function OZChooseView:closeUI(  )

    
    local kuangName = {"kuang_huang","kuang_lv","kuang_lan","kuang_zi"}

    local kuang = util_spineCreate(kuangName[self.m_machine.m_chooseIndex + 1],true,true)
    self:findChild(kuangName[self.m_machine.m_chooseIndex + 1]):addChild(kuang)
    util_spinePlay(kuang, kuangName[self.m_machine.m_chooseIndex + 1],false)

    self:runCsbAction("over"..(self.m_machine.m_chooseIndex + 1),false,function(  )
        if self.m_endCall then
            self.m_endCall()
        end
    end)
    
end

function OZChooseView:onExit()
 
end



--默认按钮监听回调
function OZChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        
        return
    end

    self.m_click = true

    if name == "click_1" then

        self.m_machine.m_chooseIndex = 0

    elseif name == "click_2" then

        self.m_machine.m_chooseIndex = 1

    elseif name == "click_3" then
        self.m_machine.m_chooseIndex = 2

    elseif name == "click_4" then
        self.m_machine.m_chooseIndex = 3

    end

    gLobalSoundManager:playSound("OZSounds/music_OZ_ChooseView_ClickToEnd.mp3")

    --performWithDelay(self,function(  )
        self:closeUI( )
    -- end,1.5)
    

end


return OZChooseView