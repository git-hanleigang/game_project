---
--xcyy
--2018年5月23日
--DiscoFeverFreespinOverView.lua

local DiscoFeverFreespinOverView = class("DiscoFeverFreespinOverView",util_require("base.BaseView"))
DiscoFeverFreespinOverView.m_CanClicked = nil
DiscoFeverFreespinOverView.m_CallFunc = nil


function DiscoFeverFreespinOverView:initUI()

    self:createCsbNode("DiscoFever/FreeSpinOver.csb")
    self.m_CanClicked = false

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self.m_CanClicked = true
    end)
    
end

function DiscoFeverFreespinOverView:changeLab(jp,nor,total )
    local JpScore = self:findChild("ml_b_coins2") 
    if JpScore then
        JpScore:setString(jp)
        self:updateLabelSize({label=JpScore,sx=1.2,sy=1.2},476)
    end
    local norScore = self:findChild("ml_b_coins1")
    if norScore then
        norScore:setString(nor)
        self:updateLabelSize({label=norScore,sx=1.2,sy=1.2},476)
    end

    local totalScore = self:findChild("ml_b_coins3")
    if totalScore then
        totalScore:setString(total)
        self:updateLabelSize({label=totalScore,sx=1.2,sy=1.2},476)
    end
 
end

function DiscoFeverFreespinOverView:initCallFunc( func)
    self.m_CallFunc = function(  )
       if func then
            func()
       end
    end
end


function DiscoFeverFreespinOverView:onEnter()
 

end

function DiscoFeverFreespinOverView:onExit()
 
end

--默认按钮监听回调
function DiscoFeverFreespinOverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        if self.m_CanClicked then

            self.m_CanClicked = false
            
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_CloseView.mp3")

            self:runCsbAction("over",false,function(  )
                if self.m_CallFunc then
                    self.m_CallFunc()
                end
                self:removeFromParent()
            end)
        end
    end
end


return DiscoFeverFreespinOverView