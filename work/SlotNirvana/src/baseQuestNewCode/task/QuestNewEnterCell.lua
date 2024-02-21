-- Created by jfwang on 2019-05-21.
-- QuestNewEnterCell
--
local QuestNewEnterCell = class("QuestNewEnterCell", util_require("base.BaseView"))

function QuestNewEnterCell:getCsbNodePath()
    return QUEST_RES_PATH.QuestNewEnterCell
end

function QuestNewEnterCell:initUI(data)
    self:createCsbNode(self:getCsbNodePath())
    --描述
    self.m_lb_value = self:findChild("BitmapFontLabel_1")
    local desc = data.p_description
    local len = #data.p_params
    if len == 1 then
        local t = util_formatCoins(data.p_params[1],3,nil,nil,nil,true)
        desc = string.format(desc,tostring(t))
    elseif len == 2 then
        local t = util_formatCoins(data.p_params[1],3,nil,nil,nil,true)
        local t1 = util_formatCoins(data.p_params[2],3,nil,nil,nil,true)
        desc = string.format(desc,tostring(t),tostring(t1))
    elseif len == 3 then
        local t = util_formatCoins(data.p_params[1],3,nil,nil,nil,true)
        local t1 = util_formatCoins(data.p_params[2],3,nil,nil,nil,true)
        local t2 = util_formatCoins(data.p_params[3],3,nil,nil,nil,true)
        desc = string.format(desc,tostring(t),tostring(t1),tostring(t2))
    end
    local m_lb_center = self:findChild("m_lb_center")
    local m_lb_top = self:findChild("m_lb_top")
    local m_lb_bottom = self:findChild("m_lb_bottom")
    m_lb_top:setVisible(false)
    m_lb_bottom:setVisible(false)
    --不换行
    local str = string.gsub(desc, ";"," ")
    m_lb_center:setString(str)
end
return QuestNewEnterCell