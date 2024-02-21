---
--xcyy
--2018年5月23日
--DragonParadeJackPotBarView.lua

local DragonParadeJackPotBarView = class("DragonParadeJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4" 

function DragonParadeJackPotBarView:initUI(machine, isDFDC)
    self.m_machine = machine
    self.m_isDFDC = isDFDC
    self.m_jackpotSignView = {}
    if self.m_isDFDC == "dfdc" then
        self:createCsbNode("DragonParade_dfdc_Jackpot.csb")

        for i = 1, 4 do
            if self.m_jackpotSignView[i] == nil then
                self.m_jackpotSignView[i] = {}
            end

            for j = 1, 3 do
                local signNode = self:findChild("Node_" .. i .. "_" .. (j - 1))

                local signView = util_createAnimation("DragonParade_dfdc_Jackpot_0.csb")
                signNode:addChild(signView)
                self.m_jackpotSignView[i][j] = signView
            end
        end
        
        self:runCsbAction("idle", true)
    else
        self:createCsbNode("DragonParade_Jackpot.csb")
    end
    

    -- self:runCsbAction("idleframe",true)

    self.m_jackpotEffect = {}
    for i = 1, 4 do
        local effectNode = self:findChild("chufa" .. i)
        local effect = util_createAnimation("DragonParade_jackpot_chufa.csb")
        effectNode:addChild(effect)
        self.m_jackpotEffect[i] = effect
        effect:setVisible(false)
    end

end

function DragonParadeJackPotBarView:runEffect(jackpotIdx)
    if self.m_jackpotEffect[jackpotIdx] then
        self.m_jackpotEffect[jackpotIdx]:setVisible(true)
        self.m_jackpotEffect[jackpotIdx]:runCsbAction("actionframe", true)
    end
end

function DragonParadeJackPotBarView:resetEffect()
    for i = 1, 4 do
        if self.m_jackpotEffect[i] then
            self.m_jackpotEffect[i]:setVisible(false)
        end
    end
    
end

function DragonParadeJackPotBarView:onEnter()

    DragonParadeJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function DragonParadeJackPotBarView:onExit()
    DragonParadeJackPotBarView.super.onExit(self)
end

-- function DragonParadeJackPotBarView:initMachine(machine, isDFDC)
    
-- end



-- 更新jackpot 数值信息
--
function DragonParadeJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function DragonParadeJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,272)
    self:updateLabelSize(info2,272)
    self:updateLabelSize(info3,241)
    self:updateLabelSize(info4,241)
end

function DragonParadeJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

-- function DragonParadeJackPotBarView:updateDFDCCoin(pickJackpots)
--     if not pickJackpots then
--         return
--     end
--     local getJackpotNums = function(str)
--         local cnt = 0
--         for k,v in pairs(pickJackpots) do
--             local data = v
--             if data and data == str then
--                 cnt = cnt + 1
--             end
--         end

--         return cnt
--     end
--     local str = {"grand", "major", "minor", "mini"}

--     for i=1,4 do
--         local bar = self.m_jackpotSignView[i]
--         for j=1,3 do
--             local coinNode = bar[j]
--             local nums = getJackpotNums(str[i])
--             if j <= nums then
--                 coinNode:setVisible(true)
--             else
--                 coinNode:setVisible(false)
--             end
--         end
--     end
-- end

function DragonParadeJackPotBarView:setJackpotCoin(index, num, isAnim)
    for i=1,4 do
        local bar = self.m_jackpotSignView[i]
        if i == index then
            for j=1,3 do
                local coinNode = bar[j]

                if j < num then
                    coinNode:findChild("qian"):setVisible(true)
                elseif j == num then
                    coinNode:findChild("qian"):setVisible(true)
                    if isAnim then
                        coinNode:runCsbAction("actionframe", false)
                    end
                else
                    coinNode:findChild("qian"):setVisible(false)
                end
            end
            if num == 2 then
                bar[3]:runCsbAction("idle2", true)
            end
        end
        
    end
end
--重置小点状态
function DragonParadeJackPotBarView:resetJackpotCoin()
    for i=1,4 do
        local bar = self.m_jackpotSignView[i]

        for j=1,3 do
            local coinNode = bar[j]
            coinNode:runCsbAction("idle", true)
        end
        
    end
end

function DragonParadeJackPotBarView:getCoinNode(index, numIdx)
    for i=1,4 do
        local bar = self.m_jackpotSignView[i]
        if i == index then
            for j=1,3 do
                if j == numIdx then
                    return bar[j]
                end
            end
        end
    end
    return nil
end

return DragonParadeJackPotBarView