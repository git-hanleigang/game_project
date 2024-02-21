--[[
    外部关联系统展示
    按钮
]]
local BaseView = util_require("base.BaseView")
local shopOuterButtonNode = class("shopOuterButtonNode", BaseView)
function shopOuterButtonNode:initUI(_btnType, _clickCallBack)
    self.m_btnType = _btnType
    self.m_clickCallBack = _clickCallBack

    self.m_lbLen = 0 -- 最多显示的数字的位数
    self.m_lbInfo = {sx = 1, sy = 1} -- 尺寸数据

    if self.m_btnType == "LUCKY_CHALLENGE" then
        self.m_lbLen = 113
        if globalData.slotRunData.isPortrait == true then
            self.m_lbInfo = {sx = 0.5, sy = 0.5}
            self:createCsbNode("Shop_Res/Gem/GemButton/node_diamondChallengePortrait.csb")
        else
            self.m_lbInfo = {sx = 0.55, sy = 0.55}
            self:createCsbNode("Shop_Res/Gem/GemButton/node_diamondChallenge.csb")
        end
    elseif self.m_btnType == "DAILY_MISSION" then
        self.m_lbLen = 113
        self.m_lbInfo = {sx = 0.6, sy = 0.6}
        self:createCsbNode("Shop_Res/Gem/GemButton/node_dailymission.csb")   
    elseif self.m_btnType == "BATTLE_PASS" then
        self.m_lbLen = 113
        self.m_lbInfo = {sx = 0.4, sy = 0.4}
        self:createCsbNode("Shop_Res/Gem/GemButton/node_battlepass.csb")
    elseif self.m_btnType == "QUEST" then
        self.m_lbLen = 46
        self:createCsbNode("Shop_Res/Gem/GemButton/node_quest.csb")
    end
end

function shopOuterButtonNode:updateNum(_num)
    self.m_num = _num
    local lbNum = self:findChild("label_shuzi")
    if lbNum then
        lbNum:setString(self.m_num)
        self.m_lbInfo.label = lbNum
        self:updateLabelSize(self.m_lbInfo, self.m_lbLen)
    end
end

function shopOuterButtonNode:clickFunc(_sender)
    local name = _sender:getName()
    if name == "Button_1" then 
        -- 点击跳过按钮
        if self.m_clickCallBack then
            self.m_clickCallBack()
        end
    end
end

return shopOuterButtonNode