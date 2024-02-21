---
--xcyy
--2018年5月23日
--ZombieRockstarWinCoinsView.lua
local ZombieRockstarWinCoinsView = class("ZombieRockstarWinCoinsView", util_require("base.BaseView"))
local ZombieRockstarPublicConfig = require "ZombieRockstarPublicConfig"
ZombieRockstarWinCoinsView.m_reelsKuaiList = {} -- 存储小块 上
ZombieRockstarWinCoinsView.m_reelsKuaiBgList = {} -- 存储小块 底
ZombieRockstarWinCoinsView.m_leftNumsList = {} -- 存储左侧数字
ZombieRockstarWinCoinsView.m_roleSpineList = {} -- 存储角色
ZombieRockstarWinCoinsView.m_roleSpineIndex = {6,5,4,3,2,1}
ZombieRockstarWinCoinsView.m_respinEffectList = {} --存储触发respin的动画

function ZombieRockstarWinCoinsView:initUI(params)
    self.m_machine = params
    self:createCsbNode("ZombieRockstar_base_collect.csb")

    -- 块
    for reelsIndex = 1, 6 do
        self.m_reelsKuaiList[reelsIndex] = {}
        self.m_reelsKuaiBgList[reelsIndex] = {}
        local reelBgNode = util_createAnimation("ZombieRockstar_base_collect_topreel.csb")
        self:findChild("reel_bottom_"..reelsIndex):addChild(reelBgNode)

        local reelNode = util_createAnimation("ZombieRockstar_base_collect_topreel.csb")
        self:findChild("reel_"..reelsIndex):addChild(reelNode)
        for index = 1, 8 do
            local kuaiNode = util_createAnimation("ZombieRockstar_base_collect_top_kuai.csb")
            reelNode:findChild("reel_kuai_"..index):addChild(kuaiNode)
            self.m_reelsKuaiList[reelsIndex][index] = kuaiNode
            kuaiNode:setVisible(false)

            local kuaiBgNode = util_createAnimation("ZombieRockstar_base_collect_top_kuai_0.csb")
            reelBgNode:findChild("reel_kuai_bg_"..index):addChild(kuaiBgNode)
            self.m_reelsKuaiBgList[reelsIndex][index] = kuaiBgNode
            self:initKuai(kuaiBgNode, index)
        end
    end

    -- 左侧数字
    for numIndex = 1, 8 do
        local numsNode = util_createAnimation("ZombieRockstar_base_collect_jishu_"..numIndex..".csb")
        self:findChild("Num_"..numIndex):addChild(numsNode)
        self.m_leftNumsList[numIndex] = numsNode
        numsNode:findChild("base_jishu_num_gold"):setVisible(false)
    end

    for jueseIndex = 1, 6 do
        self.m_roleSpineList[self.m_roleSpineIndex[jueseIndex]] = util_spineCreate("ZombieRockstar_guochang", true, true)
        self:findChild("Node_"..self.m_roleSpineIndex[jueseIndex]):addChild(self.m_roleSpineList[self.m_roleSpineIndex[jueseIndex]])
        util_spinePlay(self.m_roleSpineList[self.m_roleSpineIndex[jueseIndex]], "idleframe2_juese"..jueseIndex, true)

        -- 中奖respin的动画
        local respinEffectNode = util_createAnimation("ZombieRockstar_base_collect_tx.csb")
        self:findChild("Node_trigger"..jueseIndex):addChild(respinEffectNode)
        self.m_respinEffectList[self.m_roleSpineIndex[jueseIndex]] = respinEffectNode
        respinEffectNode:setVisible(false)
    end
    
end

function ZombieRockstarWinCoinsView:onEnter()
    ZombieRockstarWinCoinsView.super.onEnter(self)
end

function ZombieRockstarWinCoinsView:onExit()
    ZombieRockstarWinCoinsView.super.onExit(self)
end

--[[
    默认显示的界面
]]
function ZombieRockstarWinCoinsView:initKuai(_node, _row)
    if _row <= 3 then
        _node:setVisible(false)
    elseif _row <= 5 then
        _node:findChild("m_lb_coins_1"):setVisible(true)
        _node:findChild("m_lb_coins_3"):setVisible(false)
        _node:findChild("m_lb_respin_1"):setVisible(false)
    elseif _row < 8 then
        _node:findChild("m_lb_coins_1"):setVisible(false)
        _node:findChild("m_lb_coins_3"):setVisible(true)
        _node:findChild("m_lb_respin_1"):setVisible(false)
    else
        _node:findChild("m_lb_coins_1"):setVisible(false)
        _node:findChild("m_lb_coins_3"):setVisible(false)
        _node:findChild("m_lb_respin_1"):setVisible(true)
    end
end

--[[
    刷新小块
]]
function ZombieRockstarWinCoinsView:updateKuaiEffect(_node, _row, _func, maxNums)
    _node:setVisible(true)
    _node:findChild("Node_bg"):setVisible(true)
    _node:findChild("Node_2"):setVisible(true)
    if _row <= 3 then
        _node:findChild("base_jiangli_kuai_1"):setVisible(true)
        _node:findChild("base_jiangli_kuai_2"):setVisible(false)
        _node:findChild("base_jiangli_kuai_3"):setVisible(false)
        _node:findChild("Node_2"):setVisible(false)
    elseif _row <= 6 then
        _node:findChild("base_jiangli_kuai_1"):setVisible(false)
        _node:findChild("base_jiangli_kuai_2"):setVisible(true)
        _node:findChild("base_jiangli_kuai_3"):setVisible(false)
        _node:findChild("m_lb_coins_2"):setVisible(true)
        _node:findChild("m_lb_respin_2"):setVisible(false)
    else
        _node:findChild("base_jiangli_kuai_1"):setVisible(false)
        _node:findChild("base_jiangli_kuai_2"):setVisible(false)
        _node:findChild("base_jiangli_kuai_3"):setVisible(true)
        if _row == 7 then
            _node:findChild("m_lb_coins_2"):setVisible(true)
            _node:findChild("m_lb_respin_2"):setVisible(false)
        else
            _node:findChild("m_lb_coins_2"):setVisible(false)
            _node:findChild("m_lb_respin_2"):setVisible(true)
        end
    end
    _node:runCsbAction("start", false, function()
        if _row <= 3 then
            _node:runCsbAction("idle2", true)
        elseif _row <= 5 then
            if maxNums == _row then
                _node:runCsbAction("idle3", true)
            else
                _node:runCsbAction("idle2", true)
            end
        elseif _row <= 7 then
            if maxNums == _row then
                _node:runCsbAction("idle4", true)
            else
                _node:runCsbAction("idle2", true)
            end
        else
            _node:runCsbAction("idle2", true)
        end
        if _func then
            _func()
        end
    end)
end

--[[
    根据数据 刷新界面
]]
function ZombieRockstarWinCoinsView:updateViewByData(_data, _func)
    -- gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_base_nums_add)

    local maxNums = 0
    for _index, _nums in ipairs(_data) do
        if _nums > 0 then
            maxNums = maxNums < _nums and _nums or maxNums
            for _row = 1, 8 do
                if _row <= _nums then
                    performWithDelay(self, function()
                        self:updateKuaiEffect(self.m_reelsKuaiList[_index][_row], _row, function()
                            -- self.m_reelsKuaiBgList[_index][_row]:setVisible(false)
                        end, _nums)
                        self.m_leftNumsList[_row]:findChild("base_jishu_num_gold"):setVisible(true)
                    end, 3/60 * (_row - 1))
                end
            end
        end
    end

    performWithDelay(self, function()
        if _func then
            _func()
        end
    end, 3/60 * maxNums + 15/60)
end

--[[
    取消掉界面上的显示
]]
function ZombieRockstarWinCoinsView:resetViewByDate(_data)
    for _index, _nums in ipairs(_data) do
        if _nums > 0 then
            local delayIndex = 0
            for _row = 8, 1, -1 do
                if _row <= _nums then
                    delayIndex = delayIndex + 1
                    performWithDelay(self, function()
                        local kuaiNode = self.m_reelsKuaiList[_index][_row]
                        -- if _row > 2 then
                        --     self.m_reelsKuaiBgList[_index][_row]:setVisible(true)
                        -- end
                        kuaiNode:runCsbAction("over", false, function()
                            kuaiNode:setVisible(false)
                        end)
                        self.m_leftNumsList[_row]:findChild("base_jishu_num_gold"):setVisible(false)
                    end, 2/60 * (delayIndex - 1))
                end
            end
        end
    end
end

--[[
    播放触发respin的动画
]]
function ZombieRockstarWinCoinsView:playRespinEffect(_index, _func)
    local random = math.random(1,2)
    gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig["sound_ZombieRockstar_respin_trigger"..random])

    util_spinePlay(self.m_roleSpineList[self.m_roleSpineIndex[_index]], "idleframe3_juese".._index, false)

    util_changeNodeParent(self:findChild("Node_effect"), self.m_respinEffectList[_index]:getParent():getParent())
    self.m_respinEffectList[_index]:setVisible(true)
    self.m_respinEffectList[_index]:runCsbAction("actionframe", false, function()
        util_changeNodeParent(self:findChild("Node_caiqiekuang"), self.m_respinEffectList[_index]:getParent():getParent())
        util_spinePlay(self.m_roleSpineList[self.m_roleSpineIndex[_index]], "idleframe2_juese".._index, true)
        if _func then
            _func()
        end
    end)
end

--[[
    显示当前bet下 数字
]]
function ZombieRockstarWinCoinsView:showBetWinCoins()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    
    for reelsIndex = 1, 6 do
        for rowIndex = 1, 7 do
            local mul = self.m_machine.m_payTableMulti[tostring(self.m_roleSpineIndex[reelsIndex]-1)][rowIndex+1]
            local reelsKuaiNode = self.m_reelsKuaiList[reelsIndex][rowIndex]
            local reelsKuaiBgNode = self.m_reelsKuaiBgList[reelsIndex][rowIndex]
            reelsKuaiNode:findChild("m_lb_coins_2"):setString(util_formatCoins(totalBet*mul, 3))
            reelsKuaiBgNode:findChild("m_lb_coins_1"):setString(util_formatCoins(totalBet*mul, 3))
            reelsKuaiBgNode:findChild("m_lb_coins_3"):setString(util_formatCoins(totalBet*mul, 3))
            self:updateLabelSize({label=reelsKuaiNode:findChild("m_lb_coins_2"),sx=1,sy=1},86)
            self:updateLabelSize({label=reelsKuaiBgNode:findChild("m_lb_coins_1"),sx=1,sy=1},86)
            self:updateLabelSize({label=reelsKuaiBgNode:findChild("m_lb_coins_3"),sx=1,sy=1},86)
        end
    end
end

return ZombieRockstarWinCoinsView
