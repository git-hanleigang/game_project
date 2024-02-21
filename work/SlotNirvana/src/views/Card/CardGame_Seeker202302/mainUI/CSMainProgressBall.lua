--[[
    层级球
]]
local TSMainProgressBall = class("TSMainProgressBall", BaseView)

function TSMainProgressBall:initDatas(_index)
    self.m_index = _index
end

function TSMainProgressBall:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_MainLayer_GuanqiaBall.csb"
end

function TSMainProgressBall:initCsbNodes()
    self.m_spNormalBall = self:findChild("sp_ball_normal")
    self.m_spSpecialBall = self:findChild("sp_ball_special")
    self.m_spSpecialBallNow = self:findChild("sp_ball_special_now")
    self.m_lbNumNormal = self:findChild("lb_number_normal")
    self.m_lbNumSpecial = self:findChild("lb_number_special")
end

function TSMainProgressBall:initUI()
    TSMainProgressBall.super.initUI(self)
    self:initView()
end

function TSMainProgressBall:resetView()
    self:initView()
end

function TSMainProgressBall:initView()
    self.m_spNormalBall:setVisible(false)
    self.m_spSpecialBall:setVisible(false)
    self.m_spSpecialBallNow:setVisible(false)
    self.m_lbNumNormal:setVisible(false)
    self.m_lbNumSpecial:setVisible(false)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    if self.m_index == GameData:getCurLevelIndex() then
        if self:isSpecial() then
            self.m_spSpecialBallNow:setVisible(true)
            self.m_lbNumSpecial:setVisible(true)
        else
            self.m_spNormalBall:setVisible(true)
            self.m_lbNumNormal:setVisible(true)
        end
        self:playLightIdle()
    else
        if self:isSpecial() then
            self.m_spSpecialBall:setVisible(true)
            self.m_lbNumSpecial:setVisible(true)
        else
            self.m_spNormalBall:setVisible(true)
            self.m_lbNumNormal:setVisible(true)
        end
        self:playNoLightIdle()
    end
    self.m_lbNumNormal:setString(self.m_index)
    self.m_lbNumSpecial:setString(self.m_index)
end

function TSMainProgressBall:playLightIdle()
    self:runCsbAction("idle1", true, nil, 60)
end

function TSMainProgressBall:playNoLightIdle()
    self:runCsbAction("idle2", true, nil, 60)
end

function TSMainProgressBall:isSpecial()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelData = GameData:getLevelConfigByIndex(self.m_index)
    return levelData:isSpecial()
end

function TSMainProgressBall:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

return TSMainProgressBall
