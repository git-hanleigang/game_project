---
--xcyy
--2018年5月23日
--SuperstarQuestFreeStartView.lua
local PublicConfig = require "SuperstarQuestPublicConfig"
local SuperstarQuestFreeStartView = class("SuperstarQuestFreeStartView",util_require("Levels.BaseLevelDialog"))


function SuperstarQuestFreeStartView:initUI(params)
    self.m_freeCount = params.freeCount
    self.m_freeKind = params.freeKind
    self.m_keyFunc = params.keyFunc
    self.m_endFunc = params.endFunc
    self:createCsbNode("SuperstarQuest/FreeSpinStart.csb")


end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function SuperstarQuestFreeStartView:initSpineUI()
    self.m_spine = util_spineCreate("SuperstarQuest_bg",true,true)
    self:findChild("root"):addChild(self.m_spine)
    if self.m_freeKind == 1 then --minor
        self.m_spine:setSkin("juese3")
    elseif self.m_freeKind == 2 then --major
        self.m_spine:setSkin("juese2")
    else --mega
        self.m_spine:setSkin("juese1")
    end
    

    local csbNode = util_createAnimation("SuperstarQuestFreeTimes.csb")
    util_spinePushBindNode(self.m_spine,"shuzi",csbNode)
    csbNode:findChild("m_lb_num"):setString(self.m_freeCount)

    performWithDelay(self,function()
        if type(self.m_keyFunc) == "function" then
            self.m_keyFunc()
        end
    end,75 / 30)

    util_spinePlay(self.m_spine,"actionframe_guochang")
    util_spineEndCallFunc(self.m_spine,"actionframe_guochang",function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
        self:setVisible(false)
        performWithDelay(self,function()
            self:removeFromParent()
        end,0.1)
    end)

    
end




return SuperstarQuestFreeStartView