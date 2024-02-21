local StatueInfo = class("StatueInfo", BaseLayer)

function StatueInfo:ctor()
    StatueInfo.super.ctor(self)
    self.m_curPageIndex = 1
    self:setLandscapeCsbName("CardRes/season202102/Statue/StatueInfo.csb")
end
function StatueInfo:initUI()
    StatueInfo.super.initUI(self)
end

function StatueInfo:initCsbNodes()
    self.m_spInfos = {}
    for i=1,math.huge do
        local spInfo = self:findChild("sp_info"..i)
        if spInfo then
            self.m_spInfos[i] = spInfo
        else
            break
        end
    end

    self.m_btnLeft = self:findChild("btn_jiantou1")
    self.m_btnRight = self:findChild("btn_jiantou2")
end

function StatueInfo:initView()
    self:updatePageInfo()
    self:updatePageBtn()
end

function StatueInfo:updatePageInfo()
    for i=1,#self.m_spInfos do
        self.m_spInfos[i]:setVisible(i == self.m_curPageIndex)
    end
end

function StatueInfo:updatePageBtn()
    self.m_btnLeft:setVisible(true)
    self.m_btnRight:setVisible(true)
    if self.m_curPageIndex == 1 then
        self.m_btnLeft:setVisible(false)
    end
    if self.m_curPageIndex == #self.m_spInfos then
        self.m_btnRight:setVisible(false)
    end
end

function StatueInfo:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_jiantou1" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self.m_curPageIndex = self.m_curPageIndex - 1
        self:updatePageInfo()
        self:updatePageBtn()        
    elseif name == "btn_jiantou2" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self.m_curPageIndex = self.m_curPageIndex + 1
        self:updatePageInfo()
        self:updatePageBtn()        
    elseif name == "btn_x" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeUI()
    end
end

return StatueInfo