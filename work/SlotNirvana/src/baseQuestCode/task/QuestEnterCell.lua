-- Created by jfwang on 2019-05-21.
-- QuestEnterCell
--
local QuestEnterCell = class("QuestEnterCell", util_require("base.BaseView"))

function QuestEnterCell:getCsbNodePath()
    return QUEST_RES_PATH.QuestEnterCell
end

function QuestEnterCell:initUI(data, idx)
    self:createCsbNode(self:getCsbNodePath())
    --描述
    local desc = data.p_description
    local len = #data.p_params
    if len == 1 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t))
    elseif len == 2 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        local t1 = util_formatCoins(data.p_params[2], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t), tostring(t1))
    elseif len == 3 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        local t1 = util_formatCoins(data.p_params[2], 3, nil, nil, nil, true)
        local t2 = util_formatCoins(data.p_params[3], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t), tostring(t1), tostring(t2))
    end
    local m_lb_center = self:findChild("m_lb_center")
    local m_lb_top = self:findChild("m_lb_top")
    local m_lb_bottom = self:findChild("m_lb_bottom")
    m_lb_top:setVisible(false)
    m_lb_bottom:setVisible(false)
    -- 不换行
    local str = string.gsub(desc, ";", " ")
    m_lb_center:setString(str)
    if G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuest() then
        util_AutoLine(m_lb_center, str, 440, true)
    end

    for k = 1, 3 do
        local sp = self:findChild("sp_" .. k)
        if sp then
            if k == idx then
                sp:setVisible(true)
            else
                sp:setVisible(false)
            end
        end
    end
end

function QuestEnterCell:getHieght()
    local sp_bg = self:findChild("sp_bg")
    local height = 100
    if not tolua.isnull(sp_bg) then
        local size = sp_bg:getContentSize()
        height = size.height
    end
    return height
end

return QuestEnterCell
