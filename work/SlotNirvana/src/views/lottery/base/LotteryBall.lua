--[[
Author: your name
Date: 2021-11-19 17:39:39
LastEditTime: 2021-11-19 17:39:40
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/base/LotteryBall.lua
--]]
local LotteryBall = class("LotteryBall", BaseView)
local SpriteFontManager = require("utils.spriteFont.SpriteFontManager"):getInstance()

function LotteryBall:initDatas(_params)
    LotteryBall.super.initDatas(self, _params)

    self.m_bRed = _params.bRed
    self.m_number = _params.number or 0
end

function LotteryBall:initUI(_params)
    LotteryBall.super.initUI(self)

    -- 初始化 球
    local nodeWhite = self:findChild("sp_whiteball")
    local nodeRed = self:findChild("sp_redball")
    local lbNum = nil
    if not self.m_bRed then
        nodeWhite:setVisible(true)
        nodeRed:setVisible(false)

        lbNum = nodeWhite:getChildByName("lb_num")
    else
        nodeWhite:setVisible(false)
        nodeRed:setVisible(true)

        lbNum = nodeRed:getChildByName("lb_num")
    end
    -- self.m_lbNum =  lbNum
    self.m_lbNum = SpriteFontManager:convertTextBMFontToNodeBMFont(lbNum)
    self:updateNumberUI()

    self:playIdleAct()
end

-- 更新球的数字
function LotteryBall:updateNumberUI(_number)
    self.m_number = _number or self.m_number
    self.m_lbNum:setString(self.m_number)
end

function LotteryBall:getCsbName()
    return "Lottery/csd/Choose/node_ball_zhanshi.csb"
end

function LotteryBall:playIdleAct()
    self:checkCsbActionExists()
    self:runCsbAction("idle") 
end
function LotteryBall:playSweepAct(_bLoop)
    self:checkCsbActionExists()
    if _bLoop then
        self:runCsbAction("sweep", true)
        return
    end
    self:runCsbAction("sweep", false, function()
        self:playIdleAct()
    end, 60)
end
function LotteryBall:playShowAct()
    self:checkCsbActionExists()
    self:runCsbAction("start", false, function()
        self:playSweepAct()
    end, 60) 
end

function LotteryBall:checkCsbActionExists()
    if tolua.isnull(self.m_csbAct) then
        self.m_csbAct = util_actCreate(self:getCsbName())
        if self.m_csbAct and self.m_csbNode then
            self.m_csbNode:runAction(self.m_csbAct)
        end
    end
end

return LotteryBall