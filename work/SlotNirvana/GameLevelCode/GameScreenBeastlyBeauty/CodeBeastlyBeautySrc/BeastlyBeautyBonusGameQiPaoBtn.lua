---
--xcyy
--2018年5月23日
--BeastlyBeautyBonusGameQiPaoBtn.lua

local BeastlyBeautyBonusGameQiPaoBtn = class("BeastlyBeautyBonusGameQiPaoBtn",util_require("base.BaseView"))


function BeastlyBeautyBonusGameQiPaoBtn:initUI(parent)

    self.m_parent = parent

    self:createCsbNode("BeastlyBeauty_bonus.csb")

    self.m_bonusHua = util_spineCreate("BeastlyBeauty_pick_hua", true, true)
    self:findChild("Node_spine"):addChild(self.m_bonusHua)

    util_spinePlay(self.m_bonusHua, "start", false)
    util_spineEndCallFunc(self.m_bonusHua, "start", function()
        util_spinePlay(self.m_bonusHua, "idle", true)
    end)

    self:addClick(self:findChild("click_pao")) -- 非按钮节点得手动绑定监听

end


function BeastlyBeautyBonusGameQiPaoBtn:onEnter()
 

end

function BeastlyBeautyBonusGameQiPaoBtn:showAdd()
    
end
function BeastlyBeautyBonusGameQiPaoBtn:onExit()
 
end

--默认按钮监听回调
function BeastlyBeautyBonusGameQiPaoBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_pao" then

        self.m_parent:clickFunc( self ) 

    end

end


return BeastlyBeautyBonusGameQiPaoBtn