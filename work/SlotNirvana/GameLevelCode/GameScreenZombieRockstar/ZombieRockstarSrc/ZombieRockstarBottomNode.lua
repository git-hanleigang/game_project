-- 处理spin按钮点击跳过流程
local ZombieRockstarBottomNode = class("ZombieRockstarBottomNode", util_require("views.gameviews.GameBottomNode"))

-- 修改已创建的收集反馈效果
function ZombieRockstarBottomNode:changeCoinWinEffectUI(_levelName, _csbName)
    if nil ~= self.coinBottomEffectNode and nil ~= _csbName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_csbName, true, true)
        self.coinWinNode:addChild(self.coinBottomEffectNode, 99)
        self.coinBottomEffectNode:setVisible(false)
    end
end

function ZombieRockstarBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe_totalwin", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe_totalwin", function ()
            coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

function ZombieRockstarBottomNode:changeBigWinLabUi(_csbPath)
    if not self.coinWinNode then
        return
    end
    if not CCFileUtils:sharedFileUtils():isFileExist(_csbPath) then
        return
    end
    --资源创建
    if self.m_bigWinLabCsb ~= nil then
        self.m_bigWinLabCsb:removeFromParent()
        self.m_bigWinLabCsb = nil
    end
    self.m_bigWinLabCsb = util_createAnimation(_csbPath)
    self.coinWinNode:addChild(self.m_bigWinLabCsb, 100)
    self.m_bigWinLabCsb:setVisible(false)
    --初始化适配参数
    local labCoins = self.m_bigWinLabCsb:findChild("m_lb_coins")
    local labInfo = {}
    labInfo.label = labCoins
    local labSize = labCoins:getContentSize()
    labInfo.width = labSize.width
    labInfo.sx = labCoins:getScaleX()
    labInfo.sy = labCoins:getScaleY()
    self:setBigWinLabInfo(labInfo)
end

return  ZombieRockstarBottomNode