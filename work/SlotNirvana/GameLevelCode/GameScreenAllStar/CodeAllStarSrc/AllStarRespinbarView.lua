---
--xcyy
--2018年5月23日
--AllStarRespinbarView.lua

local AllStarRespinbarView = class("AllStarRespinbarView",util_require("base.BaseView"))


function AllStarRespinbarView:initUI()

    self:createCsbNode("AllStar_bonus_xiaoban.csb")


    self.m_BoomAct = util_createView("CodeAllStarSrc.AllStarRespinbarBoomActView")
    self:findChild("Node_3xiaoban"):addChild(self.m_BoomAct)
    self.m_BoomAct:setVisible(false)

end

function AllStarRespinbarView:updateTimes(times )
    if times == 3 then
        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_respin_times_change.mp3") 
        self.m_BoomAct:setVisible(true)
        self.m_BoomAct:runCsbAction("show",false,function(  )
            self.m_BoomAct:setVisible(false)
        end)
    end
    

    self:findChild("BitmapFontLabel_1"):setString(times)
end

function AllStarRespinbarView:onEnter()
 

end

function AllStarRespinbarView:onExit()
 
end



return AllStarRespinbarView