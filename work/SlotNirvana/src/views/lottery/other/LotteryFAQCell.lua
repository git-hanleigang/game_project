--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{dhs}
    time:2021-11-17 17:33:48
]]
local LotteryFAQCell = class("LotteryFAQCell",BaseView)
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local width = 800

function LotteryFAQCell:initUI(_idx,_info)

    LotteryFAQCell.super.initUI(self)

    self:createCsbNode("Lottery/csd/Lottery_FAQ_cell.csb")

    self.m_index = _idx

    --title
    local lbTitle = self:findChild("lb_question")

    --初始title高度
    self.m_lbInitialHeight = lbTitle:getContentSize().height

    util_AutoLine(lbTitle,_info.title or "",width,true)
    --读取配置后自动换行的title高度
    self.m_lbTitleHeight = lbTitle:getContentSize().height + 10
    self.m_lbTitle = lbTitle

    --content 默认是隐藏描述文字
    local lbContent = self:findChild("lb_answer")
    util_AutoLine(lbContent,_info.desc or "",width,true)
    self.m_lbContent = lbContent
    self.m_lbContent:setVisible(false)

    self.m_lbContentHeight = lbContent:getContentSize().height

    self.m_lbTotalContentHeight = self.m_lbContentHeight + 10 --math.abs(lbContent:getPositionY()) + lbContentHeight

    --button
    self.m_btnAdd = self:findChild("btn_add")
    self.m_btnReduce = self:findChild("btn_reduce")
    
    self.m_btnAdd:setVisible(true)
    self.m_btnReduce:setVisible(false)

    --底部虚线 （坐标：需要根据content.visible以及content高度+纵坐标）
    self.m_spLine = self:findChild("sp_line")
    self.m_spLine:setVisible(true)

    local contentTempValue = self.m_lbContent:getPositionY()-10
    if self.m_lbInitialHeight < self.m_lbTitleHeight then
        --证明此时title换行了
        contentTempValue = self.m_lbTitle:getPositionY() - (self.m_lbTitleHeight)
    end

    self.m_lbContent:setPosition(self.m_lbContent:getPositionX(), contentTempValue)

    self:updateLinePosition()
end

function LotteryFAQCell:updateLinePosition()
    local lineTempValue = self.m_lbTitle:getPositionY() - self.m_lbTitleHeight
    
    if self.m_lbContent:isVisible() then
        lineTempValue =  self.m_lbContent:getPositionY() - self.m_lbContentHeight - 10
    end

    self.m_spLine:setPosition(self.m_spLine:getPositionX(),  lineTempValue)
end

--返回给Cell层
function LotteryFAQCell:getCurCellSize()
    if self.m_lbContent:isVisible() then
        return cc.size(width, self.m_lbTotalContentHeight + self.m_lbTitleHeight)
    end
    return cc.size(width, self.m_lbTitleHeight)

end

function LotteryFAQCell:clickFunc(sender)
    
    local m_sBtnName = sender:getName()
    --新进来默认是折叠，点击加号按钮为lastIndex赋值
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
   
    self.m_lbContent:setVisible(not self.m_lbContent:isVisible())
    self:changeBtnTexture()
    self:updateLinePosition()

    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.UPDATE_FAQ_LISTVIEW, self.m_index)

end

function LotteryFAQCell:hideCell()
    self.m_lbContent:setVisible(false)
    self:changeBtnTexture() 
    self:updateLinePosition()
    
end

function LotteryFAQCell:changeBtnTexture()

    local show = self.m_lbContent:isVisible()
    self.m_btnAdd:setVisible(not show)
    self.m_btnReduce:setVisible(show)
    
end

return LotteryFAQCell