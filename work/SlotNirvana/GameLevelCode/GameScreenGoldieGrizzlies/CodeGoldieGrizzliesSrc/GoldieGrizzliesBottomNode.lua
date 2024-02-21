---
--xcyy
--2018年5月23日
--GoldieGrizzliesBottomNode.lua

local GoldieGrizzliesBottomNode = class("GoldieGrizzliesBottomNode", util_require("views.gameviews.GameBottomNode"))

function GoldieGrizzliesBottomNode:createCoinWinEffectUI()
    if self.coinBottomEffectNode ~= nil then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
    end
    if self.coinWinNode ~= nil then
        local effectCsbName = nil
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameNode/GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameNode/GameBottomNode_jiesuan.csb"
        end
        if effectCsbName ~= nil then
            local coinBottomEffectNode = util_createAnimation(effectCsbName)
            self.coinBottomEffectNode = coinBottomEffectNode
            self.coinWinNode:addChild(coinBottomEffectNode)
            coinBottomEffectNode:setVisible(false)
        end
    end
end

-- 修改已创建的收集反馈效果
function GoldieGrizzliesBottomNode:changeCoinWinEffectUI(_levelName, _csbName)
    if nil ~= self.coinBottomEffectNode and nil ~= _csbName then
        local csbPath = ""
        --找关卡资源
        csbPath = string.format("GameScreen%s/%s", _levelName, _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
        --找系统资源
        csbPath = string.format("GameNode/%s", _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
    --不修改,使用默认创建好的资源工程
    end
end

function GoldieGrizzliesBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            -- coinBottomEffectNode:setVisible(false)
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

return GoldieGrizzliesBottomNode
