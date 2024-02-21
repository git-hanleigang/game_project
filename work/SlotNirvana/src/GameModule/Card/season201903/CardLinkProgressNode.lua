local BaseView = util_require("base.BaseView")
local CardLinkProgressNode = class("CardLinkProgressNode", BaseView)

function CardLinkProgressNode:getCsbName()
    return string.format(CardResConfig.commonRes.linkProgressPro201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardLinkProgressNode:initUI(current)
    self:createCsbNode(self:getCsbName())
    self.layerSG = self:findChild("layer_SG")
    self.layerSGSize = self.layerSG:getSize()
    self.layerSG:setClippingEnabled(true)
    self:runCsbAction("animation", true)

    self.m_jindu = self:findChild("jindu")
    self.m_shuzi = self:findChild("shuzi_1")
end

function CardLinkProgressNode:getTotal()
    local albumID = CardSysRuntimeMgr:getCurAlbumID()
    local info = CardSysRuntimeMgr:getSeasonData():getAlbumDataById(albumID)
    if info then
        return info.clans or 0
    else
        return 0
    end
end

--拼csd工程的坐标已经有了偏移，会导致计算异常，计算的时候加上这个值
function CardLinkProgressNode:getProcessOffsetX()
    return self.m_jindu:getPositionX()
end

function CardLinkProgressNode:setProgressText(current)
    self.m_shuzi:setString(current .. "/" .. self:getTotal())
end

function CardLinkProgressNode:getProcessSize()
    return self.layerSGSize
end

function CardLinkProgressNode:setProgressInfo(current)
    local max = self:getTotal()
    local rate = current / max
    self.m_jindu:setPercent(rate * 100)
    local layerSGSize = self.layerSGSize
    self.layerSG:setSize(cc.size(rate * layerSGSize.width, layerSGSize.height))
end

function CardLinkProgressNode:startIncrease(srcPro, targetPro, perCall, overCall)
    local oriPro = srcPro
    local currentPro = srcPro
    local frameChangeV = math.min(1, (targetPro - srcPro)/10) -- 不能大于1，因为每涨到1都要回调一下的
    -- print("LINK: srcPro, targetPro, frameChangeV --- ", srcPro, targetPro, frameChangeV)

    local curPerChangeNum = 0
    local maxPerChangeNum = 1.0


    self:setProgressInfo(srcPro)
    self.m_increaseTimer =
        schedule(
        self,
        function()
            currentPro = currentPro + frameChangeV
            curPerChangeNum = curPerChangeNum + frameChangeV
            -- print("LINK: currentPro, curPerChangeNum =", currentPro, curPerChangeNum, curPerChangeNum - maxPerChangeNum, math.abs(curPerChangeNum - maxPerChangeNum))
            -- 浮点数和整数的判断
            if (curPerChangeNum >= maxPerChangeNum) or (0.0001 > math.abs(curPerChangeNum - maxPerChangeNum))  then
                curPerChangeNum = math.max(0, curPerChangeNum - maxPerChangeNum)
                -- print("LINK: < 0.001 curPerChangeNum =", curPerChangeNum)
                if perCall then                    
                    oriPro = oriPro + 1
                    -- print("LINK: perCall currentPro, oriPro =", currentPro, oriPro)
                    perCall(oriPro)
                end
                if currentPro >= targetPro or (0.0001 > math.abs(currentPro - targetPro)) then
                    self:setProgressInfo(targetPro)
                    self:endIncrease()
                    if overCall then
                        overCall()
                    end
                else
                    self:setProgressInfo(currentPro)
                end
            end
        end,
        0.01
    )
end
function CardLinkProgressNode:endIncrease()
    -- print("--- CardLinkProgressNode:endIncrease")
    if self.m_increaseTimer ~= nil then
        self:stopAction(self.m_increaseTimer)
        self.m_increaseTimer = nil
    end
end
return CardLinkProgressNode
