local SendDataManager = require "network.SendDataManager"
local EasterCollectGameEgg = class("EasterCollectGameEgg", util_require("base.BaseView"))
EasterCollectGameEgg.m_index = nil
EasterCollectGameEgg.m_callfunc = nil

function EasterCollectGameEgg:initUI(data)
    self:createCsbNode("BonusGameEgg.csb")

    local panelNode = self:findChild("click")
    self:addClick(panelNode)

    self.m_index = data.index
    self.m_callfunc = data.callfunc
    self.m_eggName = nil
end

function EasterCollectGameEgg:initView(data, callBackFunc)
end

function EasterCollectGameEgg:initEgg()
end

function EasterCollectGameEgg:setEggName(_name)
    self.m_eggName = _name
end

function EasterCollectGameEgg:getEggName(_name)
    return self.m_eggName
end

function EasterCollectGameEgg:clickFunc(sender)
    local name = sender:getName()
    if name == "click" then
        if self.m_callfunc then
            self.m_callfunc(self.m_index)
        end
    end
end

return EasterCollectGameEgg
