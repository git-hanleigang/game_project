--[[--
    小猪规则界面
]]
local PiggyBankInfoLayer = class("PiggyBankInfoLayer", BaseLayer)
function PiggyBankInfoLayer:initDatas()
    self:setLandscapeCsbName("PigBank2022/csb/info/PiggyBank_Info.csb")
    self:setPortraitCsbName("PigBank2022/csb/info/PiggyBank_Info_Portrait.csb")
end

function PiggyBankInfoLayer:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
end

function PiggyBankInfoLayer:initView()
    self:runCsbAction("idle", true, nil, 60)
end

function PiggyBankInfoLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return PiggyBankInfoLayer
