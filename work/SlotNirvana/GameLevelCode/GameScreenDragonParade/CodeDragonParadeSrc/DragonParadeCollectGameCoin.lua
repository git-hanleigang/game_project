local SendDataManager = require "network.SendDataManager"
local DragonParadeCollectGameCoin = class("DragonParadeCollectGameCoin", util_require("base.BaseView"))
DragonParadeCollectGameCoin.m_index = nil
DragonParadeCollectGameCoin.m_callfunc = nil

function DragonParadeCollectGameCoin:initUI(data)
    self:createCsbNode("DragonParade_dfdc_coin.csb")

    local panelNode = self:findChild("click")
    self:addClick(panelNode)

    self.m_index = data.index
    self.m_callfunc = data.callfunc
    self.m_coinName = "none"
end

function DragonParadeCollectGameCoin:initView(data, callBackFunc)
end

function DragonParadeCollectGameCoin:initCoin()
end

function DragonParadeCollectGameCoin:setCoinName(_name)
    self.m_coinName = _name
end

function DragonParadeCollectGameCoin:getCoinName(_name)
    return self.m_coinName
end

function DragonParadeCollectGameCoin:resetCoinName()
    self.m_coinName = "none"
end

function DragonParadeCollectGameCoin:clickFunc(sender)
    local name = sender:getName()
    if name == "click" then
        if self.m_callfunc then
            self.m_callfunc(self.m_index)
        end
    end
end

return DragonParadeCollectGameCoin
