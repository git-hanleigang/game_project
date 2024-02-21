
local BaseView = util_require("base.BaseView")
local BigCardTxt = class("BigCardTxt", BaseView)

function BigCardTxt:getCsbName()
    return string.format(CardResConfig.seasonRes.BigCardTxtRes, "season201903")
end

function BigCardTxt:initUI()
    self:createCsbNode(self:getCsbName())
    
    self.m_txtLB = self:findChild("BitmapFontLabel_1")
end

function BigCardTxt:updateStr(list, index)
    local txt = list[index]
    self.m_txtLB:setString(txt)

    -- UI是越往下宽度越小
    local width_ori = 371
    local width_real = width_ori
    local offsetWidth = 10 -- 每一行之间宽度差距
    local count = #list
    if count%2 == 0 then
        local middleIndex = (count/2)
        local startWidth = width_ori + (middleIndex-1) * offsetWidth
        width_real = startWidth - (index-1)*offsetWidth
    else
        local middleIndex = math.ceil(count/2)
        local startWidth = width_ori + (middleIndex-1) * offsetWidth
        width_real = startWidth - (index-1)*offsetWidth
    end
    
    self:updateLabelSize({label=self.m_txtLB,sx=1.28,sy=1.28}, width_real)
end

function BigCardTxt:playStart()
    self:runCsbAction("start")
end

return BigCardTxt