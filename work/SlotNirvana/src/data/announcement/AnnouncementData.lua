--[[
    公告数据
    服务器数据统一处理
]]
local AnnInfo = require("data.announcement.AnnouncementInfo")
local AnnouncementData = class("AnnouncementData")

function AnnouncementData:ctor()
    self.m_annMents = {}
end

function AnnouncementData:parseData(_netData)
    self.m_annMents = {}
    for i = 1, #_netData do
        local _info = _netData[i]
        local annInfo = AnnInfo:create()
        annInfo:parseData(_info)
        local _pos = annInfo:getPopupPos()
        if not self.m_annMents["" .. _pos] then
            self.m_annMents["" .. _pos] = {}
        end
        table.insert(self.m_annMents["" .. _pos], annInfo)
    end

end

function AnnouncementData:getAnnDatas(pos)
    if not pos then
        return self.m_annMents or {}
    else
        return self.m_annMents["" .. pos] or {}
    end
end

return AnnouncementData
