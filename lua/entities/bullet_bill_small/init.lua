AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )


local Jump_sound = Sound("Small_Bill.Defeated")
local Hurt_sound = Sound("Bill.Damage")
local fly_sound = Sound("fly.small")
local fly_ramp = Sound("fly.ramp")

util.PrecacheModel("models/weapons/w_models/w_rocket.mdl")
local HitMax = 6 //the amount of times we can collide with a player or prop before exploding

/*---------------------------------------------------------
   Initialize
---------------------------------------------------------*/
function ENT:Initialize()

        self.Entity:SetModel("models/weapons/w_models/w_rocket.mdl")
        self.Entity:PhysicsInit( SOLID_VPHYSICS )
        self.Entity:SetMoveType(  MOVETYPE_VPHYSICS )   
        self.Entity:SetSolid( SOLID_VPHYSICS )
        self.Entity:SetModelScale( self.Entity:GetModelScale()*.25,0)
        self.Entity:Activate()
        self.Entity:SetLagCompensated(true)
        self.Entity:SetHealth(80)
        
        // Wake the physics object up. Its time to have fun!
        local phys = self.Entity:GetPhysicsObject()
        if phys:IsValid() then 
                phys:Wake()
                phys:SetMass(999999)
                //phys:SetDamping( .0001, .0001 )
                phys:EnableGravity( false )
        end

        // Make it face the right way
        self.Entity:SetAngles(self.FlyAngle)

        // set hit counter to 0
        self.HitCount = 0
        //self.Entity:EmitSound("fly.ramp")
        self.Sound = CreateSound( self.Entity, fly_sound )
        self.Sound:SetSoundLevel( 65 )
        self.Sound:Play()

        self:StartMotionController()
        
end

/*---------------------------------------------------------
   Initialize II
---------------------------------------------------------*/
function ENT:OnRemove()

        if ( self.Sound ) then
                self.Sound:Stop()
        end

end

function ENT:Think()

        if self.Dead then
                self:Explode()
        end

        return true

end

/*---------------------------------------------------------
   Explode
---------------------------------------------------------*/
function ENT:Explode()

        if ( self.Exploded ) then return end

        self.Exploded = true

        local explosion = ents.Create( "env_explosion" )
		explosion:SetKeyValue( "spawnflags", 144 )
		explosion:SetKeyValue( "iMagnitude", 30 )
		explosion:SetKeyValue( "iRadiusOverride", 200 )
		explosion:SetPos(self:GetPos()) // Placing the explosion where we are
		explosion:Spawn( ) // Spawning it
		explosion:Fire("explode","",0)
		self.Entity:Remove()

        self.Entity:Remove()

end

/*---------------------------------------------------------
   PhysicsCollide
---------------------------------------------------------*/
function ENT:PhysicsSimulate( phys, deltatime )

        if self.Dead then return SIM_NOTHING end

        local fSin = math.sin( CurTime() * 20 ) * 1.1
        local fCos = math.cos( CurTime() * 20 ) * 1.1

        local vAngular = Vector(0,0,0)
        local vLinear = (self.FlyAngle:Right() * fSin) + (self.FlyAngle:Up() * fCos)
        vLinear = vLinear * deltatime * 1.001

        return vAngular, vLinear, SIM_GLOBAL_FORCE

end

/*---------------------------------------------------------
   PhysicsCollide
---------------------------------------------------------*/
function ENT:PhysicsCollide( data, physobj )

        if self.Exploded then return end

        //print(data.Speed)
        //print(data.OurOldVelocity:Length())
        
        if data.HitEntity:IsWorld() then
                self.Dead = true
        end

        if self.HitCount >= HitMax then 
                self.Dead = true
        end

        //keep going when hit player or prop (up to hitamount)        
        local ang = data.OurOldVelocity:GetNormal()
        ang = ang:Angle()
        self.Entity:SetAngles(ang) 
        self.Entity:GetPhysicsObject():SetVelocity(data.OurOldVelocity:GetNormal() * data.OurOldVelocity:Length())
        
        if( data.HitEntity && data.HitEntity:IsPlayer() ) then
            local ply = data.HitEntity
            //print("I collided with a player named: " .. ply:Nick() .. "!\n")
            local ColVector =  data.HitPos - physobj:GetPos()

            //print("The collision vector is: " .. ColVector.x .. "," .. ColVector.y .. "," .. ColVector.z .. "\n")
            //print("They player is moving : " .. ply:GetVelocity().z .. " in the z direction!\n")

            if (ColVector.z > 10 && ply:GetVelocity().z <0) then
                //print("Player is on top of the collision\n")
                pushvel = Vector(0,0,500)
                self.Entity:EmitSound("Small_Bill.Defeated")
                self.Exploded = true
                self.Entity:Remove()

                if ( self.Sound ) then
                        self.Sound:Stop()
                end

                local health = ply:Health()
                ply:SetHealth(health+10)
            else
                //print("I pushed back a player named: " .. ply:Nick() .. "!\n")
                local hitang = ColVector:GetNormalized()
                pushvel = hitang * 100
                pushvel.z = math.max(pushvel.z, 50)
                ply:TakeDamage(5,self.Creator, self.Entity)
                if(self.Entity:IsOnFire()) then ply:Ignite(5) end
                self.Sound:SetSoundLevel( 20 )
                self.Entity:EmitSound("Bill.Damage")
                self.Sound:SetSoundLevel( 40 )
            end

            ply:SetGroundEntity(nil)
            ply:SetVelocity(ply:GetVelocity() + pushvel)
            ply.was_pushed = {att=owner, t=CurTime(), wep=self:GetClass()}
        end

        self.HitCount = self.HitCount + 1
        self.Entity:NextThink(CurTime())
end

function ENT:OnTakeDamage(dmginfo)
     
        self:SetHealth(self:Health() - dmginfo:GetDamage())
  
  
        if self:Health() < 0 then
           self.Dead = true
        end
        
end