-- This file is generated by tdr. 

Ds_ResDataOperate = {} --数据操作类型
Ds_ResDataOperate.RESDATAOPERATE_INT = 1 --固定数值
Ds_ResDataOperate.RESDATAOPERATE_10K = 2 --万分比

Ds_ResDataSet = {} --数据操作类型
Ds_ResDataSet.RESDATASET_SET = 0 --数据覆盖
Ds_ResDataSet.RESDATASET_ADD = 1 --数据加法
Ds_ResDataSet.RESDATASET_SUB = 2 --数据减法

Ds_ATTRADDTYPE = {} --属性加成类型
Ds_ATTRADDTYPE.ATTRADD_BASE = 1 --基础属性
Ds_ATTRADDTYPE.ATTRADD_UPADD = 2 --加成属性(固定数值)
Ds_ATTRADDTYPE.ATTRADD_BASEMUL = 3 --基础属性乘法(万分比)
Ds_ATTRADDTYPE.ATTRADD_UPADDMUL = 4 --加成属性乘法(万分比)
Ds_ATTRADDTYPE.ATTRADD_ALLMUL = 5 --所有属性乘法(万分比)

Ds_ATTRDATATYPE = {} --属性数值类型
Ds_ATTRDATATYPE.ATTRDATA_HPMAX = 1 --当前最大生命值(固定值)
Ds_ATTRDATATYPE.ATTRHPDATA_HPCUR = 2 --当前生命值(固定值)
Ds_ATTRDATATYPE.ATTRHPDATA_HPLOSE = 3 --损失生命值(固定值)
Ds_ATTRDATATYPE.ATTRHPDATA_HPLOSEPRECENT = 4 --损失生命值万分比
Ds_ATTRDATATYPE.ATTRDATA_MMAX = 5 --当前最大法术值(固定值)
Ds_ATTRDATATYPE.ATTRHPDATA_MCUR = 6 --当前法术值(固定值)
Ds_ATTRDATATYPE.ATTRHPDATA_MLOSE = 7 --损失法术值(固定值)

Ds_BattleLegionType = {} --阵营类型
Ds_BattleLegionType.LEGION_HUM = 0 --狩猎者
Ds_BattleLegionType.LEGION_BOSS = 1 --怪兽

Ds_BattleClassType = {} --职业类型
Ds_BattleClassType.CLASSTYPE_ASSAULT = 0 --职业_突击兵
Ds_BattleClassType.CLASSTYPE_SCOUT = 1 --职业_侦查兵
Ds_BattleClassType.CLASSTYPE_SNIPER = 2 --职业_狙击兵
Ds_BattleClassType.CLASSTYPE_HOPLITE = 3 --职业_重甲兵
Ds_BattleClassType.CLASSTYPE_FIRETITAN = 4 --职业_火焰泰坦
Ds_BattleClassType.CLASSTYPE_LORDOFDEVILS = 5 --职业_魔窟领主
Ds_BattleClassType.CLASSTYPE_TROLL = 6 --职业_深渊巨魔

Ds_BattleTeamType = {} --队伍类型
Ds_BattleTeamType.WHITE = 0 --白方队伍
Ds_BattleTeamType.RED = 1 --红方队伍
Ds_BattleTeamType.BLUE = 2 --蓝方队伍
Ds_BattleTeamType.PURPLE = 3 --紫方队伍
Ds_BattleTeamType.GREEN = 4 --绿方队伍
Ds_BattleTeamType.PINK = 5 --粉方队伍
Ds_BattleTeamType.YELLOW = 6 --黄方队伍
Ds_BattleTeamType.TEAM_MAX = 7 --队伍数量

Ds_TeamLegionType = {} --阵营类型
Ds_TeamLegionType.LEGION_FRIEND = 0 --阵营友军
Ds_TeamLegionType.LEGION_ENEMY = 1 --阵营敌军
Ds_TeamLegionType.LEGION_ALLL = 2 --所有阵营单位

Ds_BattleActorType = {} --单位类型
Ds_BattleActorType.ACTORTYPE_SHOOTER = 0 --玩家操控角色
Ds_BattleActorType.ACTORTYPE_BOSS = 1 --玩家操控怪物
Ds_BattleActorType.ACTORTYPE_AISHOOTER = 2 --AI操控角色
Ds_BattleActorType.ACTORTYPE_AIBOSS = 3 --AI操控怪物
Ds_BattleActorType.ACTORTYPE_MONSTER = 4 --野怪
Ds_BattleActorType.ACTORTYPE_MAX = 5 --MAX

Ds_ItemPickType = {} --道具拾取类型
Ds_ItemPickType.PickType_ALL = 0 --所有人拾取
Ds_ItemPickType.PickType_SHOOTER = 1 --角色拾取
Ds_ItemPickType.PickType_BOSS = 2 --怪物拾取
Ds_ItemPickType.PickType_MAX = 3 --MAX

Ds_BattleActorSubType = {} --单位子类型
Ds_BattleActorSubType.SUBTYPE_NONE = 0 --无类型

Ds_BattleModeType = {} --战场模式类型
Ds_BattleModeType.BATTLEMODETYPE_TEAMMODE = 0 --团队竞技

Ds_BattleRusult = {} --战斗结果类型
Ds_BattleRusult.RESULT_NONE = 0 --无结果
Ds_BattleRusult.JUSTICE_WIN = 1 --正义胜利
Ds_BattleRusult.EVIL_WIN = 2 --邪恶胜利
Ds_BattleRusult.NO_WIN = 3 --平局

Ds_CharacterBodyType = {} --身体部位类型
Ds_CharacterBodyType.CHARACTERBODYTYPE_HEAD = 0 --身体部位_头部
Ds_CharacterBodyType.CHARACTERBODYTYPE_NECK = 1 --身体部位_脖子
Ds_CharacterBodyType.CHARACTERBODYTYPE_TORSO = 2 --身体部位_躯干
Ds_CharacterBodyType.CHARACTERBODYTYPE_STOMACH = 3 --身体部位_腹部
Ds_CharacterBodyType.CHARACTERBODYTYPE_LIMBS = 4 --身体部位_四肢
Ds_CharacterBodyType.CHARACTERBODYTYPE_MAX = 5 --身体部位最大值

Ds_GunShootMode = {} --枪支射击模式
Ds_GunShootMode.GUNSHOOTMODE_SINGLE = 0 --单发射击
Ds_GunShootMode.GUNSHOOTMODE_AUTO = 1 --全自动射击
Ds_GunShootMode.GUNSHOOTMODE_SA = 2 --单-全自动切换射击
Ds_GunShootMode.GUNSHOOTMODE_ST = 3 --单-三连发切换射击

Ds_GunAmmoType = {} --枪支弹药类型
Ds_GunAmmoType.GUNAMMOTYPE_COMMON = 0 --飞行普通子弹
Ds_GunAmmoType.GUNAMMOTYPE_AP = 1 --飞行穿甲子弹
Ds_GunAmmoType.GUNAMMOTYPE_BOLT = 2 --飞行弩箭
Ds_GunAmmoType.GUNAMMOTYPE_CANNONBALL = 3 --单-飞行爆破弹
Ds_GunAmmoType.GUNAMMOTYPE_HANDGRENADES = 4 --单-飞行爆破弹

Ds_ResCharacterAttrType = {} --角色属性类型
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN = 0 --角色属性最小值
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP = 1 --最大生命值
Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP = 2 --生命值(计算后)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP_LV = 3 --生命值成长
Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY = 4 --生命回复/5s
Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVER_LV = 5 --生命回复成长(/5s)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_INTERVAL = 6 --回血间隔
Ds_ResCharacterAttrType.EN_CHARACTERATTR_STOP_HURT_HP_RECOVERY_TIME = 7 --脱战回血时间
Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_TYPE = 8 --回血类型
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP = 9 --最大法术值
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP = 10 --法术值(计算后)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP_LV = 11 --法术值成长
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP_RECOVER = 12 --法术回复/5s
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP_RECOVER_LV = 13 --法术回复成长(/5s)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ATK = 14 --攻击力
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ATK_LV = 15 --攻击力成长
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD = 16 --最大护盾值
Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD = 17 --护盾值(计算后)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD_RECOVER = 18 --护盾回复/5s
Ds_ResCharacterAttrType.EN_CHARACTERATTR_CD_REDUCTION = 19 --冷却缩减(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORHEAD = 20 --护甲值_头部
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORNECK = 21 --护甲值_脖子
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORTORSO = 22 --护甲值_躯干
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORSTOMACH = 23 --护甲值_腹部
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORLIMBS = 24 --护甲值_四肢
Ds_ResCharacterAttrType.EN_CHARACTERATTR_WALK_MOVESPEED = 25 --站立走路速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_RUN_MOVESPEED = 26 --站立跑步速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_AIM_MOVESPEED = 27 --瞄准移动速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ROLL_ACCELERATION = 28 --战术翻滚速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_MOVESPEED = 29 --进入掩体的速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_ACCELERATION = 30 --进入掩体的加速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_MOVESPEED = 31 --倒地移动速度(万分比)
Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_HP = 32 --倒地血量
Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESURGENCE_HP = 33 --再起血量
Ds_ResCharacterAttrType.EN_CHARACTERATTR_SELFRESCUESPEED = 34 --自我援救速度
Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESCUESPEED = 35 --援救他人速度
Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX = 36 --角色属性最大值

Ds_DamageType = {} --伤害类型
Ds_DamageType.DAMAGETYPE_PHY = 0 --物理伤害
Ds_DamageType.DAMAGETYPE_BULLET = 1 --子弹贯穿伤害
Ds_DamageType.DAMAGETYPE_BLOOM = 2 --爆炸冲击伤害

Ds_ResWeaponAttrType = {} --武器属性类型
Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN = 0 --武器属性最小值
Ds_ResWeaponAttrType.EN_WEAPONATTR_NORMALDMG = 1 --武器普通伤害
Ds_ResWeaponAttrType.EN_WEAPONATTR_FIRERECOIL = 2 --武器后坐力
Ds_ResWeaponAttrType.EN_WEAPONATTR_AMMOPERCLIP = 3 --武器弹夹容量
Ds_ResWeaponAttrType.EN_WEAPONATTR_TARGETINGFOV = 4 --武器开镜倍数
Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENONCESHOTS = 5 --武器单发射速
Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENCONTINUESHOTS = 6 --武器连续射速
Ds_ResWeaponAttrType.EN_WEAPONATTR_AMMORELOADTIME = 7 --武器战术换弹时间
Ds_ResWeaponAttrType.EN_WEAPONATTR_NOAMMORELOADTIME = 8 --武器空仓换弹时间
Ds_ResWeaponAttrType.EN_WEAPONATTR_UNEQUIPTIME = 9 --武器收枪时间
Ds_ResWeaponAttrType.EN_WEAPONATTR_EQUIPTIME = 10 --武器掏枪时间
Ds_ResWeaponAttrType.EN_WEAPONATTR_AIMINGSTABILITY = 11 --武器瞄准稳定性
Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX = 12 --武器属性最大值

Ds_EquipBarType = {} --装备栏位类型
Ds_EquipBarType.EQUIPBARTYPE_NONE = 0 --装备栏位_无
Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 = 1 --装备栏位_武器1
Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 = 2 --装备栏位_武器2
Ds_EquipBarType.EQUIPBARTYPE_FIST = 3 --装备栏位_拳头
Ds_EquipBarType.EQUIPBARTYPE_THROW = 4 --装备栏位_投掷
Ds_EquipBarType.EQUIPBARTYPE_PROP = 5 --装备栏位_道具
Ds_EquipBarType.EQUIPBARTYPE_ARMOR = 6 --装备栏位_护甲
Ds_EquipBarType.EQUIPBARTYPE_HELMET = 7 --装备栏位_头盔
Ds_EquipBarType.EQUIPBARTYPE_DOWNSHIELD = 8 --装备栏位_击倒护盾
Ds_EquipBarType.EQUIPBARTYPE_BAG = 9 --装备栏位_背包
Ds_EquipBarType.EQUIPBARTYPE_MAX = 10 --装备栏位最大值

Ds_BattleWeaponType = {} --武器类型
Ds_BattleWeaponType.BATTLEWEAPONTYPE_NONE = 0 --武器无类型
Ds_BattleWeaponType.BATTLEWEAPONTYPE_NEAR = 1 --近战物理类武器
Ds_BattleWeaponType.BATTLEWEAPONTYPE_MAINGUN = 2 --远程射击类武器
Ds_BattleWeaponType.BATTLEWEAPONTYPE_SECONDGUN = 3 --副手类武器
Ds_BattleWeaponType.BATTLEWEAPONTYPE_THROW = 4 --投掷类武器
Ds_BattleWeaponType.BATTLEWEAPONTYPE_ARMOR = 5 --防具类武器
Ds_BattleWeaponType.BATTLEWEAPONTYPE_MAX = 6 --武器类型最大值

Ds_BattleWeaponSubType = {} --武器子类型
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_NONE = 0 --武器无子类型
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_HANDGUN = 2 --武器子类型_手枪
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_SHOTGUN = 3 --武器子类型_散弹枪
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_SUBMACHINEGUN = 4 --武器子类型_冲锋枪
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_RIFLE = 5 --武器子类型_步枪
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_AWP = 6 --武器子类型_狙击枪
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_THROW = 7 --武器子类型_投掷
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_BODY = 8 --武器子类型_防弹衣
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_HELMET = 9 --武器子类型_防弹头盔
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_BAG = 10 --武器子类型_背包
Ds_BattleWeaponSubType.BATTLEWEAPONSUBTYPE_MAX = 11 --武器子类型最大值

Ds_WeaponPartsBarType = {} --武器配件栏位类型
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_NONE = 0 --武器配件栏_无
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MUZZLE = 1 --武器配件栏_枪管
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_BOLT = 2 --武器配件栏_枪栓
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_CLIP = 3 --武器配件栏_弹夹
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_BUTT = 4 --武器配件栏_枪托
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MIRROR = 5 --武器配件栏_倍镜
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_SPEC = 6 --武器配件栏_特殊配件
Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MAX = 7 --武器栏位最大值

Ds_WeaponAnimationType = {} --武器动作类型
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE = 0 --武器动作_无
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_L = 1 --武器动作_左手装备
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_R = 2 --武器动作_右手装备
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_L = 3 --武器动作_左手收起
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_R = 4 --武器动作_右手收起
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPRELOAD = 5 --武器动作_换弹
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_FIRE = 6 --武器动作_开火
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_TARGETING = 7 --武器动作_瞄准
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_PULLBOLT = 8 --武器动作_拉栓
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPUP_L = 9 --蹲_武器动作_左手装备
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPUP_R = 10 --蹲_武器动作_右手装备
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPDOWN_L = 11 --蹲_武器动作_左手收起
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPDOWN_R = 12 --蹲_武器动作_右手收起
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPRELOAD = 13 --蹲_武器动作_换弹
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_FIRE = 14 --蹲_武器动作_开火
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_TARGETING = 15 --蹲_武器动作_瞄准
Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_PULLBOLT = 16 --蹲_武器动作_拉栓
Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_MAX = 17 --武器栏位最大值

Ds_BattleEquipEffectType = {} --武器装备效果类型
Ds_BattleEquipEffectType.BATTLEEQUIPEFFECTTYPE_ATTR = 1 --武器装备增加属性
Ds_BattleEquipEffectType.BATTLEEQUIPEFFECTTYPE_REATTR = 2 --武器装备回复属性
Ds_BattleEquipEffectType.BATTLEEQUIPEFFECTTYPE_BAGCAPACTIY = 3 --武器装备增加背包容量

Ds_WeaponPartEffectType = {} --装备配件效果类型
Ds_WeaponPartEffectType.WEAPONPARTEFFECTTYPE_ATTR = 1 --装备配件增加属性

Ds_ItemQualityType = {} --道具品质类型
Ds_ItemQualityType.ITEMQUALITYTYPE_WHITE = 0 --道具品质_白
Ds_ItemQualityType.ITEMQUALITYTYPE_GREEN = 1 --道具品质_绿
Ds_ItemQualityType.ITEMQUALITYTYPE_BLUE = 2 --道具品质_蓝
Ds_ItemQualityType.ITEMQUALITYTYPE_PURPLE = 3 --道具品质_紫
Ds_ItemQualityType.ITEMQUALITYTYPE_ORANGE = 4 --道具品质_橙

Ds_BattleItemsType = {} --道具类型
Ds_BattleItemsType.BATTLEITEMTYPE_NONE = 0 --道具无类型
Ds_BattleItemsType.BATTLEITEMTYPE_WEAPON = 1 --武器类道具
Ds_BattleItemsType.BATTLEITEMTYPE_BULLET = 2 --子弹类道具
Ds_BattleItemsType.BATTLEITEMTYPE_THROW = 3 --投掷类道具
Ds_BattleItemsType.BATTLEITEMTYPE_ARMOR = 4 --防具类道具
Ds_BattleItemsType.BATTLEITEMTYPE_WEPONPARTS = 5 --武器配件类道具
Ds_BattleItemsType.BATTLEITEMTYPE_MEDICAL = 6 --医疗类道具
Ds_BattleItemsType.BATTLEITEMTYPE_ENERGY = 7 --能量类道具
Ds_BattleItemsType.BATTLEITEMTYPE_BAG = 8 --背包类道具
Ds_BattleItemsType.BATTLEITEMTYPE_BOX = 9 --盒子类道具
Ds_BattleItemsType.BATTLEITEMTYPE_AVATAR = 10 --人物外观类道具
Ds_BattleItemsType.BATTLEITEMTYPE_DEATHCARD = 11 --死亡牌道具
Ds_BattleItemsType.BATTLEITEMTYPE_MAX = 12 --道具类型最大值

Ds_ItemUseType = {} --道具使用类型
Ds_ItemUseType.ITEMUSETYPE_NONE = 0 --道具不可使用
Ds_ItemUseType.ITEMUSETYPE_MANUAL = 1 --道具点击使用
Ds_ItemUseType.ITEMUSETYPE_AUTO = 2 --道具自动使用

Ds_BattleItemEffectType = {} --道具效果类型
Ds_BattleItemEffectType.BATTLEITEMEFFECTTYPE_REHP = 1 --道具触发恢复生命
Ds_BattleItemEffectType.BATTLEITEMEFFECTTYPE_SHIELD = 2 --道具触发恢复护盾值

Ds_BattleDropItemsType = {} --掉落道具类型
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_NONE = 0 --掉落无类型
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_WEAPON = 1 --掉落武器类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_BULLET = 2 --掉落子弹类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_THROW = 3 --掉落投掷类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_ARMOR = 4 --掉落防具类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_WEPONPARTS = 5 --掉落武器配件类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_MEDICAL = 6 --掉落医疗类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_ENERGY = 7 --掉落能量类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_BAG = 8 --掉落背包类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_BOX = 9 --盒子类道具
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_AVATAR = 10 --掉落人物外观类
Ds_BattleDropItemsType.BATTLEDROPITEMTYPE_MAX = 11 --掉落类型最大值

Ds_SkillType = {} --技能类型
Ds_SkillType.SKILLTYPE_NORMAL = 1 --普通攻击
Ds_SkillType.SKILLTYPE_AUTO = 2 --主动技能
Ds_SkillType.SKILLTYPE_AUTO2 = 3 --主动二段技能
Ds_SkillType.SKILLTYPE_AUTO3 = 4 --主动三段技能
Ds_SkillType.SKILLTYPE_SWITCH = 5 --主动开关技能(一个需设置技能栏一个无)
Ds_SkillType.SKILLTYPE_PASSIVE = 6 --被动技能

Ds_SkillSubType = {} --技能子类型
Ds_SkillSubType.SKILLSUBTYPE_NORMALATTACK = 1 --普通技能
Ds_SkillSubType.SKILLSUBTYPE_ATTACK = 2 --攻击技能
Ds_SkillSubType.SKILLSUBTYPE_SUBBUFF = 3 --辅助BUFF技能
Ds_SkillSubType.SKILLSUBTYPE_AVATAR = 4 --变体技能
Ds_SkillSubType.SKILLSUBTYPE_ENERGY = 5 --充能技能

Ds_SkillBarType = {} --技能栏位类型
Ds_SkillBarType.SKILLBARTYPE_NONE = 0 --技能栏无
Ds_SkillBarType.SKILLBARTYPE_Q = 1 --技能栏Q
Ds_SkillBarType.SKILLBARTYPE_W = 2 --技能栏W
Ds_SkillBarType.SKILLBARTYPE_E = 3 --技能栏E
Ds_SkillBarType.SKILLBARTYPE_R = 4 --技能栏R
Ds_SkillBarType.SKILLBARTYPE_A = 5 --技能栏A1
Ds_SkillBarType.SKILLBARTYPE_MAX = 6 --技能栏最大值

Ds_SkillTrigCastType = {} --技能触发释放类型
Ds_SkillTrigCastType.SKILLTRIGTYPE_AUTOCAST = 0 --主动释放触发
Ds_SkillTrigCastType.SKILLTRIGTYPE_TALENT = 1 --技能天赋触发

Ds_SkillTargetType = {} --技能作用对象类型
Ds_SkillTargetType.SKILL_TARGETTYPE_ALL = 0 --所有单位
Ds_SkillTargetType.SKILL_TARGETTYPE_SELF = 1 --自身
Ds_SkillTargetType.SKILL_TARGETTYPE_ALLENEMY = 2 --所有敌方
Ds_SkillTargetType.SKILL_TARGETTYPE_ALLSELF = 3 --所有己方
Ds_SkillTargetType.SKILL_TARGETTYPE_ALLMONSTER = 4 --所有野怪

Ds_SkillDistanceType = {} --技能距离类型
Ds_SkillDistanceType.SKILLDISTANCETYPE_NEARA = 0 --近战技能
Ds_SkillDistanceType.SKILLDISTANCETYPE_FAR = 1 --远程技能

Ds_SkillAtkActorType = {} --技能攻击单位类型
Ds_SkillAtkActorType.SKILLATKACTORTYPE_GROUND = 0 --攻击地面单位
Ds_SkillAtkActorType.SKILLATKACTORTYPE_AIR = 1 --攻击空中单位
Ds_SkillAtkActorType.SKILLATKACTORTYPE_AIRANDGROUND = 2 --攻击空地单位

Ds_SkillPassiveBreakType = {} --技能被动打断类型(向下包含)
Ds_SkillPassiveBreakType.SKILLPASSIVEBREAKTYPE_ALL = 1 --任意打断(1.受攻击)
Ds_SkillPassiveBreakType.SKILLPASSIVEBREAKTYPE_SOFTBUFF = 2 --软控Buff打断
Ds_SkillPassiveBreakType.SKILLPASSIVEBREAKTYPE_DEBUFF = 3 --硬控Buff打断
Ds_SkillPassiveBreakType.SKILLPASSIVEBREAKTYPE_DEAD = 4 --死亡打断
Ds_SkillPassiveBreakType.SKILLPASSIVEBREAKTYPE_GOD = 5 --上帝模式，能够打断所有(程序保护用)

Ds_SkillCooldownType = {} --技能冷却类型
Ds_SkillCooldownType.SKILLCOOLDOWNTYPE_NONE = 0 --无冷却
Ds_SkillCooldownType.SKILLCOOLDOWNTYPE_TIME = 1 --时间冷却

Ds_SkillCDStartType = {} --技能CD启动类型
Ds_SkillCDStartType.SKILLCDSTARTTYPE_CASTSKILL = 0 --释放技能启动
Ds_SkillCDStartType.SKILLCDSTARTTYPE_SKILLROLLEND = 1 --技能前摇结束启动
Ds_SkillCDStartType.SKILLCDSTARTTYPE_SKILATKEND = 2 --技能后摇结束启动

Ds_SkillCostType = {} --技能消耗类型
Ds_SkillCostType.SKILLCOSTYPE_NONE = 0 --无消耗
Ds_SkillCostType.SKILLCOSTYPE_MP = 1 --法术值消耗

Ds_SkillPointType = {} --技能指向类型
Ds_SkillPointType.SKILLPOINTTYPE_SLFE = 0 --自身
Ds_SkillPointType.SKILLPOINTTYPE_SLFEPOS = 1 --自身位置
Ds_SkillPointType.SKILLPOINTTYPE_TARGET = 2 --选择目标
Ds_SkillPointType.SKILLPOINTTYPE_DIRECTION = 3 --选择朝向
Ds_SkillPointType.SKILLPOINTTYPE_AREA = 4 --选择区域

Ds_SkillPointAreaType = {} --技能指向区域类型
Ds_SkillPointAreaType.SKILLPOINTAREA_NONE = 0 --无区域
Ds_SkillPointAreaType.ASKILLPOINTAREA_RECTANGLE = 1 --矩形
Ds_SkillPointAreaType.SKILLPOINTAREA_CIRCLE = 2 --圆形
Ds_SkillPointAreaType.SKILLPOINTAREA_CIRCULAR = 3 --扇形

Ds_SkillAttkRollBuffType = {} --技能前摇效果类型
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_NONE = 0 --前摇效果_无
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_MOVE = 1 --前摇效果_移动
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_SWIM = 2 --前摇效果_眩晕
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_SILENT = 3 --前摇效果_沉默
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_SNEER = 4 --前摇效果_嘲讽
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_PASSIVEMOVE = 5 --前摇效果_被动位移
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_PHYIMM = 6 --前摇效果_物理免疫
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_MGCIMM = 7 --前摇效果_魔法免疫
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_GOD = 8 --前摇效果_无敌
Ds_SkillAttkRollBuffType.SKILLATKROLLBUFFTYPE_TYPEMAX = 9 --前摇效果_Max

Ds_SkillCtrCastType = {} --技能受控制释放类型
Ds_SkillCtrCastType.SKILLCTRCASTTYPE_AIATKROLLCAST = 0 --有前摇通过AI释放
Ds_SkillCtrCastType.SKILLCTRCASTTYPE_AINOTATKCASTCAST = 1 --无前摇通过AI释放
Ds_SkillCtrCastType.SKILLCTRCASTTYPE_DIRECT = 2 --无前摇不通过AI受控制释放
Ds_SkillCtrCastType.SKILLCTRCASTTYPE_GOD = 3 --上帝释放(不通过AI,任何状态可放，无前摇)
Ds_SkillCtrCastType.SKILLCTRCASTTYPE_PASSIVECAST = 4 --被动技能直接释放

Ds_BuffPropertyType = {} --BUFF属性类型
Ds_BuffPropertyType.BUFFPROPERTYTYPE_TALENT = 1 --天赋BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_SYSTEM = 2 --系统BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_USEFUL = 3 --数值增益BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_UNUSEFUL = 4 --数值减益BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_HARMFUL = 5 --控制BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_UNHARMFUL = 6 --免疫控制BUFF
Ds_BuffPropertyType.BUFFPROPERTYTYPE_GODBUFF = 7 --上帝BUFF

Ds_BuffPropertySubType = {} --BUFF属性子类型
Ds_BuffPropertySubType.BUFFPROPERTYSUBTYPE_SWIM = 1 --眩晕类子类型
Ds_BuffPropertySubType.BUFFPROPERTYSUBTYPE_DELSPEED = 2 --减速类子类型

Ds_BuffMergeType = {} --BUFF叠加规则
Ds_BuffMergeType.BUFFERMERGRES_NONE = 0 --无法合并
Ds_BuffMergeType.BUFFERMERGRES_CASTERSTACK = 1 --BUFF堆叠(施法者)
Ds_BuffMergeType.BUFFERMERGRES_GROUPSTACK = 2 --BUFF堆叠(组ID)
Ds_BuffMergeType.BUFFERMERGRES_CASTERREPLACE = 3 --替换旧的BUFF（同一施法者，高等级替换低等级，同等级刷数据）
Ds_BuffMergeType.BUFFERMERGRES_CASTERMUTEX = 4 --新Buff被排斥(施法者)
Ds_BuffMergeType.BUFFERMERGRES_GROUPIDMUTEX = 5 --新Buff被排斥(组ID)
Ds_BuffMergeType.BUFFERMERGRES_GROUPIDREPLACE = 6 --替换旧的BUFF（只按组ID）
Ds_BuffMergeType.BUFFERMERGRES_UNCASTERREPLACE = 7 --不同施法者并行BUFF,同一施法者替换旧的BUFF,不同施法者无法合并但是生效

Ds_BuffOp = {} --BUFF操作类型
Ds_BuffOp.BUFF_OP_ADD = 1 --添加buff操作
Ds_BuffOp.BUFF_OP_DEL = 2 --移除buff操作
Ds_BuffOp.BUFF_OP_OVERLAY = 3 --覆盖buff操作
Ds_BuffOp.BUFF_OP_INTERRUPT = 4 --中断buff操作

Ds_BuffRemoveType = {} --BUFF外部移除类型
Ds_BuffRemoveType.BUFFREMOVETYPE_DEFUALT = 0 --任意移除Buff
Ds_BuffRemoveType.BUFFREMOVETYPE_DEAD = 1 --死亡移除Buff
Ds_BuffRemoveType.BUFFREMOVETYPE_GOD = 2 --上帝移除Buff

Ds_BuffEndType = {} --BUFF结束类型
Ds_BuffEndType.BUFFENDTYPE_ENC = 0 --Buff自然结束
Ds_BuffEndType.BUFFENDTYPE_BECLEAR = 1 --Buff被动清除
Ds_BuffEndType.BUFFENDTYPE_DEADCLEAR = 2 --Buff死亡清除

Ds_BuffEffectType = {} --Buff效果类型
Ds_BuffEffectType.BUFFEFFECTTYPE_ATTROPE = 1 --属性修改
Ds_BuffEffectType.BUFFEFFECTTYPE_SETATTR = 2 --回属性
Ds_BuffEffectType.BUFFEFFECTTYPE_DMGABSORB = 4 --吸收伤害
Ds_BuffEffectType.BUFFEFFECTTYPE_SWIM = 5 --眩晕
Ds_BuffEffectType.BUFFEFFECTTYPE_PHYIMM = 6 --物理免疫
Ds_BuffEffectType.BUFFEFFECTTYPE_MGCIMM = 7 --魔法免疫
Ds_BuffEffectType.BUFFEFFECTTYPE_GOD = 8 --无敌
Ds_BuffEffectType.BUFFEFFECTTYPE_DELBUFF = 9 --清除BUFF
Ds_BuffEffectType.BUFFEFFECTTYPE_IMMDELBUFF = 10 --免疫DEBUFF
Ds_BuffEffectType.BUFFEFFECTTYPE_SUPERBODY = 11 --霸体BUFF
Ds_BuffEffectType.BUFFEFFECTTYPE_MAX = 12 --Buff效果最大值

Ds_BuffEftSetAttrType = {} --BUFF回属性参数
Ds_BuffEftSetAttrType.BUFFSETATTRPARAM_HP = 1 --回属性HP

Ds_BuffEffectTrigType = {} --BUFF效果生效条件
Ds_BuffEffectTrigType.BUFFTRIGTYPE_TIME = 0 --BUFF效果时间周期生效
Ds_BuffEffectTrigType.BUFFTRIGTYPE_DEAD = 1 --死亡生效

Ds_LanguageDefine = {} --语言类型
Ds_LanguageDefine.NONE = 0 --无
Ds_LanguageDefine.SIM_CHINESE = 1 --简体中文
Ds_LanguageDefine.FON_CHINESE = 2 --繁体中文
Ds_LanguageDefine.ENGLISH = 3 --英文

Ds_UIMsgDefine = {} --UI事件消息
Ds_UIMsgDefine.UI_COMMON_ERRORCODE = 1 --错误码消息(i)
Ds_UIMsgDefine.UI_BATTLE_LEVEL_START = 101 --战斗_战斗开始
Ds_UIMsgDefine.UI_BATTLE_LEVEL_END = 102 --战斗_战斗结束
Ds_UIMsgDefine.UI_BATTLE_LEVEL_MATCHDATACHANGE = 103 --战斗_比赛数据改变
Ds_UIMsgDefine.UI_BATTLE_LEVEL_KILLDOWNMSG = 104 --战斗_击杀或击倒
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_ATTRDATACHAGNE = 200 --战斗_角色属性数据改变
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE = 201 --战斗_角色装备数据改变
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_BAGDATACHANGE = 202 --战斗_角色背包数据改变
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_USEITEM_NOTITY = 203 --战斗_角色使用道具开始通知
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_INTERRUPTUSEITEM_NOTITY = 204 --战斗_角色使用道具结束通知
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_STATUSCHAGNE = 205 --战斗_角色生死状态改变
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_BEATTACKNOTIFY = 206 --战斗_角色收到伤害通知
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_COVERSTATENOTIFY = 207 --战斗_掩体状态通知
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_RESPAWN = 208 --战斗_角色复活消息
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_LEAVECOVER = 209 --战斗_角色离开掩体
Ds_UIMsgDefine.UI_BATTLE_CHARACTER_AIMINGCHANGE = 210 --战斗_瞄准状态改变
Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET = 600 --系统_网络连接返回
Ds_UIMsgDefine.UI_SYSTEM_LOGIN_RET = 601 --系统_登录返回
Ds_UIMsgDefine.UI_SYSTEM_CREATEROLE_RET = 602 --系统_创建角色返回
Ds_UIMsgDefine.UI_SYSTEM_ENTERROOM_NOTIFY = 650 --系统_进入房间通知
Ds_UIMsgDefine.UI_SYSTEM_STARTMATCH_NOTIFY = 651 --系统_开始匹配通知
Ds_UIMsgDefine.UI_SYSTEM_ROOMINFO_NOTIFY = 652 --系统_房间信息变化通知
Ds_UIMsgDefine.UI_SYSTEM_CUSTEM_ROOM_DATA = 653 --自定义房间变化
Ds_UIMsgDefine.UI_SYSTEM_FETCH_CUSTEM_DATA = 654 --拉房间列表
Ds_UIMsgDefine.UI_SYSTEM_KICK_CUSTEM_DATA = 655 --踢出房间
Ds_UIMsgDefine.UI_SYSTEM_GAME_COUNT_DOWN = 656 --倒计时
Ds_UIMsgDefine.UI_SYSTEM_GAME_RESULT = 657 --游戏结束通知
Ds_UIMsgDefine.UI_SYSTEM_BEGIN_MATCH = 658 --匹配_开始匹配
Ds_UIMsgDefine.UI_SYSTEM_CHOOSE_HERO = 659 --匹配_开始选择英雄
Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_NOTIFY = 660 --匹配_准备通知
Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_RSP = 661 --匹配_准备完成
Ds_UIMsgDefine.UI_SYSTEM_MATCH_SELECT_CLASS = 662 --匹配_选择职业
Ds_UIMsgDefine.UI_SYSTEM_MATCH_CANCEL = 663 --匹配_匹配取消
Ds_UIMsgDefine.UI_SYSTEM_CREATE_TEAM = 664 --匹配_创建队伍
Ds_UIMsgDefine.UI_SYSTEM_MATCH_ENTER_TEAM = 665 --匹配_进入队伍
Ds_UIMsgDefine.UI_SYSTEM_MATCH_QUIT_TEAM = 666 --匹配_离开队伍
Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_ROOM_TEAM = 667 --匹配_同步房间信息
Ds_UIMsgDefine.UI_SYSTEM_MATCH_INVITE_PLAYER = 668 --匹配_邀请玩家
Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_TEAMLEADER = 669 --匹配_同步房主信息
Ds_UIMsgDefine.UI_SYSTEM_ENTER_MATCH_BATTLETYPE = 670 --匹配_进入匹配界面
Ds_UIMsgDefine.UI_SYSTEM_QUIT_MATCH_BATTLETYPE = 671 --匹配_退出匹配界面
Ds_UIMsgDefine.UI_S2C_FETCH_MUTI_FRIENDINFO = 700 --好友_拉取好友数据
Ds_UIMsgDefine.UI_S2C_FETCH_NEW_FRIENDINFO = 701 --好友_查找新朋友

Ds_BattleVsMode = {} --战斗模式
Ds_BattleVsMode.BATTLEVSMODE_MATCH = 1 --战斗模式_匹配
Ds_BattleVsMode.BATTLEVSMODE_CUSTOM = 2 --战斗模式_自定义

Ds_BasicState = {} --玩家基础状态
Ds_BasicState.BASICSTATE_LOBBY = 0 --大厅中
Ds_BasicState.BASICSTATE_QUEUE = 1 --组队中
Ds_BasicState.BASICSTATE_ROOM = 2 --选人中
Ds_BasicState.BASICSTATE_BATTLE = 3 --游戏中
Ds_BasicState.BASICSTATE_BATTLE_AWARD = 4 --游戏结算中
