--[[
    author:{author}
    time:2022-10-17 19:42:11
]]
-- title - 公告标题
-- name - 弹板名称
-- popupPosition - 弹出位置：1.Loading页；2.大厅
-- popupType - 弹出类型：1.横版；2.竖版
-- buttonType - 按钮类型：1.关闭游戏；2.FB粉丝页；3.回到游戏；多个按钮以英文逗号隔开
-- description - 公告内容描述

local AnnouncementInfo = class("AnnouncementInfo")

function AnnouncementInfo:ctor()
end

function AnnouncementInfo:parseData(_info)
    self.m_id = tonumber(_info.id)
    self.p_name = _info.name
    self.p_title = _info.title
    self.p_popupPosition = tonumber(_info.popupPosition)
    self.p_popupType = tonumber(_info.popupType)
    self.m_cd = _info.popupTimes
    self.p_buttonType = _info.buttonType
    self.p_description = _info.description
    self.m_needLevel = _info.needLevel
    self.m_upperLv = _info.highestLevel
    self.m_state = _info.state
    self.m_platform = _info.platform
end

function AnnouncementInfo:getId()
    return self.m_id
end

function AnnouncementInfo:getCd()
    if self.p_popupPosition == 1 then
        return 0
    else
        return self.m_cd or 0
    end
end

function AnnouncementInfo:getLowerLv()
    return math.max(self.m_needLevel, 0)
end

function AnnouncementInfo:getUpperLv()
    local _upperLv = self.m_upperLv or 0
    if _upperLv == -1 then
        _upperLv = math.huge
    end

    return _upperLv
end

function AnnouncementInfo:getName()
    return self.p_name
end

function AnnouncementInfo:getTitle()
    return self.p_title
end

function AnnouncementInfo:getPopupPos()
    return self.p_popupPosition
end

function AnnouncementInfo:getPopupType()
    return self.p_popupType
end

function AnnouncementInfo:getBtnType()
    return self.p_buttonType
end

function AnnouncementInfo:getDesc()
    return self.p_description or ""
end

function AnnouncementInfo:getPlate()
    return string.lower(self.m_platform or "")
end

return AnnouncementInfo
