--[[
Author: cxc
Date: 2021-11-25 18:02:27
LastEditTime: 2021-11-25 18:02:28
LastEditors: your name
Description: 乐透上一期中头奖玩家信息
FilePath: /SlotNirvana/src/GameModel/Lottery/model/LotteryDataPreUserData.lua
--]]
local LotteryDataPreUserData = class("LotteryDataPreUserData")

function LotteryDataPreUserData:parseData(_userInfo)
    self.m_facebookId = _userInfo.facebookId
    self.m_head = _userInfo.head
    self.m_robotHead = _userInfo.robotHead
    self.m_name = _userInfo.name
    self.m_level = _userInfo.level
    self.m_frameId = _userInfo.frame
end

function LotteryDataPreUserData:getFbId()
    return self.m_facebookId or ""
end
function LotteryDataPreUserData:getSysHead()
    return self.m_head or ""
end
function LotteryDataPreUserData:getRobotHead()
    return self.m_robotHead or ""
end
function LotteryDataPreUserData:getUserName()
    return self.m_name or ""
end
function LotteryDataPreUserData:getUserLevel()
    return self.m_level or 1
end
function LotteryDataPreUserData:getUserFrameId()
    return self.m_frameId
end

return LotteryDataPreUserData