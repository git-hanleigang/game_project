--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-01 16:43:57
]]
--jacpot显示界面
--ChilliFiestaRsJackpotView.lua

local ChilliFiestaRsJackpotView = class("ChilliFiestaRsJackpotView",util_require("base.BaseView"))

function ChilliFiestaRsJackpotView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("ChilliFiesta_Jackpot_2.csb")

    self:runCsbAction("idleframe",true)
    self:resetCurRefreshTime()
end

function ChilliFiestaRsJackpotView:changeCsbAni(_str)
    self:runCsbAction(_str,true)
end

function ChilliFiestaRsJackpotView:updateJackpotInfo()
    if not self.m_machine then
        return
    end


    self:changeNode(self:findChild("ml_b_coins42"),4,true,15)
    self:changeNode(self:findChild("ml_b_coins32"),3,true,15)
    self:changeNode(self:findChild("ml_b_coins22"),2,true,15)
    
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

    self:updateLabelSize({label=self:findChild("ml_b_coins1"),sx=0.66,sy=0.66},516)
    self:updateLabelSize({label=self:findChild("ml_b_coins22"),sx=0.47,sy=0.47},516)
    self:updateLabelSize({label=self:findChild("ml_b_coins32"),sx=0.5,sy=0.5},345)
    self:updateLabelSize({label=self:findChild("ml_b_coins42"),sx=0.5,sy=0.5},345)
end
--jackpot算法
function ChilliFiestaRsJackpotView:changeNode(label,index,isJump,count)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,count))
end

function ChilliFiestaRsJackpotView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end


function ChilliFiestaRsJackpotView:onExit()

end

--默认按钮监听回调
function ChilliFiestaRsJackpotView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function ChilliFiestaRsJackpotView:updateLabCoins( coins )
    local lab = self:findChild("ml_b_coins2")
    if lab then
        lab:setString(coins)
        self:updateLabelSize({label=lab,sx=0.54,sy=0.54},516)
    end
end

--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function ChilliFiestaRsJackpotView:resetCurRefreshTime()
    self.m_curTime = 0
end

function ChilliFiestaRsJackpotView:updateMegaShow()
    local icon_super = self:findChild("ChiliFiesta_Jackpot_super")
    local icon_mega = self:findChild("ChiliFiesta_Jackpot_mega")
    local icon_grand = self:findChild("ChiliFiesta_Jackpot_grand")
    --获取当前jackpot状态`
    local status = self.m_machine.m_jackpot_status
    icon_super:setVisible(status == "Super")
    icon_mega:setVisible(status == "Mega")
    icon_grand:setVisible(status == "Normal")
end


return ChilliFiestaRsJackpotView