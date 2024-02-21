--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-01 16:43:57
]]
--jacpot显示界面
--ChilliFiestaJackpotView.lua

local ChilliFiestaJackpotView = class("ChilliFiestaJackpotView",util_require("base.BaseView"))

function ChilliFiestaJackpotView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("ChilliFiesta_Jackpot.csb")

    self:runCsbAction("show",false,function()
        self:runCsbAction("idle",true)
    end)
    self:resetCurRefreshTime()

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)
end

function ChilliFiestaJackpotView:changeCsbAni(_str)
    self:runCsbAction(_str,true)
end

function ChilliFiestaJackpotView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("ml_b_coins4"),4,true,15)
    self:changeNode(self:findChild("ml_b_coins3"),3,true,15)
    self:changeNode(self:findChild("ml_b_coins2"),2,true,15)

    

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild("ml_b_coins1"),1,true,15) 
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild("ml_b_coins1")
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end
    
    self:updateLabelSize({label=self:findChild("ml_b_coins1"),sx=0.9,sy=0.9},630)
    self:updateLabelSize({label=self:findChild("ml_b_coins2"),sx=0.7,sy=0.7},572)
    self:updateLabelSize({label=self:findChild("ml_b_coins3"),sx=0.5,sy=0.5},534)
    self:updateLabelSize({label=self:findChild("ml_b_coins4"),sx=0.5,sy=0.5},534)


    self:changeNode(self:findChild("ml_b_coins42"),4,true,15)
    self:changeNode(self:findChild("ml_b_coins32"),3,true,15)
    self:changeNode(self:findChild("ml_b_coins22"),2,true,15)
    self:updateLabelSize({label=self:findChild("ml_b_coins22"),sx=1,sy=1},253)
    self:updateLabelSize({label=self:findChild("ml_b_coins32"),sx=0.9,sy=0.9},253)
    self:updateLabelSize({label=self:findChild("ml_b_coins42"),sx=0.9,sy=0.9},253)
end
--jackpot算法
function ChilliFiestaJackpotView:changeNode(label,index,isJump,count)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,count))
end

function ChilliFiestaJackpotView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end


function ChilliFiestaJackpotView:onExit()

end

--默认按钮监听回调
function ChilliFiestaJackpotView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function ChilliFiestaJackpotView:resetCurRefreshTime()
    self.m_curTime = 0
end

function ChilliFiestaJackpotView:updateMegaShow()
    local icon_super = self:findChild("ChiliFiesta_Jackpot_super")
    local icon_mega = self:findChild("ChiliFiesta_Jackpot_mega")
    local icon_grand = self:findChild("ChiliFiesta_Jackpot_grand")
    --获取当前jackpot状态`
    local status = self.m_machine.m_jackpot_status
    icon_super:setVisible(status == "Super")
    icon_mega:setVisible(status == "Mega")
    icon_grand:setVisible(status == "Normal")

    if self.m_curStatus and self.m_curStatus ~= status and (status == "Mega" or status == "Super") then
        self.m_light:setVisible(true)
        self.m_light:runCsbAction("win",false,function()
            self.m_light:setVisible(false)
        end)
        for index = 1,8 do
            self.m_light:findChild("Particle_"..index):resetSystem()
        end
    end

    self.m_curStatus = status
end

return ChilliFiestaJackpotView