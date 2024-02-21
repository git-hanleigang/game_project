
local WestRangerSlotNode = class("WestRangerSlotNode",util_require("Levels.SlotsNode"))

WestRangerSlotNode.m_numLabel = nil--图标上额外加的数字

-- 解决静态图的展示问题 修改静态图可见性和图片资源的地方都要调用
function WestRangerSlotNode:upDateWestRangerSlotNodeImage(_ccbName)
    -- 不在静态图展示状态
    if nil == self.p_symbolImage or not self.p_symbolImage:isVisible() then
        return
    end
    local nodeName = "WestRangerBonusAddNode"

    local ccbName = _ccbName or self.m_ccbName
    local config = {
        Socre_WestRanger_Bonus  = true,
        Socre_WestRanger_Bonus2 = true,
    }
    local configData = config[ccbName]
    -- 没有配置的信号在开启静态图展示时把新增节点移除掉
    if not configData then
        local addNode = self.p_symbolImage:getChildByName(nodeName)
        if addNode then
            release_print("[WestRangerSlotNode:upDateWestRangerSlotNodeImage] 移除bonus的静态图附加节点")
            addNode:removeFromParent()
            release_print("[WestRangerSlotNode:upDateWestRangerSlotNodeImage] 移除bonus的静态图附加节点 完毕")
        end
        return
    end
end
-- 创建bonus 和 bonus2 静态图的分数展示节点
function WestRangerSlotNode:createBonusAddNode(_score, _bGold)
    local addNode = nil
    -- 不存在静态图节点
    if nil == self.p_symbolImage then
        return addNode
    end
    local nodeName = "WestRangerBonusAddNode"
    
    -- 不存在的话创建一下
    addNode = self.p_symbolImage:getChildByName(nodeName)
    if not addNode then
        addNode = util_createAnimation("Socre_WestRanger_Bonus_coin.csb")
        self.p_symbolImage:addChild(addNode, 10)
        addNode:setName(nodeName)
        addNode:setScale(2)
        --关卡小块尺寸的宽高
        local size = self.p_symbolImage:getContentSize()
        local pos  = cc.p(size.width/2, size.height/2) 
        addNode:setPosition(pos)
    end
    -- 刷新
    local isJackpot = _score == "mini" or _score == "minor" or _score == "major"
    addNode:findChild("m_lb_mini"):setVisible(_score == "mini")
    addNode:findChild("m_lb_minor"):setVisible(_score == "minor")
    addNode:findChild("m_lb_mijor"):setVisible(_score == "major")

    addNode:findChild("m_lb_score_yin"):setVisible(not isJackpot and not _bGold)
    addNode:findChild("m_lb_score_jin"):setVisible(not isJackpot and _bGold)
    if not isJackpot then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local sScore  = util_formatCoins(_score * lineBet, 3)
        addNode:findChild("m_lb_score_yin"):setString(sScore)
        addNode:findChild("m_lb_score_jin"):setString(sScore)
    end

    return addNode
end

function WestRangerSlotNode:reset()
    WestRangerSlotNode.super.reset(self)
    self:upDateWestRangerSlotNodeImage()
end
function WestRangerSlotNode:resetReelStatus()
    WestRangerSlotNode.super.resetReelStatus(self)
    self:upDateWestRangerSlotNodeImage()
end
function WestRangerSlotNode:initSlotNodeByCCBName(ccbName,symbolType)
    WestRangerSlotNode.super.initSlotNodeByCCBName(self, ccbName,symbolType)
    self:upDateWestRangerSlotNodeImage(ccbName)
end
function WestRangerSlotNode:changeSymbolImageByName(ccbName)
    WestRangerSlotNode.super.changeSymbolImageByName(self, ccbName)
    self:upDateWestRangerSlotNodeImage(ccbName)
end

return WestRangerSlotNode