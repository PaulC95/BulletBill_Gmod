AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )


local Burn_Sound = Sound("Fire.Plasma")
local Jump_sound = Sound("Small_Bill.Defeated")
local Hurt_sound = Sound("Bill.Damage")
local fly_sound = Sound("fly.big")
local fly_ramp = Sound("fly.ramp")
util.PrecacheModel("models/weapons/w_models/w_rocket.mdl")
local HitMax = 10 //the amount of times we can collide with a player or prop before exploding
nexttargetcheck = CurTime() + 1

/*---------------------------------------------------------
   Initialize
---------------------------------------------------------*/
function ENT:Initialize()

        self.Entity:SetModel("models/weapons/w_models/w_rocket.mdl")
        self.Entity:SetModelScale( self.Entity:GetModelScale()*1,0)
        self.Entity:PhysicsInit( SOLID_VPHYSICS )
        self.Entity:SetMoveType(  MOVETYPE_VPHYSICS )   
        self.Entity:SetSolid( SOLID_VPHYSICS )
        self.Entity:SetLagCompensated(true)
        self.Entity:SetHealth(1000)
        
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
        self.Target = NULL
        self.Entity:EmitSound("loop_low")

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

        //print("my health is:" .. self:Health() .. "\n" )
        if self.Dead then self:Explode() return end
       
        if self.Exploded then return end

        self:Track()

        self:NextThink(CurTime())

return true end

/*---------------------------------------------------------
   Explode
---------------------------------------------------------*/
function ENT:Explode()

        if ( self.Exploded ) then return end

        self.Exploded = true

        local explosion = ents.Create( "env_explosion" )
		explosion:SetKeyValue( "spawnflags", 144 )
		explosion:SetKeyValue( "iMagnitude", 60 )
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

        if self.Exploded then return SIM_NOTHING end

        local fSin = math.sin( CurTime() * 20 ) * 1.1
        local fCos = math.cos( CurTime() * 20 ) * 1.1

        local vAngular = Vector(0,0,0)
        local vLinear = (self.Entity:GetForward():Angle():Right() * fSin) + (self.Entity:GetForward():Angle():Up() * fCos)
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

        anglebuffer= CurTime()
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
        
            if ( ColVector.z >=4 && (ply:GetVelocity().z < 0 or ColVector:Dot(self.Entity:GetForward()) < 0)) then
                //self.Entity.Emitter = nil
                //print("Player is on top of the collision\n")
                pushvel = Vector(0,0,500)
                self.Entity:EmitSound("Small_Bill.Defeated")
                self.Exploded = true
                self.Defeated = true
                self.Emitter = nil

                local phys = self.Entity:GetPhysicsObject()
                if phys:IsValid() then 
                        phys:SetMass(20)
                        phys:Sleep()
                        phys:EnableGravity( true )
                end

                if ( self.Sound ) then
                        self.Sound:Stop()
                end

                local health = ply:Health()
                ply:SetHealth(health+25)
            else
                //print("I pushed back a player named: " .. ply:Nick() .. "!\n")
                local hitang = ColVector:GetNormalized()
                pushvel = hitang * 350
                pushvel.z = math.max(pushvel.z, 100)
                ply:TakeDamage(20,self.Creator, self.Entity)
                if(self.Entity:IsOnFire()) then ply:Ignite(5) end
                self.Sound:SetSoundLevel( 20 )
                self.Entity:EmitSound("Bill.Damage")
                self.Sound:SetSoundLevel( 65 )
            end

            ply:SetGroundEntity(nil)
            ply:SetVelocity(ply:GetVelocity() + pushvel)
            ply.was_pushed = {att=owner, t=CurTime(), wep=self:GetClass()}
        end

        self.HitCount = self.HitCount + 1
        self.Entity:NextThink(CurTime())
end

//tracking code

//first we need to find out which player is closest && in front of us

// Gets the nearest player relative to pos and within 90 degrees of fwd vector

function GetNearestPlayerInfront(pos,fwd) 

        local dist = 200000
        local ply = NULL
        local targetvect = NULL

        for _, v in pairs( player.GetAll() ) do

                //find distance to a player
                local newdist = pos:DistToSqr( v:GetPos() )

                //find angle to between where we are pointing and that player
                targetvect = v:GetPos()-pos
                ntarget = targetvect:GetNormalized()
                nfwd = fwd:GetNormalized()
                local dot = nfwd:Dot(ntarget)
                tarangle = math.deg(math.acos(dot))

                ////print("mypos: " .. pos.x .. "," .. pos.y  .. "," .. pos.z .. "\ntarget player: " .. v:Nick() .. "\ntarget pos: " .. v:GetPos().x .. "," .. v:GetPos().y  .. "\ntarget vector:" .. targetvect.x .. "," .. targetvect.y .. "," .. targetvect.z .. "\nangle between is ".. tarangle .. "\n")
                
                //check if that player is closer than the last one we check and also not behind us and also not behind a wall and is alive!
                /*local tr = util.TraceLine( {
                        start = pos,
                        endpos = v:GetPos()
                        filter = function(ent) if !(ent == self.Entity) then return true end end
                })
                */


                if (newdist < dist && (tarangle < 90)) && v:Alive() then
                        ply = v
                        dist = newdist
                end
        end

        if(ply.IsPlayer()) then //print("\nplayer found: " .. ply:Nick() .. " at a distance of: " .. math.sqrt(dist) .. " and an angle of: " .. tarangle .. "\n")
        else ////print ("no players found")
        end 

        return ply
end


function ENT:Track()

        local fwd = self.Entity:GetForward()

        ////print("my forward vector is: " .. fwd.x .. "," .. fwd.y .. "," .. fwd.z .. "\n")

        target = GetNearestPlayerInfront(self:GetPos(),fwd)

        

        if (target:IsPlayer() && (!self:OnTarget(target))) then
                ////print("My target is " .. target:GetName() .. "\nTracking target!\n" )

                //remember our speed and velocity

                local currentvelocity = self.Entity:GetVelocity()
                local speed = currentvelocity:Length()

                ////print("My speed is " .. speed .. "\n" )

                //we want to aim at the eyes of our victim
                
                local aimpoint = target:EyePos()
                local targetvect = aimpoint - self.Entity:GetPos()
                local targetang = targetvect:Angle()
                local ntarget = targetvect:GetNormalized()
                local dot = fwd:Dot(ntarget)
                local ang = math.deg(math.acos(dot))

                //difference between our velocity and the target vector gives us a velocity change vector
                local vchange = targetvect - fwd

                ////print("target vector:" .. targetvect.x .. "," .. targetvect.y .. "," .. targetvect.z .. "\n")

                ////print("my change vector is: " .. vchange.x .. "," .. vchange.y .. "," .. vchange.z .. "\n")

                //we want to find the rotation (normal) vector between our forward vecor and target vector
                local normal = (fwd:Cross(targetvect)):GetNormalized()

                
                ////print("angle between me and my target is: " .. tarangle .. "\n correcting... \n")

                local currentang = fwd:Angle()
                ////print("the angle im pointing is: "  .. currentang.x .. "," .. currentang.y .. "," .. currentang.z .. "\n")

                ////print("my rotation axis is: "  .. normal.x .. "," .. normal.y .. "," .. normal.z .. "\n")
                ////print("my velocity angle is ".. currentang.x .. "," .. currentang.y .. "," .. currentang.z .. "\n")
                local dang = currentang - targetang
                
                dx = math.AngleDifference( targetang.y, currentang.y)
                dy = math.AngleDifference( targetang.x, currentang.x)

                ////print("I'm facing " .. dx .. " degrees away from my target in my xy (left/right) plane.\n")
                ////print("I'm facing " .. dy .. " degrees away from my target in my xz (up/down) plane.\n")
                
                //rotate left or right
                if math.abs(dx) < 5 then   
                elseif normal.z > 0 then currentang:RotateAroundAxis(currentang:Up(),1)
                elseif normal.z <0 then currentang:RotateAroundAxis(currentang:Up(),-1) end

                //rotate up or down
                if math.abs(dy) < 5 && targetvect:Length() > 100 then

                elseif vchange.z < 0 then currentang:RotateAroundAxis(currentang:Right(),-0.5)
                elseif vchange.z > 0 then currentang:RotateAroundAxis(currentang:Right(),0.5) 
                
                end
                
                
                ////print("my new velocity angle is ".. currentang.x .. "," .. currentang.y .. "," .. currentang.z .. "\n")
                
                
                self.Entity:SetAngles(currentang)
                
                //self.Entity:GetPhysicsObject():RotateAroundAxis(normal,math.max(tarangle/10,1))
                
                local newfwd = currentang:Forward()

                //local newvelocity = (newfwd * 10)
                ////print("my new velocity angle is ".. newvelocity.x .. "," .. newvelocity.y .. "," .. newvelocity.z .. "\n")

                self.Entity:GetPhysicsObject():SetVelocityInstantaneous(newfwd*self.Speed)

         
        elseif (self:OnTarget(target)) 
                then

                //print( "I'm on target!\n" )

        else 
                //print("No target found!") 
        
        end        

        self.Entity:NextThink(CurTime())

end

function ENT:OnTarget(target)

        local fwd = self.Entity:GetForward()

        local tr = util.TraceLine( {
                start = self.Entity:GetPos() + fwd*20 ,
                endpos = self.Entity:GetPos() + fwd*10000
        })
        ////print(tr.Entity)

        if ((self.target) && (tr.Entity == target)) then return true
                else return false end
end

function ENT:OnTakeDamage(dmginfo)
     
        self:SetHealth(self:Health() - dmginfo:GetDamage())
  
        if (self:Health() < 0) then
           self.Dead = true
        end
end