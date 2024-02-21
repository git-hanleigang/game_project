local InviteConfig = {}

InviteConfig.EVENT_NAME = {
    INVITER_UPDATA_FREE = "INVITER_UPDATA_FREE", --邀请界面领取人数奖励
    INVITER_UPDATA_PAY = "INVITER_UPDATA_PAY", --邀请界面领取付费奖励
    INVITER_UPDATA_LIST = "INVITER_UPDATA_LIST", --刷新入口
    INVITER_GUIDE = "INVITER_GUIDE", --yindao
    INVITEE_UPDATA_PAY = "INVITER_UPDATA_PAY", --被邀请界面领奖
    INVITER_GUIDER = "INVITER_GUIDER", --邀请页引导
    INVITEE_GUIDER = "INVITEE_GUIDER", --被邀请页引导
    INVITER_UPDATA_REWARD = "INVITER_UPDATA_REWARD", --刷新入口
    INVITEE_GUIDER_FINSH = "INVITEE_GUIDER_FINSH", --被邀请页引导
    INVITER_REWARD_COLLECT = "INVITER_REWARD_COLLECT", --被邀请页引导
}

InviteConfig.SHARE = {
	EMAIL = 2,
	SMS = 1,
	FB = 3
}

InviteConfig.FISTSHAR = "FistShare"  --是不是领取了奖励
InviteConfig.GUID = "Guid" --领取奖励引导第几步

return InviteConfig