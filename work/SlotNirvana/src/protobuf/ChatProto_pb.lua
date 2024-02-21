-- Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf"
local bpi = require("protobuf.BaseProtoFunction")
local CHATBASEPROTO_PB = require("ChatBaseProto_pb")
module('ChatProto_pb')


local localTable = {}
localTable.MESSAGETYPE = protobuf.EnumDescriptor()
localTable.MESSAGETYPE_TEXT_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_JACKPOT_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_CARD_CLAN_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_CASHBONUS_JACKPOT_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_PURCHASE_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_CLAN_CHALLENGE_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_CLAN_MEMBER_CARD_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_SYSTEM_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_LOTTERY_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_RANK_REWARD_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_RUSH_REWARD_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_JACKPOT_SHARE_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_AVATAR_FRAME_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_RED_PACKAGE_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_RED_PACKAGE_COLLECT_ENUM = protobuf.EnumValueDescriptor()
localTable.MESSAGETYPE_CLAN_DUEL_ENUM = protobuf.EnumValueDescriptor()
AUTHSEND = protobuf.Descriptor()
localTable.AUTHSEND_PRODUCTNO_FIELD = protobuf.FieldDescriptor()
localTable.AUTHSEND_GROUP_FIELD = protobuf.FieldDescriptor()
localTable.AUTHSEND_USER_FIELD = protobuf.FieldDescriptor()
localTable.AUTHSEND_TOKEN_FIELD = protobuf.FieldDescriptor()
AUTHRECEIVE = protobuf.Descriptor()
localTable.AUTHRECEIVE_CODE_FIELD = protobuf.FieldDescriptor()
localTable.AUTHRECEIVE_DESC_FIELD = protobuf.FieldDescriptor()
localTable.AUTHRECEIVE_SID_FIELD = protobuf.FieldDescriptor()
SYNCSEND = protobuf.Descriptor()
localTable.SYNCSEND_SID_FIELD = protobuf.FieldDescriptor()
localTable.SYNCSEND_MSGID_FIELD = protobuf.FieldDescriptor()
localTable.SYNCSEND_CHIPSMSGID_FIELD = protobuf.FieldDescriptor()
localTable.SYNCSEND_GIFTMSGID_FIELD = protobuf.FieldDescriptor()
localTable.SYNCSEND_CHATMSGID_FIELD = protobuf.FieldDescriptor()
localTable.SYNCSEND_REDPACKAGEMSGID_FIELD = protobuf.FieldDescriptor()
SYNCRECEIVE = protobuf.Descriptor()
localTable.SYNCRECEIVE_CODE_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_DESC_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_ALL_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_CHIPS_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_GIFT_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_CHAT_FIELD = protobuf.FieldDescriptor()
localTable.SYNCRECEIVE_REDPACKAGE_FIELD = protobuf.FieldDescriptor()
MESSAGESEND = protobuf.Descriptor()
localTable.MESSAGESEND_SID_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_CONTENT_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_TYPE_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_NICKNAME_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_HEAD_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_FACEBOOKID_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGESEND_FRAME_FIELD = protobuf.FieldDescriptor()
NOTICE = protobuf.Descriptor()
localTable.NOTICE_MSG_FIELD = protobuf.FieldDescriptor()
HEARTSEND = protobuf.Descriptor()
localTable.HEARTSEND_SID_FIELD = protobuf.FieldDescriptor()
COLLECTSEND = protobuf.Descriptor()
localTable.COLLECTSEND_SID_FIELD = protobuf.FieldDescriptor()
localTable.COLLECTSEND_MSGID_FIELD = protobuf.FieldDescriptor()
localTable.COLLECTSEND_COINS_FIELD = protobuf.FieldDescriptor()
localTable.COLLECTSEND_COLLECTOR_FIELD = protobuf.FieldDescriptor()
COLLECTALLSEND = protobuf.Descriptor()
localTable.COLLECTALLSEND_SID_FIELD = protobuf.FieldDescriptor()
localTable.COLLECTALLSEND_MSGID_FIELD = protobuf.FieldDescriptor()
localTable.COLLECTALLSEND_COINS_FIELD = protobuf.FieldDescriptor()
MESSAGEINFO = protobuf.Descriptor()
localTable.MESSAGEINFO_MSGID_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_TYPE_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_CONTENT_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_SENDUSER_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_SENDTIME_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_STATUS_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_EFFECTIME_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_EXTRA_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_COINS_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_NICKNAME_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_HEAD_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_FACEBOOKID_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_EXTENDDATA_FIELD = protobuf.FieldDescriptor()
localTable.MESSAGEINFO_FRAME_FIELD = protobuf.FieldDescriptor()

TEXT = 1
JACKPOT = 2
CARD_CLAN = 3
CASHBONUS_JACKPOT = 4
PURCHASE = 5
CLAN_CHALLENGE = 6
CLAN_MEMBER_CARD = 7
SYSTEM = 8
LOTTERY = 9
RANK_REWARD = 10
RUSH_REWARD = 11
JACKPOT_SHARE = 12
AVATAR_FRAME = 13
RED_PACKAGE = 14
RED_PACKAGE_COLLECT = 15
CLAN_DUEL = 16

bpi.setEnumInfo(localTable.MESSAGETYPE_TEXT_ENUM,"TEXT",0,1)
bpi.setEnumInfo(localTable.MESSAGETYPE_JACKPOT_ENUM,"JACKPOT",1,2)
bpi.setEnumInfo(localTable.MESSAGETYPE_CARD_CLAN_ENUM,"CARD_CLAN",2,3)
bpi.setEnumInfo(localTable.MESSAGETYPE_CASHBONUS_JACKPOT_ENUM,"CASHBONUS_JACKPOT",3,4)
bpi.setEnumInfo(localTable.MESSAGETYPE_PURCHASE_ENUM,"PURCHASE",4,5)
bpi.setEnumInfo(localTable.MESSAGETYPE_CLAN_CHALLENGE_ENUM,"CLAN_CHALLENGE",5,6)
bpi.setEnumInfo(localTable.MESSAGETYPE_CLAN_MEMBER_CARD_ENUM,"CLAN_MEMBER_CARD",6,7)
bpi.setEnumInfo(localTable.MESSAGETYPE_SYSTEM_ENUM,"SYSTEM",7,8)
bpi.setEnumInfo(localTable.MESSAGETYPE_LOTTERY_ENUM,"LOTTERY",8,9)
bpi.setEnumInfo(localTable.MESSAGETYPE_RANK_REWARD_ENUM,"RANK_REWARD",9,10)
bpi.setEnumInfo(localTable.MESSAGETYPE_RUSH_REWARD_ENUM,"RUSH_REWARD",10,11)
bpi.setEnumInfo(localTable.MESSAGETYPE_JACKPOT_SHARE_ENUM,"JACKPOT_SHARE",11,12)
bpi.setEnumInfo(localTable.MESSAGETYPE_AVATAR_FRAME_ENUM,"AVATAR_FRAME",12,13)
bpi.setEnumInfo(localTable.MESSAGETYPE_RED_PACKAGE_ENUM,"RED_PACKAGE",13,14)
bpi.setEnumInfo(localTable.MESSAGETYPE_RED_PACKAGE_COLLECT_ENUM,"RED_PACKAGE_COLLECT",14,15)
bpi.setEnumInfo(localTable.MESSAGETYPE_CLAN_DUEL_ENUM,"CLAN_DUEL",15,16)
bpi.setEnumValues(localTable.MESSAGETYPE,"MessageType","chat.MessageType",{localTable.MESSAGETYPE_TEXT_ENUM,localTable.MESSAGETYPE_JACKPOT_ENUM,localTable.MESSAGETYPE_CARD_CLAN_ENUM,localTable.MESSAGETYPE_CASHBONUS_JACKPOT_ENUM,localTable.MESSAGETYPE_PURCHASE_ENUM,localTable.MESSAGETYPE_CLAN_CHALLENGE_ENUM,localTable.MESSAGETYPE_CLAN_MEMBER_CARD_ENUM,localTable.MESSAGETYPE_SYSTEM_ENUM,localTable.MESSAGETYPE_LOTTERY_ENUM,localTable.MESSAGETYPE_RANK_REWARD_ENUM,localTable.MESSAGETYPE_RUSH_REWARD_ENUM,localTable.MESSAGETYPE_JACKPOT_SHARE_ENUM,localTable.MESSAGETYPE_AVATAR_FRAME_ENUM,localTable.MESSAGETYPE_RED_PACKAGE_ENUM,localTable.MESSAGETYPE_RED_PACKAGE_COLLECT_ENUM,localTable.MESSAGETYPE_CLAN_DUEL_ENUM})
bpi.setFieldBaseInfo(localTable.AUTHSEND_PRODUCTNO_FIELD,"productNo","chat.AuthSend.productNo",1,0,2,false,"",9,9)
bpi.setFieldBaseInfo(localTable.AUTHSEND_GROUP_FIELD,"group","chat.AuthSend.group",2,1,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.AUTHSEND_USER_FIELD,"user","chat.AuthSend.user",3,2,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.AUTHSEND_TOKEN_FIELD,"token","chat.AuthSend.token",4,3,1,false,"",9,9)
bpi.setMessageInfo(AUTHSEND,"AuthSend","chat.AuthSend",{},{},{localTable.AUTHSEND_PRODUCTNO_FIELD, localTable.AUTHSEND_GROUP_FIELD, localTable.AUTHSEND_USER_FIELD, localTable.AUTHSEND_TOKEN_FIELD},false,{})
bpi.setFieldEnumInfo(localTable.AUTHRECEIVE_CODE_FIELD,"code","chat.AuthReceive.code",1,0,2,true,SUCCEED,CHATBASEPROTO_PB.RESPONSECODE,14,8)
bpi.setFieldBaseInfo(localTable.AUTHRECEIVE_DESC_FIELD,"desc","chat.AuthReceive.desc",2,1,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.AUTHRECEIVE_SID_FIELD,"sid","chat.AuthReceive.sid",3,2,1,false,"",9,9)
bpi.setMessageInfo(AUTHRECEIVE,"AuthReceive","chat.AuthReceive",{},{},{localTable.AUTHRECEIVE_CODE_FIELD, localTable.AUTHRECEIVE_DESC_FIELD, localTable.AUTHRECEIVE_SID_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.SYNCSEND_SID_FIELD,"sid","chat.SyncSend.sid",1,0,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.SYNCSEND_MSGID_FIELD,"msgId","chat.SyncSend.msgId",2,1,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.SYNCSEND_CHIPSMSGID_FIELD,"chipsMsgId","chat.SyncSend.chipsMsgId",3,2,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.SYNCSEND_GIFTMSGID_FIELD,"giftMsgId","chat.SyncSend.giftMsgId",4,3,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.SYNCSEND_CHATMSGID_FIELD,"chatMsgId","chat.SyncSend.chatMsgId",5,4,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.SYNCSEND_REDPACKAGEMSGID_FIELD,"redPackageMsgId","chat.SyncSend.redPackageMsgId",6,5,1,false,"",9,9)
bpi.setMessageInfo(SYNCSEND,"SyncSend","chat.SyncSend",{},{},{localTable.SYNCSEND_SID_FIELD, localTable.SYNCSEND_MSGID_FIELD, localTable.SYNCSEND_CHIPSMSGID_FIELD, localTable.SYNCSEND_GIFTMSGID_FIELD, localTable.SYNCSEND_CHATMSGID_FIELD, localTable.SYNCSEND_REDPACKAGEMSGID_FIELD},false,{})
bpi.setFieldEnumInfo(localTable.SYNCRECEIVE_CODE_FIELD,"code","chat.SyncReceive.code",1,0,2,true,SUCCEED,CHATBASEPROTO_PB.RESPONSECODE,14,8)
bpi.setFieldBaseInfo(localTable.SYNCRECEIVE_DESC_FIELD,"desc","chat.SyncReceive.desc",2,1,1,false,"",9,9)
bpi.setFieldMessageTypeInfo(localTable.SYNCRECEIVE_ALL_FIELD,"all","chat.SyncReceive.all",3,2,3,false,{},MESSAGEINFO,11,10)

bpi.setFieldMessageTypeInfo(localTable.SYNCRECEIVE_CHIPS_FIELD,"chips","chat.SyncReceive.chips",4,3,3,false,{},MESSAGEINFO,11,10)

bpi.setFieldMessageTypeInfo(localTable.SYNCRECEIVE_GIFT_FIELD,"gift","chat.SyncReceive.gift",5,4,3,false,{},MESSAGEINFO,11,10)

bpi.setFieldMessageTypeInfo(localTable.SYNCRECEIVE_CHAT_FIELD,"chat","chat.SyncReceive.chat",6,5,3,false,{},MESSAGEINFO,11,10)

bpi.setFieldMessageTypeInfo(localTable.SYNCRECEIVE_REDPACKAGE_FIELD,"redPackage","chat.SyncReceive.redPackage",7,6,3,false,{},MESSAGEINFO,11,10)

bpi.setMessageInfo(SYNCRECEIVE,"SyncReceive","chat.SyncReceive",{},{},{localTable.SYNCRECEIVE_CODE_FIELD, localTable.SYNCRECEIVE_DESC_FIELD, localTable.SYNCRECEIVE_ALL_FIELD, localTable.SYNCRECEIVE_CHIPS_FIELD, localTable.SYNCRECEIVE_GIFT_FIELD, localTable.SYNCRECEIVE_CHAT_FIELD, localTable.SYNCRECEIVE_REDPACKAGE_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.MESSAGESEND_SID_FIELD,"sid","chat.MessageSend.sid",1,0,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGESEND_CONTENT_FIELD,"content","chat.MessageSend.content",2,1,1,false,"",9,9)
bpi.setFieldEnumInfo(localTable.MESSAGESEND_TYPE_FIELD,"type","chat.MessageSend.type",3,2,1,false,nil,localTable.MESSAGETYPE,14,8)
bpi.setFieldBaseInfo(localTable.MESSAGESEND_NICKNAME_FIELD,"nickname","chat.MessageSend.nickname",4,3,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGESEND_HEAD_FIELD,"head","chat.MessageSend.head",5,4,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGESEND_FACEBOOKID_FIELD,"facebookId","chat.MessageSend.facebookId",6,5,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGESEND_FRAME_FIELD,"frame","chat.MessageSend.frame",7,6,1,false,"",9,9)
bpi.setMessageInfo(MESSAGESEND,"MessageSend","chat.MessageSend",{},{},{localTable.MESSAGESEND_SID_FIELD, localTable.MESSAGESEND_CONTENT_FIELD, localTable.MESSAGESEND_TYPE_FIELD, localTable.MESSAGESEND_NICKNAME_FIELD, localTable.MESSAGESEND_HEAD_FIELD, localTable.MESSAGESEND_FACEBOOKID_FIELD, localTable.MESSAGESEND_FRAME_FIELD},false,{})
bpi.setFieldMessageTypeInfo(localTable.NOTICE_MSG_FIELD,"msg","chat.Notice.msg",1,0,1,false,nil,MESSAGEINFO,11,10)

bpi.setMessageInfo(NOTICE,"Notice","chat.Notice",{},{},{localTable.NOTICE_MSG_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.HEARTSEND_SID_FIELD,"sid","chat.HeartSend.sid",1,0,1,false,"",9,9)
bpi.setMessageInfo(HEARTSEND,"HeartSend","chat.HeartSend",{},{},{localTable.HEARTSEND_SID_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.COLLECTSEND_SID_FIELD,"sid","chat.CollectSend.sid",1,0,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.COLLECTSEND_MSGID_FIELD,"msgId","chat.CollectSend.msgId",2,1,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.COLLECTSEND_COINS_FIELD,"coins","chat.CollectSend.coins",3,2,1,false,0,3,2)
bpi.setFieldBaseInfo(localTable.COLLECTSEND_COLLECTOR_FIELD,"collector","chat.CollectSend.collector",4,3,1,false,"",9,9)
bpi.setMessageInfo(COLLECTSEND,"CollectSend","chat.CollectSend",{},{},{localTable.COLLECTSEND_SID_FIELD, localTable.COLLECTSEND_MSGID_FIELD, localTable.COLLECTSEND_COINS_FIELD, localTable.COLLECTSEND_COLLECTOR_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.COLLECTALLSEND_SID_FIELD,"sid","chat.CollectAllSend.sid",1,0,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.COLLECTALLSEND_MSGID_FIELD,"msgId","chat.CollectAllSend.msgId",2,1,3,false,{},9,9)
bpi.setFieldBaseInfo(localTable.COLLECTALLSEND_COINS_FIELD,"coins","chat.CollectAllSend.coins",3,2,3,false,{},3,2)
bpi.setMessageInfo(COLLECTALLSEND,"CollectAllSend","chat.CollectAllSend",{},{},{localTable.COLLECTALLSEND_SID_FIELD, localTable.COLLECTALLSEND_MSGID_FIELD, localTable.COLLECTALLSEND_COINS_FIELD},false,{})
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_MSGID_FIELD,"msgId","chat.MessageInfo.msgId",1,0,1,false,"",9,9)
bpi.setFieldEnumInfo(localTable.MESSAGEINFO_TYPE_FIELD,"type","chat.MessageInfo.type",2,1,1,false,nil,localTable.MESSAGETYPE,14,8)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_CONTENT_FIELD,"content","chat.MessageInfo.content",3,2,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_SENDUSER_FIELD,"sendUser","chat.MessageInfo.sendUser",4,3,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_SENDTIME_FIELD,"sendTime","chat.MessageInfo.sendTime",5,4,1,false,0,3,2)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_STATUS_FIELD,"status","chat.MessageInfo.status",6,5,1,false,0,5,1)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_EFFECTIME_FIELD,"effecTime","chat.MessageInfo.effecTime",7,6,1,false,0,3,2)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_EXTRA_FIELD,"extra","chat.MessageInfo.extra",8,7,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_COINS_FIELD,"coins","chat.MessageInfo.coins",9,8,1,false,0,3,2)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_NICKNAME_FIELD,"nickname","chat.MessageInfo.nickname",10,9,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_HEAD_FIELD,"head","chat.MessageInfo.head",11,10,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_FACEBOOKID_FIELD,"facebookId","chat.MessageInfo.facebookId",12,11,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_EXTENDDATA_FIELD,"extendData","chat.MessageInfo.extendData",13,12,1,false,"",9,9)
bpi.setFieldBaseInfo(localTable.MESSAGEINFO_FRAME_FIELD,"frame","chat.MessageInfo.frame",14,13,1,false,"",9,9)
bpi.setMessageInfo(MESSAGEINFO,"MessageInfo","chat.MessageInfo",{},{},{localTable.MESSAGEINFO_MSGID_FIELD, localTable.MESSAGEINFO_TYPE_FIELD, localTable.MESSAGEINFO_CONTENT_FIELD, localTable.MESSAGEINFO_SENDUSER_FIELD, localTable.MESSAGEINFO_SENDTIME_FIELD, localTable.MESSAGEINFO_STATUS_FIELD, localTable.MESSAGEINFO_EFFECTIME_FIELD, localTable.MESSAGEINFO_EXTRA_FIELD, localTable.MESSAGEINFO_COINS_FIELD, localTable.MESSAGEINFO_NICKNAME_FIELD, localTable.MESSAGEINFO_HEAD_FIELD, localTable.MESSAGEINFO_FACEBOOKID_FIELD, localTable.MESSAGEINFO_EXTENDDATA_FIELD, localTable.MESSAGEINFO_FRAME_FIELD},false,{})

AuthReceive = protobuf.Message(AUTHRECEIVE)
AuthSend = protobuf.Message(AUTHSEND)
CollectAllSend = protobuf.Message(COLLECTALLSEND)
CollectSend = protobuf.Message(COLLECTSEND)
HeartSend = protobuf.Message(HEARTSEND)
MessageInfo = protobuf.Message(MESSAGEINFO)
MessageSend = protobuf.Message(MESSAGESEND)
Notice = protobuf.Message(NOTICE)
SyncReceive = protobuf.Message(SYNCRECEIVE)
SyncSend = protobuf.Message(SYNCSEND)
