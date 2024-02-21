--[[
    选择档位弹板
]]
local PBC = require "JungleJauntPublicConfig"
local JungleJauntChooseView = class("JungleJauntChooseView",util_require("Levels.BaseLevelDialog"))

function JungleJauntChooseView:initUI(_initData)
    self.m_machine = _initData.machine
    self:createCsbNode("JungleJaunt/JungleJaunt_jinru.csb")
    
    local tarList = PBC.RoadManType
    for index=1,#tarList do
        self:addClick(self:findChild(tarList[index].."_click"))
    end

    self.m_bg = util_spineCreate("JungleJaunt_qizi",true,true)
    self:findChild("root1"):addChild(self.m_bg,-1)
    self.m_bg:setVisible(false)

end

function JungleJauntChooseView:onEnter()
    self.super.onEnter(self)
    util_setCascadeColorEnabledRescursion(self, true)
end

function JungleJauntChooseView:playChooseViewStartAnim(_currData)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_37)

    self.m_fnOver  = _currData.fnOver
    self.m_isOnEnter = _currData.bOnEnter

    local roadMan = self.m_machine.m_roadMainView.m_man
    roadMan:setVisible(false)

    self:setPosition(cc.p(0,0))
    self.m_bg:setVisible(false)
    self.m_bCanClick = false
    local delayTime = self.m_isOnEnter and 0.5 or 0
    performWithDelay(self,function(  )
        self.m_bg:setVisible(true)
        self.m_bCanClick = false
        -- gLobalSoundManager:playSound(PBC.SoundConfig.JungleJaunt_SOUND_48)
        util_spinePlay(self.m_bg,"tanban_start")
        util_spineEndCallFunc(self.m_bg,"tanban_start",function()
            util_spinePlay(self.m_bg,"tanban_idle",true)
            self.m_bCanClick = true
        end)
    end,delayTime)

end

function JungleJauntChooseView:playChooseViewOverAnim(_overId)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_38)

    local roadMan = self.m_machine.m_roadMainView.m_man
    local animId = PBC.RoadManTypeNum[_overId]

    util_spinePlay(self.m_bg,"qizi"..animId.."_start")
    util_spineEndCallFunc(self.m_bg,"qizi"..animId.."_start",function()
        if self.m_fnOver then
            self.m_fnOver() 
        end
        self:setVisible(false)
        self:setPosition(cc.p(0,0))
        roadMan:setVisible(true)
    end)

    performWithDelay(self,function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_39)
        util_playMoveToAction(self,20 / 30,util_convertToNodeSpace(roadMan, self:getParent()))
    end,20/30)
    
end

--默认按钮监听回调
function JungleJauntChooseView:clickFunc(sender)
    if not self.m_bCanClick then
        return
    end
    self.m_bCanClick = false
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
    local nodeTag = sender:getTag() 
    local nodeName = sender:getName()
    local overType = PBC.RoadManType[1] 
    if nodeName == "shizi_click" then
        overType = PBC.RoadManType[1]
    elseif nodeName == "daxiang_click" then
        overType = PBC.RoadManType[2]
    elseif nodeName == "xiniu_click" then
        overType = PBC.RoadManType[3]
    elseif nodeName == "houzi_click" then
        overType = PBC.RoadManType[4]
    end
    gLobalNoticManager:postNotification(PBC.ObserversConfig.UpdateRoadMan,{manType = overType})
    self:playChooseViewOverAnim(overType)
          
end


return JungleJauntChooseView