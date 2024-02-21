--[[
    引导提示气泡(指针)配置信息
    author:{author}
    time:2022-09-02 16:19:52
]]
local GuideTipInfo = class("GuideTipInfo")

function GuideTipInfo:ctor()
    -- 当前信号id
    self.m_tipId = nil
    -- lua名称
    self.m_luaName = ""
    -- 节点名称
    self.m_nodeName = ""
    -- 资源类型
    self.m_type = ""
    -- 资源路径
    self.m_path = ""
    -- 层级
    self.m_zOrder = 0
    -- 坐标
    self.m_pos = cc.p(0, 0)
end

function GuideTipInfo:parseData(info)
    self.m_tipId = info.tipId
    -- lua名称
    self.m_luaName = info.luaName
    -- 节点名称
    self:setNodeName(info.nodeName)
    self.m_type = info.type or ""
    self.m_path = info.path or ""
    --
    self.m_zOrder = tonumber(info.zOrder)
    self:setPos(info.pos or "")
end

function GuideTipInfo:getTipId()
    return self.m_tipId
end

function GuideTipInfo:getLuaName()
    return self.m_luaName or ""
end

function GuideTipInfo:setNodeName(nodeName)
    nodeName = nodeName or ""
    -- if nodeName ~= "" then
    --     local strs = string.split(nodeName, "|")
    --     self.m_nodeName = strs
    -- end
    self.m_nodeName = nodeName
end

function GuideTipInfo:getNodeName()
    return self.m_nodeName or {}
end

function GuideTipInfo:isCsb()
    return self.m_type == "csb"
end

function GuideTipInfo:isLua()
    return self.m_type == "lua"
end

function GuideTipInfo:getPath()
    return self.m_path
end

function GuideTipInfo:getZOrder()
    return self.m_zOrder or 0
end

function GuideTipInfo:getPos()
    return self.m_pos
end

function GuideTipInfo:setPos(pos)
    pos = pos or ""
    local strs = string.split(pos, "|")
    if #strs == 2 then
        self.m_pos = cc.p(tonumber(strs[1]), tonumber(strs[2]))
    end
end

return GuideTipInfo
