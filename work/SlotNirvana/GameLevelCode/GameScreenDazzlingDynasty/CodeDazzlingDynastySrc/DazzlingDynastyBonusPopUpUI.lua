--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-21 22:02:42
]]
local DazzlingDynastyBonusPopUpUI = class("DazzlingDynastyBonusPopUpUI", util_require("base.BaseView"))
local CodeGameScreenDazzlingDynastyMachine = util_require("GameScreenDazzlingDynasty.CodeGameScreenDazzlingDynastyMachine")

function DazzlingDynastyBonusPopUpUI:initUI()
    self:createCsbNode("DazzlingDynasty_Choose1.csb")
    self.m_lb_score = self:findChild("m_lb_score")
    self.itemPreUIInfoList = {}
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle1", true)
            self:__flyScoreUI()
        end
    )
    self:setPosition(display.width / 2,display.height / 2)
    self.m_lb_score:setString("0")
end

function DazzlingDynastyBonusPopUpUI:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    self:__initItemUI()
end

function DazzlingDynastyBonusPopUpUI:__getBonusCoin()
    local machine = self.m_machine
    local storedIcons = machine.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local totalScore = 0
    for k, v in ipairs(storedIcons) do
        local score = machine:getReSpinSymbolScore(v[1]) or 0 --获取分数（网络数据）
        totalScore = totalScore + score
    end
    return totalScore
end

function DazzlingDynastyBonusPopUpUI:__initItemUI()
    local lbScore = self.m_lb_score
    local machine = self.m_machine
    local reelRow = machine.m_iReelRowNum
    local reelCol = machine.m_iReelColumnNum
    local itemPreUIInfoList = self.itemPreUIInfoList
    local deviceMidWidth,deviceMidHeight = display.width / 2,display.height / 2
    
    local fixSymbolNodeList = {}
    self.fixSymbolNodeList = fixSymbolNodeList
    for i = 1,reelRow do
        for j = 1,reelCol do
            local symbolNode = machine:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            if symbolNode == nil then
                return
            end
            local symbolType = symbolNode.p_symbolType
            if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 then
                table.insert(fixSymbolNodeList,symbolNode)
                local symbolPositionX,symbolPositionY = symbolNode:getPosition()
                itemPreUIInfoList[symbolNode] = {symbolNode:getParent(),symbolPositionX,symbolPositionY}
                local symbolPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolPositionX,symbolPositionY))
                symbolNode:removeFromParent(false)
                self:addChild(symbolNode,symbolNode:getLocalZOrder())
                symbolNode:setPosition(symbolPos.x - deviceMidWidth,symbolPos.y - deviceMidHeight)
            end
        end
    end
    table.sort(fixSymbolNodeList,
    function(a,b)
        local aRowIndex = a.p_rowIndex
        local bRowIndex = b.p_rowIndex
        local aColIndex = a.p_cloumnIndex
        local bColIndex = b.p_cloumnIndex
        local aSymbolType = machine:formatAddSpinSymbol(a.p_symbolType)
        local bSymbolType = machine:formatAddSpinSymbol(b.p_symbolType)
        if aSymbolType == bSymbolType then
            if aRowIndex == bRowIndex then
                return aColIndex < bColIndex
            else
                if aColIndex == bColIndex then
                    return aRowIndex > bRowIndex
                else
                    return aColIndex < bColIndex
                end
            end
        else
            return aSymbolType < bSymbolType
        end
    end)
end

function DazzlingDynastyBonusPopUpUI:__flyScoreUI()
    local machine = self.m_machine
    local lbScore = self.m_lb_score
    local fixSymbolNodeList = self.fixSymbolNodeList
    local deviceMidWidth,deviceMidHeight = display.width / 2,display.height / 2
    local scorePosX,scorePosY = lbScore:getPosition()
    local animCor = nil
    animCor = coroutine.create(
    function()
        for k,v in ipairs(fixSymbolNodeList) do
            local rowIndex = v.p_rowIndex
            local columnIndex = v.p_cloumnIndex
            local symbolType = v.p_symbolType
            local symbolPositionX,symbolPositionY = v:getPosition()
            local moveActionNode = util_createView("GameScreenDazzlingDynasty.CodeDazzlingDynastySrc.DazzlingDynastyBonusScore")
            local a = v:getLocalZOrder()
            self:addChild(moveActionNode,v:getLocalZOrder() + REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            moveActionNode:setMachineInfo(machine)
            moveActionNode:setPosition(symbolPositionX,symbolPositionY)
            local _,score = machine:getScoreInfoByPos(rowIndex, columnIndex)
            local scorePos = self.m_lb_score:getParent():convertToWorldSpace(cc.p(scorePosX - deviceMidWidth,scorePosY - deviceMidHeight))
            moveActionNode:playSmallAnimation(symbolType,score,scorePos,
            function()
                self:__addScore(score)
            end,nil)
            
            performWithDelay(v,
            function()
                util_resumeCoroutine(animCor)
            end,0.5)
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_Bonus_Lv1.mp3")
            coroutine.yield()
        end

        performWithDelay(self,
        function()
            util_resumeCoroutine(animCor)
        end,1)
        coroutine.yield()
        animCor = nil
        self:__returnToReelParent()
        self:runCsbAction("down",false,
        function()
            local bonusUI = util_createView("GameScreenDazzlingDynasty.CodeDazzlingDynastySrc.DazzlingDynastyBonusUI")
            bonusUI:setExtraInfo(machine,self.callBack)
            self:addChild(bonusUI,util_getNodeCount(self))
        end)
        gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Bonus_PopUp.mp3")
    end)
    performWithDelay(self,
    function() 
        util_resumeCoroutine(animCor)
    end,1)
end

function DazzlingDynastyBonusPopUpUI:__returnToReelParent()
    for k,v in pairs(self.itemPreUIInfoList) do
        k:removeFromParent(false)
        v[1]:addChild(k,k:getLocalZOrder())
        k:setPosition(v[2],v[3])
    end
end

function DazzlingDynastyBonusPopUpUI:__addScore(score)
    if not score then
        return
    end
    --不清楚原因
    local lbScore = self.m_lb_score
    lbScore:setString(tostring(tonumber(lbScore:getString()) + score))
end

function DazzlingDynastyBonusPopUpUI:__setButtonEnabled(flag)
    self.btnBonus:setEnabled(flag)
    self.btnFreeGames:setEnabled(flag)
end

function DazzlingDynastyBonusPopUpUI:close()
    self:removeFromParent()
end

function DazzlingDynastyBonusPopUpUI:onExit()
    self.m_machine.bonusPopUpUI = nil
end
return DazzlingDynastyBonusPopUpUI