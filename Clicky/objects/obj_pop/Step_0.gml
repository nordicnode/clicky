/// @description drift
x += hsp;
y += vsp;
vsp += 0.035;
hsp *= 0.97;
life -= 1;
if (life <= 0) instance_destroy();
