---
--xcyy
--2018年5月23日
--MagikMirrorPickGameFlowerBtn.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorPickGameFlowerBtn = class("MagikMirrorPickGameFlowerBtn",util_require("Levels.BaseLevelDialog"))


function MagikMirrorPickGameFlowerBtn:initUI(parent)

    self.m_parent = parent

    self:createCsbNode("MagikMirror_pick_rose.csb")

    self.m_bonusHua = util_spineCreate("MagikMirror_pick_hua", true, true)
    self:findChild("Node_spine"):addChild(self.m_bonusHua)

    util_spinePlay(self.m_bonusHua, "idle", true)    

    self:addClick(self:findChild("click_pao")) -- 非按钮节点得手动绑定监听

end

function MagikMirrorPickGameFlowerBtn:showClickAction()
    if not tolua.isnull(self.m_bonusHua) then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_flower_click)
        util_spinePlay(self.m_bonusHua, "actionframe", false)
        util_spineEndCallFunc(self.m_bonusHua, "actionframe",function()
            if not tolua.isnull(self.m_bonusHua) then
                self.m_bonusHua:setVisible(false)
            end
        end)
    end
   
end

function MagikMirrorPickGameFlowerBtn:hideCurFlower()
    if not tolua.isnull(self.m_bonusHua) then
        util_spinePlay(self.m_bonusHua, "over")
    end
end

function MagikMirrorPickGameFlowerBtn:setShowNum(num)
    if tonumber(num) <= 5 then      --对应free次数
        self:findChild("Node_pick_cishu"):setVisible(false)
        self:findChild("Node_free_cishu"):setVisible(true)
        self:findChild("m_lb_free"):setString("+".. tonumber(num))
    elseif tonumber(num) == 6 then   --对应pick6次数
        self:findChild("Node_pick_cishu"):setVisible(true)
        self:findChild("Node_free_cishu"):setVisible(false)
        self:findChild("m_lb_pick"):setString("+".. 2)
    elseif tonumber(num) == 7 then   --对应pick7次数
        self:findChild("Node_pick_cishu"):setVisible(true)
        self:findChild("Node_free_cishu"):setVisible(false)
        self:findChild("m_lb_pick"):setString("+".. 3)
    end
end

--默认按钮监听回调
function MagikMirrorPickGameFlowerBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_pao" then

        self.m_parent:clickFunc( self ) 

    end

end


return MagikMirrorPickGameFlowerBtn