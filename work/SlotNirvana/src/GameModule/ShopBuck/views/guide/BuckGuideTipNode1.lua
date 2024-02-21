local BuckGuideTipNode1 = class("BuckGuideTipNode1", BaseView)

function BuckGuideTipNode1:initDatas(_tipId)
    self.m_tipId = _tipId
end

function BuckGuideTipNode1:getCsbName()
    if self.m_tipId == "t001" then
        return "ShopBuck/csb/guide/ShopBuckGuide_1.csb"
    elseif self.m_tipId == "t002" then
        if globalData.slotRunData.isPortrait then
            return "ShopBuck/csb/guide/ShopBuckGuide_2_V.csb"
        end
        return "ShopBuck/csb/guide/ShopBuckGuide_2.csb"
    elseif self.m_tipId == "t003" then
        if globalData.slotRunData.isPortrait then
            return "ShopBuck/csb/guide/ShopBuckGuide_3_V.csb"
        end
        return "ShopBuck/csb/guide/ShopBuckGuide_3.csb"
    elseif self.m_tipId == "t004" then
        return "ShopBuck/csb/guide/ShopBuckGuide_4.csb"
    elseif self.m_tipId == "t2001" then
        if globalData.slotRunData.isPortrait then
            return "ShopBuck/csb/guide/ShopBuckGuide_5_V.csb"
        end
        return "ShopBuck/csb/guide/ShopBuckGuide_5.csb"
    elseif self.m_tipId == "t2002" then
        if globalData.slotRunData.isPortrait then
            return "ShopBuck/csb/guide/ShopBuckGuide_6_V.csb"
        end
        return "ShopBuck/csb/guide/ShopBuckGuide_6.csb"
    end
end

function BuckGuideTipNode1:initUI()
    BuckGuideTipNode1.super.initUI(self)
    self:playShow(function()
        if not tolua.isnull(self) then
            self:playIdle()
        end
    end)
end

function BuckGuideTipNode1:playShow(_over)
    -- self:runCsbAction("show", false, _over, 60)
    if _over then
        _over()
    end
end

function BuckGuideTipNode1:playIdle()
    self:runCsbAction("idle", true, nil, 60)
    if _over then
        _over()
    end
end

function BuckGuideTipNode1:playOver(_over)
    -- self:runCsbAction("over", false, _over, 60)
    if _over then
        _over()
    end
end

return BuckGuideTipNode1