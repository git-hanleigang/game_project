--[[
    des:赛季界面独有的轮盘提示
    每隔两秒动一次，最多动三次
    author:{author}
    time:2019-12-09 11:12:34
]]
local CardMenuWheelTip = class("CardMenuWheelTip", util_require("base.BaseView"))
function CardMenuWheelTip:initUI()
    self:createCsbNode(CardResConfig.CardMenuWheelTipRes)
    self.m_playNum = 3
end


function CardMenuWheelTip:updateAnim()
    self:runCsbAction("show", false, nil, 60)
    local times = 0
    self.m_sche = schedule(self, function()
        times = times + 1

        if times == self.m_playNum then
            self:runCsbAction("idle", false, function()
                self:closeUI()
            end, 60)
        else
            self:runCsbAction("idle", false, nil, 60)                            
        end
    end, 3)
end

function CardMenuWheelTip:closeUI()
    if self.m_sche ~= nil then
        self:stopAction(self.m_sche)
        self.m_sche = nil
    end
    self:removeFromParent()
end

return CardMenuWheelTip