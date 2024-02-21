---
--xcyy
--2018年5月23日
--HogHustlerMapPig.lua

local HogHustlerMapPig = class("HogHustlerMapPig",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")
local max_num = {3, 5, 7}

local safeBox_name_tag = {"lan", "hong", "jin"}

local keyColumn_key_name_tag =  {{"Node_yaoshi31", "Node_yaoshi32", "Node_yaoshi33"},
                                {"Node_yaoshi51", "Node_yaoshi52", "Node_yaoshi53", "Node_yaoshi54", "Node_yaoshi55"},
                                {"Node_yaoshi71", "Node_yaoshi72", "Node_yaoshi73", "Node_yaoshi74", "Node_yaoshi75", "Node_yaoshi76", "Node_yaoshi77"}}
local levelPrize_tag = {"Node_levelprize1", "Node_levelprize2", "Node_levelprize3"}
function HogHustlerMapPig:initUI(data)
    self.m_index = data.index  --索引值
    self.m_plan = data.plan or 0  --当前的进度
    self:createCsbNode("HogHustler_baoxianxiang.csb")
    -- local name = self.m_index == 1 and "piglan_L" or "pig"
    -- self.m_pig = util_createAnimation("HogHustler_xiaozhu.csb")
    -- self:findChild("pig"):addChild(self.m_pig)

    -- self.m_pigIdle = util_createAnimation("HogHustler_xiaozhu_L.csb")
    -- self:findChild(name):addChild(self.m_pigIdle)

    -- self.m_hammer_plan = util_createAnimation("HogHustler_xiaozhu_jindu.csb")
    -- self:findChild("plan"):addChild(self.m_hammer_plan)

    
    self:runCsbAction("idleframe", true)

    self.m_keyColumn = util_createAnimation("HogHustler_yaoshilan.csb")
    self:findChild("yaoshilan_" .. safeBox_name_tag[self.m_index]):addChild(self.m_keyColumn)

    self.m_keyColumn:findChild("Node_3"):setVisible(self.m_index == 1)
    self.m_keyColumn:findChild("Node_5"):setVisible(self.m_index == 2)
    self.m_keyColumn:findChild("Node_7"):setVisible(self.m_index == 3)

    self.m_keyColumn:playAction("idle", true)

    self.m_safeBoxLevelPrize = util_createAnimation("HogHustler_baoxianxiangleverprize.csb")
    self:findChild(levelPrize_tag[self.m_index]):addChild(self.m_safeBoxLevelPrize)

    self:initPig()
end

function HogHustlerMapPig:setPlan(_plan)
    self.m_plan = _plan
end

function HogHustlerMapPig:onEnter()
    HogHustlerMapPig.super.onEnter(self)
end

function HogHustlerMapPig:onExit()
    HogHustlerMapPig.super.onExit(self)
end

function HogHustlerMapPig:initPig()
    -- local pig_name_tag = {"lan", "fen", "jin"}
    -- for index = 1,3 do
    --     local name = "xiaozhu_"..pig_name_tag[index]
    --     self.m_pig:findChild("xiaozhu_"..pig_name_tag[index]):setVisible(index == self.m_index)
    --     if index > 1 then
    --         self.m_pigIdle:findChild("xiaozhu_"..pig_name_tag[index]):setVisible(index == self.m_index)
    --     end
    --     self.m_hammer_plan:findChild("jindu_"..pig_name_tag[index]):setVisible(index == self.m_index)
    -- end
    -- self.m_addCoins = util_createAnimation("HogHustler_xiaozhu_jinbi.csb")
    -- self.m_pig:findChild("Node_jinbi"..self.m_index):addChild(self.m_addCoins)
    -- self.m_addCoins:setVisible(false)
    -- self:initPigAni()

    
    for index = 1,3 do
        self:findChild("baoxianxiang_" .. safeBox_name_tag[index]):setVisible(index == self.m_index)
    end


    self:updateKeyNum()

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function HogHustlerMapPig:updateKeyNum(_num)
    if self.m_index < 1 or self.m_index > 3 then
        release_print("HogHustlerMapPig:updateKeyNum Error!!!")
        return
    end
    local plan_num = 0
    if _num then
        plan_num = _num
        self.m_plan = _num
    else
        plan_num = self.m_plan
    end
    
    if max_num[self.m_index] <=  plan_num then
        plan_num = max_num[self.m_index]
    end

    for k, v in ipairs(keyColumn_key_name_tag[self.m_index]) do
        local keyNode = self.m_keyColumn:findChild(v)
        local keyNodeView = util_getChildByName(keyNode, "keyNode" .. k)
        if keyNodeView and not tolua.isnull(keyNodeView) then
        else
            keyNodeView = util_createAnimation("HogHustler_shoujilanyaoshi.csb")
            keyNode:addChild(keyNodeView)
            keyNodeView:setName("keyNode" .. k)
        end
        keyNodeView:setVisible(k <= plan_num)
    end


    
    self:runCsbAction("actionframe2", false, function()
        self:runCsbAction("idleframe", true)
    end)
    if self.m_index == 2 then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_safebox_red_turn)
    end
    if plan_num == max_num[self.m_index] - 1 then
        self.m_keyColumn:runCsbAction("fankui", false, function()
            self.m_keyColumn:playAction("idle2", true)
        end)
        
    else
        self.m_keyColumn:runCsbAction("fankui", false, function()
            self.m_keyColumn:playAction("idle", true)
        end)
        
    end
end

function HogHustlerMapPig:initPigAni()

end

function HogHustlerMapPig:getKeyWorldPos()
    if self.m_index < 1 or self.m_index > 3 then
        release_print("HogHustlerMapPig:getKeyWorldPos Error!!!")
        return self
    end
    local plan_num = self.m_plan
    if max_num[self.m_index] <=  plan_num then
        plan_num = max_num[self.m_index]
    end
    local index = plan_num + 1
    if max_num[self.m_index] <= index then
        index = max_num[self.m_index]
    end
    local keyNode = self.m_keyColumn:findChild(keyColumn_key_name_tag[self.m_index][index])

    local worldPos = keyNode:getParent():convertToWorldSpace(cc.p(keyNode:getPosition()))
    return worldPos, keyNode
    -- return self
end

function HogHustlerMapPig:showEffect(win)

    self:updateKeyNum(win)

    print("effectover+++++++++effectaaaaa11111111")
    gLobalNoticManager:postNotification("MAP_OVER_SMELLYRICH")


end


function HogHustlerMapPig:showAddCoins()

end


function HogHustlerMapPig:openSafeBox(_func, _funcSafeBoxOpen)

    local partical_tag = {{"Particle_3"}, {"Particle_1", "Particle_2"}, {"Particle_4", "Particle_5", "Particle_6"}}

    if partical_tag[self.m_index] then
        for i = 1, #partical_tag[self.m_index] do
            local particle = self.m_keyColumn:findChild(partical_tag[self.m_index][i])
            particle:resetSystem()
        end
    end
    
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_collectkeyfull_light)
    self.m_keyColumn:playAction("actionframe", false, function()
        if partical_tag[self.m_index] then
            for i = 1, #partical_tag[self.m_index] do
                local particle = self.m_keyColumn:findChild(partical_tag[self.m_index][i])
                particle:stopSystem()
            end
        end

        self.m_keyColumn:playAction("over", false, function()
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_safebox_open)
            self:runCsbAction("actionframe2", false, function()
                self:runCsbAction("actionframe", false, function()
                    self:runCsbAction("idle2", true)

                    -- if _func then
                    --     _func()
                    -- end
                end)

                
                if _funcSafeBoxOpen then
                    _funcSafeBoxOpen()
                end
                self.m_safeBoxLevelPrize:playAction("start", false)

                self:waitWithDelay(3, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    end)

    
end

--延时
function HogHustlerMapPig:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return HogHustlerMapPig