--[[
    弹板界面信息
    author:{author}
    time:2020-08-18 20:37:35
]]
local PopUpInfo = class("PopUpInfo")

function PopUpInfo:ctor()
    self.p_day = 0
    -- 弹板ID
    self.p_popUpId = -1
    -- 弹板名（多主题用）
    self.p_popUpName = ""
    -- 弹板说明
    self.p_description = ""
    self.p_facebook = 0
    -- 所属点位
    self.p_pos = 0
    self.p_type = ""
    -- 筛选优先级
    -- self.p_filtOrder = 0
    -- 弹出优先级
    self.p_popOrder = 0
    -- 引用名
    self.p_ref = ""
    -- 开启状态
    self.p_openFlag = 0
    self.p_external = -1
    -- 互斥检查
    self.p_checkName = ""
    -- 自动关闭延时
    self.p_autoCloseDelay = -1
end

function PopUpInfo:parseData(data)
    self.p_day = data.day
    self.p_popUpId = data.popupId
    self.p_popUpName = data.popupName
    self.p_description = data.description
    self.p_facebook = data.facebook
    self.p_pos = data.pos
    self.p_type = data.type
    self.p_popOrder = data.popOrder
    self.p_ref = data.programName
    self.p_openFlag = data.openFlag
    self.p_external = tonumber(data.external)
    self.p_checkName = data.checkName
    self.p_autoCloseDelay = data.autoCloseDelay
end

function PopUpInfo:getType()
    return self.p_type
end

function PopUpInfo:getPosId()
    return self.p_pos
end

function PopUpInfo:getPopUpId()
    return self.p_popUpId
end

function PopUpInfo:isOpen()
    return self.p_openFlag > 0
end

function PopUpInfo:getRefName()
    return self.p_ref
end

function PopUpInfo:getPopupName()
    return self.p_popUpName
end

-- 检测互斥名
function PopUpInfo:getCheckName()
    return self.p_checkName
end

-- 弹出优先级
function PopUpInfo:getPopOrder()
    return self.p_popOrder
end

-- 自动关闭界面延时
function PopUpInfo:getAutoCloseDelay()
    return self.p_autoCloseDelay
end

return PopUpInfo
