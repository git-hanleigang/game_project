--[[
    author:{author}
    time:2022-05-16 15:25:59
]]
local FlyBuckNode = class("FlyBuckNode", BaseView)

function FlyBuckNode:initDatas(flyCuyInfo, index)
    self.m_index = index or 0
    self.m_flyCuyInfo = flyCuyInfo
end

function FlyBuckNode:getIdx()
    return self.m_index
end

function FlyBuckNode:initUI()
    local randomCoinCsbNum = 3
    self:createCsbNode("Lobby/FlyBucks_" .. randomCoinCsbNum .. ".csb")
end

function FlyBuckNode:playAction()
    self:runCsbAction("act_1", true, nil, 30)
end

-- 开始飞行
function FlyBuckNode:flyStart()
    self:setVisible(true)
    local nodeLizi = cc.ParticleSystemQuad:create("Lobby/Bucks/tuoweilizi1.plist")
    self:addChild(nodeLizi, -1)
    nodeLizi:setPosition(cc.p(0, 0))

    -- local timeLineName = "act_1"
    -- local actionTime = util_csbGetAnimTimes(csbAct, timeLineName, 60)
    -- local speed = actionTime / flyTime
    self.m_csbAct:setTimeSpeed(1.2)
    self.m_csbNode:setRotation(math.random(0, 360))
end

return FlyBuckNode
