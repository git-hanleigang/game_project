---
--xcyy
--2018年5月23日
--BunnysLockMapItem.lua

local BunnysLockMapItem = class("BunnysLockMapItem",util_require("Levels.BaseLevelDialog"))

--游戏类型
local GAME_TYPE         =       {
    GRASS   =   0,  --草
    EMPTY   =   1,  --空  
    LAST_ORDER  =   2,  --最终大奖
    MUTILPLE    =   3,  --倍数加成
    BOX         =   4,  --开箱子(赛马bonus)
    TOP_DOLLAR  =   5,  --topdollar
    PICK        =   6,  --多福多彩
    MONEY       =   7,  --钱
    BOMB        =   8,  --炸弹
}

local DIRECTION = {
    UP =  1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4
}

local GRASS_ANI = {
    [DIRECTION.UP] = "switch4",
    [DIRECTION.DOWN] = "switch2",
    [DIRECTION.RIGHT] = "switch1",
    [DIRECTION.LEFT] = "switch3",
}

function BunnysLockMapItem:initUI(params)
    self.m_parentView = params.parentView
    self:createCsbNode("Map_item.csb")

    self.m_grass = util_createAnimation("Map_grass.csb")
    self:addChild(self.m_grass)

    self.m_star = util_createAnimation("Map_xingxing.csb")
    self:findChild("xingxing"):addChild(self.m_star)
    
end

function BunnysLockMapItem:updateMutiple(multi)
    self.m_star:findChild("shuzi"):setString(multi * 100) 
end

function BunnysLockMapItem:refreshUI(data)
    self.m_data = data
    local gameType = data[3]
    self.m_grass:setVisible(gameType == GAME_TYPE.GRASS)

    self:updateReward(data)
end

function BunnysLockMapItem:updateReward(data)
    local avgBet = self.m_parentView.m_machine.m_collectData.avgbet

    local gameType = data[3]
    self:findChild("Map_di"):setVisible(true)
    
    

    self:findChild("Map_lanzi"):setVisible(gameType == GAME_TYPE.TOP_DOLLAR)
    self:findChild("Map_lihe"):setVisible(gameType == GAME_TYPE.BOX)
    self:findChild("Map_wenzi"):setVisible(gameType == GAME_TYPE.MUTILPLE)
    self:findChild("Map_youqitong"):setVisible(gameType == GAME_TYPE.PICK)
    self:findChild("Map_qian"):setVisible(gameType == GAME_TYPE.MONEY)
    self:findChild("Map_zhadan"):setVisible(false)--(gameType == GAME_TYPE.BOMB)
    self:findChild("Map_baoxiang"):setVisible(gameType == GAME_TYPE.LAST_ORDER)
    -- if gameType == GAME_TYPE.LAST_ORDER then
    --     self:runCsbAction("baoxiang_idle")
    -- else
    --     self:runCsbAction("idleframe1")
    -- end
    self:runCsbAction("idleframe1")

    local coins = data[5]
    local str = util_formatCoins(coins,3)
    self:findChild("Map_qian"):setString(str)
end

function BunnysLockMapItem:clearGrassAni(direction)
    if not self:isHaveGrass() then
        return
    end
    local aniName = GRASS_ANI[direction]
    self.m_grass:runCsbAction(aniName,false,function()
        self.m_grass:runCsbAction("idleframe",false)
        self.m_grass:setVisible(false)
    end)
end

function BunnysLockMapItem:isHaveGrass()
    return self.m_grass:isVisible()
end

function BunnysLockMapItem:runIdleAni()
    self:runCsbAction("idleframe")
end

--[[
    隐藏底和草丛
]]
function BunnysLockMapItem:hideDi()
    self:findChild("Map_di"):setVisible(false)
    self.m_grass:setVisible(false)
end

--[[
    开奖动画
]]
function BunnysLockMapItem:showAni(func)
    
    self:findChild("guangci_1"):setVisible(true)
    self:findChild("Sprite_4"):setVisible(true)
    self:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    炸弹动画
]]
function BunnysLockMapItem:showBombAni(func)
    self:findChild("Map_zhadan"):setVisible(true)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_show_bomb.mp3")
    self:showAni(function()
        self:runCsbAction("zhadan_actionframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
    end)
    self:findChild("guangci_1"):setVisible(false)
    self:findChild("Sprite_4"):setVisible(false)
end

--[[
    宝箱开奖动画
]]
function BunnysLockMapItem:showBoxReward(func)
    self:showAni(function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_final_box_open.mp3")
        self:runCsbAction("baoxiang_acitonframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
    end)
    
end

--[[
    收集星星动画
]]
function BunnysLockMapItem:changeToStarAni(func)
    self:showAni(function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_change_to_star.mp3")
        local randIndex = math.random(1,2)
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_prize_sound_"..randIndex..".mp3")
        self:runCsbAction("prize_xingxing",false,function()
            if type(func) == "function" then
                func()
            end
        end)
    end)
    
end

--[[
    收集星星动画
]]
function BunnysLockMapItem:collectStarAni(func)
    self.m_star:runCsbAction("yidong",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

return BunnysLockMapItem