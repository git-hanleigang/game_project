---
--xcyy
--2018年5月23日
--CashRushJackpotsMatch.lua

local CashRushJackpotsMatch = class("CashRushJackpotsMatch",util_require("Levels.BaseLevelDialog"))

CashRushJackpotsMatch.m_configCount = 6

function CashRushJackpotsMatch:initUI()

    self:createCsbNode("CashRushJackpots_pick_match.csb")

    self.m_configTbl = {}
    for i=1, self.m_configCount do
        self.m_configTbl[i] = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsMatchItem",self, i)
        self:findChild("Node_zuhe"..i):addChild(self.m_configTbl[i])
    end
end

function CashRushJackpotsMatch:onEnter()
    CashRushJackpotsMatch.super.onEnter(self)
end

function CashRushJackpotsMatch:onExit()
    CashRushJackpotsMatch.super.onExit(self)
end

function CashRushJackpotsMatch:resetDate()
    for i=1, self.m_configCount do
        self.m_configTbl[i]:resetDate()
    end
end

function CashRushJackpotsMatch:refreshConfigView(_config, _onEnter)
    local config = _config
    for i=1, self.m_configCount do
        local curConfig = config[i]
        self.m_configTbl[i]:refreshItemView(curConfig, _onEnter)
    end
end

function CashRushJackpotsMatch:refreshProcess(_index, _curConfig)
    local index = _index
    local curConfig = _curConfig
    local process = curConfig.ball or 0
    self.m_configTbl[index]:refreshProcess(process)
end

function CashRushJackpotsMatch:playTriggerMatchAction(_index)
    self.m_configTbl[_index]:playTriggerAction()
end

function CashRushJackpotsMatch:playLastMatchAction(_index)
    self.m_configTbl[_index]:playLastAction()
end

function CashRushJackpotsMatch:getNodeWorldPos(_curProcess, _selectRewardIndex)
    local worldPos = self.m_configTbl[_selectRewardIndex]:getNodeWorldPos(_curProcess)
    return worldPos
end

return CashRushJackpotsMatch
