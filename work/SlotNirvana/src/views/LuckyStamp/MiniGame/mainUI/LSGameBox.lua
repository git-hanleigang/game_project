--[[
    宝箱
]]
local LSGameBox = class("LSGameBox", BaseView)

function LSGameBox:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_coinBox.csb"
end

function LSGameBox:initDatas(_index)
    self.m_index = _index
    self.m_boxType = self:getBoxType(true)
end

function LSGameBox:initCsbNodes() --2023
    --self.m_nodeCoin = self:findChild("node_coin")
    -- self.m_particle = self:findChild("Particle_1")
    -- self.m_particle:stopSystem()
    self.m_nodes = {}
    for i = 1, 12 do
        local node = self:findChild("node" .. i)
        table.insert(self.m_nodes, node)

        if i == self.m_index then
            self.m_coin = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameCoin", self.m_index)
            node:getChildByName("node_coin"):addChild(self.m_coin)

            self.m_coinFire = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameCoinFire", self.m_index) 
            local fireCoin = self:findChild("node_fireCoin"..i)
            if fireCoin then
                fireCoin:addChild(self.m_coinFire)
            end
        end

    end
end

function LSGameBox:initNodes()
    for i = 1, 12 do
        self.m_nodes[i]:setVisible(i == self.m_index)
        --self.m_spFires[i]:setVisible(false)
    end
end

function LSGameBox:coins2Fire(index)
    self.m_spFires[index]:setVisible(true)
end

function LSGameBox:initUI()
    LSGameBox.super.initUI(self)
    self:initBoxType()
    self:initCoin()
    self:initNodes()

    --self:initGoldenCoin()
end

-- function LSGameBox:initGoldenCoin()
--     for i = 1, 12 do
--         if i == self.m_index then
--             local finalCoins = self:getUpCoin()
--             local m_lbNum = self:findChild("lb_num" .. i)
--             m_lbNum:setString(util_formatCoins(finalCoins, 3))
--         end
--     end
-- end

-- function LSGameBox:updateGoldenCoin()
--     self:initGoldenCoin()
-- end

function LSGameBox:initBoxType()
    if self.m_boxType == LuckyStampCfg.StampType.Normal then
        self:playNormalIdle()
    else
        self:playGoldenIdle()
    end
end

function LSGameBox:resetBoxType()
    self.m_boxType = self:getBoxType(true)
    self:initBoxType()
end

function LSGameBox:initCoin()
    -- self.m_coin = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameCoin", self.m_index)
    -- self.m_nodeCoin:addChild(self.m_coin)
end

function LSGameBox:resetCoin()
    self.m_coin:resetUI()
    self.m_coinFire:resetUI()
end

function LSGameBox:playNormalIdle()
    self:runCsbAction("idle_normal", true, nil, 60)
end

function LSGameBox:playGoldenIdle()
    self:runCsbAction("idle_golden", true, nil, 60)
end

function LSGameBox:playChange(_over)
    --self.m_particle:resetSystem()
    self:runCsbAction("change", false, _over, 60)
    return util_csbGetAnimTimes(self.m_csbAct, "change")
end

-- 返回消耗的时间，秒
function LSGameBox:upBox()
    local boxType = self:getBoxType()
    if self.m_boxType == LuckyStampCfg.StampType.Normal and boxType == LuckyStampCfg.StampType.Golden then
        gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/overturn.mp3")
        self.m_boxType = boxType
        local costTime =
            self:playChange(
            function()
                if not tolua.isnull(self) then
                    self:playGoldenIdle()
                end
            end
        )
        return costTime
    end
    return 0
end

function LSGameBox:upCoin()
    local t = 0
    if self.m_coin then
        local _t = self.m_coin:upCoin()
        t = math.max(t, _t)
    end
    if self.m_coinFire then
        local _t = self.m_coinFire:upCoin()
        t = math.max(t, _t)
    end
    return t
end

function LSGameBox:onShowedCallFunc()
end

function LSGameBox:onEnter()
    LSGameBox.super.onEnter(self)
end

-- 获取戳的数据
function LSGameBox:getStampData(_isInit)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        return data:getCurProcessData(_isInit)
    end
    return nil
end

-- 获取当前戳的宝箱数据
function LSGameBox:getCurBoxData(_isInit)
    local stampData = self:getStampData(_isInit)
    if stampData then
        return stampData:getLatticeDataByIndex(self.m_index)
    end
    return nil
end

-- 获取增长后的金币
function LSGameBox:getUpCoin()
    if LuckyStampCfg.TEST_MODE == true then
        return 200000000 * self.m_index
    end
    local boxData = self:getCurBoxData()
    if boxData then
        return boxData:getCoins()
    end
    return 0
end

function LSGameBox:isDefaultGoldenBox()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        if data:getGoldenIndex() == self.m_index then
            return true
        end
    end
    return false
end

-- 获取金币宝箱的类型
function LSGameBox:getBoxType(_isInit)
    if LuckyStampCfg.TEST_MODE == true then
        return LuckyStampCfg.StampType.Normal
    end
    if self:isDefaultGoldenBox() then
        return LuckyStampCfg.StampType.Golden
    else
        local boxData = self:getCurBoxData(_isInit)
        if boxData then
            return boxData:getType()
        end
        return LuckyStampCfg.StampType.Normal
    end
end

return LSGameBox
