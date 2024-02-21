---
--xcyy
--2018年5月23日
--JollyFactoryMultiBox.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryMultiBox = class("JollyFactoryMultiBox",util_require("base.BaseView"))


function JollyFactoryMultiBox:initUI(params)
    self.m_machine = params.machine
    
end


--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JollyFactoryMultiBox:initSpineUI()
    self.m_spine = util_spineCreate("JollyFactory_box",true,true)
    self:addChild(self.m_spine)

    self.m_multiLbl = util_createAnimation("JollyFactory_Free_AllWins_multi.csb")
    util_spinePushBindNode(self.m_spine, "sz", self.m_multiLbl)


end

function JollyFactoryMultiBox:runIdleAni()
    self:runSpineAni("idle",true)
end

--[[
    反馈动效
]]
function JollyFactoryMultiBox:runFeedBackAni(multi,func)
    self:runSpineAni("actionframe",false,function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)

    performWithDelay(self,function()
        self:updateMulti(multi)
    end,4 / 30)
end

--[[
    刷新倍数
]]
function JollyFactoryMultiBox:updateMulti(multi)
    local m_lb_num = self.m_multiLbl:findChild("m_lb_num")
    
    m_lb_num:setString(multi.."X")
    local info={label = m_lb_num,sx = 1,sy = 1}
    self:updateLabelSize(info,200)
end

function JollyFactoryMultiBox:runSpineAni(aniName,isLoop,func)
    if not isLoop then
        isLoop = false
    end

    --动作已经执行完不需要融合
    if not self.m_runAniEnd then
        -- util_spineMix(self.m_spine,self.m_curAniName,aniName,0.2)
    end

    self.m_runAniEnd = false
    self.m_curAniName = aniName
    util_spinePlay(self.m_spine,aniName,isLoop)
    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    performWithDelay(self,function()
        if not isLoop then
            self.m_runAniEnd = true
        end
        
        if type(func) == "function" then
            func()
        end
    end,aniTime)

    return aniTime
end

return JollyFactoryMultiBox