--[[
    再选一次按钮
]]
local CSMainPickAgain = class("CSMainPickAgain", BaseView)

function CSMainPickAgain:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_MainLayer_PICK.csb"
end

function CSMainPickAgain:initCsbNodes()
    self.m_lbGems = self:findChild("lb_number")
end

function CSMainPickAgain:updatePick(_gems, _clickContinue, _clickPickAgain)
    self.m_gems = _gems or 0
    self.m_clickContinue = _clickContinue
    self.m_clickPickAgain = _clickPickAgain
    self:updatePrice(_gems)
end

function CSMainPickAgain:updatePrice(_price)
    _price = _price or 0
    self.m_lbGems:setString(_price)
end

function CSMainPickAgain:playShow(_over)
    self.m_isRequesting = false
    self.m_isOpenShoping = false
    self:runCsbAction("start", false, function()
        if _over then
            _over()
        end
        self:playIdle()
    end, 60)
end

function CSMainPickAgain:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function CSMainPickAgain:playHide(_over)
    self:runCsbAction("over", false, _over, 60)
end

function CSMainPickAgain:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_thanks" then
        if self.m_isOpenShoping == true then
            return
        end
        if self.m_isRequesting == true then
            return
        end
        self.m_isRequesting = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.CardSeeker):requestGiveUpAgain(function()
            if not tolua.isnull(self) then
                if self.m_clickContinue then
                    self.m_clickContinue()
                end
                self:playHide(function()
                    self.m_isRequesting = false
                end)
            end
        end)
    elseif name == "btn_pick" then
        if self.m_isOpenShoping == true then
            return
        end
        if self.m_isRequesting == true then
            return
        end
        -- 打开商城钻石界面
        if globalData.userRunData.gemNum < self.m_gems then
            self.m_isOpenShoping = true
            util_performWithDelay(self, function()
                self.m_isOpenShoping = false
            end, 1)
            local params = {activityName = "CSMainPickAgain", log = true, shopPageIndex = 2}
            G_GetMgr(G_REF.Shop):showMainLayer(params)
        else
            self.m_isRequesting = true
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            G_GetMgr(G_REF.CardSeeker):requestPickAgain(function()
                if not tolua.isnull(self) then
                    if self.m_clickPickAgain then
                        self.m_clickPickAgain()
                    end
                    self:playHide(function()
                        self.m_isRequesting = false
                    end)                
                end
            end)
        end
    end
end

return CSMainPickAgain
