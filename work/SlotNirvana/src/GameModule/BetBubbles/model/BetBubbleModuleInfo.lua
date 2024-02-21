--[[

]]

local BetBubbleModuleInfo = class("BetBubbleModuleInfo", BaseSingleton)

function BetBubbleModuleInfo:ctor()
    BetBubbleModuleInfo.super.ctor(self)

    self.m_moduleName = nil
    self.m_moduleLua = ""
    self.m_refs = {}
    self.m_isLimitMaxH = true
end

function BetBubbleModuleInfo:parseData(_info)
    self.m_moduleName = _info.name
    self.m_moduleLua = _info.moduleLua
    self.m_refs = _info.refs
    self.m_isLimitMaxH = _info.isLimitMaxH == true
end

function BetBubbleModuleInfo:getModuleName()
    return self.m_moduleName
end
function BetBubbleModuleInfo:getModuleLua()
    return self.m_moduleLua
end
function BetBubbleModuleInfo:getRefs()
    return self.m_refs
end
function BetBubbleModuleInfo:isLimitMaxH()
    return self.m_isLimitMaxH
end

function BetBubbleModuleInfo:isRefInModule(_ref)
    if self.m_refs and #self.m_refs > 0 then
        for i=1,#self.m_refs do
            if self.m_refs[i] == _ref then
                return true
            end
        end
    end
    return false
end

return BetBubbleModuleInfo