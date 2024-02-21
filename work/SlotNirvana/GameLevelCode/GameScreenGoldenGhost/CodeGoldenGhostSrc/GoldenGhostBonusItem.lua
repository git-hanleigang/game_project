local GoldenGhostBonusItem = class("GoldenGhostBonusItem",util_require("base.BaseView"))

function GoldenGhostBonusItem:setItemEvenStates( )

    local touch = self:findChild("touch")
    self.touch = touch
    self:addClick(touch)
    self:setOpenedFlag(false)
    self:setScoreInfo(false,0,nil,nil)
end

function GoldenGhostBonusItem:initUI()
    self:createCsbNode("Socre_GoldenGhost_Game_bonus_pumkin.csb")

    self.m_spine =  util_spineCreate("Socre_GoldenGhost_Game_bonus_pumkin",true,true)
    self:findChild("spineNode"):addChild(self.m_spine)

    self.jackPotGrand = self:findChild("grand")
    self.jackPotMajor = self:findChild("major")
    self.jackPotMinor = self:findChild("minor")
    self.jackPotMini = self:findChild("mini")
    self.lbScore = self:findChild("m_lb_coins")
    -- 置灰图片
    self.jackPotGrandGray = self:findChild("grand_gray")
    self.jackPotMajorGray = self:findChild("major_gray")
    self.jackPotMinorGray = self:findChild("minor_gray")
    self.jackPotMiniGray = self:findChild("mini_gray")
    self.lbSoreGray = self:findChild("m_lb_coins_gray")

    --外部调用
    self.tuowei = self:findChild("tuowei")

    self:setItemEvenStates( )
end

function GoldenGhostBonusItem:setExtraInfo(game,index,state,scoreType,score,machine)
    self.game = game
    self.index = index
    self:initItemUI(false,state,scoreType,score)
    self.machine = machine
end

function GoldenGhostBonusItem:setOpenedFlag(flag)
    self.openedFlag = flag
end

function GoldenGhostBonusItem:getOpenedFlag()
    return self.openedFlag
end

function GoldenGhostBonusItem:setScoreInfo(openAllFlag,state,scoreType,score)
    local isOpened = true
    if not openAllFlag then
        isOpened = (state == 1 or state == 2) and self:getOpenedFlag()
    end
    openAllFlag = openAllFlag and not self:getOpenedFlag()
    --设置文字
    --先注释
    if scoreType == "Grand" then
        self.jackPotGrand:setVisible(isOpened)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)
        
        self.jackPotGrandGray:setVisible(openAllFlag)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Major" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(isOpened)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)

        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajorGray:setVisible(openAllFlag)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Minor" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(isOpened)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)

        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinorGray:setVisible(openAllFlag)
        self.jackPotMiniGray:setVisible(false)
        self.lbSoreGray:setVisible(false)
    elseif scoreType == "Mini" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(isOpened)
        self.lbScore:setVisible(false)

        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMiniGray:setVisible(openAllFlag)
        self.lbSoreGray:setVisible(false)
    else
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.jackPotMinor:setVisible(false)

        self.jackPotGrandGray:setVisible(false)
        self.jackPotMajorGray:setVisible(false)
        self.jackPotMinorGray:setVisible(false)
        self.jackPotMiniGray:setVisible(false)
        if not self.lbScore then return end
        if score ~= nil then
            local strScore = util_formatCoins(score,3,true)
            self.lbScore:setVisible(isOpened)
            self.lbScore:setString(strScore)
            
            self.lbSoreGray:setVisible(openAllFlag)
            self.lbSoreGray:setString(strScore)
        else
            self.lbScore:setVisible(false)
            self.lbSoreGray:setVisible(false)
        end
    end
end

function GoldenGhostBonusItem:initItemUI( openAllFlag,state,scoreType,score )
    if state == 0 then
        self:runCsbAction("idle1",true)
    elseif state == 1 then
        self:runCsbAction("actionframe1")
        self:pauseForIndex(95)
    --打开绿色
    elseif state == 2 then
        self:runCsbAction("idle2",true)
    end
    local isOpened = (state == 1 or state == 2) and self:getOpenedFlag()
    openAllFlag = openAllFlag and not self:getOpenedFlag()
    --设置文字
    if scoreType == "Grand" then
        self.jackPotGrand:setVisible(isOpened)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)

        -- self.jackPotGrandGray:setVisible(openAllFlag)
        -- self.jackPotMajorGray:setVisible(false)
        -- self.jackPotMinorGray:setVisible(false)
        -- self.jackPotMiniGray:setVisible(false)
        -- self.lbSoreGray:setVisible(false)
    elseif scoreType == "Major" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(isOpened)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)

        -- self.jackPotGrandGray:setVisible(false)
        -- self.jackPotMajorGray:setVisible(openAllFlag)
        -- self.jackPotMinorGray:setVisible(false)
        -- self.jackPotMiniGray:setVisible(false)
        -- self.lbSoreGray:setVisible(false)
    elseif scoreType == "Minor" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(isOpened)
        self.jackPotMini:setVisible(false)
        self.lbScore:setVisible(false)

        -- self.jackPotGrandGray:setVisible(false)
        -- self.jackPotMajorGray:setVisible(false)
        -- self.jackPotMinorGray:setVisible(openAllFlag)
        -- self.jackPotMiniGray:setVisible(false)
        -- self.lbSoreGray:setVisible(false)
    elseif scoreType == "Mini" then
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMinor:setVisible(false)
        self.jackPotMini:setVisible(isOpened)
        self.lbScore:setVisible(false)

        -- self.jackPotGrandGray:setVisible(false)
        -- self.jackPotMajorGray:setVisible(false)
        -- self.jackPotMinorGray:setVisible(false)
        -- self.jackPotMiniGray:setVisible(openAllFlag)
        -- self.lbSoreGray:setVisible(false)
    else
        self.jackPotGrand:setVisible(false)
        self.jackPotMajor:setVisible(false)
        self.jackPotMini:setVisible(false)
        self.jackPotMinor:setVisible(false)

        -- self.jackPotGrandGray:setVisible(false)
        -- self.jackPotMajorGray:setVisible(false)
        -- self.jackPotMinorGray:setVisible(false)
        -- self.jackPotMiniGray:setVisible(false)
        if not self.lbScore then return end
        if score ~= nil then
            local strScore = util_formatCoins(score,3,true)
            self.lbScore:setVisible(isOpened)
            self.lbScore:setString(strScore)
            -- self.lbSoreGray:setVisible(openAllFlag)
            -- self.lbSoreGray:setString(strScore)
        else
            self.lbScore:setVisible(false)
            -- self.lbSoreGray:setVisible(false)
        end
    end
end

function GoldenGhostBonusItem:showJackpotWinView(index,coins,func)
    self.machine:showRespinJackpot(index,coins,func)
end

function GoldenGhostBonusItem:openItemUI(state,scoreType,score,callBack,trigOtherState)
    self.game:playTriggerAction(self)
    -- util_performWithDelay(self,function()
    self:setScoreInfo(false,state,scoreType,score)
    local actionframeId = trigOtherState or state
    self:runCsbAction("actionframe" .. tostring(actionframeId),false,function()
        if state == 2 then
            self:runCsbAction("idle2",true)
        end
    end)
    performWithDelay(self,function()
        local jackPotTypeList = {"Grand","Major","Minor","Mini"} 
        local jackPotIdx = table.indexof(jackPotTypeList,scoreType)
        if jackPotIdx then
            self:showJackpotWinView(jackPotIdx,score,function ( ... )
                -- body
                performWithDelay(self,function()
                    if callBack ~= nil then
                        callBack()
                    end
                end,8 / 30)
                gLobalSoundManager:setBackgroundMusicVolume(1)
            end)
        else
            performWithDelay(self,function()
                if callBack ~= nil then
                    callBack()
                end
            end,8 / 30)
        end
    end,70 / 60)

end

function GoldenGhostBonusItem:openGrayItemUI(state,scoreType,score)
    if self:getOpenedFlag() then return end
    self:setScoreInfo(true,state,scoreType,score)
    self:runCsbAction("dark",false)
end

function GoldenGhostBonusItem:clickFunc(sender)
    local game = self.game
    local index = self.index
    if game:canClick(index) and sender == self.touch then
        game:sendData(index)
    end
end



--播放动画 解决播放cocos时间线时 播一下spine时间线
function GoldenGhostBonusItem:runCsbAction(key, loop, func, fps)
    util_csbPlayForKey(self.m_csbAct, key, loop, func, fps)

    util_spinePlay(self.m_spine, key, loop)
end

return GoldenGhostBonusItem