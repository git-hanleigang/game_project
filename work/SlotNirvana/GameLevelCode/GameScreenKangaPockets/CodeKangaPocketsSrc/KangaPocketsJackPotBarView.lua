local KangaPocketsJackPotBarView = class("KangaPocketsJackPotBarView",util_require("Levels.BaseLevelDialog"))

function KangaPocketsJackPotBarView:initUI(_data)
    self.m_machine     = _data.machine

    self:createCsbNode("KangaPockets_JackpotBar.csb")
    self:initJackpotList()
end

function KangaPocketsJackPotBarView:onEnter()
    KangaPocketsJackPotBarView.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function KangaPocketsJackPotBarView:initJackpotList()
    local jackpotRes = {
        [1] = {parent = self:findChild("Node_Grand"), csb = "KangaPockets_base_Grand.csb"},
        [2] = {parent = self:findChild("Node_Major"), csb = "KangaPockets_base_Major.csb"},
        [3] = {parent = self:findChild("Node_Minor"), csb = "KangaPockets_base_Minor.csb"},
        [4] = {parent = self:findChild("Node_Mini"),  csb = "KangaPockets_base_Mini.csb"},
    }
    self.m_jackpotList = {}
    for _jpIndex,_resData in ipairs(jackpotRes) do
        local jpCsb = util_createAnimation(_resData.csb)
        _resData.parent:addChild(jpCsb)
        self.m_jackpotList[_jpIndex] = jpCsb
        jpCsb:runCsbAction("idle", true)
    end
end
-- 更新jackpot 数值信息
--
function KangaPocketsJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    for _jpIndex,_jpCsb in ipairs(self.m_jackpotList) do
        local labCoins = _jpCsb:findChild("m_lb_coins")
        local value = self.m_machine:BaseMania_updateJackpotScore(_jpIndex)
        labCoins:setString(util_formatCoins(value,20,nil,nil,true))
        self:updateLabelSize({label=labCoins,sx=1,sy=1}, 197)
    end
end


return KangaPocketsJackPotBarView