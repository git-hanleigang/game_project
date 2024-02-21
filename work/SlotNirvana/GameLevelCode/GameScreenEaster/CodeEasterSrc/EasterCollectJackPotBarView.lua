--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-02-18 11:03:30
]]
local EasterCollectJackPotBarView = class("EasterCollectJackPotBarView", util_require("base.BaseView"))

EasterCollectJackPotBarView.m_grandEggNum = 0
EasterCollectJackPotBarView.m_majorEggNum = 0
EasterCollectJackPotBarView.m_minorEggNum = 0
EasterCollectJackPotBarView.m_miniEggNum = 0

function EasterCollectJackPotBarView:initUI(data)
    self.m_machine = data.machine
    self.m_gameMachine = data.gameMachine

    self:createCsbNode("BonusGameJackPotBar.csb")

    self:initView()

    self:runCsbAction("idle1", true)
end

function EasterCollectJackPotBarView:onEnter()
end

function EasterCollectJackPotBarView:onExit()
end

function EasterCollectJackPotBarView:initView()
    self:initLabel()
    self:initEgg()

    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function EasterCollectJackPotBarView:initLabel()
    self.m_lb_grand = self:findChild("m_lb_grand")
    self.m_lb_major = self:findChild("m_lb_major")
    self.m_lb_minor = self:findChild("m_lb_minor")
    self.m_lb_mini = self:findChild("m_lb_mini")

    self:updateLabelSize({label = self.m_lb_grand}, 425)
    self:updateLabelSize({label = self.m_lb_major}, 350)
    self:updateLabelSize({label = self.m_lb_minor}, 322)
    self:updateLabelSize({label = self.m_lb_mini}, 322)
end

function EasterCollectJackPotBarView:initEgg()
    local jackpot = {"grand", "major", "minor", "mini"}

    for key, jackpotName in pairs(jackpot) do
        -- 鸡蛋筐
        local eggFrame = util_createAnimation("BonusGameJackpotBarEgg.csb")
        self:findChild("egg_" .. jackpotName):addChild(eggFrame)
        self:hideEggFrame(eggFrame)
        eggFrame:findChild(jackpotName):setVisible(true)
        local eggNum = 3
        for i = 1, eggNum do
            local egg = util_createAnimation("BonusGameJackpotBarEgg_0.csb")
            self:hideEgg(egg)

            egg:findChild("Easter_egg_" .. jackpotName):setVisible(true)
            egg:runCsbAction("actionframe", false)

            local name = "Node_BonusGameJackpotBarEgg_" .. jackpotName .. "_" .. i
            eggFrame:findChild(name):addChild(egg)
            self["bonusJpBarEgg" .. jackpotName .. "_" .. i] = egg

            egg:setVisible(false)
        end
    end
end

function EasterCollectJackPotBarView:hideEggFrame(_eggFrame)
    local jackpot = {"grand", "major", "minor", "mini"}
    for j = 1, #jackpot do
        _eggFrame:findChild(jackpot[j]):setVisible(false)
    end
end

function EasterCollectJackPotBarView:hideEgg(_egg)
    local jackpot = {"grand", "major", "minor", "mini"}

    for j = 1, #jackpot do
        _egg:findChild("Easter_egg_" .. jackpot[j]):setVisible(false)
    end
end

-- 更新jackpot 数值信息
--
function EasterCollectJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self.m_lb_grand, 1, true)
    self:changeNode(self.m_lb_major, 2, true)
    self:changeNode(self.m_lb_minor, 3)
    self:changeNode(self.m_lb_mini, 4)

    self:updateSize()
end

function EasterCollectJackPotBarView:updateSize()
    self:updateLabelSize({label = self.m_lb_grand, sx = 1, sy = 1}, 425)
    self:updateLabelSize({label = self.m_lb_major, sx = 0.9, sy = 0.9}, 350)
    self:updateLabelSize({label = self.m_lb_minor, sx = 0.8, sy = 0.8}, 322)
    self:updateLabelSize({label = self.m_lb_mini, sx = 0.8, sy = 0.8}, 322)
end

function EasterCollectJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

function EasterCollectJackPotBarView:resetEgg()
    for k, v in pairs(self.eggNodeList) do
        v.curIndex = 0

        for i = 1, 3 do
            local eggSp = v.egg.spNode:getChildByName("egg_" .. i)
            eggSp:setVisible(false)
        end
    end
end

function EasterCollectJackPotBarView:updateEggVisible()
    local jackpot = {"grand", "major", "minor", "mini"}

    for key, jackpotName in pairs(jackpot) do
        local eggNum = 3
        for i = 1, eggNum do
            local egg = self["bonusJpBarEgg" .. jackpotName .. "_" .. i]
            local eggNum = self:getEggNum(jackpotName)
            egg:setVisible(false)
            if i <= eggNum then
                egg:setVisible(true)
            end
        end
    end
end

function EasterCollectJackPotBarView:updateEggNum(_jpName, _num)
    local name = "m_" .. _jpName .. "EggNum"
    self[name] = _num
end

function EasterCollectJackPotBarView:getEggNum(_jpName)
    local name = "m_" .. _jpName .. "EggNum"
    return self[name]
end

function EasterCollectJackPotBarView:playAnimEgg(_jpName)
    local eggNum = self:getEggNum(_jpName)

    local eggNode = self["bonusJpBarEgg" .. _jpName .. "_" .. eggNum + 1]
    local eggPar1 = eggNode:findChild("Particle_1")
    local eggPar2 = eggNode:findChild("Particle_2")
    eggPar1:resetSystem()
    eggPar2:resetSystem()
    eggNode:runCsbAction("actionframe")
    eggNode:setVisible(true)
    -- local waitNode = cc.Node:create()
    -- self:addChild(waitNode)
    -- performWithDelay(
    --     waitNode,
    --     function()
    --         waitNode:removeFromParent()
    --     end,
    --     50 / 60
    -- )
end

return EasterCollectJackPotBarView
