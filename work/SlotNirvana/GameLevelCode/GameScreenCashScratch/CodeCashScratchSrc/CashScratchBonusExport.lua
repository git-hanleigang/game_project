---
--xcyy
--2018年5月23日
--CashScratchBonusExport.lua

local CashScratchBonusExport = class("CashScratchBonusExport",util_require("Levels.BaseLevelDialog"))

function CashScratchBonusExport:initUI(_machine)
    self.m_machine  = _machine
    self.m_initData = {}
    --
    self:createCsbNode("CashScratch_export.csb")

    -- 不是播放完毕就开始播放下一张动画的话 卡片数量 2 -> 3   使用时创建
    self.m_cardList = {}
end

--[[
    _initData = {
        {
            cardIndex       = 1,
            iPos            = 0,
            symbolType      = 0,
            winCoin         = 0,
            winSymbolType   = {0}, 
            icon            = {0,0,0 ,0,0,0 ,0,0,0},
        },
    }
]]
function CashScratchBonusExport:setInitData(_initData)
    self.m_initData = _initData

    self:resetUiState()
end
function CashScratchBonusExport:resetUiState()
    local labMaxCoin = self:findChild("m_lb_coins"):setVisible(false)
    self:findChild("m_lb_coins"):setOpacity(0)
end
--[[
    卡片spine
]]
function CashScratchBonusExport:changeLightShow(_isSuper)
    local baseUpNode     = self:findChild("base_up")
    local baseDownNode   = self:findChild("base_down")
    local superUpNode    = self:findChild("superfree_up")
    local superDownNode  = self:findChild("superfree_down")

    baseUpNode:setVisible(not _isSuper)
    baseDownNode:setVisible(not _isSuper)
    superUpNode:setVisible(_isSuper)
    superDownNode:setVisible(_isSuper)
end
function CashScratchBonusExport:playLightAnim(_fun)
    gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_export_light.mp3")

    self:runCsbAction("start", false, function()
        self:runCsbAction("idleframe", false)

        if _fun then
            _fun()
        end
    end)
end

function CashScratchBonusExport:playExportAnim(_animIndex, _fun)
    local cardData = self.m_initData[_animIndex]
    if not cardData then
        self:playOverAnim(_fun)
        return
    end

    local curCard = nil

    if #self.m_cardList > 0 then
        curCard = table.remove(self.m_cardList, 1)
    else
        curCard = util_spineCreate("CashScratch_card",true,true)
        self:findChild("guaguaka"):addChild(curCard)
        curCard:setVisible(false)
    end

    local skin = self.m_machine:getCashScratchBonusSymbolIndex(cardData.symbolType)
    --重置一下 出现坐标
    local idleName = "idle2"
    util_spinePlay(curCard, idleName, false)
    util_spineEndCallFunc(curCard, idleName,handler(nil,function(  )
        -- 刷新 皮肤 | 层级
        curCard:setSkin( tostring(skin) )
        local order = _animIndex*10
        curCard:setLocalZOrder(order)
        curCard:setVisible(true)
        -- 开始打印
        gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_exportCard.mp3")
        local animName = 1 == math.random(1, 2) and "start" or "start2"
        util_spinePlay(curCard, animName, false)
        util_spineEndCallFunc(curCard, animName,handler(nil,function(  )
            table.insert(self.m_cardList, curCard)
        end))
        -- 第20帧 淡入
        self.m_machine:levelPerformWithDelay(18/30, function()
            self:playLabelFadeIn(_animIndex)

            -- 第25帧播放淡入
            self.m_machine:levelPerformWithDelay(7/30, function()
                self:playExportAnim(_animIndex+1, _fun)
            end)
        end)
       

    end))
    
end

function CashScratchBonusExport:playOverAnim(_fun)
    self:runCsbAction("over", false, function()
        if _fun then
            _fun()
        end

        for i,_card in ipairs(self.m_cardList) do
            util_spinePlay(_card, "over", false)
            util_spineEndCallFunc(_card, "over",handler(nil,function(  )
                _card:setVisible(false)
            end))
        end
    end)
end
--[[
    文本淡入
]]
function CashScratchBonusExport:playLabelFadeIn(_animIndex)
    local cardData = self.m_initData[_animIndex]
    local coins    = self.m_machine:getBonusCardWinUpCoins(cardData)

    local labMaxCoin = self:findChild("m_lb_coins")
    labMaxCoin:setVisible(true)
    labMaxCoin:setOpacity(0)

    local info  = {label = labMaxCoin, sx = 1, sy = 1, width = 230}
    labMaxCoin:setString(util_formatCoins(coins,20,nil,nil,true))
    self:updateLabelSize(info, info.width)

    local order = _animIndex*10+1
    labMaxCoin:setLocalZOrder(order)

    local actFade = cc.FadeIn:create(5/30)
    labMaxCoin:runAction(actFade)
end

return CashScratchBonusExport