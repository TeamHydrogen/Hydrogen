--[[

Hey reader! If you've seen this branch then you'll see that this is a new
file and is empty!

I'm currently working on documentation first and then going to
this, however I am debating whether we should take an object-oriented
approach to this or functional

The api would look something similar to this for OOP:

HitboxHandler.new()
Hitbox:itemEnteredHitbox(function() 
    -- avoid 
end)
Hitbox:Destroy() -- cleans everything up

This would make every hitbox independent and would probably be easier

Or

HitboxHandler.CreateHitbox("HitboxName")
HitboxHandler.HitboxEntered("HitboxName", function(Part)
    
end)
HitboxHandler.DestroyHitbox("HitboxName")

Please discuss in the discord channel which you think would be best and why

]]

local Hitboxes = {}

return Hitboxes
