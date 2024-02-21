---
--xcyy
--2018年5月23日
--ClassicCashRespinbarView.lua

local ClassicCashRespinbarView = class("ClassicCashRespinbarView",util_require("base.BaseView"))
local PublicConfig = require "ClassicCashPublicConfig"

function ClassicCashRespinbarView:initUI()

    self:createCsbNode("ClassicCash_bonus_xiaoban.csb")

end

function ClassicCashRespinbarView:updateTimes(times, _isStart)
    if times == 1 then
        self:findChild("sp_respin"):setVisible(true)
        self:findChild("sp_respins"):setVisible(false)
    else
        self:findChild("sp_respins"):setVisible(true)
        self:findChild("sp_respin"):setVisible(false)
    end
    if times == 3 and not _isStart then
        gLobalSoundManager:playSound(PublicConfig.Music_Respin_Refresh) 
        self:runCsbAction("actionframe",false,function(  )
            self:runCsbAction("idle",true)
        end)
    end

    self:findChild("m_lb_num"):setString(times)
end

function ClassicCashRespinbarView:onEnter()
 

end

function ClassicCashRespinbarView:onExit()
 
end



return ClassicCashRespinbarView