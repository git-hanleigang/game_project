local MrCashGoLevelBoxIcon = class("MrCashGoLevelBoxIcon",util_require("Levels.BaseLevelDialog"))

MrCashGoLevelBoxIcon.ORDER = {
    MASK   = 30,
    KUANG  = 40,
    FANGZI = 50,
}

function MrCashGoLevelBoxIcon:initDatas(_machine)
    self.m_machine  = _machine

    self.m_data = {}
end
--[[
    结构 {
        框体spine

        房子spine 金币文本cocos(挂在插槽里)
    }
]]
function MrCashGoLevelBoxIcon:initUI()
    
    self.m_coinsList = {}
    self.m_kuangList = {}
    self.m_fangziList = {}
    -- 框体，房子背景，金币文本
    local kuang1  = util_spineCreate("Socre_MrCashGo_Scatter_Lvkuang",true,true)
    self:addChild(kuang1, self.ORDER.KUANG)
    self.m_kuangList[self.m_machine.SYMBOL_LevelBox_1] = kuang1
    kuang1:setVisible(false)
    local fangzi1 = util_spineCreate("Socre_MrCashGo_Scatter_0",true,true)
    self:addChild(fangzi1, self.ORDER.FANGZI)
    self.m_fangziList[self.m_machine.SYMBOL_LevelBox_1] = fangzi1
    local labCoins1 = util_createAnimation("MrCashGo_ScatterLab.csb")
    util_spinePushBindNode(fangzi1, "kong2", labCoins1)
    labCoins1:findChild("Particle_1"):setVisible(false)
    self.m_coinsList[self.m_machine.SYMBOL_LevelBox_1] = labCoins1
    fangzi1:setVisible(false)
    -- 框体，房子背景，金币文本 2
    local kuang2  = util_spineCreate("Socre_MrCashGo_Scatter_Hongkuang",true,true)
    self:addChild(kuang2, self.ORDER.KUANG)
    self.m_kuangList[self.m_machine.SYMBOL_LevelBox_2] = kuang2
    kuang2:setVisible(false)
    local fangzi2 = util_spineCreate("Socre_MrCashGo_Scatter_1",true,true)
    self:addChild(fangzi2, 50)
    self.m_fangziList[self.m_machine.SYMBOL_LevelBox_2] = fangzi2
    local labCoins2 = util_createAnimation("MrCashGo_ScatterLab.csb")
    util_spinePushBindNode(fangzi2, "kong2", labCoins2)
    labCoins2:findChild("Particle_1"):setVisible(false)
    self.m_coinsList[self.m_machine.SYMBOL_LevelBox_2] = labCoins2
    fangzi2:setVisible(false)
    -- 框体，房子背景，金币文本 3
    local kuang3  = util_spineCreate("Socre_MrCashGo_Scatter_Huangkuang",true,true)
    self:addChild(kuang3, self.ORDER.KUANG)
    self.m_kuangList[self.m_machine.SYMBOL_LevelBox_3] = kuang3
    kuang3:setVisible(false)
    local fangzi3 = util_spineCreate("Socre_MrCashGo_Scatter_2",true,true)
    self:addChild(fangzi3, 50)
    self.m_fangziList[self.m_machine.SYMBOL_LevelBox_3] = fangzi3
    local labCoins3 = util_createAnimation("MrCashGo_ScatterLab.csb")
    util_spinePushBindNode(fangzi3, "kong2", labCoins3)
    labCoins3:findChild("Particle_1"):setVisible(false)
    self.m_coinsList[self.m_machine.SYMBOL_LevelBox_3] = labCoins3
    fangzi3:setVisible(false)
end
--[[
    _data = {
        symbolType = 101,      -- 信号值
        level      = 1,        -- 图标等级
        coins      = 0,        -- 赢钱
        coinsType  = "",       -- 赢钱类型 ("":普通倍数 , "mini":jackpot , "minor":jackpot)
        jpIndex    = 0,        -- 奖池索引
    }
]]
function MrCashGoLevelBoxIcon:setIconData(_data)
    for k,v in pairs(_data) do
        self.m_data[k] = v

        -- 刷新一下等级
        if "symbolType" == k then
            self.m_data.level = self.m_machine:getLevelBoxLevel(v)
        end
        -- 刷新一下jpIndex
        if "coinsType" == k then
            if "mini" == v then
                self.m_data.jpIndex = 4
            elseif "minor" == v then
                self.m_data.jpIndex = 3
            else
                self.m_data.jpIndex = 0
            end
        end
    end
end
--[[
    free结束时调用，隐藏背景清理数据
]]
function MrCashGoLevelBoxIcon:clearIconData()
    self.m_data = {}
end
function MrCashGoLevelBoxIcon:resetIconShow()
    for k,_icon in pairs(self.m_kuangList) do
        _icon:setVisible(false)
    end
    for k,_fangzi in pairs(self.m_fangziList) do
        _fangzi:setVisible(false)
    end
end

-- 刷新框体展示
function MrCashGoLevelBoxIcon:upDateFrameShow(_playSound, _isTransfer)
    for _symbolType,_kuang in pairs(self.m_kuangList) do
        local isVisible = _symbolType == self.m_data.symbolType
        _kuang:setVisible(isVisible)
        if isVisible then
            gLobalNoticManager:postNotification("MrCashGoMachine_playUpGradeLevelBoxSound", {_symbolType, _playSound, _isTransfer})
            util_spinePlay(_kuang, "suoding", false)
        end
    end

    return 30/30
end
function MrCashGoLevelBoxIcon:playFrameHide()
    local kuang = self.m_kuangList[self.m_data.symbolType]
    util_spinePlay(kuang, "xiaoshi", false)
    util_spineEndCallFunc(kuang, "xiaoshi", function()
        kuang:setVisible(false)
    end)
end
-- 刷新结算底板展示
function MrCashGoLevelBoxIcon:upDateCoinsBgShow()
    local fangzi = self.m_fangziList[self.m_data.symbolType]
    fangzi:setVisible(true)
    util_spinePlay(fangzi, "actionframe1", false)

    return 18/30
end
function MrCashGoLevelBoxIcon:playCoinsBgHide()
    local fangzi = self.m_fangziList[self.m_data.symbolType]
    util_spinePlay(fangzi, "actionframe2", false)

    return 33/30
end
-- 刷新金钱展示
function MrCashGoLevelBoxIcon:upDateCoinsShow()
    local icon = self.m_coinsList[self.m_data.symbolType]

    local isShowMini  = "mini"   == self.m_data.coinsType
    local isShowMinor = "minor"  == self.m_data.coinsType

    icon:findChild("mini"):setVisible(isShowMini)
    icon:findChild("minor"):setVisible(isShowMinor)

    local coinsVisible = not isShowMini and not isShowMinor
    -- 用于十倍及以上的数字显示 (金色板板)
    if coinsVisible then
        local bShowLv3Lab = self:isShowLv3Lab(self.m_data.symbolType, self.m_data.coins)
        icon:findChild("m_lb_coins"):setVisible(not bShowLv3Lab)
        icon:findChild("m_lb_coins_0"):setVisible(bShowLv3Lab)
        local labCoins = bShowLv3Lab and icon:findChild("m_lb_coins_0") or icon:findChild("m_lb_coins")

        local sCoins = util_formatCoins(self.m_data.coins, 3)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins,sx=0.5,sy=0.5}, 240)
    else
        icon:findChild("m_lb_coins"):setVisible(false)
        icon:findChild("m_lb_coins_0"):setVisible(false)
    end
    

    

    return self:playCoinsBgHide()
end
function MrCashGoLevelBoxIcon:isShowLv3Lab(_symbol, _winCoins)
    if _symbol == self.m_machine.SYMBOL_LevelBox_3 then
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate  = _winCoins / totalBet
        return winRate >= 10
    end

    return false
end
--[[
    收集飞行
]]
function MrCashGoLevelBoxIcon:getFlyEffectCoinsLab()
    local icon = self.m_coinsList[self.m_data.symbolType]

    if "mini"   == self.m_data.coinsType then
        return icon:findChild("mini")
    elseif "minor"  == self.m_data.coinsType then
        return icon:findChild("minor")
    else
        local bShowLv3Lab = self:isShowLv3Lab(self.m_data.symbolType, self.m_data.coins)
        local lab = bShowLv3Lab and icon:findChild("m_lb_coins_0") or icon:findChild("m_lb_coins")
        return lab
    end
end
--收集时播一下spine的时间线
function MrCashGoLevelBoxIcon:playFlyEffectAnim()
    local fangzi = self.m_fangziList[self.m_data.symbolType]
    util_spinePlay(fangzi, "shouji", false)
end
--[[
    钞票雨的遮罩淡入|淡出
]]
function MrCashGoLevelBoxIcon:playCellMaskFadeIn()
    local panel = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
    self:addChild(panel, self.ORDER.MASK)
    local size = cc.size(self.m_machine.m_SlotNodeW+1, self.m_machine.m_SlotNodeH+1)
    panel:setContentSize(size)
    panel:setPosition(-size.width/2, -size.height/2)
    panel:setOpacity(0)
    
    local actList = {}
    table.insert(actList, cc.FadeTo:create(0.5, self.m_machine.m_panelOpacity))
    table.insert(actList, cc.RemoveSelf:create())
    panel:runAction(cc.Sequence:create(actList))

    return 0.5
end
function MrCashGoLevelBoxIcon:playCellMaskFadeOut()
    local panel = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
    self:addChild(panel, self.ORDER.MASK)
    local size = cc.size(self.m_machine.m_SlotNodeW+1, self.m_machine.m_SlotNodeH+1)
    panel:setContentSize(size)
    panel:setPosition(-size.width/2, -size.height/2)
    panel:setOpacity(self.m_machine.m_panelOpacity)
    
    local actList = {}
    table.insert(actList, cc.FadeOut:create(0.5))
    table.insert(actList, cc.RemoveSelf:create())
    panel:runAction(cc.Sequence:create(actList))
end


return MrCashGoLevelBoxIcon