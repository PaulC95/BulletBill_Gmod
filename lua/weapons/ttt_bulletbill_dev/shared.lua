SWEP.Gun 					= ("ttt_bulletbill")
SWEP.Category				= "Bullet Bill Launcher"
SWEP.Author					= "Paul"
SWEP.Contact				= "https://steamcommunity.com/id/PaulGC/"
SWEP.Purpose				= ""
SWEP.Instructions			= ""
SWEP.PrintName				= "Bullet Bill DEV"
SWEP.Slot					= 7
SWEP.SlotPos				= 7
SWEP.DrawAmmo				= false
SWEP.DrawWeaponInfoBox		= false
SWEP.BounceWeaponIcon   	= false
SWEP.DrawCrosshair			= false
SWEP.Weight					= 40
SWEP.AutoSwitchTo			= true
SWEP.AutoSwitchFrom			= true
SWEP.HoldType 				= "rpg"

SWEP.ViewModelFOV			= 70
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_models/c_bblauncher.mdl"
SWEP.WorldModel				= "models/weapons/w_models/bblauncher.mdl"

SWEP.ShowWorldModel			= true
SWEP.Spawnable				= true
SWEP.AdminOnly				= false
SWEP.FiresUnderwater 		= false

SWEP.Base 					= "weapon_tttbase"
SWEP.Kind 					= WEAPON_EQUIP2
SWEP.AllowDrop 				= true
SWEP.IsSilent 				= false
SWEP.NoSights 				= true
SWEP.AutoSpawnable 			= false


SWEP.EquipMenuData = {
      type="Weapon",
      name="Bullet Bill DEV",
      desc="Left click - Smaller faster Bullet Bill. \nRight click - Bigger slower Bullet Bill with tracking!\nYou can fire 4 small shots OR 1 big one.\nSo choose wisely before you shoot!"
   };

SWEP.Icon = "vgui/ttt/bulletbillicon.png"


SWEP.Primary.Sound				= Sound( "Weapon_Bill_Launcher.Single" )
SWEP.Primary.RPM				= 2000
SWEP.Primary.ClipSize			= 4			-- Change those 3 Variables to whatever you like
SWEP.Primary.DefaultClip		= 4				-- if you want to shoot more than 1 rocket!
SWEP.Primary.KickUp				= 0.25
SWEP.Primary.KickDown			= 0.16
SWEP.Primary.KickHorizontal		= 0.16
SWEP.Primary.Automatic			= true
SWEP.Primary.Delay				= .1
SWEP.Primary.Ammo				= "RPG_Round"
SWEP.Primary.NumShots			= 1
SWEP.Primary.Recoil				= 0.25
SWEP.Primary.Cone				= 0.0125


SWEP.ReloadTime 				= .1
SWEP.SelectiveFire		= true
SWEP.CanBeSilenced		= false
SWEP.LimitedStock               = true

//SWEP.Secondary.IronFOV			= 65

SWEP.data 				= {}
SWEP.data.ironsights			= 1

SWEP.Primary.Damage		= 60
SWEP.Primary.Spread		= .05
SWEP.Primary.IronAccuracy = .01




SWEP.IronSightsPos = Vector(-7.55, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(0, 0, 0)
SWEP.SightsAng = Vector(0, 0, 0)
SWEP.RunSightsPos = Vector(0, 0, 0)
SWEP.RunSightsAng = Vector(0, 0, 0)
tracking = false
Defeated =false
Avoid = true

---------------------------------------------------------
---------------------------------------------------------

function SWEP:PrimaryAttack()

        local tr = util.TraceLine( {
                start = self.Owner:GetShootPos(),
                endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 150,
                filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
        } )
        self.Weapon:SetSkin(1)
        self.Weapon:SetNextPrimaryFire( CurTime() + 0.2 )

        if(tr.Fraction < 1) then return end
        if not self:CanPrimaryAttack() then return end
        if ( self.Weapon:Clip1() < 0 ) then return end
        self.Weapon:EmitSound("Weapon_Bill_Launcher.Single")
        self.Weapon:SetNextPrimaryFire(CurTime() + 1)
        self.Weapon:SetNextSecondaryFire(CurTime() + 1)
        self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
        //self.Weapon:TakePrimaryAmmo(1)

        if ( SERVER ) then


                bill = ents.Create( "bullet_bill_small" )                        
                bill:SetPos( self.Owner:GetShootPos() + (self.Owner:GetAimVector()*60))
                bill.Creator = self.Owner
                bill.FlyAngle = self.Owner:GetAimVector():Angle()
                bill:Spawn()
                bill.Speed = 350
                //bill.Tracking = tracking
                bill.Avoidance = false
                local phys = bill:GetPhysicsObject()
                if (phys:IsValid()) then
                        phys:SetVelocity( self.Owner:GetAimVector() * bill.Speed)
                end
                
                
                
                
        end


end

function SWEP:Think()
	if self.Weapon:Clip1() > 0 then
		self.Weapon:SendWeaponAnim(ACT_VM_IDLE_DEPLOYED)
        end

        
end

function SWEP:SecondaryAttack()

        if not self:CanPrimaryAttack() then return end

        
        local tr = util.TraceLine( {
                start = self.Owner:GetShootPos(),
                endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 150,
                filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
        } )
        self.Weapon:SetNextPrimaryFire( CurTime() + 0.2 )

        if(tr.Fraction < 1) then return end
        if not self:CanPrimaryAttack() then return end
        if ( self.Weapon:Clip1() < 4 ) then print("not enough ammo")return end
        self.Weapon:EmitSound("Weapon_Bill_Launcher.Single")
        self.Weapon:SetNextPrimaryFire(CurTime() + 1)
        self.Weapon:SetNextSecondaryFire(CurTime() + 1)
        self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
        //self.Weapon:TakePrimaryAmmo(4)
        if ( SERVER ) then


                local bill = ents.Create( "bullet_bill_big_dev" )                        
                bill:SetPos( self.Owner:GetShootPos() + (self.Owner:GetAimVector()*60))
                bill.Creator = self.Owner
                bill.FlyAngle = self.Owner:GetAimVector():Angle()
                bill:Spawn()
                bill.Speed = 150
                local phys = bill:GetPhysicsObject()
                if (phys:IsValid()) then
                        phys:SetVelocity( self.Owner:GetAimVector() * bill.Speed)
                end
                
                
                
                
        end

        
end

