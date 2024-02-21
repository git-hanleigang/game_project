--[[
    author:JohnnyFred
    time:2019-12-16 18:12:21
]]
local BaseRankHelpUI = class("BaseRankHelpUI", BaseLayer)

function BaseRankHelpUI:ctor(csb_res)
    BaseRankHelpUI.super.ctor(self)
    self:setPauseSlotsEnabled(true)
    self.ActionType = "Common"
    -- 设置横屏csb
    if csb_res then
        self:setCsbName(csb_res)
    end
    local csb_name = self:getCsbName()
    self:setLandscapeCsbName(csb_name)
    self:setExtendData("BaseRankHelpUI")
end

function BaseRankHelpUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

------------------------------------------子类重写---------------------------------------

function BaseRankHelpUI:onShowedCallFunc()
    if util_csbActionExists(self.m_csbAct, "idle") then
        self:runCsbAction("idle", true, nil, 60)
    end
end

------------------------------------------子类重写---------------------------------------
-- 指定资源路径
function BaseRankHelpUI:getCsbName()
    return self.csb_res
end

function BaseRankHelpUI:setCsbName(csb_res)
    self.csb_res = csb_res
end

------------------------------------------子类重写---------------------------------------

return BaseRankHelpUI
