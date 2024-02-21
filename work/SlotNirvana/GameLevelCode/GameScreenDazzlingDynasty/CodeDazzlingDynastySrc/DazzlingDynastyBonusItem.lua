--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-06 14:27:10
]]

local DazzlingDynastyBonusItem = class("DazzlingDynastyBonusItem",util_require("base.BaseView"))

function DazzlingDynastyBonusItem:initUI()
    self:createCsbNode("Socre_DazzlingDynasty_Game_BlueDiamond.csb")
    self.greenDiamond = self:findChild("DazzlingDynasty_WF_coin1_1")
    self.redDiamond = self:findChild("DazzlingDynasty_WF_coin2_2")
    self.blueDiamond = self:findChild("DazzlingDynasty_WF_coin3_3")
    self.grayDiamond = self:findChild("DazzlingDynasty_WF_coin1_gray")
    -- self.flashLight = self:findChild("DazzlingDynasty_minigame_saoguang6_4")
    self.jackPotGrand = self:findChild("DazzlingDynasty_Grand_4")
    self.jackPotGrandGray = self:findChild("DazzlingDynasty_Grand_gray_2")
    self.jackPotMajor = self:findChild("DazzlingDynasty_Major_5")
    self.jackPotMajorGray = self:findChild("DazzlingDynasty_Major_gray_3")
    self.jackPotMinor = self:findChild("DazzlingDynasty_Minor_7")
    self.jackPotMinorGray = self:findChild("DazzlingDynasty_Minor_gray_5")
    self.jackPotMini = self:findChild("DazzlingDynasty_Mini_6")
    self.jackPotMiniGray = self:findChild("DazzlingDynasty_Mini_gray_4")
    self.lbScore = self:findChild("m_lb_score")
    self.lbSoreGray = self:findChild("m_lb_score_gray")
    local touch = self:findChild("touch")
    self.touch = touch
    self:addClick(touch)
    self:setOpenedFlag(false)
    self:setScoreInfo(false,0,nil,nil)
end

function DazzlingDynastyBonusItem:setExtraInfo(game,index,state,scoreType,score)
    self.game = game
    self.index = index
    self:setScoreInfo(false,state,scoreType,score)
end

function DazzlingDynastyBonusItem:setOpenedFlag(flag)
    self.openedFlag = flag
end

function DazzlingDynastyBonusItem:getOpenedFlag()
    return self.openedFlag
end

function DazzlingDynastyBonusItem:setScoreInfo(openAllFlag,state,scoreType,score)
    --设置背景
    if state ~= nil then
        --初始化
        if state == 0 then
            self.greenDiamond:setVisible(false)
            self.redDiamond:setVisible(true)
            self.blueDiamond:setVisible(false)
            self.grayDiamond:setVisible(false)
            -- self.flashLight:setVisible(false)
        --打开
        elseif state == 1 then
            self.greenDiamond:setVisible(false)
            self.redDiamond:setVisible(false)
            self.blueDiamond:setVisible(true)
            self.grayDiamond:setVisible(false)
            -- self.flashLight:setVisible(false)
        --打开绿色
        elseif state == 2 then
            self.greenDiamond:setVisible(true)
            self.redDiamond:setVisible(false)
            self.blueDiamond:setVisible(false)
            self.grayDiamond:setVisible(false)
            -- self.flashLight:setVisible(false)
        --被动暗绿色
        elseif state == 3 then
            self.greenDiamond:setVisible(false)
            self.redDiamond:setVisible(false)
            self.blueDiamond:setVisible(false)
            self.grayDiamond:setVisible(true)
            -- self.flashLight:setVisible(false)
        end
    end
    local isOpened = (state == 1 or state == 2) and self:getOpenedFlag()
    openAllFlag = openAllFlag and not self:getOpenedFlag()
    --设置文字
    if scoreType == "Grand" then
        self.jackPotGrand:setVisible(isOpened)
        self.jackPotGrandGray:setVisible(openAllFlag)
        self.jackPotMajor:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        self.lbScore:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Major" then
        self.jackPotGrand:setVisible(false)
        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajor:setVisible(isOpened)
        self.jackPotMajorGray:setVisible(openAllFlag)
        self.jackPotMinor:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        self.lbScore:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Minor" then
        self.jackPotGrand:setVisible(false)
        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinor:setVisible(isOpened)
        self.jackPotMinorGray:setVisible(openAllFlag)
        self.jackPotMini:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        self.lbScore:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Mini" then
        self.jackPotGrand:setVisible(false)
        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMini:setVisible(isOpened)
        self.jackPotMiniGray:setVisible(openAllFlag)
        self.lbScore:setVisible(false)
        self.lbSoreGray:setVisible(false)
    else
        self.jackPotGrand:setVisible(false)
        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        if score ~= nil then
            local strScore = util_formatCoins(score,3,true)
            self.lbScore:setVisible(isOpened)
            self.lbSoreGray:setVisible(openAllFlag)
            self.lbSoreGray:setString(strScore)
            self.lbScore:setString(strScore)
        else
            self.lbScore:setVisible(false)
            self.lbSoreGray:setVisible(false)
        end
    end 
end

function DazzlingDynastyBonusItem:openItemUI(state,scoreType,score,callBack,endCallBack)
    -- local flashLight = self.flashLight
    -- flashLight:setVisible(true)
    self.game:playTriggerAction(self)
    util_performWithDelay(self,function()
        self:setScoreInfo(false,state,scoreType,score)
        self:runCsbAction("actionframe",false,
        function()
            if endCallBack ~= nil then
                endCallBack()
            end
            -- flashLight:setVisible(false)
        end)
        performWithDelay(self,function()
            if callBack ~= nil then
                callBack()
            end
        end,8 / 30)
    end,10 / 30)
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Game_OpenItem.mp3")
end

function DazzlingDynastyBonusItem:openGrayItemUI(state,scoreType,score)
    self:setScoreInfo(true,state,scoreType,score)
    self:runCsbAction("actionframe_over",false)
end

function DazzlingDynastyBonusItem:clickFunc(sender)
    local game = self.game
    local index = self.index
    if game:canClick(index) and sender == self.touch then
        game:sendData(index)
    end
end

return DazzlingDynastyBonusItem