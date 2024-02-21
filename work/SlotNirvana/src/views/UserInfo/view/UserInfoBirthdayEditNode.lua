--[[
    个人信息生日编辑节点
]]
local UserInfoBirthdayEditNode = class("UserInfoBirthdayEditNode", BaseView)

function UserInfoBirthdayEditNode:initUI()
    UserInfoBirthdayEditNode.super.initUI(self)
    self:initView()
end

function UserInfoBirthdayEditNode:getCsbName()
    return "Activity/csd/Information/Iformation_friend_birthday.csb"
end

function UserInfoBirthdayEditNode:initCsbNodes()
    self.m_lb_birthday = self:findChild("lb_birthday")
    self.m_btn_edit = self:findChild("btn_edit")
end

function UserInfoBirthdayEditNode:initView()
    self:initBirthdayLabel()
end

function UserInfoBirthdayEditNode:initBirthdayLabel()
    local birthday = "----.--.--"
    local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
    if data and data:isEditBirthdayInfo() then
        local birthdayInfo = data:getBirthdayInformation()
        local birthdayDate = birthdayInfo.birthdayDate
        if birthdayDate then
            local year = string.sub(birthdayDate, 1, 4)
            local month = string.sub(birthdayDate, 5, 6)
            local day = string.sub(birthdayDate, 7, 8)
            birthday = year .. "." .. month .. "." .. day
        end
    end
    self.m_lb_birthday:setString(birthday)
end

function UserInfoBirthdayEditNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_edit" then
        G_GetMgr(G_REF.UserInfo):showBirthdayEditLayer()
    end
end

function UserInfoBirthdayEditNode:onEnter()
    UserInfoBirthdayEditNode.super.onEnter(self)
    -- 修改生日消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                self:initView()
            end
        end,
        ViewEventType.NOTIFY_BIRTHDAY_REQUEST_EDIT
    )
end

return UserInfoBirthdayEditNode